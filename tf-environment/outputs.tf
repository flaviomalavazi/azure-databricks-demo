
output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "storage_account_principal_id" {
  value = azurerm_storage_account.demo_storage_account.identity.0.principal_id
}

output "storage_account_tenant_id" {
  value = azurerm_storage_account.demo_storage_account.identity.0.tenant_id
}

output "databricks_ws" {
  value = azurerm_databricks_workspace.databricks_demo_workspace.workspace_url
}

output "sql_server_domain_name" {
  value = azurerm_mssql_server.demo_sql_server.fully_qualified_domain_name
}
