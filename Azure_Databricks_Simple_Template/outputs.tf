output "resource_group_name" {
  value = module.databricks_workspace.resource_group_name
}

output "resource_group_id" {
  value = module.databricks_workspace.resource_group_id
}

output "databricks_azure_workspace_resource_url" {
  value = module.databricks_workspace.databricks_ws_url
}

output "cluster_id" {
  value = module.cluster.cluster_id
}
