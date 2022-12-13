# Azure Databricks End to End Demo


## How to run this demo on your own:
---

1. Install Azure-cli - [How to install azure-cli](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
2. Run `az config set extension.use_dynamic_install=yes_without_prompt` to allow installing extensions without prompt.
3. Install terraform cli - [How to install terraform-cli](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
4. Run `az login` to authenticate (make sure you are on the right tenant)
5. Go to the `tf-environment` folder (on unix based systems, the command is: `cd tf-environment`)
6. Run a `terraform init` to initialize terraform and install the required providers
7. Run a `terraform plan` on the folder tf-environment, make sure it works properly (i.e.: no authentication errors)
8. Run a `terraform apply`, the first apply will probably not work for the IOT device as it will have to install the library, but it should work perfectly on the second one
9. After the second `terraform apply`, the demo should be ready to roll
10. Go to [Azure's IoT simulator](https://azure-samples.github.io/raspberry-pi-web-simulator/) and add the code in `scripts/iot_simulator_code/iot_simulator.js`
11. Get the IoT Connection string of your device and replace it on the code that you just pasted on the simulator on the previous step
12. Access your DataFactory to get the data out of the SQL Server by running the pipeline called `historical_pipeline` once
13. After going through the previous step, you are now able to run the DLT demo or the separate notebooks for a classic demo. 
14. When you're done playing, DON'T FORGET to destroy your resources by running a `terraform destroy`
