# Databricks notebook source
# MAGIC %run "./00_Create_variables" $reset_data=False

# COMMAND ----------

database_host = dbutils.secrets.get(scope = "keyvault-managed-secret-scope", key = "sql-server-host") # sql_server host
database_port = dbutils.secrets.get(scope = "keyvault-managed-secret-scope", key = "sql-server-port") # sql server port
database_name = dbutils.secrets.get(scope = "keyvault-managed-secret-scope", key = "sql-server-database") # database name
user = dbutils.secrets.get(scope = "keyvault-managed-secret-scope", key = "sql-server-admin-username") # sql server admin username
password = dbutils.secrets.get(scope = "keyvault-managed-secret-scope", key = "sql-server-admin-password") # sql server admin password

# COMMAND ----------

url = f"""jdbc:sqlserver://{database_host}:{database_port};database={database_name};user={user}@{database_host.split(".")[0]};password={password};encrypt=true;trustServerCertificate=false;hostNameInCertificate=*.database.windows.net;loginTimeout=30;databaseName={database_name};"""

# COMMAND ----------

query = f"""SELECT DISTINCT TABLE_SCHEMA FROM {database_name}.INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE'"""

schemaDF = (spark.read
              .format("com.microsoft.sqlserver.jdbc.spark")
              .option("url", url)
              .option("query", query)
              .load())

schemas = [row['TABLE_SCHEMA'] for row in schemaDF.collect()]

print(f"The schemas: {schemas} have tables")
schemas_filter = "','".join(schemas)

# COMMAND ----------

query = f"""
            SELECT
                TABLE_SCHEMA
                ,TABLE_NAME
                ,COLUMN_NAME
                ,ORDINAL_POSITION
                ,COLUMN_DEFAULT
                ,IS_NULLABLE
                ,DATA_TYPE
                ,CHARACTER_MAXIMUM_LENGTH
            FROM
                INFORMATION_SCHEMA.COLUMNS
            WHERE
                TABLE_SCHEMA IN ('{schemas_filter}')
        """

tablesDF = (spark.read
  .format("com.microsoft.sqlserver.jdbc.spark")
  .option("url", url)
  .option("query", query)
  .load().orderBy(["TABLE_SCHEMA", "TABLE_NAME", "ORDINAL_POSITION"]))

tables = [{"schema": row['TABLE_SCHEMA'], "table_name": row['TABLE_NAME']} for row in tablesDF.select("TABLE_NAME", "TABLE_SCHEMA").distinct().collect()]

print(f"There are {len(tables)} tables to be read...")

# COMMAND ----------

tableData = {}
for table in tables:
    # Read from SQL Table
    tableData[table['table_name']] = {}
    tableData[table['table_name']]['schema'] = table['schema']
    tableData[table['table_name']]['data'] = (spark.read
                      .format("com.microsoft.sqlserver.jdbc.spark")
                      .option("url", url)
                      .option("dbtable", table['table_name'])
                      .load())

# COMMAND ----------

number_of_tables = len(tables)
print(f"Saving {number_of_tables} tables to ADLS...")
for table in tableData.keys():
    tableData[table]['data'].write.format("parquet").mode("overwrite").save(f"{varLandingZonePath}/{tableData[table]['schema']}/{table}/")
    print(f"Table: {tableData[table]['schema']}.{table} saved successfully!")
