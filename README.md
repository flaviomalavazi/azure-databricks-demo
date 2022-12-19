# Azure Databricks End to End Demo


## How to run this demo on your own:
---

1. Install Azure-cli - [How to install azure-cli](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
2. Run `az config set extension.use_dynamic_install=yes_without_prompt` to allow installing extensions without prompt.
3. Install terraform cli - [How to install terraform-cli](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
4. Run `az login` to authenticate (make sure you are on the right tenant)
5. Go to the `tf-environment` folder (on unix based systems, the command is: `cd tf-environment`)
6. Create a file called `creds.tf` (the name is important because it's already included on the `.gitignore` file so that it won't be transmited to the remote git provider)
   1. Within the `creds.tf` file, paste the following code:
        ```
        /*
        NÃO MODIFIQUE O BLOCO DE COMENTÁRIOS.

        Vamos utilizar este bloco para declarar valores sensíveis em nossa demo (ele está incluso no .gitignore do repositório, então não será replicado para o ambiente remoto)

        Mais informações sobre variáveis no terraform podem ser encontradas aqui: https://www.terraform.io/language/values/variables

        Mais informações sobre os `locals` podem ser encontradas aqui: https://www.terraform.io/language/values/locals

        Altere o my_ip_range para refletir seu IP de acesso para o SQL Server fora da rede da Azure - no arquivo sql_server.tf você encontrará as definições de regra de firewall para fazer o bloqueio destes IPs do range nos recursos `azurerm_mssql_firewall_rule`, caso seja necessário apenas um range de liberaçao, basta eliminar a segunda regra (`mssql_firewall_rule_allow_my_ip_2`)
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
        ```
        2. Replace the variables above with your own
7. Run a `terraform init` to initialize terraform and install the required providers
8. Run a `terraform plan` on the folder tf-environment, make sure it works properly (i.e.: no authentication errors)
9.  Run a `terraform apply`, the first apply will probably not work for the IOT device as it will have to install the library, but it should work perfectly on the second one
10. After the second `terraform apply`, the demo should be ready to roll
11. Go to [Azure's IoT simulator](https://azure-samples.github.io/raspberry-pi-web-simulator/) and add the code in `scripts/iot_simulator_code/iot_simulator.js`
12. Get the IoT Connection string of your device and replace it on the code that you just pasted on the simulator on the previous step
13. Access your DataFactory to get the data out of the SQL Server by running the pipeline called `historical_pipeline` once
14. After going through the previous step, you are now able to run the DLT demo or the separate notebooks for a classic demo. 
15. When you're done playing, DON'T FORGET to destroy your resources by running a `terraform destroy`
