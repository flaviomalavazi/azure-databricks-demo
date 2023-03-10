provider "databricks" {
  host  = var.azure_databricks_workspace_url
  alias = "workspace"
}
