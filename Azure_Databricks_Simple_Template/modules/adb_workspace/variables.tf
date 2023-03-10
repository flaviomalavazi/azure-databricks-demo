
// Prefixo para os nomes dos recursos que serão criados
variable "prefix" {
  type        = string
  description = "(Opcional) Prefixo que utilizaremos na nomenclatura de todos os recursos criados."
  default     = null
}

variable "no_public_ip" {
  type        = bool
  description = "(Obrigatório) Flag para indicar se o workspace vai se conectar ao plano de dados Databricks sem IPs públicos."
  default     = true
}

variable "storage_account_sku" {
  type        = string
  description = "(Obrigatório) The SKU for the storage account that will host the DBFS"
  default     = "Standard_LRS"
}

variable "databricks_sku" {
  type        = string
  description = "(Obrigatório) O SKU do workspace Databricks"
  default     = "premium"
}

variable "resource_group_location" {
  type        = string
  description = "(Obrigatório) A localização do resource group"
}

variable "tags" {
  type        = map(string)
  description = "(Opcional) Mapa de tags a serem aplicadas no cluster"
  default     = null
}

data "azurerm_client_config" "current_environment_config" {}

data "external" "me" {
  program = ["az", "account", "show", "--query", "user"]
}

// Geração de uma string aleatória para evitar conflitos entre usuários deste template em um mesmo ambiente
resource "random_string" "suffix" {
  special = false
  upper   = false
  length  = 6
}

locals {
  resource_group_name       = var.prefix != null ? "${var.prefix}-rg" : "${random_string.suffix.result}-rg"
  managed_rg                = var.prefix != null ? "${var.prefix}-mrg" : "${random_string.suffix.result}-mrg"
  databricks_workspace_name = var.prefix != null ? "${var.prefix}-adb-workspace" : "${random_string.suffix.result}-adb-workspace"
  storage_account_name      = var.prefix != null ? "adbadls${var.prefix}" : "adbadls${random_string.suffix.result}"
  databricks_my_username    = data.external.me // Nome do usuário que será criado no workspace gerido pelo terraform
}
