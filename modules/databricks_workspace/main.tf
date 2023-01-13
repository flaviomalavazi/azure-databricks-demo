resource "azurerm_databricks_workspace" "databricks_demo_workspace" {
  name                          = local.databricks_instance_name
  resource_group_name           = resource.azurerm_resource_group.rg.name
  managed_resource_group_name   = local.managed_rg
  location                      = resource.azurerm_resource_group.rg.location
  sku                           = "premium"
  public_network_access_enabled = true // no front end privatelink deployment
  tags                          = local.tags
  custom_parameters {
    storage_account_sku_name = "Standard_LRS"
  }
}
