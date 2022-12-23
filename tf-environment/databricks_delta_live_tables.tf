
resource "databricks_pipeline" "demo_dlt_pipeline" {
  name        = "Demo_DLT_Pipeline"
  storage     = "abfss://${resource.azurerm_storage_container.demo_general_purpose_container.name}@${resource.azurerm_storage_account.demo_storage_account.name}.dfs.core.windows.net/dlt"
  target      = "dlt_demo"
  channel     = "preview"
  edition     = "advanced"
  photon      = false
  continuous  = true
  development = true
  depends_on = [
    resource.azurerm_databricks_workspace.databricks_demo_workspace,
    resource.databricks_secret_scope.databricks_secret_scope_kv_managed,
    resource.databricks_cluster_policy.default_data_access_policy
  ]
  cluster {
    label     = "default"
    policy_id = resource.databricks_cluster_policy.default_data_access_policy.id
    autoscale {
      min_workers = 1
      max_workers = 5
      mode        = "ENHANCED"
    }
    custom_tags = {
      cluster_type = "dlt_demo_pipeline"
    }
  }

  cluster {
    label       = "maintenance"
    num_workers = 1
    custom_tags = {
      cluster_type = "dlt_demo_pipeline_maintenance"
    }
  }

  library {
    notebook {
      path = data.databricks_notebook.dlt_demo_notebook.path
    }
  }

}


resource "databricks_pipeline" "demo_dlt_pipeline_v2" {
  name        = "Demo_DLT_Pipeline_v2"
  storage     = "abfss://${resource.azurerm_storage_container.demo_general_purpose_container.name}@${resource.azurerm_storage_account.demo_storage_account.name}.dfs.core.windows.net/dlt_v2"
  target      = "dlt_demo_v2"
  channel     = "preview"
  edition     = "advanced"
  photon      = false
  continuous  = true
  development = true
  depends_on = [
    resource.azurerm_databricks_workspace.databricks_demo_workspace,
    resource.databricks_secret_scope.databricks_secret_scope_kv_managed,
    resource.databricks_cluster_policy.default_data_access_policy
  ]
  cluster {
    label     = "default"
    policy_id = resource.databricks_cluster_policy.default_data_access_policy.id
    autoscale {
      min_workers = 1
      max_workers = 5
      mode        = "ENHANCED"
    }
    custom_tags = {
      cluster_type = "dlt_demo_pipeline"
    }
  }

  cluster {
    label       = "maintenance"
    num_workers = 1
    custom_tags = {
      cluster_type = "dlt_demo_pipeline_maintenance"
    }
  }

  library {
    notebook {
      path = "${data.databricks_current_user.me.home}/Demo_v2/Delta_Live_Tables/DLT_Pipeline_v2"
    }
  }

}