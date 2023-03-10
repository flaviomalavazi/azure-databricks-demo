data "databricks_node_type" "smallest" {
  provider   = databricks.workspace
  local_disk = true
}

data "databricks_spark_version" "latest_lts" {
  provider          = databricks.workspace
  long_term_support = true
}

resource "databricks_cluster" "this" {
  provider                = databricks.workspace
  cluster_name            = var.cluster_name
  spark_version           = var.spark_version == null ? data.databricks_spark_version.latest_lts.id : var.spark_version
  node_type_id            = var.node_type_id == null ? data.databricks_node_type.smallest.id : var.node_type_id
  autotermination_minutes = var.autotermination_minutes == null ? 30 : var.autotermination_minutes
  data_security_mode      = "USER_ISOLATION"
  custom_tags             = var.tags
  autoscale {
    min_workers = var.min_auto_scaling
    max_workers = var.max_auto_scaling
  }
}
