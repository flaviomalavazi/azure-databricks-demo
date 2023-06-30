// Criando o SQL Server 
resource "azurerm_mssql_server" "demo_sql_server" {
  name                          = "demo-sqlserver-${random_string.suffix.result}"
  resource_group_name           = azurerm_resource_group.rg.name
  location                      = azurerm_resource_group.rg.location
  version                       = "12.0"
  administrator_login           = local.demo_sql_server_admin_login
  administrator_login_password  = azurerm_key_vault_secret.sql_server_admin_password.value
  minimum_tls_version           = "1.2"
  public_network_access_enabled = true

  // Permitindo que a pessoa que é dona da demo faça login no sql server com seu login do Azure AD
  azuread_administrator {
    login_username = local.databricks_my_username
    object_id      = data.azurerm_client_config.current_environment_config.object_id
  }

  tags = local.tags
}

/* 
  Permitindo que recursos da própria Azure também acessem 
  o SQL Server - Isto é importante pois faremos a escrita dos dados 
  históricos usando um Notebook Databricks e depois faremos a 
  leitura usando o Data Factory
**/
resource "azurerm_mssql_firewall_rule" "mssql_firewall_rule_allow_azure_services" {
  name             = "AllowAzureServicesRange"
  server_id        = azurerm_mssql_server.demo_sql_server.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

// Criando o primeiro database em nosso SQL Server
resource "azurerm_mssql_database" "fleet_maintenance_database" {
  name           = var.sql_server_database_name
  server_id      = azurerm_mssql_server.demo_sql_server.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  max_size_gb    = 1
  read_scale     = false
  sku_name       = "S1"
  zone_redundant = false

  tags = local.tags
}
