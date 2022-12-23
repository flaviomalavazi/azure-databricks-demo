
resource "databricks_job" "demo_workflow" {
  webhook_notifications {
  }
  task {
    task_key = "DEMO_ONLY_Write_to_SQL_Server"
    notebook_task {
      source        = "WORKSPACE"
      notebook_path = "${data.databricks_current_user.me.home}/Demo_v2/DEMO_Write_Mock_Data_to_SQL_Server"
    }
    existing_cluster_id = resource.databricks_cluster.first_cluster.id
    email_notifications {
    }
  }
  task {
    task_key = "Read_Data_From_SQL_Server"
    notebook_task {
      source        = "WORKSPACE"
      notebook_path = "${data.databricks_current_user.me.home}/Demo_v2/01_Read_Data_from_SQL_Server"
    }
    existing_cluster_id = resource.databricks_cluster.first_cluster.id
    email_notifications {
    }
    depends_on {
      task_key = "DEMO_ONLY_Write_to_SQL_Server"
    }
  }
  name = "Demo_Start_Workflow"
  email_notifications {
  }
}
