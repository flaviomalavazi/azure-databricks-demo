module "databricks_workspace" {
  source                  = "./modules/adb_workspace"
  prefix                  = "exemplo-terraform"
  resource_group_location = "brazilsouth"
  no_public_ip            = true
  storage_account_sku     = "Standard_LRS"
  databricks_sku          = "premium"
  tags = { // Tags para facilitar a governança do seu ambiente
    Environment = "Demo-with-terraform"
    Owner       = split("@", lookup(data.external.me.result, "name"))[0]
    OwnerEmail  = lookup(data.external.me.result, "name")
    KeepUntil   = "2023-01-31"
    Keep-Until  = "2023-01-31"
  }
}

module "cluster" {
  source                         = "./modules/adb_auto_scaling_cluster"
  azure_databricks_workspace_url = module.databricks_workspace.databricks_ws_url
  auto_scaling_cluster           = true
  min_auto_scaling               = 1
  max_auto_scaling               = 3
  cluster_name                   = "First Cluster"
  autotermination_minutes        = 30
  tags = { // Tags para facilitar a governança do seu ambiente
    Environment = "Demo-with-terraform"
    Owner       = split("@", lookup(data.external.me.result, "name"))[0]
    OwnerEmail  = lookup(data.external.me.result, "name")
    KeepUntil   = "2023-01-31"
    Keep-Until  = "2023-01-31"
  }
}
