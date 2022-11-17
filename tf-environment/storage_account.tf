
resource "azurerm_storage_account" "demo_storage_account" {
  name                = local.storage_account_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  identity {
    type = "SystemAssigned"
  }
  account_kind              = "StorageV2"
  is_hns_enabled            = true
  enable_https_traffic_only = true
  account_tier              = "Standard"
  account_replication_type  = "LRS"
  tags                      = local.tags
}

resource "azurerm_storage_container" "demo_general_purpose_container" {
  name                  = local.demo_general_purpose_storage_container_name
  storage_account_name  = azurerm_storage_account.demo_storage_account.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "demo_synapse_container" {
  name                  = local.demo_synapse_storage_container_name
  storage_account_name  = azurerm_storage_account.demo_storage_account.name
  container_access_type = "private"
}

resource "azurerm_role_assignment" "role_assignment_ad_application" {
  scope                = resource.azurerm_storage_account.demo_storage_account.id
  principal_id         = resource.azurerm_data_factory.demo_data_factory.identity.0.principal_id
  role_definition_name = "Contributor"
}
