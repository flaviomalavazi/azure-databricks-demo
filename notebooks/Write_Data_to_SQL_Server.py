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

    rs = con.execute('SELECT GETDATE() as timestamp_of_now')

    for row in rs:
        print(row)

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
    rs = engine.connect().execute(create_maintenance_header_table).fetchall()
    print(rs)
    maintenance_header_table_rows = engine.connect().execute("select count(1) from dbo.maintenance_header").fetchone()[0]
except Exception as e:
    if "[42S01] [Microsoft][ODBC Driver 17 for SQL Server][SQL Server]There is already an object named 'maintenance_header' in the database." in str(e):
        maintenance_header_table_rows = engine.connect().execute("select count(1) from dbo.maintenance_header").fetchone()[0]
        print(f"There are {maintenance_header_table_rows} rows on that table already, skipping this step")
    else:
        raise e

# COMMAND ----------

try:
    rs = engine.connect().execute(create_power_output_table).fetchall()
    print(rs)
    power_output_table_rows = engine.connect().execute("select count(1) from dbo.power_output").fetchone()[0]
except Exception as e:
    if "[42S01] [Microsoft][ODBC Driver 17 for SQL Server][SQL Server]There is already an object named 'power_output' in the database." in str(e):
        power_output_table_rows = engine.connect().execute("select count(1) from dbo.power_output").fetchone()[0]
        print(f"There are {power_output_table_rows} rows on that table already, skipping this step")
    else:
        raise e

# COMMAND ----------

try:
    rs = engine.connect().execute(create_last_etl_table).fetchall()
    print(rs)
    last_etl_table_rows = engine.connect().execute("select count(1) from dbo.etl_timestamp").fetchone()[0]
except Exception as e:
    if "[42S01] [Microsoft][ODBC Driver 17 for SQL Server][SQL Server]There is already an object named 'etl_timestamp' in the database." in str(e):
        last_etl_table_rows = engine.connect().execute("select count(1) from dbo.etl_timestamp").fetchone()[0]
        print(f"There are {last_etl_table_rows} rows on that table already, skipping this step")
    else:
        raise e

# COMMAND ----------

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

days_to_subtract = 90
days_ahead = 7

begin_date = datetime.today() - timedelta(days=days_to_subtract)

delta = (datetime.today() + timedelta(days=days_ahead)) - begin_date

# COMMAND ----------

maintenances = []

for days_to_add in range(delta.days + 1):
    day = datetime.strftime((begin_date + timedelta(days=days_to_add)), "%Y-%m-%d")
    for turbine in turbines:
        maintenances.append(f"""INSERT [dbo].[maintenance_header] ([deviceId], [date], [maintenance]) VALUES (N'{turbine}', CAST(N'{day}' AS Date), {choice([0, 0, 0, 0, 0, 0, 0, 1])})""")
    maintenances.append(";")

maintenances = "\n".join(maintenances)

# COMMAND ----------

if maintenance_header_table_rows == 0:
    rs = engine.connect().execute(maintenances)
    print(rs)

# COMMAND ----------

measurements = []

for days_to_add in range(delta.days + 1):
    day = datetime.strftime((begin_date + timedelta(days=days_to_add)), "%Y-%m-%d")
    for hour in range(hour_range):
        window = datetime.strftime(begin_date, f"{day}T{str(hour).zfill(2)}:00:00.000")
        for turbine in turbines:
            measurements.append(f"""INSERT [dbo].[power_output] ([deviceId], [date], [window], [power]) VALUES (N'{turbine}', CAST(N'{day}' AS Date), CAST(N'{window}' AS DateTime), {str(round(randrange(0,300)+random(),5))})""")
    measurements.append(";")

measurements = "\n".join(measurements)

# COMMAND ----------

if power_output_table_rows == 0:
    rs = engine.connect().execute(measurements)
    print(rs)

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
