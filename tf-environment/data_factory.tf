resource "azurerm_data_factory" "demo_data_factory" {
  name                = "demo-adf-${random_string.suffix.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  identity {
    type = "SystemAssigned"
  }


  tags = local.tags

}

resource "azurerm_data_factory_linked_service_azure_blob_storage" "linked_service_storage_account_blob" {
  name                 = "adls_blob_storage"
  data_factory_id      = azurerm_data_factory.demo_data_factory.id
  use_managed_identity = true
  connection_string    = azurerm_storage_account.demo_storage_account.primary_connection_string
}

resource "azurerm_data_factory_linked_service_key_vault" "key_vault_linked_service" {
  name            = "demo_key_vault_linked_service"
  data_factory_id = azurerm_data_factory.demo_data_factory.id
  key_vault_id    = azurerm_key_vault.demo_key_vault.id
  depends_on = [
    resource.azurerm_key_vault_access_policy.adf_access_to_key_vault
  ]
}

resource "azurerm_data_factory_linked_service_azure_sql_database" "linked_service_azure_sql_server" {
  name            = "demo_sql_server_linked_service"
  data_factory_id = azurerm_data_factory.demo_data_factory.id
  key_vault_connection_string {
    linked_service_name = resource.azurerm_data_factory_linked_service_key_vault.key_vault_linked_service.name
    secret_name         = resource.azurerm_key_vault_secret.sql_server_connection_string.name
  }
}

resource "azurerm_data_factory_dataset_sql_server_table" "azure_sql_server_power_output_table" {
  name                = "power_output_table"
  data_factory_id     = azurerm_data_factory.demo_data_factory.id
  linked_service_name = azurerm_data_factory_linked_service_azure_sql_database.linked_service_azure_sql_server.name
  table_name          = local.demo_sql_server_power_output_table_name
}

resource "azurerm_data_factory_dataset_sql_server_table" "azure_sql_server_status_data_table" {
  name                = "status_data_table"
  data_factory_id     = azurerm_data_factory.demo_data_factory.id
  linked_service_name = azurerm_data_factory_linked_service_azure_sql_database.linked_service_azure_sql_server.name
  table_name          = local.demo_sql_server_turbine_status_table_name
}

resource "azurerm_data_factory_dataset_parquet" "parquet_sink_power_output" {
  name                = "power_output_data_parquet"
  data_factory_id     = azurerm_data_factory.demo_data_factory.id
  linked_service_name = resource.azurerm_data_factory_linked_service_azure_blob_storage.linked_service_storage_account_blob.name
  compression_codec   = "snappy"
  azure_blob_storage_location {
    container            = local.demo_general_purpose_storage_container_name
    dynamic_path_enabled = false
    path                 = "landing/power_output"
  }
}

resource "azurerm_data_factory_dataset_parquet" "parquet_sink_maintenance_data" {
  name                = "maintenance_data_parquet"
  data_factory_id     = azurerm_data_factory.demo_data_factory.id
  linked_service_name = resource.azurerm_data_factory_linked_service_azure_blob_storage.linked_service_storage_account_blob.name
  compression_codec   = "snappy"
  azure_blob_storage_location {
    container            = local.demo_general_purpose_storage_container_name
    dynamic_path_enabled = false
    path                 = "landing/status_data"
  }
}

resource "azurerm_data_factory_linked_service_azure_databricks" "msi_linked_databricks_workspace" {
  name                       = "ADBLinkedServiceViaMSI"
  data_factory_id            = azurerm_data_factory.demo_data_factory.id
  description                = "Demo Azure Databricks Linked Service via MSI"
  adb_domain                 = "https://${resource.azurerm_databricks_workspace.databricks_demo_workspace.workspace_url}"
  msi_work_space_resource_id = resource.azurerm_databricks_workspace.databricks_demo_workspace.id
  existing_cluster_id        = resource.databricks_cluster.first_cluster.id
}

resource "azurerm_data_factory_pipeline" "demo_data_pipeline" {
  name            = "historical_data_pipeline"
  data_factory_id = azurerm_data_factory.demo_data_factory.id
  activities_json = <<JSON
[
    {
                "name": "DEMO_ONLY_write_historical_data_to_sql_server",
                "type": "DatabricksNotebook",
                "policy": {
                    "timeout": "0.12:00:00",
                    "retry": 0,
                    "retryIntervalInSeconds": 30,
                    "secureOutput": false,
                    "secureInput": false
                },
                "userProperties": [],
                "typeProperties": {
                    "notebookPath": "${data.databricks_current_user.me.home}/Demo/Write_Data_to_SQL_Server"
                },
                "linkedServiceName": {
                    "referenceName": "${resource.azurerm_data_factory_linked_service_azure_databricks.msi_linked_databricks_workspace.name}",
                    "type": "LinkedServiceReference"
                }
            },
            {
                "name": "data_maintenance",
                "type": "Copy",
                "dependsOn": [
                    {
                        "activity": "DEMO_ONLY_write_historical_data_to_sql_server",
                        "dependencyConditions": [
                            "Succeeded"
                        ]
                    }
                ],
                "policy": {
                    "timeout": "0.12:00:00",
                    "retry": 0,
                    "retryIntervalInSeconds": 30,
                    "secureOutput": false,
                    "secureInput": false
                },
                "userProperties": [],
                "typeProperties": {
                    "source": {
                        "type": "AzureSqlSource",
                        "queryTimeout": "02:00:00",
                        "partitionOption": "None"
                    },
                    "sink": {
                        "type": "ParquetSink",
                        "storeSettings": {
                            "type": "AzureBlobFSWriteSettings"
                        },
                        "formatSettings": {
                            "type": "ParquetWriteSettings"
                        }
                    },
                    "enableStaging": false,
                    "translator": {
                        "type": "TabularTranslator",
                        "typeConversion": true,
                        "typeConversionSettings": {
                            "allowDataTruncation": true,
                            "treatBooleanAsNumber": false
                        }
                    }
                },
                "inputs": [
                    {
                        "referenceName": "${resource.azurerm_data_factory_dataset_sql_server_table.azure_sql_server_status_data_table.name}",
                        "type": "DatasetReference"
                    }
                ],
                "outputs": [
                    {
                        "referenceName": "${resource.azurerm_data_factory_dataset_parquet.parquet_sink_maintenance_data.name}",
                        "type": "DatasetReference"
                    }
                ]
            },
            {
                "name": "data_power",
                "type": "Copy",
                "dependsOn": [
                    {
                        "activity": "DEMO_ONLY_write_historical_data_to_sql_server",
                        "dependencyConditions": [
                            "Succeeded"
                        ]
                    }
                ],
                "policy": {
                    "timeout": "0.12:00:00",
                    "retry": 0,
                    "retryIntervalInSeconds": 30,
                    "secureOutput": false,
                    "secureInput": false
                },
                "userProperties": [],
                "typeProperties": {
                    "source": {
                        "type": "AzureSqlSource",
                        "queryTimeout": "02:00:00",
                        "partitionOption": "None"
                    },
                    "sink": {
                        "type": "ParquetSink",
                        "storeSettings": {
                            "type": "AzureBlobFSWriteSettings"
                        },
                        "formatSettings": {
                            "type": "ParquetWriteSettings"
                        }
                    },
                    "enableStaging": false,
                    "translator": {
                        "type": "TabularTranslator",
                        "typeConversion": true,
                        "typeConversionSettings": {
                            "allowDataTruncation": true,
                            "treatBooleanAsNumber": false
                        }
                    }
                },
                "inputs": [
                    {
                        "referenceName": "${resource.azurerm_data_factory_dataset_sql_server_table.azure_sql_server_power_output_table.name}",
                        "type": "DatasetReference"
                    }
                ],
                "outputs": [
                    {
                        "referenceName": "${resource.azurerm_data_factory_dataset_parquet.parquet_sink_power_output.name}",
                        "type": "DatasetReference"
                    }
                ]
            },
            {
                "name": "Ingest_data_to_delta",
                "type": "DatabricksNotebook",
                "dependsOn": [
                    {
                        "activity": "data_maintenance",
                        "dependencyConditions": [
                            "Succeeded"
                        ]
                    },
                    {
                        "activity": "data_power",
                        "dependencyConditions": [
                            "Succeeded"
                        ]
                    }
                ],
                "policy": {
                    "timeout": "0.12:00:00",
                    "retry": 0,
                    "retryIntervalInSeconds": 30,
                    "secureOutput": false,
                    "secureInput": false
                },
                "userProperties": [],
                "typeProperties": {
                    "notebookPath": "${data.databricks_current_user.me.home}/Demo/01_Batch_ADF_to_Delta_Table"
                },
                "linkedServiceName": {
                    "referenceName": "${resource.azurerm_data_factory_linked_service_azure_databricks.msi_linked_databricks_workspace.name}",
                    "type": "LinkedServiceReference"
                }
            }
            ]
  JSON
}
