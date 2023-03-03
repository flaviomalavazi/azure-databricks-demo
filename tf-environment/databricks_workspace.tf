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
  cluster_name                = "Demo Cluster"
  spark_version               = data.databricks_spark_version.latest_version.id
  node_type_id                = "Standard_DS4_v2" # data.databricks_node_type.smallest.id
  policy_id                   = resource.databricks_cluster_policy.default_data_access_policy.id
  apply_policy_default_values = true
  data_security_mode          = "NONE"
  autotermination_minutes     = 120
  depends_on = [
    resource.azurerm_databricks_workspace.databricks_demo_workspace,
    resource.databricks_cluster_policy.default_data_access_policy,
    resource.databricks_secret_scope.databricks_secret_scope_kv_managed,
    resource.azurerm_key_vault_secret.storage_account_secret_key
  ]

  autoscale {
    min_workers = 1
    max_workers = 5
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
    maven {
      coordinates = "com.microsoft.azure:spark-mssql-connector_2.12:1.2.0"
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
  for_each = fileset("../Demo/", "*.py")
  source   = "../Demo/${each.value}"
  path     = "${data.databricks_current_user.me.home}/Demo/${replace(each.value, ".py", "")}"
  depends_on = [
    azurerm_databricks_workspace.databricks_demo_workspace
  ]
}

resource "databricks_notebook" "base_notebooks_demo_v2" {
  for_each = fileset("../Demo_v2/", "*.py")
  source   = "../Demo_v2/${each.value}"
  path     = "${data.databricks_current_user.me.home}/Demo_v2/${replace(each.value, ".py", "")}"
  depends_on = [
    azurerm_databricks_workspace.databricks_demo_workspace
  ]
}

resource "databricks_notebook" "classic_de_notebooks_demo_v2" {
  for_each = fileset("../Demo_v2/Classic_Data_Engineering/", "*.py")
  source   = "../Demo_v2/Classic_Data_Engineering/${each.value}"
  path     = "${data.databricks_current_user.me.home}/Demo_v2/Classic_Data_Engineering/${replace(each.value, ".py", "")}"
  depends_on = [
    azurerm_databricks_workspace.databricks_demo_workspace
  ]
}

resource "databricks_notebook" "dlt_notebooks_demo_v2" {
  for_each = fileset("../Demo_v2/Delta_Live_Tables/", "*.py")
  source   = "../Demo_v2/Delta_Live_Tables/${each.value}"
  path     = "${data.databricks_current_user.me.home}/Demo_v2/Delta_Live_Tables/${replace(each.value, ".py", "")}"
  depends_on = [
    azurerm_databricks_workspace.databricks_demo_workspace
  ]
}

resource "databricks_notebook" "foreach_dlt" {
  for_each = fileset("../Delta_Live_Tables/", "*.py")
  source   = "../Delta_Live_Tables/${each.value}"
  path     = "${data.databricks_current_user.me.home}/DLT_Demo/${replace(each.value, ".py", "")}"
  depends_on = [
    azurerm_databricks_workspace.databricks_demo_workspace
  ]
}

resource "databricks_notebook" "foreach_general_examples" {
  for_each = fileset("../General_examples/", "*.py")
  source   = "../General_examples/${each.value}"
  path     = "${data.databricks_current_user.me.home}/General_examples/${replace(each.value, ".py", "")}"
  depends_on = [
    azurerm_databricks_workspace.databricks_demo_workspace
  ]
}

resource "databricks_secret_scope" "databricks_secret_scope_kv_managed" {
  name = "keyvault-managed-secret-scope"

  keyvault_metadata {
    resource_id = azurerm_key_vault.demo_key_vault.id
    dns_name    = azurerm_key_vault.demo_key_vault.vault_uri
  }

  depends_on = [
    resource.azurerm_key_vault.demo_key_vault,
    resource.azurerm_key_vault_access_policy.user_access_to_key_vault,
    resource.azurerm_key_vault_secret.storage_account_secret_key
  ]

}
resource "databricks_cluster_policy" "default_data_access_policy" {
  name = "Data-Access-Cluster-Policy"
  depends_on = [
    resource.databricks_secret_scope.databricks_secret_scope_kv_managed
  ]
  definition = <<JSON
                          {
                            "spark_conf.spark.hadoop.fs.azure.account.auth.type.test.dfs.core.windows.net": {
                              "type": "fixed",
                              "value": "OAuth",
                              "hidden": true
                            },
                            "spark_conf.spark.hadoop.fs.azure.account.oauth.provider.type.test.dfs.core.windows.net": {
                              "type": "fixed",
                              "value": "org.apache.hadoop.fs.azurebfs.oauth2.ClientCredsTokenProvider",
                              "hidden": true
                            },
                            "spark_conf.spark.hadoop.fs.azure.account.oauth2.client.id.test.dfs.core.windows.net": {
                              "type": "fixed",
                              "value": "{{secrets/keyvault-managed-secret-scope/azure-ad-application-id}}",
                              "hidden": true
                            },
                            "spark_conf.spark.hadoop.fs.azure.account.oauth2.client.secret.test.dfs.core.windows.net": {
                              "type": "fixed",
                              "value": "{{secrets/keyvault-managed-secret-scope/azure-id-authentication-key}}",
                              "hidden": true
                            },
                            "spark_conf.spark.hadoop.fs.azure.account.oauth2.client.endpoint.test.dfs.core.windows.net": {
                              "type": "fixed",
                              "value": "https://login.microsoftonline.com/{{secrets/keyvault-managed-secret-scope/tenant-id}}/oauth2/token",
                              "hidden": true
                            },
                            "spark_conf.spark.hadoop.fs.azure.account.key.${resource.azurerm_storage_account.demo_storage_account.name}.dfs.core.windows.net": {
                              "type": "fixed",
                              "value": "{{secrets/keyvault-managed-secret-scope/storage-account-key}}",
                              "hidden": true
                            }
                          }
  JSON
}

data "databricks_notebook" "dlt_demo_notebook" {
  path   = "${data.databricks_current_user.me.home}/DLT_Demo/DLT_Pipeline"
  format = "SOURCE"
  depends_on = [
    resource.databricks_notebook.foreach_dlt,
    resource.azurerm_databricks_workspace.databricks_demo_workspace
  ]
}


resource "databricks_sql_global_config" "demo_sql_global_config_access_control" {
  security_policy           = "DATA_ACCESS_CONTROL"
  enable_serverless_compute = true
  data_access_config = {
    "spark.hadoop.fs.azure.account.auth.type" : "OAuth",
    "spark.hadoop.fs.azure.account.oauth.provider.type" : "org.apache.hadoop.fs.azurebfs.oauth2.ClientCredsTokenProvider",
    "spark.hadoop.fs.azure.account.oauth2.client.id" : "{{secrets/${resource.databricks_secret_scope.databricks_secret_scope_kv_managed.name}/${resource.azurerm_key_vault_secret.azuread_application_id.name}}}",
    "spark.hadoop.fs.azure.account.oauth2.client.secret" : "{{secrets/${resource.databricks_secret_scope.databricks_secret_scope_kv_managed.name}/${resource.azurerm_key_vault_secret.azuread_application_client_secret.name}}}",
    "spark.hadoop.fs.azure.account.oauth2.client.endpoint" : "https://login.microsoftonline.com/${data.azurerm_client_config.current_environment_config.tenant_id}/oauth2/token"
  }
  sql_config_params = {
    "ANSI_MODE" : "true"
  }
}

resource "databricks_sql_endpoint" "demo_sql_warehouse" {
  name                      = "Demo Warehouse"
  cluster_size              = "Small"
  max_num_clusters          = 1
  enable_serverless_compute = true
  auto_stop_mins            = 5

  depends_on = [
    resource.azurerm_databricks_workspace.databricks_demo_workspace,
    resource.databricks_secret_scope.databricks_secret_scope_kv_managed,
    resource.databricks_sql_global_config.demo_sql_global_config_access_control
  ]

}
