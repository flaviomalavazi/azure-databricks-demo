resource "azurerm_resource_group" "rg" {
  location = var.resource_group_location
  name     = "${var.prefix}-rg-${random_string.suffix.result}"
  tags     = local.tags
}

resource "azurerm_user_assigned_identity" "my_user_assigned_identity" {
  location            = azurerm_resource_group.rg.location
  name                = local.demo_managed_identity
  resource_group_name = azurerm_resource_group.rg.name
}

resource "shell_script" "register_iot_edge_device" {
  lifecycle_commands {
    create = "$script create"
    read   = "$script read"
    delete = "$script delete"
  }

  environment = {
    iot_hub_name         = resource.azurerm_iothub.iot_hub_demo.name
    iot_edge_device_name = "edge-device-${random_string.suffix.result}"
    script               = "../scripts/terraform/register_iot_edge_device.sh"
  }
}
