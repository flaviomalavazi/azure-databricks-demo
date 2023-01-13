terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.32.0"
    }

    databricks = {
      source  = "databricks/databricks"
      version = "1.7.0"
    }

  }

}

provider "azurerm" {
  features {}
}

provider "databricks" {
  host = azurerm_databricks_workspace.databricks_demo_workspace.workspace_url
}
