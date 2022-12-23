# Databricks notebook source
dbutils.widgets.dropdown("reset_data", "True", ["True", "False"], "Reset all data")
reset_data = True if dbutils.widgets.get("reset_data") == "True" else False

# COMMAND ----------

varSubscriptionId = dbutils.secrets.get(scope = "keyvault-managed-secret-scope", key = "subscription-id")
varTenantId = dbutils.secrets.get(scope = "keyvault-managed-secret-scope", key = "tenant-id")
varResourceGroupName = dbutils.secrets.get(scope = "keyvault-managed-secret-scope", key = "resource-group-name")
varStorageAccountName = dbutils.secrets.get(scope = "keyvault-managed-secret-scope", key = "storage-account-name") # Storage acccount name
varStorageAccountAccessKey = dbutils.secrets.get(scope = "keyvault-managed-secret-scope", key = "storage-account-key") # Storage access key
varApplicationId = dbutils.secrets.get(scope = "keyvault-managed-secret-scope", key = "azure-ad-application-id")
varAuthenticationKey = dbutils.secrets.get(scope = "keyvault-managed-secret-scope", key = "azure-id-authentication-key")
varFileSystemName = dbutils.secrets.get(scope = "keyvault-managed-secret-scope", key = "storage-account-general-purpose-container") # ADLS container name
varRootBucketPath = f"abfss://{varFileSystemName}@{varStorageAccountName}.dfs.core.windows.net"
varLandingZonePath = f"abfss://{varFileSystemName}@{varStorageAccountName}.dfs.core.windows.net/landing"

adf_landing_zone = varLandingZonePath
delta_live_tables_path = f"{varRootBucketPath}/dlt"
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
#         dbutils.fs.rm(varLandingZonePath, True) # This is not deleted intentionally, we might want to keep the data extracted by adf and delete the data processed by databricks
        dbutils.fs.rm(streamingPath, True)
        dbutils.fs.rm(delta_tables_root_path, True)
        dbutils.fs.rm(checkpoints_root_path, True)
        dbutils.fs.rm(schema_checkpoints_root_path, True)
        dbutils.fs.rm(delta_live_tables_path, True)
    except Exception as e:
        print(e)
    spark.sql(f"DROP SCHEMA IF EXISTS {target_database} CASCADE")

