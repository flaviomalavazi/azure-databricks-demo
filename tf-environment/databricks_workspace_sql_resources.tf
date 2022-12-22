// Queries
resource "databricks_sql_query" "gold_table_query_check" {
  query          = <<EOT
                    SELECT
                      sensor.*,
                      weather.temperature, 
                      weather.humidity, 
                      weather.windspeed, 
                      weather.winddirection,
                      maint.maintenance,
                      power.power
                    FROM
                      hive_metastore.dlt_demo.silver_agg_turbine_data sensor
                      INNER JOIN hive_metastore.dlt_demo.silver_agg_weather_data weather
                        ON sensor.`date` = weather.`date` AND sensor.`window` = weather.`window`
                      INNER JOIN hive_metastore.dlt_demo.silver_maintenance_data maint
                        ON sensor.`date` = maint.`date` and sensor.deviceid = maint.deviceid
                      INNER JOIN hive_metastore.dlt_demo.silver_poweroutput_data power
                      ON sensor.`date` = power.`date` AND sensor.`window` = power.`window` AND sensor.deviceid = power.deviceid 
                EOT
  name           = "Verification_Query_For_Gold_DLT_Table"
  data_source_id = resource.databricks_sql_endpoint.demo_sql_warehouse.data_source_id
}


resource "databricks_sql_query" "daily_summary_943ce445_af87_4797_9691_afde95c08e97" {
  query          = "select \n\t`date`\n\t,sum(power) as power_generated\n\t,count(distinct case when maintenance = 1 then deviceId else null end) AS broken_turbines \nfrom \n\thive_metastore.dlt_demo.gold_turbine_data\nwhere\n\t`date` <= getdate()\ngroup by\n\t`date`\norder by\n\t`date` desc"
  name           = "Daily_Summary"
  data_source_id = resource.databricks_sql_endpoint.demo_sql_warehouse.data_source_id
}
resource "databricks_sql_query" "gold_table_data_0452cdab_e378_4a2a_a1e2_86fa8b6f9c73" {
  query          = "select\n  *\nfrom\n  hive_metastore.dlt_demo.gold_turbine_data\nwhere\n  `date` <= getdate()"
  name           = "Gold_table_data"
  data_source_id = resource.databricks_sql_endpoint.demo_sql_warehouse.data_source_id
}
resource "databricks_sql_query" "gold_table_query_check_746e141c_1040_4d94_b069_e7f52fa21492" {
  query          = "SELECT\n  sensor.*,\n  weather.temperature,\n  weather.humidity,\n  weather.windspeed,\n  weather.winddirection,\n  maint.maintenance,\n  power.power\nFROM\n  hive_metastore.dlt_demo.silver_agg_turbine_data sensor\n  INNER JOIN hive_metastore.dlt_demo.silver_agg_weather_data weather ON sensor.`date` = weather.`date`\n  AND sensor.`window` = weather.`window`\n  INNER JOIN hive_metastore.dlt_demo.silver_maintenance_data maint ON sensor.`date` = maint.`date`\n  and sensor.deviceid = maint.deviceid\n  INNER JOIN hive_metastore.dlt_demo.silver_poweroutput_data power ON sensor.`date` = power.`date`\n  AND sensor.`window` = power.`window`\n  AND sensor.deviceid = power.deviceid"
  name           = "Gold_table_query_check"
  data_source_id = resource.databricks_sql_endpoint.demo_sql_warehouse.data_source_id
}
resource "databricks_sql_query" "maintenance_status_35d30e19_a826_430e_982e_23bb07c8c855" {
  query          = "select \n\t`date`\n\t,case \n\t\twhen maintenance = 1 then deviceId else null \n\t\tend as maintenance_turbine\nfrom \n\thive_metastore.dlt_demo.silver_maintenance_data\nwhere\n\t`date` <= getdate()"
  name           = "Maintenance_Status"
  data_source_id = resource.databricks_sql_endpoint.demo_sql_warehouse.data_source_id
}
resource "databricks_sql_query" "power_production_and_loss_2aceefeb_23ab_4e72_acd5_4c494039df6e" {
  query          = "select \n\tpw.`date`\n\t,pw.deviceId\n\t,sum(case when md.maintenance = 0 then `power` else 0 end) \t\t\t\t\t\t\t\t\tas daily_actual_power\n\t,sum(`power`) \t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\tas daily_theoretical_power\n\t,sum(`power`) - sum(case when md.maintenance = 0 then `power` else 0 end)\t\tas daily_defict\nfrom \n\thive_metastore.dlt_demo.silver_poweroutput_data as pw\n\tjoin hive_metastore.dlt_demo.silver_maintenance_data md on pw.deviceId = md.deviceId and pw.`date` = md.`date` \nwhere\n\tpw.deviceId <> \"WindTurbine-10\"\n\tand pw.`date` <= getdate()\ngroup by\n\tpw.`date`\n\t,pw.deviceId\norder by\n\tpw.`date`\n\t,pw.deviceId"
  name           = "Power_production_and_loss"
  data_source_id = resource.databricks_sql_endpoint.demo_sql_warehouse.data_source_id
}
resource "databricks_sql_query" "summary_power_production_and_loss_58236411_2f20_4cc5_ad8d_e415fb02466e" {
  query          = "select \n\tsum(case when md.maintenance = 0 then `power` else 0 end) \t\t\t\t\t\t\t\t\tas daily_actual_power\n\t,sum(`power`) \t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\tas daily_theoretical_power\n\t,sum(`power`) - sum(case when md.maintenance = 0 then `power` else 0 end)\t\tas daily_defict\nfrom \n\thive_metastore.dlt_demo.silver_poweroutput_data as pw\n\tjoin hive_metastore.dlt_demo.silver_maintenance_data md on pw.deviceId = md.deviceId and pw.`date` = md.`date` \nwhere\n\tpw.deviceId <> \"WindTurbine-10\"\n"
  name           = "Summary_power_production_and_loss"
  data_source_id = resource.databricks_sql_endpoint.demo_sql_warehouse.data_source_id
}
resource "databricks_sql_query" "turbine_rotation_data_d43ca92d_2a51_4019_972a_1104855f02a4" {
  query          = "select\n  *\nfrom\n  hive_metastore.dlt_demo.silver_agg_turbine_data\nwhere\n  `window` >= getdate() - INTERVAL 7 DAYS\n  and `date` <= getdate()"
  name           = "Turbine_rotation_data"
  data_source_id = resource.databricks_sql_endpoint.demo_sql_warehouse.data_source_id
}
resource "databricks_sql_query" "weather_data_8777f989_6390_4ec7_bd79_6ab21d18ad07" {
  query          = "select\n  *\nfrom\n  hive_metastore.dlt_demo.silver_agg_weather_data\nwhere\n  `window` >= getdate() - INTERVAL 7 DAYS\n  and `date` <= getdate()"
  name           = "Weather_data"
  data_source_id = resource.databricks_sql_endpoint.demo_sql_warehouse.data_source_id
}

// Dashboard Definition
resource "databricks_sql_dashboard" "demo_dashboard_8b02222a_e374_4658_b766_8d7f379586ea" {
  name = "[Demo] Wind Turbine Dashboard"
}

// Dashboard Components
resource "databricks_sql_visualization" "agg_power_generated_kwh_0452cdab_e378_4a2a_a1e2_86fa8b6f9c734700f148_22c8_49cf_a16d_c4e5cace696a" {
  type       = "chart"
  query_plan = "{\"selects\": [{\"column\": \"window\"}, {\"function\": \"SUM\", \"args\": [{\"column\": \"power\"}], \"alias\": \"column_c29e138b24066\"}, {\"column\": \"deviceId\"}], \"groups\": [{\"column\": \"window\"}, {\"column\": \"deviceId\"}]}"
  query_id   = databricks_sql_query.gold_table_data_0452cdab_e378_4a2a_a1e2_86fa8b6f9c73.id
  options    = "{\"version\": 2, \"globalSeriesType\": \"column\", \"sortX\": true, \"sortY\": true, \"legend\": {\"traceorder\": \"normal\"}, \"xAxis\": {\"type\": \"-\", \"labels\": {\"enabled\": true}}, \"yAxis\": [{\"type\": \"-\", \"title\": {\"text\": \"Power Generated (KWh)\"}}, {\"type\": \"-\", \"opposite\": true}], \"alignYAxesAtZero\": true, \"error_y\": {\"type\": \"data\", \"visible\": true}, \"series\": {\"stacking\": \"stack\", \"error_y\": {\"type\": \"data\", \"visible\": true}}, \"seriesOptions\": {\"column_c29e138b24066\": {\"yAxis\": 0, \"type\": \"column\"}, \"WindTurbine-1\": {\"color\": \"#373144\"}, \"WindTurbine-2\": {\"color\": \"#534B62\"}, \"WindTurbine-3\": {\"color\": \"#90869F\"}, \"WindTurbine-4\": {\"color\": \"#A499B3\"}, \"WindTurbine-5\": {\"color\": \"#BAABC4\"}, \"WindTurbine-6\": {\"color\": \"#D0BCD5\"}, \"WindTurbine-7\": {\"color\": \"#7994DB\"}, \"WindTurbine-8\": {\"color\": \"#226CE0\"}, \"WindTurbine-9\": {\"color\": \"#1B5CC5\"}}, \"valuesOptions\": {}, \"direction\": {\"type\": \"counterclockwise\"}, \"sizemode\": \"diameter\", \"coefficient\": 1, \"numberFormat\": \"0,0[.]\", \"percentFormat\": \"0[.]00%\", \"textFormat\": \"\", \"missingValuesAsZero\": true, \"useAggregationsUi\": true, \"swappedAxes\": false, \"dateTimeFormat\": \"YYYY-MM-DD HH:mm\", \"showDataLabels\": true, \"columnConfigurationMap\": {\"x\": {\"column\": \"window\", \"id\": \"column_c29e138b23970\"}, \"y\": [{\"id\": \"column_c29e138b24066\", \"column\": \"power\", \"transform\": \"SUM\"}], \"series\": {\"column\": \"deviceId\", \"id\": \"column_c29e138b24064\"}}, \"isAggregationOn\": true, \"condensed\": true, \"withRowNumber\": true, \"hideYAxes\": false}"
  name       = "(Agg) - Power Generated (KWh)"
}

resource "databricks_sql_visualization" "nrt_rpm_turbines_d43ca92d_2a51_4019_972a_1104855f02a40118d43f_13d8_4df3_a773_e107774ef0c8" {
  type       = "chart"
  query_plan = "{\"selects\": [{\"column\": \"window\"}, {\"function\": \"SUM\", \"args\": [{\"column\": \"rpm\"}], \"alias\": \"column_c29e138b14915\"}, {\"column\": \"deviceId\"}], \"groups\": [{\"column\": \"window\"}, {\"column\": \"deviceId\"}]}"
  query_id   = databricks_sql_query.turbine_rotation_data_d43ca92d_2a51_4019_972a_1104855f02a4.id
  options    = "{\"version\": 2, \"globalSeriesType\": \"column\", \"sortX\": true, \"sortY\": true, \"legend\": {\"traceorder\": \"normal\", \"enabled\": true, \"placement\": \"below\"}, \"xAxis\": {\"type\": \"-\", \"labels\": {\"enabled\": true}}, \"yAxis\": [{\"type\": \"-\", \"title\": {\"text\": \"Turbine RPM\"}}, {\"type\": \"-\", \"opposite\": true}], \"alignYAxesAtZero\": true, \"error_y\": {\"type\": \"data\", \"visible\": true}, \"series\": {\"stacking\": null, \"error_y\": {\"type\": \"data\", \"visible\": true}}, \"seriesOptions\": {\"column_c29e138b14915\": {\"yAxis\": 0, \"type\": \"column\"}, \"column_c29e138b14917\": {\"yAxis\": 0, \"type\": \"column\"}, \"WindTurbine-0\": {\"color\": \"#1B1725\", \"type\": \"column\"}, \"WindTurbine-1\": {\"color\": \"#373144\", \"type\": \"column\"}, \"WindTurbine-2\": {\"color\": \"#534B62\", \"type\": \"column\"}, \"WindTurbine-3\": {\"color\": \"#90869F\", \"type\": \"column\"}, \"WindTurbine-4\": {\"color\": \"#A499B3\", \"type\": \"column\"}, \"WindTurbine-5\": {\"color\": \"#BAABC4\", \"type\": \"column\"}, \"WindTurbine-6\": {\"color\": \"#D0BCD5\", \"type\": \"column\"}, \"WindTurbine-7\": {\"color\": \"#7994DB\", \"type\": \"column\"}, \"WindTurbine-8\": {\"color\": \"#226CE0\", \"type\": \"column\"}, \"WindTurbine-9\": {\"color\": \"#1B5CC5\", \"type\": \"column\"}}, \"valuesOptions\": {}, \"direction\": {\"type\": \"counterclockwise\"}, \"sizemode\": \"diameter\", \"coefficient\": 1, \"numberFormat\": \"0,0[.]00000\", \"percentFormat\": \"0[.]00%\", \"textFormat\": \"\", \"missingValuesAsZero\": true, \"useAggregationsUi\": true, \"swappedAxes\": false, \"dateTimeFormat\": \"YYYY-MM-DD HH:mm\", \"showDataLabels\": false, \"columnConfigurationMap\": {\"x\": {\"column\": \"window\", \"id\": \"column_c29e138b14913\"}, \"y\": [{\"id\": \"column_c29e138b14915\", \"column\": \"rpm\", \"transform\": \"SUM\"}], \"series\": {\"column\": \"deviceId\", \"id\": \"column_c29e138b14918\"}}, \"isAggregationOn\": true, \"condensed\": true, \"withRowNumber\": true}"
  name       = "(NRT) - RPM Turbines"
}
resource "databricks_sql_visualization" "nrt_temperature_humidity_8777f989_6390_4ec7_bd79_6ab21d18ad07eed263ed_ad42_4256_976c_05848514af0b" {
  type       = "chart"
  query_plan = "{\"selects\": [{\"column\": \"window\"}, {\"function\": \"SUM\", \"args\": [{\"column\": \"temperature\"}], \"alias\": \"column_c29e138b20287\"}, {\"function\": \"SUM\", \"args\": [{\"column\": \"humidity\"}], \"alias\": \"column_c29e138b20289\"}], \"groups\": [{\"column\": \"window\"}]}"
  query_id   = databricks_sql_query.weather_data_8777f989_6390_4ec7_bd79_6ab21d18ad07.id
  options    = "{\"version\": 2, \"globalSeriesType\": \"combo\", \"sortX\": true, \"sortY\": true, \"legend\": {\"traceorder\": \"normal\", \"enabled\": true, \"placement\": \"below\"}, \"xAxis\": {\"type\": \"-\", \"labels\": {\"enabled\": true}, \"title\": {\"text\": \"Date & Time\"}}, \"yAxis\": [{\"type\": \"-\", \"title\": {\"text\": \"Temperature\"}}, {\"type\": \"-\", \"opposite\": true, \"title\": {\"text\": \"Humidity\"}}], \"alignYAxesAtZero\": true, \"error_y\": {\"type\": \"data\", \"visible\": true}, \"series\": {\"stacking\": null, \"error_y\": {\"type\": \"data\", \"visible\": true}}, \"seriesOptions\": {\"column_c29e138b20287\": {\"yAxis\": 0, \"type\": \"column\", \"color\": \"#E92828\"}, \"column_c29e138b20289\": {\"yAxis\": 1, \"type\": \"line\", \"color\": \"#002FB4\"}}, \"valuesOptions\": {}, \"direction\": {\"type\": \"counterclockwise\"}, \"sizemode\": \"diameter\", \"coefficient\": 1, \"numberFormat\": \"0,0[.]00000\", \"percentFormat\": \"0[.]00%\", \"textFormat\": \"\", \"missingValuesAsZero\": true, \"useAggregationsUi\": true, \"swappedAxes\": false, \"dateTimeFormat\": \"YYYY-MM-DD HH:mm\", \"showDataLabels\": false, \"columnConfigurationMap\": {\"x\": {\"column\": \"window\", \"id\": \"column_c29e138b20162\"}, \"y\": [{\"id\": \"column_c29e138b20287\", \"column\": \"temperature\", \"transform\": \"SUM\"}, {\"id\": \"column_c29e138b20289\", \"column\": \"humidity\", \"transform\": \"SUM\"}]}, \"isAggregationOn\": true}"
  name       = "(NRT) - Temperature & Humidity"
}
resource "databricks_sql_visualization" "nrt_turbine_angle_d43ca92d_2a51_4019_972a_1104855f02a42423d6eb_4730_4fe2_b38d_b9fbe5ef4fac" {
  type       = "chart"
  query_plan = "{\"selects\": [{\"column\": \"window\"}, {\"function\": \"SUM\", \"args\": [{\"column\": \"angle\"}], \"alias\": \"column_c29e138b39593\"}, {\"column\": \"deviceId\"}], \"groups\": [{\"column\": \"window\"}, {\"column\": \"deviceId\"}]}"
  query_id   = databricks_sql_query.turbine_rotation_data_d43ca92d_2a51_4019_972a_1104855f02a4.id
  options    = "{\"version\": 2, \"globalSeriesType\": \"column\", \"sortX\": true, \"sortY\": true, \"legend\": {\"traceorder\": \"normal\", \"enabled\": true, \"placement\": \"below\"}, \"xAxis\": {\"type\": \"-\", \"labels\": {\"enabled\": true}}, \"yAxis\": [{\"type\": \"-\", \"title\": {\"text\": \"Turbine Angle\"}}, {\"type\": \"-\", \"opposite\": true}], \"alignYAxesAtZero\": true, \"error_y\": {\"type\": \"data\", \"visible\": true}, \"series\": {\"stacking\": null, \"error_y\": {\"type\": \"data\", \"visible\": true}}, \"seriesOptions\": {\"column_c29e138b39593\": {\"yAxis\": 0, \"type\": \"column\"}, \"WindTurbine-0\": {\"color\": \"#1B1725\"}, \"WindTurbine-1\": {\"color\": \"#373144\"}, \"WindTurbine-2\": {\"color\": \"#534B62\"}, \"WindTurbine-3\": {\"color\": \"#90869F\"}, \"WindTurbine-4\": {\"color\": \"#A499B3\"}, \"WindTurbine-5\": {\"color\": \"#BAABC4\"}, \"WindTurbine-6\": {\"color\": \"#D0BCD5\"}, \"WindTurbine-7\": {\"color\": \"#7994DB\"}, \"WindTurbine-8\": {\"color\": \"#226CE0\"}, \"WindTurbine-9\": {\"color\": \"#1B5CC5\"}}, \"valuesOptions\": {}, \"direction\": {\"type\": \"counterclockwise\"}, \"sizemode\": \"diameter\", \"coefficient\": 1, \"numberFormat\": \"0,0[.]00000\", \"percentFormat\": \"0[.]00%\", \"textFormat\": \"\", \"missingValuesAsZero\": true, \"useAggregationsUi\": true, \"swappedAxes\": false, \"dateTimeFormat\": \"YYYY-MM-DD HH:mm\", \"showDataLabels\": false, \"columnConfigurationMap\": {\"x\": {\"column\": \"window\", \"id\": \"column_c29e138b39591\"}, \"y\": [{\"id\": \"column_c29e138b39593\", \"column\": \"angle\", \"transform\": \"SUM\"}], \"series\": {\"column\": \"deviceId\", \"id\": \"column_c29e138b39594\"}}, \"isAggregationOn\": true}"
  name       = "(NRT) - Turbine Angle"
}
resource "databricks_sql_visualization" "nrt_wind_speed_direction_8777f989_6390_4ec7_bd79_6ab21d18ad07a6c92c56_5979_4851_9e9e_e0750028dd6e" {
  type       = "chart"
  query_plan = "{\"selects\": [{\"column\": \"window\"}, {\"function\": \"SUM\", \"args\": [{\"column\": \"windspeed\"}], \"alias\": \"column_c29e138b19787\"}, {\"column\": \"winddirection\"}], \"groups\": [{\"column\": \"window\"}, {\"column\": \"winddirection\"}]}"
  query_id   = databricks_sql_query.weather_data_8777f989_6390_4ec7_bd79_6ab21d18ad07.id
  options    = "{\"version\": 2, \"globalSeriesType\": \"line\", \"sortX\": true, \"sortY\": true, \"legend\": {\"traceorder\": \"normal\", \"enabled\": true, \"placement\": \"below\"}, \"xAxis\": {\"type\": \"-\", \"labels\": {\"enabled\": true}}, \"yAxis\": [{\"type\": \"-\"}, {\"type\": \"-\", \"opposite\": true}], \"alignYAxesAtZero\": true, \"error_y\": {\"type\": \"data\", \"visible\": true}, \"series\": {\"stacking\": null, \"error_y\": {\"type\": \"data\", \"visible\": true}}, \"seriesOptions\": {\"column_c29e138b19787\": {\"yAxis\": 0, \"type\": \"line\"}, \"column_c29e138b19789\": {\"yAxis\": 0, \"type\": \"line\"}, \"column_c29e138b19872\": {\"yAxis\": 0, \"type\": \"line\"}}, \"valuesOptions\": {}, \"direction\": {\"type\": \"counterclockwise\"}, \"sizemode\": \"diameter\", \"coefficient\": 1, \"numberFormat\": \"0,0[.]00000\", \"percentFormat\": \"0[.]00%\", \"textFormat\": \"\", \"missingValuesAsZero\": true, \"useAggregationsUi\": true, \"swappedAxes\": false, \"dateTimeFormat\": \"YYYY-MM-DD HH:mm\", \"showDataLabels\": false, \"columnConfigurationMap\": {\"x\": {\"column\": \"window\", \"id\": \"column_c29e138b19785\"}, \"y\": [{\"id\": \"column_c29e138b19787\", \"column\": \"windspeed\", \"transform\": \"SUM\"}], \"series\": {\"column\": \"winddirection\", \"id\": \"column_c29e138b19874\"}}, \"isAggregationOn\": true}"
  name       = "(NRT) - Wind Speed & Direction"
}
resource "databricks_sql_visualization" "power_generated_today_943ce445_af87_4797_9691_afde95c08e97b1c1c7a9_d26e_4f65_b69c_a8e3eb90dece" {
  type     = "counter"
  query_id = databricks_sql_query.daily_summary_943ce445_af87_4797_9691_afde95c08e97.id
  options  = "{\"counterLabel\": \"KWh\", \"counterColName\": \"power_generated\", \"rowNumber\": 1, \"targetRowNumber\": 1, \"stringDecimal\": 0, \"stringDecChar\": \".\", \"stringThouSep\": \",\", \"tooltipFormat\": \"0,0.000\", \"targetColName\": \"\"}"
  name     = "Power generated today"
}
resource "databricks_sql_visualization" "power_loss_per_day_due_to_maintenance_2aceefeb_23ab_4e72_acd5_4c494039df6ef37034bc_1b31_4383_8f68_b32483f2221e" {
  type       = "chart"
  query_plan = "{\"selects\": [{\"column\": \"date\"}, {\"function\": \"SUM\", \"args\": [{\"column\": \"daily_defict\"}], \"alias\": \"column_8c235f5b61300\"}], \"groups\": [{\"column\": \"date\"}]}"
  query_id   = databricks_sql_query.power_production_and_loss_2aceefeb_23ab_4e72_acd5_4c494039df6e.id
  options    = "{\"version\": 2, \"globalSeriesType\": \"column\", \"sortX\": true, \"sortY\": true, \"legend\": {\"traceorder\": \"normal\"}, \"xAxis\": {\"type\": \"-\", \"labels\": {\"enabled\": true}, \"title\": {\"text\": \"Date\"}}, \"yAxis\": [{\"type\": \"-\"}, {\"type\": \"-\", \"opposite\": true}], \"alignYAxesAtZero\": true, \"error_y\": {\"type\": \"data\", \"visible\": true}, \"series\": {\"stacking\": null, \"error_y\": {\"type\": \"data\", \"visible\": true}}, \"seriesOptions\": {\"column_8c235f5b61300\": {\"yAxis\": 0, \"type\": \"column\", \"color\": \"#981717\", \"name\": \"Daily power deficit (KWh)\"}}, \"valuesOptions\": {}, \"direction\": {\"type\": \"counterclockwise\"}, \"sizemode\": \"diameter\", \"coefficient\": 1, \"numberFormat\": \"0,0[.]00000\", \"percentFormat\": \"0[.]00%\", \"textFormat\": \"\", \"missingValuesAsZero\": true, \"useAggregationsUi\": true, \"swappedAxes\": false, \"dateTimeFormat\": \"YYYY-MM-DD HH:mm\", \"showDataLabels\": false, \"columnConfigurationMap\": {\"x\": {\"column\": \"date\", \"id\": \"column_8c235f5b61298\"}, \"y\": [{\"id\": \"column_8c235f5b61300\", \"column\": \"daily_defict\", \"transform\": \"SUM\"}]}, \"isAggregationOn\": true}"
  name       = "Power loss per day due to maintenance"
}
resource "databricks_sql_visualization" "power_produced_per_day_2aceefeb_23ab_4e72_acd5_4c494039df6ed0fc87f3_950d_478a_b36f_414b83bea229" {
  type       = "chart"
  query_plan = "{\"selects\": [{\"column\": \"date\"}, {\"column\": \"deviceId\"}, {\"function\": \"SUM\", \"args\": [{\"column\": \"daily_actual_power\"}], \"alias\": \"column_8c235f5b33088\"}], \"groups\": [{\"column\": \"date\"}, {\"column\": \"deviceId\"}]}"
  query_id   = databricks_sql_query.power_production_and_loss_2aceefeb_23ab_4e72_acd5_4c494039df6e.id
  options    = "{\"version\": 2, \"globalSeriesType\": \"column\", \"sortX\": true, \"sortY\": true, \"legend\": {\"traceorder\": \"normal\", \"enabled\": true, \"placement\": \"below\"}, \"xAxis\": {\"type\": \"-\", \"labels\": {\"enabled\": true}}, \"yAxis\": [{\"type\": \"-\", \"title\": {\"text\": \"Daily Power Production (KWh)\"}}, {\"type\": \"-\", \"opposite\": true}], \"alignYAxesAtZero\": true, \"error_y\": {\"type\": \"data\", \"visible\": true}, \"series\": {\"stacking\": \"stack\", \"error_y\": {\"type\": \"data\", \"visible\": true}}, \"seriesOptions\": {\"column_8c235f5b33088\": {\"name\": \"daily_power\", \"yAxis\": 0, \"type\": \"column\"}, \"column_8c235f5b54605\": {\"yAxis\": 0, \"type\": \"column\"}, \"WindTurbine-1\": {\"color\": \"#373144\"}, \"WindTurbine-2\": {\"color\": \"#534B62\"}, \"WindTurbine-3\": {\"color\": \"#90869F\"}, \"WindTurbine-4\": {\"color\": \"#A499B3\"}, \"WindTurbine-5\": {\"color\": \"#BAABC4\"}, \"WindTurbine-6\": {\"color\": \"#D0BCD5\"}, \"WindTurbine-7\": {\"color\": \"#7994DB\"}, \"WindTurbine-8\": {\"color\": \"#226CE0\"}, \"WindTurbine-9\": {\"color\": \"#1B5CC5\"}}, \"valuesOptions\": {}, \"direction\": {\"type\": \"counterclockwise\"}, \"sizemode\": \"diameter\", \"coefficient\": 1, \"numberFormat\": \"0,0[.]00000\", \"percentFormat\": \"0[.]00%\", \"textFormat\": \"\", \"missingValuesAsZero\": true, \"useAggregationsUi\": true, \"swappedAxes\": false, \"dateTimeFormat\": \"YYYY-MM-DD HH:mm\", \"showDataLabels\": false, \"columnConfigurationMap\": {\"x\": {\"column\": \"date\", \"id\": \"column_8c235f5b33086\"}, \"series\": {\"column\": \"deviceId\", \"id\": \"column_8c235f5b33087\"}, \"y\": [{\"column\": \"daily_actual_power\", \"transform\": \"SUM\", \"id\": \"column_8c235f5b33088\"}]}, \"isAggregationOn\": true, \"condensed\": true, \"withRowNumber\": true}"
  name       = "Power produced per day"
}
resource "databricks_sql_widget" "r094c6b3fe8c" {
  visualization_id = databricks_sql_visualization.nrt_rpm_turbines_d43ca92d_2a51_4019_972a_1104855f02a40118d43f_13d8_4df3_a773_e107774ef0c8.visualization_id
  title            = "[NRT] - RPM Turbines"
  position {
    size_y = 8
    size_x = 3
    pos_y  = 24
  }
  dashboard_id = databricks_sql_dashboard.demo_dashboard_8b02222a_e374_4658_b766_8d7f379586ea.id
}
resource "databricks_sql_widget" "r0c20409fa29" {
  visualization_id = databricks_sql_visualization.power_produced_per_day_2aceefeb_23ab_4e72_acd5_4c494039df6ed0fc87f3_950d_478a_b36f_414b83bea229.visualization_id
  title            = "Power produced per day"
  position {
    size_y = 10
    size_x = 6
    pos_y  = 32
  }
  dashboard_id = databricks_sql_dashboard.demo_dashboard_8b02222a_e374_4658_b766_8d7f379586ea.id
}
resource "databricks_sql_widget" "r105d406471b" {
  visualization_id = databricks_sql_visualization.agg_power_generated_kwh_0452cdab_e378_4a2a_a1e2_86fa8b6f9c734700f148_22c8_49cf_a16d_c4e5cace696a.visualization_id
  title            = "[Agg] - Power Generated (KWh)"
  position {
    size_y = 11
    size_x = 6
    pos_y  = 5
  }
  dashboard_id = databricks_sql_dashboard.demo_dashboard_8b02222a_e374_4658_b766_8d7f379586ea.id
}
resource "databricks_sql_widget" "r1a66606b344" {
  visualization_id = databricks_sql_visualization.summary_power_lost_due_to_maintenance_58236411_2f20_4cc5_ad8d_e415fb02466ea304d7f8_c661_48b0_a8b1_e7c88d5f0e7b.visualization_id
  title            = "Power lost due to maintenance (All time)"
  position {
    size_y = 5
    size_x = 2
    pos_x  = 4
  }
  dashboard_id = databricks_sql_dashboard.demo_dashboard_8b02222a_e374_4658_b766_8d7f379586ea.id
}
resource "databricks_sql_widget" "r4d3cff3be52" {
  visualization_id = databricks_sql_visualization.nrt_temperature_humidity_8777f989_6390_4ec7_bd79_6ab21d18ad07eed263ed_ad42_4256_976c_05848514af0b.visualization_id
  title            = "[NRT] - Temperature & Humidity"
  position {
    size_y = 8
    size_x = 3
    pos_y  = 16
  }
  dashboard_id = databricks_sql_dashboard.demo_dashboard_8b02222a_e374_4658_b766_8d7f379586ea.id
}
resource "databricks_sql_widget" "r5c7bfbc8665" {
  visualization_id = databricks_sql_visualization.turbines_under_maintenance_per_day_35d30e19_a826_430e_982e_23bb07c8c85523a1c77d_93e2_4ad2_8871_c29641dbafba.visualization_id
  title            = "Turbines under maintenance per day"
  position {
    size_y = 8
    size_x = 3
    pos_y  = 42
  }
  dashboard_id = databricks_sql_dashboard.demo_dashboard_8b02222a_e374_4658_b766_8d7f379586ea.id
}
resource "databricks_sql_widget" "r9c106de2c13" {
  visualization_id = databricks_sql_visualization.nrt_turbine_angle_d43ca92d_2a51_4019_972a_1104855f02a42423d6eb_4730_4fe2_b38d_b9fbe5ef4fac.visualization_id
  title            = "[NRT] - Turbine Angle"
  position {
    size_y = 8
    size_x = 3
    pos_y  = 24
    pos_x  = 3
  }
  dashboard_id = databricks_sql_dashboard.demo_dashboard_8b02222a_e374_4658_b766_8d7f379586ea.id
}
resource "databricks_sql_widget" "rb3aa4145e34" {
  visualization_id = databricks_sql_visualization.nrt_wind_speed_direction_8777f989_6390_4ec7_bd79_6ab21d18ad07a6c92c56_5979_4851_9e9e_e0750028dd6e.visualization_id
  title            = "[NRT] - Wind Speed & Direction"
  position {
    size_y = 8
    size_x = 3
    pos_y  = 16
    pos_x  = 3
  }
  dashboard_id = databricks_sql_dashboard.demo_dashboard_8b02222a_e374_4658_b766_8d7f379586ea.id
}
resource "databricks_sql_widget" "rd972e029932" {
  visualization_id = databricks_sql_visualization.power_loss_per_day_due_to_maintenance_2aceefeb_23ab_4e72_acd5_4c494039df6ef37034bc_1b31_4383_8f68_b32483f2221e.visualization_id
  title            = "Daily power loss due to maintenance (KWh)"
  position {
    size_y = 8
    size_x = 3
    pos_y  = 42
    pos_x  = 3
  }
  dashboard_id = databricks_sql_dashboard.demo_dashboard_8b02222a_e374_4658_b766_8d7f379586ea.id
}
resource "databricks_sql_widget" "rf4c4dbceed1" {
  visualization_id = databricks_sql_visualization.power_generated_today_943ce445_af87_4797_9691_afde95c08e97b1c1c7a9_d26e_4f65_b69c_a8e3eb90dece.visualization_id
  title            = "Power Generated Today"
  position {
    size_y = 5
    size_x = 2
  }
  dashboard_id = databricks_sql_dashboard.demo_dashboard_8b02222a_e374_4658_b766_8d7f379586ea.id
}
resource "databricks_sql_widget" "rf7da5910821" {
  visualization_id = databricks_sql_visualization.turbines_under_maintenance_today_943ce445_af87_4797_9691_afde95c08e97b9ac167c_9100_4594_8135_fb1e1b6ad2fc.visualization_id
  title            = "Turbines under maintenance today"
  position {
    size_y = 5
    size_x = 2
    pos_x  = 2
  }
  dashboard_id = databricks_sql_dashboard.demo_dashboard_8b02222a_e374_4658_b766_8d7f379586ea.id
}
resource "databricks_sql_visualization" "summary_power_lost_due_to_maintenance_58236411_2f20_4cc5_ad8d_e415fb02466ea304d7f8_c661_48b0_a8b1_e7c88d5f0e7b" {
  type     = "counter"
  query_id = databricks_sql_query.summary_power_production_and_loss_58236411_2f20_4cc5_ad8d_e415fb02466e.id
  options  = "{\"counterLabel\": \"KWh lost due to maintenance\", \"counterColName\": \"daily_defict\", \"rowNumber\": 1, \"targetRowNumber\": 1, \"stringDecimal\": 0, \"stringDecChar\": \".\", \"stringThouSep\": \",\", \"tooltipFormat\": \"0,0.000\"}"
  name     = "Summary power lost due to maintenance"
}
resource "databricks_sql_visualization" "turbines_under_maintenance_per_day_35d30e19_a826_430e_982e_23bb07c8c85523a1c77d_93e2_4ad2_8871_c29641dbafba" {
  type       = "chart"
  query_plan = "{\"selects\": [{\"column\": \"date\"}, {\"function\": \"COUNT_DISTINCT\", \"args\": [{\"column\": \"maintenance_turbine\"}], \"alias\": \"column_c29e138b36731\"}], \"groups\": [{\"column\": \"date\"}]}"
  query_id   = databricks_sql_query.maintenance_status_35d30e19_a826_430e_982e_23bb07c8c855.id
  options    = "{\"version\": 2, \"globalSeriesType\": \"column\", \"sortX\": true, \"sortY\": true, \"legend\": {\"traceorder\": \"normal\"}, \"xAxis\": {\"type\": \"-\", \"labels\": {\"enabled\": true}}, \"yAxis\": [{\"type\": \"linear\", \"rangeMin\": 0, \"rangeMax\": 10}, {\"type\": \"-\", \"opposite\": true}], \"alignYAxesAtZero\": false, \"error_y\": {\"type\": \"data\", \"visible\": true}, \"series\": {\"stacking\": null, \"error_y\": {\"type\": \"data\", \"visible\": true}}, \"seriesOptions\": {\"column_c29e138b36731\": {\"name\": \"*\", \"yAxis\": 0, \"type\": \"column\"}}, \"valuesOptions\": {}, \"direction\": {\"type\": \"counterclockwise\"}, \"sizemode\": \"diameter\", \"coefficient\": 1, \"numberFormat\": \"0,0\", \"percentFormat\": \"0[.]00%\", \"textFormat\": \"\", \"missingValuesAsZero\": true, \"useAggregationsUi\": true, \"swappedAxes\": false, \"dateTimeFormat\": \"YYYY-MM-DD HH:mm\", \"showDataLabels\": false, \"columnConfigurationMap\": {\"x\": {\"column\": \"date\", \"id\": \"column_c29e138b36729\"}, \"y\": [{\"column\": \"maintenance_turbine\", \"transform\": \"COUNT_DISTINCT\", \"id\": \"column_c29e138b36731\"}]}, \"isAggregationOn\": true, \"hideYAxes\": false}"
  name       = "Turbines under maintenance per day"
}
resource "databricks_sql_visualization" "turbines_under_maintenance_today_943ce445_af87_4797_9691_afde95c08e97b9ac167c_9100_4594_8135_fb1e1b6ad2fc" {
  type     = "counter"
  query_id = databricks_sql_query.daily_summary_943ce445_af87_4797_9691_afde95c08e97.id
  options  = "{\"counterLabel\": \"Turbines under maintenance\", \"counterColName\": \"broken_turbines\", \"rowNumber\": 1, \"targetRowNumber\": 1, \"stringDecimal\": 0, \"stringDecChar\": \".\", \"stringThouSep\": \",\", \"tooltipFormat\": \"0,0.000\"}"
  name     = "Turbines under maintenance today"
}
