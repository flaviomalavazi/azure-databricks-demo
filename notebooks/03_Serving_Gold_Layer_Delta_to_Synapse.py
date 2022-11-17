# Databricks notebook source
# MAGIC %run "./00_Create_variables" $reset_data=False

# COMMAND ----------

# MAGIC %md 
# MAGIC #Goals for this demo
# MAGIC 1. Databricks reads IoT Telemetry + Maintanance data from Delta Lake (Silver Layer - enriched), joins data and stores on Delta Lake (Gold Layer - aggreaged) </br>
# MAGIC 2. Databricks writes Gold Layer data to Synapse Analytics Dedicated SQL Pool </br>
# MAGIC 3. Data is ready to be consumed by BI/Analytics and Data Science / Machine Learning</br>
# MAGIC <img src="https://mcg1stanstor00.blob.core.windows.net/images/demos/Azure Demos/azure-integration-demo-part3-v2.png" alt="" width="600">

# COMMAND ----------

# MAGIC %md
# MAGIC 
# MAGIC #Read Silver tables (batch + streaming)

# COMMAND ----------

import time
from pyspark.sql import functions as F

df_turbine_sensor = ( spark.readStream.format('delta').option('ignoreChanges',True).table(f'{target_database}.turbine_sensor_agg')
  .withColumn("hour", F.date_format(F.col("window"), 'H:mm')) )
df_maintenanceheader = spark.readStream.format('delta').option('ignoreChanges',True).table(f'{target_database}.maintenance_header')
df_poweroutput = spark.readStream.format('delta').option('ignoreChanges',True).table(f'{target_database}.power_output')

df_turbine_sensor.createOrReplaceTempView("turbine_sensor_agg_streaming")
df_maintenanceheader.createOrReplaceTempView("maintenance_header_streaming")
df_poweroutput.createOrReplaceTempView("power_output_streaming")

# COMMAND ----------

# MAGIC %md
# MAGIC 
# MAGIC #Create Gold table

# COMMAND ----------

df_gold_turbine = spark.sql(f"""
SELECT 
  sensor.*,
  weather.temperature, weather.humidity, weather.windspeed, weather.winddirection,
  maint.maintenance,
  power.power
FROM turbine_sensor_agg_streaming sensor
INNER JOIN {target_database}.weather_agg weather
  ON sensor.`date` = weather.`date`
  AND sensor.`window` = weather.`window`
INNER JOIN maintenance_header_streaming maint
  ON sensor.`date` = maint.`date`
  and sensor.deviceid = maint.deviceid
INNER JOIN power_output_streaming power
  ON sensor.`date` = power.`date`
  AND sensor.`window` = to_timestamp(power.`window`, 'yyyy-MM-dd H:mm:ss')
  AND sensor.deviceid = power.deviceid
""")

# COMMAND ----------

display(df_gold_turbine)

# COMMAND ----------

def merge_delta(incremental, target): 
  incremental.dropDuplicates(['date','window','deviceid']).createOrReplaceTempView("incremental")
  
  try:
    # MERGE records into the target table using the specified join key
    incremental._jdf.sparkSession().sql(f"""
      MERGE INTO delta.`{target}` t
      USING incremental i
      ON i.`date`=t.`date` AND i.`window` = t.`window` AND i.deviceId = t.deviceid
      WHEN MATCHED THEN UPDATE SET *
      WHEN NOT MATCHED THEN INSERT *
    """)
  except:
    # If the †arget table does not exist, create one
    incremental.write.format("delta").partitionBy("date").save(target)
    
turbine_gold = (
    df_gold_turbine
    .writeStream                                                               # Write the resulting stream
    .foreachBatch(lambda i, b: merge_delta(i, GOLD_PATH + "turbine_gold"))     # Pass each micro-batch to a function
    .outputMode("append")
    .option("checkpointLocation", CHECKPOINT_PATH + "turbine_gold")             # Checkpoint so we can restart streams gracefully
    .start()
)

# COMMAND ----------

# spark.sql(f"DROP TABLE IF EXISTS iot_demo.turbine_gold")
# Create the external tables once data starts to stream in
while True:
  try:
    spark.sql(f'CREATE TABLE IF NOT EXISTS {target_database}.turbine_gold USING DELTA LOCATION "{GOLD_PATH + "turbine_gold"}"')
    break
  except Exception as e:
    print("error, trying again in 3 seconds")
    print(e)
    time.sleep(3)
    pass

# COMMAND ----------

spark.sql(f"select * from {target_database}.turbine_gold").display()

# COMMAND ----------

# MAGIC %md
# MAGIC 
# MAGIC #Write gold table to Synapse Dedicated SQL Pool

# COMMAND ----------

# DBTITLE 1,Writing the Data to Azure Synapse
# Use COPY INTO for faster loads to Synapse from Databricks
spark.conf.set("spark.databricks.sqldw.writeSemantics", "copy") 

write_to_synapse = (
  spark.readStream
    .format('delta')
    .option('ignoreChanges',True)
    .table(f'{target_database}.turbine_gold')                                   # Read in Gold turbine data from Delta as a stream
    .writeStream
    .format("com.databricks.spark.sqldw")                                       # Write to Synapse (SQL DW connector)
    .option("url", JDBC_URL)                                                    # SQL Pool JDBC connection (with SQL Auth) string
    .option("tempDir", SYNAPSE_PATH)                                            # Temporary ADLS path to stage the data (with forwarded permissions)
    .option("forwardSparkAzureStorageCredentials", "true")
    .option("dbTable", f"{target_database}.turbine_gold")                       # Table in Synapse to write to
    .option("checkpointLocation", CHECKPOINT_PATH_SYNAPSE + "turbine_gold")     # Checkpoint for resilient streaming
    .start()
)