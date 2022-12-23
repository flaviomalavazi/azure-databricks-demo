# Databricks notebook source
# MAGIC %run "../00_Create_variables" $reset_data=False

# COMMAND ----------

# MAGIC %md-sandbox
# MAGIC # Wind Turbine Predictive Maintenance with the Lakehouse
# MAGIC 
# MAGIC <img src="https://github.com/QuentinAmbard/databricks-demo/raw/main/manufacturing/wind_turbine/turbine-photo-open-license.jpg" width="500px" style="float:right; margin-left: 20px"/>
# MAGIC Predictive maintenance is a key capabilities in Manufacturing industry. Being able to repair before an actual failure can drastically increase productivity and efficiency, preventing from long and costly outage. <br/> 
# MAGIC 
# MAGIC Typical use-cases include:
# MAGIC 
# MAGIC - Predict valve failure in gaz/petrol pipeline to prevent from industrial disaster
# MAGIC - Detect abnormal behavior in a production line to limit and prevent manufacturing defect in the product
# MAGIC - Repairing early before larger failure leading to more expensive reparation cost and potential product outage
# MAGIC 
# MAGIC In this demo, our business analyst have determined that if we can proactively identify and repair Wind turbines prior to failure, this could increase energy production by 20%.
# MAGIC 
# MAGIC In addition, the business requested a predictive dashboard that would allow their Turbine Maintenance group to monitore the turbines and identify the faulty one. This will also allow us to track our ROI and ensure we reach this extra 20% productivity gain over the year.
# MAGIC 
# MAGIC 
# MAGIC <img width="1px" src="https://www.google-analytics.com/collect?v=1&gtm=GTM-NKQ8TT7&tid=UA-163989034-1&cid=555&aip=1&t=event&ec=field_demos&ea=display&dp=%2F42_field_demos%2Fmanufacturing%2Fwind_turbine%2Fnotebook_dlt&dt=MANUFACTURING_WIND_TURBINE">

# COMMAND ----------

# MAGIC %md 
# MAGIC 
# MAGIC #Architecture
# MAGIC <img src="https://mcg1stanstor00.blob.core.windows.net/images/demos/Azure Demos/Azure Databricks Lakehouse + with Azure Data Services.jpg" alt="" width="1400" height="1080">

# COMMAND ----------

# MAGIC %md 
# MAGIC #Goals for this demo</br>
# MAGIC 1) Azure Data Factory connects to source system and lands data into parquet file in Data Lake Landing Zone</br>
# MAGIC 2) Azure Data Factory orchestrates the execution of a Databricks Notebook</br>
# MAGIC 3) Databricks reads new and updated files (changed data) using Auto Loader and lands it into Delta Lake table</br>
# MAGIC <img src="https://mcg1stanstor00.blob.core.windows.net/images/demos/Azure Demos/Data Factory to Azure Databricks.jpg" alt="" width="600" height="600">

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
  "cloudFiles.useNotifications": "true",
  "cloudFiles.maxFilesPerTrigger": 1
}

# COMMAND ----------

# read the maintenance_header records from the landing zone using Auto Loader
maintenanceheader_df = (
                        spark.readStream.format("cloudFiles")
                                        .options(**cloudfile)
                                        .option("cloudFiles.schemaLocation", f"{schema_checkpoints_root_path}/maintenance_header_schema")
                                        .load(f"{adf_landing_zone}/dbo/maintenance_header")
                       )

# COMMAND ----------

# read the power_output records from the landing zone using Auto Loader
poweroutput_df = (
                  spark.readStream.format("cloudFiles")
                                    .options(**cloudfile)
                                    .option("cloudFiles.schemaLocation", f"{schema_checkpoints_root_path}/power_output_schema")
                                    .load(f"{adf_landing_zone}/dbo/power_output")
                  )

# COMMAND ----------

autoload = (
  maintenanceheader_df.writeStream 
  .format("delta")
  .outputMode("append")
  .trigger(once=True)
  .option("checkpointLocation", f"{checkpoints_root_path}/maintenanceheader_v2/")
  .option("mergeSchema", "true")
  .start(f"{delta_tables_root_path}/silver/maintenanceheader_v2")
)

autoload.awaitTermination()

# COMMAND ----------

autoload = (
  poweroutput_df.writeStream 
  .format("delta") 
  .outputMode("append") 
  .trigger(once=True) 
  .option("checkpointLocation", f"{checkpoints_root_path}/poweroutput_v2/") 
  .option("mergeSchema", "true")
  .start(f"{delta_tables_root_path}/silver/poweroutput_v2")
)

autoload.awaitTermination()

# COMMAND ----------

# MAGIC %md
# MAGIC 
# MAGIC #Create delta tables
# MAGIC Create tables on top of delta storage so that tables can be easily found and managed for end users

# COMMAND ----------

spark.sql(f"CREATE SCHEMA IF NOT EXISTS {target_database}_v2")

# COMMAND ----------

spark.sql(f"""
              CREATE TABLE IF NOT EXISTS {target_database}_v2.maintenance_header
              USING DELTA
              LOCATION '{delta_tables_root_path}/silver/maintenanceheader_v2'
              """
          )

# COMMAND ----------

spark.sql(f"""
              CREATE TABLE IF NOT EXISTS {target_database}_v2.power_output
              USING DELTA
              LOCATION '{delta_tables_root_path}/silver/poweroutput_v2'
              """
          )