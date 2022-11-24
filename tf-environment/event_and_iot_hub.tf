
resource "azurerm_eventhub_namespace" "demo_eventhub_namespace" {
  name                = local.demo_eventhub_namespace
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  tags                = local.tags
}

resource "azurerm_eventhub" "demo_eventhub" {
  name                = local.demo_eventhub_name
  resource_group_name = azurerm_resource_group.rg.name
  namespace_name      = azurerm_eventhub_namespace.demo_eventhub_namespace.name
  partition_count     = 1
  message_retention   = 1
}

resource "azurerm_eventhub_authorization_rule" "eh_demo_databricks_reader_authorization_rule" {
  resource_group_name = azurerm_resource_group.rg.name
  namespace_name      = azurerm_eventhub_namespace.demo_eventhub_namespace.name
  eventhub_name       = azurerm_eventhub.demo_eventhub.name
  name                = "databricks-reader"
  listen              = true
}

resource "azurerm_eventhub_authorization_rule" "eh_iot_write_key_authorization_rule" {
  resource_group_name = azurerm_resource_group.rg.name
  namespace_name      = azurerm_eventhub_namespace.demo_eventhub_namespace.name
  eventhub_name       = azurerm_eventhub.demo_eventhub.name
  name                = "iot-writer-connection"
  send                = true
}

resource "azurerm_eventhub_authorization_rule" "eh_shared_access_key_authorization_rule" {
  resource_group_name = azurerm_resource_group.rg.name
  namespace_name      = azurerm_eventhub_namespace.demo_eventhub_namespace.name
  eventhub_name       = azurerm_eventhub.demo_eventhub.name
  name                = "RootManageSharedAccessKey"
  listen              = true
  send                = true
  manage              = true
}

resource "azurerm_iothub" "iot_hub_demo" {
  name                = "demo-iothub-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  sku {
    name     = "S1"
    capacity = "1"
  }

  endpoint {
    type              = "AzureIotHub.EventHub"
    connection_string = azurerm_eventhub_authorization_rule.eh_iot_write_key_authorization_rule.primary_connection_string
    name              = "iot-write-to-eventhub"
  }

  route {
    name           = "iot-write-to-eventhub"
    source         = "DeviceMessages"
    condition      = "true"
    endpoint_names = ["iot-write-to-eventhub"]
    enabled        = true
  }

  cloud_to_device {
    max_delivery_count = 30
    default_ttl        = "PT1H"
    feedback {
      time_to_live       = "PT1H10M"
      max_delivery_count = 15
      lock_duration      = "PT30S"
    }
  }

  tags = local.tags

}
