# Databricks notebook source
# MAGIC %sh
# MAGIC curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
# MAGIC curl https://packages.microsoft.com/config/ubuntu/16.04/prod.list > /etc/apt/sources.list.d/mssql-release.list
# MAGIC sudo apt-get update
# MAGIC sudo ACCEPT_EULA=Y apt-get -q -y install msodbcsql17

# COMMAND ----------

from sqlalchemy import create_engine
import pyodbc
import urllib
from datetime import datetime, timedelta
from random import randrange, random, choice

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

with engine.connect() as con:
    print("Testing connection with SQL Server...")
    rs = con.execute('SELECT GETDATE() as timestamp_of_now')

    for row in rs:
        print(row)
        print("Connection successfull!")

# COMMAND ----------

create_maintenance_header_table = """CREATE TABLE [dbo].[maintenance_header] (
        deviceId nvarchar(64) NOT NULL,
        date date NOT NULL,
        maintenance int NOT NULL
    );"""

create_power_output_table = """CREATE TABLE [dbo].[power_output](
	[deviceId] [nvarchar](max) NOT NULL,
	[date] [date] NOT NULL,
	[window] [datetime] NULL,
	[power] [float] NOT NULL
);
"""

create_last_etl_table = """CREATE TABLE [dbo].[etl_timestamp](
	[TableName] [varchar](50) NULL,
	[LastETLRunTime] [datetime] NULL
);
"""

# COMMAND ----------

try:
    rs = engine.connect().execute(create_maintenance_header_table)
    print(rs)
    maintenance_header_table_rows = engine.connect().execute("select count(1) from dbo.maintenance_header").fetchone()[0]
    print(f"There are {maintenance_header_table_rows} rows on the table")
except Exception as e:
    if "[42S01] [Microsoft][ODBC Driver 17 for SQL Server][SQL Server]There is already an object named 'maintenance_header' in the database." in str(e):
        maintenance_header_table_rows = engine.connect().execute("select count(1) from dbo.maintenance_header").fetchone()[0]
        print(f"There are {maintenance_header_table_rows} rows on that table already, skipping this step")
    else:
        raise e

# COMMAND ----------

try:
    rs = engine.connect().execute(create_power_output_table)
    print(rs)
    power_output_table_rows = engine.connect().execute("select count(1) from dbo.power_output").fetchone()[0]
    print(f"There are {power_output_table_rows} rows on the table")
except Exception as e:
    if "[42S01] [Microsoft][ODBC Driver 17 for SQL Server][SQL Server]There is already an object named 'power_output' in the database." in str(e):
        power_output_table_rows = engine.connect().execute("select count(1) from dbo.power_output").fetchone()[0]
        print(f"There are {power_output_table_rows} rows on that table already, skipping this step")
    else:
        raise e

# COMMAND ----------

try:
    rs = engine.connect().execute(create_last_etl_table)
    print(rs)
    last_etl_table_rows = engine.connect().execute("select count(1) from dbo.etl_timestamp").fetchone()[0]
    print(f"There are {last_etl_table_rows} rows on the table")
except Exception as e:
    if "[42S01] [Microsoft][ODBC Driver 17 for SQL Server][SQL Server]There is already an object named 'etl_timestamp' in the database." in str(e):
        last_etl_table_rows = engine.connect().execute("select count(1) from dbo.etl_timestamp").fetchone()[0]
        print(f"There are {last_etl_table_rows} rows on that table already, skipping this step")
    else:
        raise e

# COMMAND ----------

import pandas as pd
from itertools import islice

turbines = ["WindTurbine-1",
            "WindTurbine-2",
            "WindTurbine-3",
            "WindTurbine-4",
            "WindTurbine-5",
            "WindTurbine-6",
            "WindTurbine-7",
            "WindTurbine-8",
            "WindTurbine-9",
            "WindTurbine-10"]

hour_range = 24

days_to_subtract = 60
days_ahead = 7

begin_date = datetime.today() - timedelta(days=days_to_subtract)

delta = (datetime.today() + timedelta(days=days_ahead)) - begin_date

end_date = datetime.strftime((begin_date + timedelta(days=(delta.days+1))), "%Y-%m-%d")

measurement_times = [x for x in pd.date_range(start= pd.Timestamp(begin_date).round('10T'), end = pd.Timestamp(end_date).round('10T'), freq="10T")]

# COMMAND ----------

maintenances = []
maintenance_block = []
j = 0

for days_to_add in range(delta.days + 1):
    day = datetime.strftime((begin_date + timedelta(days=days_to_add)), "%Y-%m-%d")
    for turbine in turbines:
        maintenances.append(f"""INSERT [dbo].[maintenance_header] ([deviceId], [date], [maintenance]) VALUES (N'{turbine}', CAST(N'{day}' AS Date), {choice([0, 0, 0, 0, 0, 0, 0, 1])})""")
        if j < 99:
            j = j + 1
        else:
            maintenances.append(";")
            maintenance_block.append("\n".join(maintenances))
            maintenances = []
            j = 0
            
if j != 0:
    maintenances.append(";")
    maintenance_block.append("\n".join(maintenances))
    maintenances = []
    j = 0

# COMMAND ----------

if maintenance_header_table_rows < 980:
    for block in maintenance_block:
        rs = engine.connect().execute(block)
        print(rs)

# COMMAND ----------

measurements = []
measurements_block = []
rows_to_insert = 0
batch_size = 100

for window in measurement_times:
    for turbine in turbines:
        measurements.append(f"""INSERT [dbo].[power_output] ([deviceId], [date], [window], [power]) VALUES (N'{turbine}', CAST(N'{datetime.strftime(window, "%Y-%m-%d")}' AS Date), CAST(N'{window}' AS DateTime), {str(round(randrange(0,300)+random(),5))})""")
        rows_to_insert = rows_to_insert + 1
        
i = 0
big_statement = ""
list_of_statements = []
for statement in measurements:
    if i <= batch_size:
        big_statement = f"""{big_statement}\n{statement};"""
        i = i + 1
    else:
        list_of_statements.append(f"""{big_statement}\n{statement};""")
        big_statement = ""
        i = 0

if big_statement != "":
    list_of_statements.append(f"""{big_statement};""")

# COMMAND ----------

power_output_table_rows = engine.connect().execute("select count(1) from dbo.power_output").fetchone()[0]
print(f"There are {power_output_table_rows} rows on the table")

# COMMAND ----------

from time import sleep
i = 0
if power_output_table_rows == 0:
    print(f"{rows_to_insert} rows will be added to the table")
    for statement in list_of_statements:
        rs = engine.connect().execute(statement)
        sleep(0.2)
        i = i + 1
        if (i % int(batch_size/50) == 0):
            print(f"{i} out of {len(list_of_statements)} blocks written")
print(f"{i} blocks were written to the database")

# COMMAND ----------

last_etl_timestamp = datetime.strftime(datetime.now(), "%Y-%m-%dT%H:%M:%S.000")

if last_etl_table_rows == 0:
    rs = engine.connect().execute(f"""INSERT [dbo].[etl_timestamp] ([TableName], [LastETLRunTime]) VALUES (N'maintenance_header', CAST(N'{last_etl_timestamp}' AS DateTime));
INSERT [dbo].[etl_timestamp] ([TableName], [LastETLRunTime]) VALUES (N'power_output', CAST(N'{last_etl_timestamp}' AS DateTime));""")
    print(rs)
else:
    print("There were previous ETLs, updating timestamp...")
    rs = engine.connect().execute(f"""DELETE FROM [dbo].[etl_timestamp] WHERE LastETLRunTime < '{last_etl_timestamp}';""")
    rs = engine.connect().execute(f"""INSERT [dbo].[etl_timestamp] ([TableName], [LastETLRunTime]) VALUES (N'maintenance_header', CAST(N'{last_etl_timestamp}' AS DateTime));
    INSERT [dbo].[etl_timestamp] ([TableName], [LastETLRunTime]) VALUES (N'power_output', CAST(N'{last_etl_timestamp}' AS DateTime));""")
    last_etl_table_rows = engine.connect().execute("select count(1) from dbo.etl_timestamp").fetchone()[0]
    print(f"There are {last_etl_table_rows} rows on that table now")
