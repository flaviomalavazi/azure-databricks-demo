# Databricks notebook source
dbutils.widgets.dropdown("auth_method", "service_identity", ["service_identity", "access_key", "sas"], "Authentication Method")

# COMMAND ----------

# MAGIC %md
# MAGIC # Acessando uma storage account com entidade de serviço Azure
# MAGIC - [Documentação completa](https://learn.microsoft.com/pt-br/azure/databricks/external-data/azure-storage#--access-azure-data-lake-storage-gen2-or-blob-storage-using-oauth-20-with-an-azure-service-principal)
# MAGIC - Permissões para o aplicativo no Azure AD que fará a autenticação para acesso ao ABFSS:
# MAGIC   - É necessário que o app tenha acesso à blob account declarado explicitamente, a documentação para isso pode ser encontrada [aqui](https://learn.microsoft.com/pt-br/azure/databricks/security/aad-storage-service-principal) (referenciada no link da documentação completa acima).
# MAGIC     - Este acesso deve ser o de `Colaborador de dados de BLOB de armazenamento`
# MAGIC   
# MAGIC   
# MAGIC # Acessando a storage account com Token SAS
# MAGIC - [Documentação completa](https://learn.microsoft.com/pt-br/azure/databricks/external-data/azure-storage#access-azure-data-lake-storage-gen2-or-blob-storage-using-a-sas-token)
# MAGIC 
# MAGIC # Acessando a storage account com chave de acesso
# MAGIC - [Documentação completa](https://learn.microsoft.com/pt-br/azure/databricks/external-data/azure-storage#--access-azure-data-lake-storage-gen2-or-blob-storage-using-the-account-key)

# COMMAND ----------

# DBTITLE 1,Configurando as credenciais para acesso a um container na storage account desejada
authMethod = dbutils.widgets.get("auth_method")
varStorageAccountName = dbutils.secrets.get(scope = "keyvault-managed-secret-scope", key = "storage-account-name") # Storage acccount name
varFileSystemName = dbutils.secrets.get(scope = "keyvault-managed-secret-scope", key = "storage-account-general-purpose-container") # ADLS container name

if authMethod == "service_identity":
    print("Service Identity selected!")
    varTenantId = dbutils.secrets.get(scope = "keyvault-managed-secret-scope", key = "tenant-id") # Tenant ID da Azure
    varApplicationId = dbutils.secrets.get(scope = "keyvault-managed-secret-scope", key = "azure-ad-application-id") # Aplicativo registrado no Azure AD (https://portal.azure.com/#view/Microsoft_AAD_RegisteredApps/ApplicationsListBlade)
    varAuthenticationKey = dbutils.secrets.get(scope = "keyvault-managed-secret-scope", key = "azure-id-authentication-key") # Client Secret do aplicativo registrado no Azure AD (print abaixo)
    spark.conf.set(f"fs.azure.account.auth.type.{varStorageAccountName}.dfs.core.windows.net", "OAuth")
    spark.conf.set(f"fs.azure.account.oauth.provider.type.{varStorageAccountName}.dfs.core.windows.net", "org.apache.hadoop.fs.azurebfs.oauth2.ClientCredsTokenProvider")
    spark.conf.set(f"fs.azure.account.oauth2.client.id.{varStorageAccountName}.dfs.core.windows.net", f"{varApplicationId}")
    spark.conf.set(f"fs.azure.account.oauth2.client.secret.{varStorageAccountName}.dfs.core.windows.net", varAuthenticationKey)
    spark.conf.set(f"fs.azure.account.oauth2.client.endpoint.{varStorageAccountName}.dfs.core.windows.net", f"https://login.microsoftonline.com/{varTenantId}/oauth2/token")
elif authMethod == "sas":
    print("SAS token selected!")
    varSASToken = dbutils.secrets.get(scope = "keyvault-managed-secret-scope", key = "storage-account-sas-token") # SEM a interrogação inicial do SaS token
    spark.conf.set(f"fs.azure.account.auth.type.{varStorageAccountName}.dfs.core.windows.net", "SAS")
    spark.conf.set(f"fs.azure.sas.token.provider.type.{varStorageAccountName}.dfs.core.windows.net", "org.apache.hadoop.fs.azurebfs.sas.FixedSASTokenProvider")
    spark.conf.set(f"fs.azure.sas.fixed.token.{varStorageAccountName}.dfs.core.windows.net", f"{varSASToken}")
else:
    print("Storage Account Access Key selected!")
    varStorageAccountAccessKey = dbutils.secrets.get(scope = "keyvault-managed-secret-scope", key = "storage-account-key") # Storage access key
    spark.conf.set(f"fs.azure.account.key.{varStorageAccountName}.dfs.core.windows.net", varStorageAccountAccessKey)

# COMMAND ----------

# DBTITLE 1,Pegando o path que queremos acessar
varContainerPath = f"abfss://{varFileSystemName}@{varStorageAccountName}.dfs.core.windows.net"

# COMMAND ----------

# DBTITLE 1,Verificando a leitura do path
dbutils.fs.ls(f"{varContainerPath}")

# COMMAND ----------

# DBTITLE 1,Criando um dataframe para escrita no ABFSS
from pyspark.sql.types import StructType,StructField, StringType, IntegerType

data2 = [("James","","Smith","36636","M",3000),
    ("Michael","Rose","","40288","M",4000),
    ("Robert","","Williams","42114","M",4000),
    ("Maria","Anne","Jones","39192","F",4000),
    ("Jen","Mary","Brown","","F",-1)
  ]

schema = StructType([ \
    StructField("firstname",StringType(),True), \
    StructField("middlename",StringType(),True), \
    StructField("lastname",StringType(),True), \
    StructField("id", StringType(), True), \
    StructField("gender", StringType(), True), \
    StructField("salary", IntegerType(), True) \
  ])
 
df = spark.createDataFrame(data=data2,schema=schema)
df.display()

# COMMAND ----------

# DBTITLE 1,Escrevendo o Dataframe para uma Delta Table no ABFSS
df.write.mode("overwrite").format("delta").save(f"{varContainerPath}/tabela_exemplo")

# COMMAND ----------

# DBTITLE 1,Verificando se a tabela está presente em nosso container
dbutils.fs.ls(f"{varContainerPath}/tabela_exemplo")

# COMMAND ----------

# DBTITLE 1,Lendo a tabela para um novo Dataframe
df2 = spark.read.load(f"{varContainerPath}/tabela_exemplo")
df2.display()

# COMMAND ----------

# DBTITLE 1,Deletando completamente a tabela
dbutils.fs.rm(f"{varContainerPath}/tabela_exemplo", True)

# COMMAND ----------

# DBTITLE 1,Verificando nosos container novamente
dbutils.fs.ls(f"{varContainerPath}")
