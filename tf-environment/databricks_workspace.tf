/*

Note:
  Hashicorp maintains Azurerm with MSFT and they also own Databricks workspace creation as part of the azurerm provider.
  This is why we never configured a databricks provider for this exercise.

Please do the following:

1. Create an azure databricks workspace using the vnet, subnets and association ids in the previous section.
  https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/databricks_workspace

2. Create an output with the databricks workspace url

After creating this resource please run:

../../terraform plan

../../terraform apply

After the end of the module please run:

../terraform destroy

*/


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

data "databricks_current_user" "me" {
  depends_on = [azurerm_databricks_workspace.databricks_demo_workspace]
}

resource "azurerm_role_assignment" "adf_role_assignment_databricks" {
  scope                = resource.azurerm_databricks_workspace.databricks_demo_workspace.id
  role_definition_name = "Contributor"
  principal_id         = resource.azurerm_data_factory.demo_data_factory.identity.0.principal_id
}

data "databricks_node_type" "smallest" {
  local_disk = true
  depends_on = [azurerm_databricks_workspace.databricks_demo_workspace]
}

data "databricks_spark_version" "latest_version" {
  long_term_support = true
  depends_on        = [azurerm_databricks_workspace.databricks_demo_workspace]
}

resource "databricks_cluster" "first_cluster" {
  cluster_name            = "Demo Cluster"
  spark_version           = data.databricks_spark_version.latest_version.id
  node_type_id            = "Standard_DS3_v2"  # data.databricks_node_type.smallest.id
  depends_on              = [azurerm_databricks_workspace.databricks_demo_workspace]
  data_security_mode      = "NONE"
  autotermination_minutes = 20
  autoscale {
    min_workers = 1
    max_workers = 3
  }

  spark_conf = {
    "spark.databricks.io.cache.enabled" : true,
    "spark.databricks.io.cache.maxDiskUsage" : "50g",
    "spark.databricks.io.cache.maxMetaDataCache" : "1g",
    "spark.databricks.unityCatalog.userIsolation.python.preview" : true

  }

  library {
    maven {
      coordinates = "com.microsoft.azure:azure-eventhubs-spark_2.12:2.3.21"
    }
  }

  library {
    pypi {
      package = "sqlalchemy"
    }
  }

  library {
    pypi {
      package = "pyodbc"
    }
  }

  azure_attributes {
    availability       = "SPOT_WITH_FALLBACK_AZURE"
    first_on_demand    = 1
    spot_bid_max_price = 100
  }

  custom_tags = {
    "ClusterScope" = "Initial Demo"
  }

}

resource "databricks_notebook" "foreach_python" {
  for_each = fileset("../notebooks/", "*.py")
  source   = "../notebooks/${each.value}"
  path     = "${data.databricks_current_user.me.home}/Demo/${replace(each.value, ".py", "")}"
  depends_on = [
    azurerm_databricks_workspace.databricks_demo_workspace
  ]
}

resource "databricks_secret_scope" "storage_account_secret_scope" {
  name = "storage_account_credentials"
}

resource "databricks_secret" "storage_account_name" {
  key          = "storage_account_name"
  string_value = local.storage_account_name
  scope        = databricks_secret_scope.storage_account_secret_scope.id
}

resource "databricks_secret" "storage_account_secret_key" {
  key          = "storage_account_key"
  string_value = resource.azurerm_storage_account.demo_storage_account.primary_access_key
  scope        = databricks_secret_scope.storage_account_secret_scope.id
}

resource "databricks_secret" "storage_account_general_purpose_container" {
  key          = "storage_account_general_purpose_container"
  string_value = local.demo_general_purpose_storage_container_name
  scope        = databricks_secret_scope.storage_account_secret_scope.id
}

resource "databricks_secret_scope" "sql_server_secret_scope" {
  name = "sql_server_credentials"
}

resource "databricks_secret" "sql_server_admin_username" {
  key          = "username"
  string_value = local.demo_sql_server_admin_login
  scope        = databricks_secret_scope.sql_server_secret_scope.id
}

resource "databricks_secret" "sql_server_admin_password" {
  key          = "password"
  string_value = local.demo_sql_server_admin_password
  scope        = databricks_secret_scope.sql_server_secret_scope.id
}

resource "databricks_secret" "sql_server_host" {
  key          = "host"
  string_value = "demo-sqlserver-${random_string.suffix.result}.database.windows.net"
  scope        = databricks_secret_scope.sql_server_secret_scope.id
}

resource "databricks_secret" "sql_server_port" {
  key          = "port"
  string_value = "1433"
  scope        = databricks_secret_scope.sql_server_secret_scope.id
}

resource "databricks_secret" "sql_server_database" {
  key          = "database"
  string_value = var.sql_server_database_name
  scope        = databricks_secret_scope.sql_server_secret_scope.id
}

resource "databricks_secret_scope" "event_hub_secret_scope" {
  name = "event_hub_secrets"
}

resource "databricks_secret" "event_hub_name" {
  key          = "event_hub_name"
  string_value = local.demo_eventhub_name
  scope        = databricks_secret_scope.event_hub_secret_scope.id
}

resource "databricks_secret" "event_hub_iot_endpoint" {
  key          = "eventhub_iot_endpoint"
  string_value = local.demo_eventhub_name
  scope        = databricks_secret_scope.event_hub_secret_scope.id
}

resource "databricks_secret_scope" "databricks_secret_scope_kv_managed" {
  name = "keyvault-managed-secret-scope"

  keyvault_metadata {
    resource_id = azurerm_key_vault.demo_key_vault.id
    dns_name    = azurerm_key_vault.demo_key_vault.vault_uri
  }
}
