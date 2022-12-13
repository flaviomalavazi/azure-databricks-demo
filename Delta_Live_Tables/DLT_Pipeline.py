# Databricks notebook source
import dlt
import pyspark.sql.functions as F

# COMMAND ----------

varSubscriptionId = dbutils.secrets.get(scope = "keyvault-managed-secret-scope", key = "subscription-id")
varTenantId = dbutils.secrets.get(scope = "keyvault-managed-secret-scope", key = "tenant-id")
varResourceGroupName = dbutils.secrets.get(scope = "keyvault-managed-secret-scope", key = "resource-group-name")
varStorageAccountName = dbutils.secrets.get(scope = "keyvault-managed-secret-scope", key = "storage-account-name")     # Storage acccount name
varStorageAccountAccessKey = dbutils.secrets.get(scope = "keyvault-managed-secret-scope", key = "storage-account-key") # Storage access key
varApplicationId = dbutils.secrets.get(scope = "keyvault-managed-secret-scope", key = "azure-ad-application-id")
varAuthenticationKey = dbutils.secrets.get(scope = "keyvault-managed-secret-scope", key = "azure-id-authentication-key")
varFileSystemName = dbutils.secrets.get(scope = "keyvault-managed-secret-scope", key = "storage-account-general-purpose-container") # ADLS container name
varEventHubNameSpace = dbutils.secrets.get(scope = "keyvault-managed-secret-scope", key = "eventhub-namespace") # EventHubNamespace
varEventHubName = dbutils.secrets.get(scope = "keyvault-managed-secret-scope", key = "eventhub-name") # EventHubName

synapse_storage_container = dbutils.secrets.get(scope = "keyvault-managed-secret-scope", key = "storage-account-synapse-container") # ADLS container name for Synapse Integration

varRootBucketPath = f"abfss://{varFileSystemName}@{varStorageAccountName}.dfs.core.windows.net"
varLandingZonePath = f"abfss://{varFileSystemName}@{varStorageAccountName}.dfs.core.windows.net/landing"

adf_landing_zone = varLandingZonePath
delta_tables_root_path = f"{varRootBucketPath}/delta_tables"
checkpoints_root_path = f"{varRootBucketPath}/checkPoints"
schema_checkpoints_root_path = f"{varRootBucketPath}/schemaCheckPoints"

spark.conf.set("fs.azure.account.auth.type", "OAuth")
spark.conf.set("fs.azure.account.oauth.provider.type",  "org.apache.hadoop.fs.azurebfs.oauth2.ClientCredsTokenProvider")
spark.conf.set("fs.azure.account.oauth2.client.id", varApplicationId)
spark.conf.set("fs.azure.account.oauth2.client.secret", varAuthenticationKey)
spark.conf.set("fs.azure.account.oauth2.client.endpoint", f"https://login.microsoftonline.com/{varTenantId}/oauth2/token")
spark.conf.set(f"fs.azure.account.key.{varStorageAccountName}.dfs.core.windows.net", varStorageAccountAccessKey)

# COMMAND ----------

# Auto Loader configurations
cloudfile = {
#   Authentication Options for access using an Azure AD App
  "cloudFiles.subscriptionId": varSubscriptionId,
  "cloudFiles.tenantId": varTenantId,
  "cloudFiles.clientId": varApplicationId,
  "cloudFiles.clientSecret": varAuthenticationKey,
  "cloudFiles.resourceGroup": varResourceGroupName,
  "cloudFiles.format": "parquet",
  "cloudFiles.useNotifications": "true"
}

# COMMAND ----------

@dlt.table
def silver_maintenance_data():
    return (
        spark.readStream.format("cloudFiles")
            .options(**cloudfile)
            .option("cloudFiles.schemaLocation", f"{schema_checkpoints_root_path}/turbine_status")
            .load(f"{adf_landing_zone}/status_data")
    )

# COMMAND ----------

@dlt.table
def silver_poweroutput_data():
    return (
        spark.readStream.format("cloudFiles")
            .options(**cloudfile)
            .option("cloudFiles.schemaLocation", f"{schema_checkpoints_root_path}/turbine_sensor_data")
            .load(f"{adf_landing_zone}/power_output")
    )

# COMMAND ----------

@dlt.table
def bronze_sensor_data():
    readConnectionString=dbutils.secrets.get(scope = "keyvault-managed-secret-scope", key = "eventhub-iot-endpoint")
    eh_sasl = f'kafkashaded.org.apache.kafka.common.security.plain.PlainLoginModule required username="$ConnectionString" password="{readConnectionString}";'
    kafka_options = {
         "kafka.bootstrap.servers": f"{varEventHubNameSpace}.servicebus.windows.net:9093",
         "kafka.sasl.mechanism": "PLAIN",
         "kafka.security.protocol": "SASL_SSL",
         "kafka.request.timeout.ms": "60000",
         "kafka.session.timeout.ms": "30000",
         "startingOffsets": "earliest",
         "kafka.sasl.jaas.config": eh_sasl,
         "subscribe": f"{varEventHubName}",
    }
    # Schema of incoming data from IoT hub
    schema = "timestamp timestamp, deviceId string, temperature double, humidity double, windspeed double, winddirection string, rpm double, angle double"
    iot_stream = (
                spark.readStream.format("kafka")
                  .options(**kafka_options)
                  .load()
                  .withColumn('reading', F.from_json(F.col('value').cast('string'), schema))        # Extract the "body" payload from the messages
                  .select('reading.*', F.to_date('reading.timestamp').alias('date'))                # Create a "date" field for partitioning
    )
    return iot_stream

# COMMAND ----------

@dlt.table
def silver_turbine_data():
    return dlt.read_stream("bronze_sensor_data").where("temperature IS NULL").select("date", "timestamp", "deviceId", "rpm", "angle")

# COMMAND ----------

@dlt.table
def silver_weather_data():
    return dlt.read_stream("bronze_sensor_data").where("temperature IS NOT NULL").select("date", "deviceid", "timestamp", "temperature", "humidity", "windspeed", "winddirection")

# COMMAND ----------

@dlt.view
def silver_agg_weather_data_vw():
    stream_data = (
                    dlt.read_stream("silver_weather_data")
                    .withWatermark("timestamp", "1 hour")
                    .groupby("date"
                             , F.window(F.col("timestamp"), "1 hour").alias("agg_window")
                             , "deviceId"
                            )
                    .agg(
                            F.avg("temperature").alias("temperature") 
                            ,F.avg("humidity").alias("humidity")
                            ,F.avg("windspeed").alias("windspeed")
                            ,F.last("winddirection").alias("winddirection")
                            ,F.date_trunc("hour", F.min(F.col("timestamp"))).alias("window")
                        )
                    .withColumn("watermark", F.current_timestamp())
    )
    return stream_data
        
target = "silver_agg_weather_data"
source = f"{target}_vw"

dlt.create_streaming_live_table(target)

dlt.apply_changes(
  target = target,
  source = source,
  keys = ["date", "window", "deviceid"],
  sequence_by = F.col("watermark"),
  stored_as_scd_type = 1
)

# COMMAND ----------

@dlt.view
def silver_agg_turbine_data_vw():
    stream_data = (
                    dlt.read_stream("silver_turbine_data")
                    .withWatermark("timestamp", "1 hour")
                    .groupby("date"
                             , F.window(F.col("timestamp"), "1 hour").alias("agg_window")
                             , "deviceId"
                            )
                    .agg(
                            F.avg("rpm").alias("rpm") 
                            ,F.avg("angle").alias("angle")
                            ,F.date_trunc("hour", F.min(F.col("timestamp"))).alias("window")
                    )
                    .withColumn("watermark", F.current_timestamp())
    )
    return stream_data
        
target = "silver_agg_turbine_data"
source = f"{target}_vw"

dlt.create_streaming_live_table(target)

dlt.apply_changes(
  target = target,
  source = source,
  keys = ["date", "window", "deviceid"],
  sequence_by = F.col("watermark"),
  stored_as_scd_type = 1
)

# COMMAND ----------

@dlt.view
def gold_turbine_data_vw():
    turbine_sensor = dlt.read_stream("silver_agg_turbine_data").withColumn("hour", F.date_format(F.col("window"), 'H:mm'))
    maintenance = dlt.read_stream("silver_maintenance_data")
    power_output = dlt.read_stream("silver_poweroutput_data")
    weather = dlt.read_stream("silver_agg_weather_data")
    final_data = (turbine_sensor.select("date", "window", "deviceId", "rpm", "angle")
                  .join(weather.select("date", "window", "temperature", "humidity", "windspeed", "winddirection"), ["date", "window"])
                  .join(maintenance.select("date", "deviceId", "maintenance"), ["date", "deviceId"])
                  .join(power_output.select("date", "window", "deviceId", "power"), ["date", "window", "deviceId"])
                  .withColumn("watermark", F.current_timestamp())
                 )
    return final_data
    
target = "gold_turbine_data"
source = f"{target}_vw"

dlt.create_streaming_live_table(target)

dlt.apply_changes(
  target = target,
  source = source,
  keys = ["date", "window", "deviceid"],
  sequence_by = F.col("watermark"),
  stored_as_scd_type = 1
)
