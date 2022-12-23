
resource "azurerm_storage_account" "demo_storage_account" {
  name                = local.storage_account_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  identity {
    type = "SystemAssigned"
  }

  sas_policy {
    expiration_period = "90.00:00:00"
    expiration_action = "Log"
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

resource "azurerm_role_assignment" "role_assignment_ad_application" {
  scope                = resource.azurerm_storage_account.demo_storage_account.id
  principal_id         = resource.azurerm_data_factory.demo_data_factory.identity.0.principal_id
  role_definition_name = "Contributor"
}

resource "time_static" "sas_token_start_date" {}

resource "time_offset" "sas_token_expiration_date" {
  offset_days = 7
}

data "azurerm_storage_account_sas" "sas_for_storage_account" {
  connection_string = azurerm_storage_account.demo_storage_account.primary_connection_string
  https_only        = false
  signed_version    = "2021-06-08"

  resource_types {
    service   = true
    container = true
    object    = true
  }

  services {
    blob  = true
    queue = true
    table = true
    file  = true
  }

  start  = resource.time_static.sas_token_start_date.rfc3339
  expiry = resource.time_offset.sas_token_expiration_date.rfc3339
  permissions {
    read    = true
    write   = true
    delete  = true
    list    = true
    add     = true
    create  = true
    update  = true
    process = true
    tag     = true
    filter  = true
  }
}
