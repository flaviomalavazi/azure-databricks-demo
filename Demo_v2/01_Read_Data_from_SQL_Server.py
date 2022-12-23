# Databricks notebook source
# MAGIC %run "./00_Create_variables" $reset_data=False

# COMMAND ----------

# MAGIC %sh
# MAGIC curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
# MAGIC curl https://packages.microsoft.com/config/ubuntu/16.04/prod.list > /etc/apt/sources.list.d/mssql-release.list
# MAGIC sudo apt-get update
# MAGIC sudo ACCEPT_EULA=Y apt-get -q -y install msodbcsql17

# COMMAND ----------

from sqlalchemy import create_engine
import pyodbc
import urllib
import pandas as pd
from datetime import datetime, timedelta
from random import randrange, random, choice
from pyspark.sql import DataFrame
from pyspark.sql.types import *
import pyspark.sql.functions as F

# COMMAND ----------

driver = "ODBC Driver 17 for SQL Server"
database_host = dbutils.secrets.get(scope = "keyvault-managed-secret-scope", key = "sql-server-host") # sql_server host
database_port = dbutils.secrets.get(scope = "keyvault-managed-secret-scope", key = "sql-server-port") # sql server port
database_name = dbutils.secrets.get(scope = "keyvault-managed-secret-scope", key = "sql-server-database") # database name
user = dbutils.secrets.get(scope = "keyvault-managed-secret-scope", key = "sql-server-admin-username") # sql server admin username
password = dbutils.secrets.get(scope = "keyvault-managed-secret-scope", key = "sql-server-admin-password") # sql server admin password

# COMMAND ----------

params = urllib.parse.quote_plus(f"DRIVER={driver};SERVER=tcp:{database_host},{database_port};DATABASE={database_name};UID={user};PWD={password}")
engine = create_engine("mssql+pyodbc:///?odbc_connect=%s" % params)

# COMMAND ----------

query = f"""
            SELECT
                DISTINCT TABLE_SCHEMA
            FROM
                {database_name}.INFORMATION_SCHEMA.TABLES
            WHERE
                TABLE_TYPE = 'BASE TABLE'
          """

schemas = list(pd.read_sql(query, engine).TABLE_SCHEMA.unique())
schema_filter = "','".join(schemas)

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
                TABLE_SCHEMA IN ('{schema_filter}')
            ORDER BY
                TABLE_SCHEMA
                ,TABLE_NAME
                ,ORDINAL_POSITION
        """

table_schemas = pd.read_sql(query, engine)
tables = list(table_schemas.TABLE_NAME.unique())

print(f"There are {len(tables)} tables to be read...")

# COMMAND ----------

table_definitions = {}
for schema in schemas:
    schema_subset = table_schemas[table_schemas.TABLE_SCHEMA == schema]
    table_definitions = {f"{table}": schema_subset[schema_subset.TABLE_NAME == table].set_index("TABLE_NAME").to_dict("list") for table in schema_subset.TABLE_NAME.unique()}

# COMMAND ----------

for table in table_definitions.keys():
    table_definitions[table]['query'] = f"""SELECT * FROM {table_definitions[table]['TABLE_SCHEMA'][0]}.{table}"""

# COMMAND ----------

# type_conversions = {
#     "date": DateType(),
#     "datetime": TimestampType(),
#     "float": FloatType(),
#     "int": IntegerType()
# }

# def type_converter(incoming_type, incoming_column_length):
#     try:
#         return type_conversions[incoming_type]
#     except KeyError:
#         return StringType()
# #         if incoming_type not in ("nvarchar", "varchar") or incoming_column_length < 0:
# #             return StringType()
# #         elif incoming_type == "nvarchar" and incoming_column_length > 0:
# #                 return CharType(incoming_column_length)
# #         elif incoming_type == "varchar" and incoming_column_length > 0:
# #             return VarcharType(incoming_column_length)
#     except Exception as e:
#         print(f"{e}, incoming_type = {incoming_type}, incoming_column_length = {incoming_column_length}")
#         raise e

# COMMAND ----------

# for table in table_definitions.keys():
#     table_definitions[table]["table_spark_schema"] = {column_name: {"type": type_converter(column_type, column_length), "nullable": True if column_nullable == "YES" else False} for column_name, column_type, column_length, column_nullable in zip(table_definitions[table]['COLUMN_NAME'], table_definitions[table]['DATA_TYPE'], table_definitions[table]['CHARACTER_MAXIMUM_LENGTH'], table_definitions[table]['IS_NULLABLE'])}

# COMMAND ----------

for table in table_definitions.keys():
    table_definitions[table]["sql_server_data"] = spark.createDataFrame(pd.read_sql(table_definitions[table]["query"], engine))

# COMMAND ----------

number_of_tables = len(list(table_definitions.keys()))
print(f"Saving {number_of_tables} tables to ADLS...")
for table in table_definitions.keys():
    table_definitions[table]["sql_server_data"].write.format("parquet").mode("overwrite").save(f"{varLandingZonePath}/{table_definitions[table]['TABLE_SCHEMA'][0]}/{table}/")
    print(f"Table: {table_definitions[table]['TABLE_SCHEMA'][0]}.{table} saved successfully!")