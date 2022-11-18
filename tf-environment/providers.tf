/*
Terraform provider -> bloco de provedores obrigatório.

Você pode encontrar os provedores necessários (`required_providers`) utilizando: https://registry.terraform.io/providers/databricks/databricks/1.2.1 e
no topo direito superior clicar em `use provider`, o que deve apresentar o bloco necessário. Você vai precisar de diferentes providers para utilizar
funcionalidades diferentes no terraform.

Você pode especificar a versão do provedor ou utilizar a mais recente se não especificar a versão. É indicado que você trave seus provedores em uma versão
específica caso uma nova versão não seja retro compatível.

Nesta demo, vamos precisar do provedor azurerm, o random e do Databricks.
*/

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.29.0"
    }

    azuread = {
      source  = "hashicorp/azuread"
      version = "2.15.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.4.1"
    }

    time = {
      source  = "hashicorp/time"
      version = "0.9.1"
    }

    databricks = {
      source  = "databricks/databricks"
      version = "1.5.0"
    }

    shell = {
      source  = "scottwinkler/shell"
      version = "1.7.10"
    }

  }

}

provider "azurerm" {
  features {}
}

# 
provider "shell" {}

provider "databricks" {
  host = azurerm_databricks_workspace.databricks_demo_workspace.workspace_url
}

# Configure the Azure Active Directory Provider
provider "azuread" {}

provider "time" {}
