/*
NÃO MODIFIQUE O BLOCO DE COMENTÁRIOS.

Vamos utilizar este bloco para declarar variáveis para nossa demo.

Mais informações sobre variáveis no terraform podem ser encontradas aqui: https://www.terraform.io/language/values/variables

Mais informações sobre os `locals` podem ser encontradas aqui: https://www.terraform.io/language/values/locals

Fique a vontade para alterar os valores defaults das tags indicadas.

**/


// Região da Azure onde nosso workspace Azure Databricks (e os recursos gerenciados por ele) será criado.
variable "resource_group_location" {
  type        = string
  default     = "brazilsouth" // Pode ser alterado
  description = "Localização do grupo de recursos."
}

// Prefixo para os nomes dos recursos que serão criados
variable "prefix" {
  type        = string
  default     = "demos-latam-azure-databricks" // Pode ser alterado
  description = "Prefixo que utilizaremos na nomenclatura de todos os recursos criados."
}

data "azurerm_client_config" "current_environment_config" {}

// Geração de uma string aleatória para evitar conflitos entre usuários deste template em um mesmo ambiente
resource "random_string" "suffix" {
  special = false
  upper   = false
  length  = 6
}

resource "random_string" "password_sufix" {
  special = false
  upper   = false
  length  = 10
}
variable "sql_server_database_name" {
  type        = string
  default     = "fleetmaintenance"
  description = "Default sql server database name"
}

locals {
  managed_rg                                  = "${var.prefix}-mrg-${random_string.suffix.result}"
  demo_managed_identity                       = "${var.prefix}-managed_identity-${random_string.suffix.result}"
  demo_ad_app_name                            = "${var.prefix}-adls-adapp-${random_string.suffix.result}"
  azuread_application_role_permissions_name   = "${var.prefix}-adls-adapp-${random_string.suffix.result}-role"
  demo_key_vault_name                         = "keyvault-${random_string.suffix.result}"
  databricks_instance_name                    = "${var.prefix}-${random_string.suffix.result}"
  storage_account_name                        = "adatabricksadls${random_string.suffix.result}"
  demo_general_purpose_storage_container_name = "${var.prefix}-container"
  demo_synapse_storage_container_name         = "${var.prefix}-synapse"
  demo_terraform_storage_container_name       = "terraform-state"
  demo_eventhub_namespace                     = "demo-eh-ns-${random_string.suffix.result}"
  demo_eventhub_name                          = "demo-eventhub-${random_string.suffix.result}"
  demo_sql_server_admin_login                 = "adminstrator${random_string.suffix.result}"
  demo_sql_server_power_output_table_name     = "dbo.power_output"
  demo_sql_server_turbine_status_table_name   = "dbo.maintenance_header"
  demo_sql_server_last_etl_table_name         = "dbo.etl_timestamp"
  databricks_my_username                      = var.my_username // Nome do usuário que será criado no workspace gerido pelo terraform
  tags = {                                                      // Tags para facilitar a governança do seu ambiente
    Environment = "Demo-with-terraform"
    Owner       = split("@", var.my_username)[0]
    OwnerEmail  = var.my_username
    KeepUntil   = "2023-01-31"
    Keep-Until  = "2022-01-31"
  }

}
