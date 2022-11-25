resource "azurerm_key_vault" "demo_key_vault" {
  name                        = local.demo_key_vault_name
  location                    = resource.azurerm_resource_group.rg.location
  resource_group_name         = resource.azurerm_resource_group.rg.name
  tenant_id                   = data.azurerm_client_config.current_environment_config.tenant_id
  soft_delete_retention_days  = 7
  enabled_for_disk_encryption = true
  purge_protection_enabled    = false
  sku_name                    = "standard"
  tags                        = local.tags
}

resource "azurerm_key_vault_access_policy" "user_access_to_key_vault" {
  key_vault_id = azurerm_key_vault.demo_key_vault.id
  tenant_id    = data.azurerm_client_config.current_environment_config.tenant_id
  object_id    = data.azurerm_client_config.current_environment_config.object_id

  key_permissions = [
    "Get", "List",
  ]

  secret_permissions = [
    "Get", "Backup", "Delete", "List", "Purge", "Recover", "Restore", "Set"
  ]

  storage_permissions = [
    "Get", "List",
  ]
}

resource "azurerm_key_vault_access_policy" "adf_access_to_key_vault" {
  key_vault_id = azurerm_key_vault.demo_key_vault.id
  tenant_id    = data.azurerm_client_config.current_environment_config.tenant_id
  object_id    = resource.azurerm_data_factory.demo_data_factory.identity.0.principal_id

  key_permissions = [
    "Get", "List",
  ]

  secret_permissions = [
    "Get", "List",
  ]

  storage_permissions = [
    "Get", "List",
  ]

  depends_on = [
    resource.azurerm_data_factory.demo_data_factory
  ]
}

#Create KeyVault SQL Admin password
resource "random_password" "sql_server_admin_password" {
  length           = 32
  special          = true
  override_special = "!#$&="
}

resource "azurerm_key_vault_secret" "subscription_id" {
  name         = "subscription-id"
  value        = data.azurerm_client_config.current_environment_config.subscription_id
  key_vault_id = azurerm_key_vault.demo_key_vault.id
  depends_on = [
    resource.azurerm_key_vault_access_policy.user_access_to_key_vault,
    resource.azurerm_key_vault_access_policy.adf_access_to_key_vault,
  ]
}

resource "azurerm_key_vault_secret" "tenant_id" {
  name         = "tenant-id"
  value        = data.azurerm_client_config.current_environment_config.tenant_id
  key_vault_id = azurerm_key_vault.demo_key_vault.id
  depends_on = [
    resource.azurerm_key_vault_access_policy.user_access_to_key_vault,
    resource.azurerm_key_vault_access_policy.adf_access_to_key_vault,
  ]
}

resource "azurerm_key_vault_secret" "resource_group_name" {
  name         = "resource-group-name"
  value        = resource.azurerm_resource_group.rg.name
  key_vault_id = azurerm_key_vault.demo_key_vault.id
  depends_on = [
    resource.azurerm_key_vault_access_policy.user_access_to_key_vault,
    resource.azurerm_key_vault_access_policy.adf_access_to_key_vault,
  ]
}

resource "azurerm_key_vault_secret" "azuread_application_id" {
  name         = "azure-ad-application-id"
  value        = resource.azuread_application.demo_azuread_writing_application.application_id
  key_vault_id = azurerm_key_vault.demo_key_vault.id
  depends_on = [
    resource.azurerm_key_vault_access_policy.user_access_to_key_vault,
    resource.azurerm_key_vault_access_policy.adf_access_to_key_vault,
  ]
}

resource "azurerm_key_vault_secret" "azuread_application_client_secret" {
  name         = "azure-id-authentication-key"
  value        = resource.azuread_application_password.demo_azuread_writing_application_secret.value
  key_vault_id = azurerm_key_vault.demo_key_vault.id
  depends_on = [
    resource.azurerm_key_vault_access_policy.user_access_to_key_vault,
    resource.azurerm_key_vault_access_policy.adf_access_to_key_vault,
  ]
}

resource "azurerm_key_vault_secret" "storage_account_name" {
  name         = "storage-account-name"
  value        = local.storage_account_name
  key_vault_id = azurerm_key_vault.demo_key_vault.id
  depends_on = [
    resource.azurerm_key_vault_access_policy.user_access_to_key_vault,
    resource.azurerm_key_vault_access_policy.adf_access_to_key_vault,
  ]
}

resource "azurerm_key_vault_secret" "storage_account_secret_key" {
  name         = "storage-account-key"
  value        = resource.azurerm_storage_account.demo_storage_account.primary_access_key
  key_vault_id = azurerm_key_vault.demo_key_vault.id
  depends_on = [
    resource.azurerm_key_vault_access_policy.user_access_to_key_vault,
    resource.azurerm_key_vault_access_policy.adf_access_to_key_vault,
  ]
}

resource "azurerm_key_vault_secret" "storage_account_sas_token" {
  name         = "storage-account-sas-token"
  value        = replace(data.azurerm_storage_account_sas.sas_for_storage_account.sas, "?", "")
  key_vault_id = azurerm_key_vault.demo_key_vault.id
  depends_on = [
    resource.azurerm_key_vault_access_policy.user_access_to_key_vault,
    resource.azurerm_key_vault_access_policy.adf_access_to_key_vault,
  ]
}

resource "azurerm_key_vault_secret" "storage_account_general_purpose_container" {
  name         = "storage-account-general-purpose-container"
  value        = local.demo_general_purpose_storage_container_name
  key_vault_id = azurerm_key_vault.demo_key_vault.id
  depends_on = [
    resource.azurerm_key_vault_access_policy.user_access_to_key_vault,
    resource.azurerm_key_vault_access_policy.adf_access_to_key_vault,
  ]
}

resource "azurerm_key_vault_secret" "storage_account_synapse_container" {
  name         = "storage-account-synapse-container"
  value        = local.demo_synapse_storage_container_name
  key_vault_id = azurerm_key_vault.demo_key_vault.id
  depends_on = [
    resource.azurerm_key_vault_access_policy.user_access_to_key_vault,
    resource.azurerm_key_vault_access_policy.adf_access_to_key_vault,
  ]
}

resource "azurerm_key_vault_secret" "sql_server_connection_string" {
  name         = "sql-server-connection-string"
  value        = "data source=${resource.azurerm_mssql_server.demo_sql_server.fully_qualified_domain_name};initial catalog=${resource.azurerm_mssql_database.fleet_maintenance_database.name};user id=${local.demo_sql_server_admin_login};Password=${random_password.sql_server_admin_password.result};integrated security=False;encrypt=True;connection timeout=30"
  key_vault_id = azurerm_key_vault.demo_key_vault.id
  depends_on = [
    resource.azurerm_key_vault_access_policy.user_access_to_key_vault,
    resource.azurerm_key_vault_access_policy.adf_access_to_key_vault,
  ]
}

resource "azurerm_key_vault_secret" "sql_server_admin_username" {
  name         = "sql-server-admin-username"
  value        = local.demo_sql_server_admin_login
  key_vault_id = azurerm_key_vault.demo_key_vault.id
  depends_on = [
    resource.azurerm_key_vault_access_policy.user_access_to_key_vault,
    resource.azurerm_key_vault_access_policy.adf_access_to_key_vault,
  ]
}

# Create Key Vault Secret
resource "azurerm_key_vault_secret" "sql_server_admin_password" {
  name         = "sql-server-admin-password"
  value        = random_password.sql_server_admin_password.result
  key_vault_id = azurerm_key_vault.demo_key_vault.id
  depends_on = [
    resource.azurerm_key_vault_access_policy.user_access_to_key_vault,
    resource.azurerm_key_vault_access_policy.adf_access_to_key_vault,
  ]
}

resource "azurerm_key_vault_secret" "sql_server_host" {
  name         = "sql-server-host"
  value        = "demo-sqlserver-${random_string.suffix.result}.database.windows.net"
  key_vault_id = azurerm_key_vault.demo_key_vault.id
  depends_on = [
    resource.azurerm_key_vault_access_policy.user_access_to_key_vault,
    resource.azurerm_key_vault_access_policy.adf_access_to_key_vault,
  ]
}

resource "azurerm_key_vault_secret" "sql_server_port" {
  name         = "sql-server-port"
  value        = "1433"
  key_vault_id = azurerm_key_vault.demo_key_vault.id
  depends_on = [
    resource.azurerm_key_vault_access_policy.user_access_to_key_vault,
    resource.azurerm_key_vault_access_policy.adf_access_to_key_vault,
  ]
}

resource "azurerm_key_vault_secret" "sql_server_database" {
  name         = "sql-server-database"
  value        = var.sql_server_database_name
  key_vault_id = azurerm_key_vault.demo_key_vault.id
  depends_on = [
    resource.azurerm_key_vault_access_policy.user_access_to_key_vault,
    resource.azurerm_key_vault_access_policy.adf_access_to_key_vault,
  ]
}

resource "azurerm_key_vault_secret" "event_hub_name" {
  name         = "eventhub-name"
  value        = local.demo_eventhub_name
  key_vault_id = azurerm_key_vault.demo_key_vault.id
  depends_on = [
    resource.azurerm_key_vault_access_policy.user_access_to_key_vault,
    resource.azurerm_key_vault_access_policy.adf_access_to_key_vault,
  ]
}

resource "azurerm_key_vault_secret" "event_hub_iot_endpoint" {
  name         = "eventhub-iot-endpoint"
  value        = resource.azurerm_eventhub_authorization_rule.eh_demo_databricks_reader_authorization_rule.primary_connection_string
  key_vault_id = azurerm_key_vault.demo_key_vault.id
  depends_on = [
    resource.azurerm_key_vault_access_policy.user_access_to_key_vault,
    resource.azurerm_key_vault_access_policy.adf_access_to_key_vault,
  ]
}
