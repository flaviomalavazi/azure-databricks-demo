output "resource_group_name" {
  value = resource.azurerm_resource_group.rg.name
}

output "resource_group_id" {
  value = resource.azurerm_resource_group.rg.id
}

output "databricks_azure_workspace_resource_id" {
  value = azurerm_databricks_workspace.this.id
}

output "databricks_ws_url" {
  value = "https://${resource.azurerm_databricks_workspace.this.workspace_url}/"
}
