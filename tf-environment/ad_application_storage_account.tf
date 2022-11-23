data "azuread_client_config" "current" {}

resource "azuread_application" "demo_azuread_writing_application" {
  display_name = local.demo_ad_app_name
  owners = [
    data.azuread_client_config.current.object_id,
    data.azurerm_client_config.current_environment_config.object_id,
  ]
  sign_in_audience = "AzureADMyOrg"
}

resource "time_rotating" "password_rotation_practices" {
  rotation_days = 90
}

resource "azuread_application_password" "demo_azuread_writing_application_secret" {
  application_object_id = azuread_application.demo_azuread_writing_application.object_id
  rotate_when_changed = {
    rotation = time_rotating.password_rotation_practices.id
  }
}

resource "azuread_service_principal" "azuread_application_service_principal" {
  application_id               = resource.azuread_application.demo_azuread_writing_application.application_id
  app_role_assignment_required = false
  owners = [
    data.azuread_client_config.current.object_id,
    data.azurerm_client_config.current_environment_config.object_id,
  ]
}

resource "azurerm_role_assignment" "azuread_application_role_assingment_storage_acount_contributor" {
  scope                = resource.azurerm_storage_account.demo_storage_account.id
  role_definition_name = "Contributor"
  principal_id         = resource.azuread_service_principal.azuread_application_service_principal.id
}

resource "azurerm_role_assignment" "azuread_application_role_assingment_storage_acount_data_contributor" {
  scope                = resource.azurerm_storage_account.demo_storage_account.id
  role_definition_name = "Storage Queue Data Contributor"
  principal_id         = resource.azuread_service_principal.azuread_application_service_principal.id
}

resource "azurerm_role_assignment" "azuread_application_role_assingment_storage_acount_blob_data_contributor" {
  scope                = resource.azurerm_storage_account.demo_storage_account.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = resource.azuread_service_principal.azuread_application_service_principal.id
}

resource "azurerm_role_assignment" "azuread_application_role_assingment_on_resource_group" {
  scope                = resource.azurerm_resource_group.rg.id
  role_definition_name = "EventGrid EventSubscription Contributor"
  principal_id         = resource.azuread_service_principal.azuread_application_service_principal.id
}
