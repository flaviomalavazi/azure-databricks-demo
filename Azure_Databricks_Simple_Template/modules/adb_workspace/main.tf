resource "azurerm_resource_group" "rg" {
  location = var.resource_group_location
  name     = local.resource_group_name
  tags     = var.tags
}

resource "azurerm_databricks_workspace" "this" {
  name                          = local.databricks_workspace_name
  resource_group_name           = resource.azurerm_resource_group.rg.name
  managed_resource_group_name   = local.managed_rg
  location                      = resource.azurerm_resource_group.rg.location
  sku                           = var.databricks_sku
  public_network_access_enabled = true // no front end privatelink deployment
  tags                          = var.tags
  custom_parameters {
    no_public_ip             = var.no_public_ip
    storage_account_name     = local.storage_account_name
    storage_account_sku_name = var.storage_account_sku
  }
}
