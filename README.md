# private_kube

**Prerequisites and one-time setups**
* All configuration is set against westeurope (hard-coded), as it is the closest DC. 
* Initial storage account was created manually. It did not include infrastructure encryption. For improved security, it’s better to include it, and using either Microsoft managed keys, or a private key from a customer managed key vault. It can be included in the deployment, and managed on a per project level.
**az storage account create --name projname_storage --resource_group projname_core_storage --location westeurope --require-infrastructure-encryption true**
* There are additional approaches to accessing the private K8S cluster other than RunCommandPreview. Like Virtual Network Peering, using a jump-box (bastion), or VPN. There are considerations to the suitable selection. More details in https://docs.microsoft.com/en-us/azure/aks/private-clusters 
* Private link to K8S registry require the Premium SKU. https://docs.microsoft.com/en-us/azure/container-registry/container-registry-skus . 
* The network subnets are class D. (provide 251 addresses)
* I used a Mac machine, install azure cli: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-macos.
   1. brew update && brew install azure-cli
   1. az login (or without web browser az login –use_device_code)
* Install terraform: https://www.terraform.io/downloads.html 
* As a one-time setup, enable the RunCommandPreview option (to access and run commands against a private K8S cluster)
Enable Run command preview feature: (one time per subscription) – takes a few minutes
**az feature register --namespace "Microsoft.ContainerService" --name "RunCommandPreview"**

It takes few minutes for status to show Registered. Can verify status by running:
**az feature list -o table --query "[?contains(name, 'Microsoft.ContainerService/RunCommandPreview')].{Name:name,State:properties.state}"**
 
When ready, refresh the registration of the resource provider:
**az provider register --namespace Microsoft.ContainerService**

To provision:
1. Clone the kube_private repo. and issue:
   1. cd kube_private
   1. terraform init
   1. terraform apply
(will be prompted for a project name. must be alphanumeric)

