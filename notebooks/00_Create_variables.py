# Databricks notebook source
dbutils.widgets.dropdown("reset_data", "True", ["True", "False"], "Reset all data")
reset_data = True if dbutils.widgets.get("reset_data") == "True" else False

# COMMAND ----------
varSubscriptionId = dbutils.secrets.get(scope = "keyvault-managed-secret-scope", key = "subscription-id")
varTenantId = dbutils.secrets.get(scope = "keyvault-managed-secret-scope", key = "tenant-id")
varResourceGroupName = dbutils.secrets.get(scope = "keyvault-managed-secret-scope", key = "resource-group-name")
varStorageAccountName = dbutils.secrets.get(scope = "keyvault-managed-secret-scope", key = "storage-account-name") # Storage acccount name
varStorageAccountAccessKey = dbutils.secrets.get(scope = "keyvault-managed-secret-scope", key = "storage-account-key") # Storage access key
# varApplicationId = dbutils.secrets.get(scope = "keyvault-managed-secret-scope", key = "storage-account-application-id")
# varAuthenticationKey = dbutils.secrets.get(scope = "keyvault-managed-secret-scope", key = "storage-account-authentication-key")
varFileSystemName = dbutils.secrets.get(scope = "keyvault-managed-secret-scope", key = "storage-account-general-purpose-container") # ADLS container name
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

EVENT_HUB_NAME = dbutils.secrets.get(scope = "keyvault-managed-secret-scope", key = "eventhub-name")
IOT_ENDPOINT = dbutils.secrets.get(scope = "keyvault-managed-secret-scope", key = "eventhub-iot-endpoint")
target_database = "latam_azure_databricks_iot_demo"

streamingPath = varRootBucketPath + "/streaming_data/"
BRONZE_PATH = streamingPath + "bronze/"
SILVER_PATH = streamingPath + "silver/"
GOLD_PATH = streamingPath + "gold/"
CHECKPOINT_PATH = streamingPath + "checkpoint/"

# JDBC_URL = dbutils.secrets.get(scope="fmalavazi_azure_demo", key="jdbc_url")

SYNAPSE_PATH = f"abfss://{synapse_storage_container}@{varStorageAccountName}.dfs.core.windows.net/synapse-tmp/"
CHECKPOINT_PATH_SYNAPSE = f"{varRootBucketPath}/synapse-checkpoint/iot-demo/"

# COMMAND ----------

try:
  dbutils.fs.ls(varLandingZonePath)
except:
  pass

# COMMAND ----------

if reset_data:
    from functools import reduce
    spark.sql(f"USE CATALOG hive_metastore")
    try:
        dbutils.fs.rm(varLandingZonePath, True)
        dbutils.fs.rm(streamingPath, True)
        dbutils.fs.rm(delta_tables_root_path, True)
        dbutils.fs.rm(checkpoints_root_path, True)
        dbutils.fs.rm(schema_checkpoints_root_path, True)
    except Exception as e:
        print(e)
    spark.sql(f"DROP SCHEMA IF EXISTS {target_database} CASCADE")
#     df = spark.read.format("csv").option("header",True).load(f"{varLandingZonePath}_raw/power_data_raw/power_output.csv")
#     power_columns = ["deviceId", "date", "window", "power"]
#     old_columns = df.schema.names
#     df = reduce(lambda df, idx: df.withColumnRenamed(old_columns[idx], power_columns[idx]), range(len(old_columns)), df)
#     df2 = spark.read.format("csv").option("header",True).load(f"{varLandingZonePath}_raw/status_data_raw/maintenance_header.csv")
#     status_data_columns = ["deviceId", "date", "maintenance"]
#     old_columns = df2.schema.names
#     df2 = reduce(lambda df2, idx: df2.withColumnRenamed(old_columns[idx], status_data_columns[idx]), range(len(old_columns)), df2)
#     df.write.parquet(f"{varLandingZonePath}/sensor_data")
#     df2.write.parquet(f"{varLandingZonePath}/status_data")
#     del df, df2
