# Azure Databricks End to End Demo


## How to run this demo on your own:
---

1. Install Azure-cli
2. Run 'az config set extension.use_dynamic_install=yes_without_prompt' to allow installing extensions without prompt.
3. Install terraform cli
4. Run az login to authenticate (make sure you are on the right tenant)
5. Run a terraform plan on the folder tf-environment, make sure it works properly (no authentication errors)
6. Run a Terraform Apply, the first apply will not work for the IOT device, but it should work perfectly on the second one
7. After the second apply, the demo should be ready to roll

