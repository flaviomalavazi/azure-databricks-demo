/*
NÃO MODIFIQUE O BLOCO DE COMENTÁRIOS.

Vamos utilizar este bloco para declarar valores sensíveis em nossa demo (ele está incluso no .gitignore do repositório, então não será replicado para o ambiente remoto)

Mais informações sobre variáveis no terraform podem ser encontradas aqui: https://www.terraform.io/language/values/variables

Mais informações sobre os `locals` podem ser encontradas aqui: https://www.terraform.io/language/values/locals

Altere o my_ip_range para refletir seu IP de acesso para o SQL Server fora da rede da Azure - no arquivo sql_server.tf você encontrará as definições de regra de firewall para fazer o bloqueio destes IPs do range como abaixo, caso seja necessário apenas um range de liberaçao, basta eliminar a segunda regra (`mssql_firewall_rule_allow_my_ip_2`)

// Fechando o SQL Server para IPs no seu range
resource "azurerm_mssql_firewall_rule" "mssql_firewall_rule_allow_my_ip" {
  name             = "AllowMyIpRange"
  server_id        = azurerm_mssql_server.demo_sql_server.id
  start_ip_address = var.my_ip_range[0]
  end_ip_address   = var.my_ip_range[1]
}

resource "azurerm_mssql_firewall_rule" "mssql_firewall_rule_allow_my_ip_2" {
  name             = "AllowMyIpRange"
  server_id        = azurerm_mssql_server.demo_sql_server.id
  start_ip_address = var.my_ip_range[2]
  end_ip_address   = var.my_ip_range[3]
}

**/

variable "my_ip_range" {
  type        = list(any)
  default     = ["192.168.0.1", "192.168.0.2", "192.168.0.3", "192.168.0.4"]
  description = "My IP Range - A list composed of 4 IPs that, when paired (0-1, 2-3) produce the range in which the SQL Server Database will be accessible outside the Azure Infrastructure if you want to access it from yourj local machine"
}

variable "my_username" {
  type        = string
  default     = "your.email@example.com"
  description = "Username for the demo owner and for the Databricks workspace admin"
}
