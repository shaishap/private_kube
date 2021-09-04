provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "RG" {
  name     = format("%s-%s",upper(var.az_projname),"RG")  
  location = "West Europe"
}

resource "azurerm_kubernetes_cluster" "kubecluster" {
  name                = format("%s-%s",var.az_projname, "kc") 
  resource_group_name = azurerm_resource_group.RG.name
  location            = azurerm_resource_group.RG.location
  dns_prefix          = format("%s-%s",var.az_projname, "kc") 
  private_cluster_enabled = true

  identity {
    type = "SystemAssigned"
  }

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_D2_v2"
  }

  tags = {
    Environment = azurerm_resource_group.RG.name
  }

}


resource "azurerm_virtual_network" "vnet" {
  name                = format("%s-%s",var.az_projname, "vn") 
  address_space       = ["10.1.0.0/16"]
  location            = azurerm_resource_group.RG.location
  resource_group_name = azurerm_resource_group.RG.name
}

resource "azurerm_subnet" "service_subnet" {
  name                = format("%s-%s",var.az_projname, "servicenet")
  resource_group_name  = azurerm_resource_group.RG.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.1.1.0/24"]
  #enforce_private_link_service_network_policies = true
}

resource "azurerm_subnet" "endpoint_subnet" {
  name                = format("%s-%s",var.az_projname, "endpointnet")
  resource_group_name  = azurerm_resource_group.RG.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.1.2.0/24"]

  enforce_private_link_endpoint_network_policies = true
}

resource "azurerm_container_registry" "cont_rgy" {
  name                = format("%s%s",var.az_projname, "cregistry")
  resource_group_name = azurerm_resource_group.RG.name
  location            = azurerm_resource_group.RG.location
  admin_enabled       = false
  public_network_access_enabled = false 
  sku = "Premium"  

}


resource "azurerm_private_dns_zone" "private_dz" {
  name                = "privatelink.azurecr.io"
  resource_group_name = azurerm_resource_group.RG.name
}
resource "azurerm_private_dns_a_record" "dns_a1" {
  name                = lower(azurerm_container_registry.cont_rgy.name)
  zone_name           = azurerm_private_dns_zone.private_dz.name
  resource_group_name = azurerm_resource_group.RG.name
  ttl                 = 10
  records             = ["10.1.2.5"]
}

resource "azurerm_private_endpoint" "private_endpoint" {
  name                = format("%s-%s", var.az_projname, "endpoint")
  resource_group_name = azurerm_resource_group.RG.name
  location            = azurerm_resource_group.RG.location
  subnet_id           = azurerm_subnet.endpoint_subnet.id

  private_dns_zone_group {
    name = azurerm_private_dns_zone.private_dz.name
    private_dns_zone_ids = [azurerm_private_dns_zone.private_dz.id]
  }

  private_service_connection {
    name                = format("%s-%s", var.az_projname, "psc") 
    private_connection_resource_id = azurerm_container_registry.cont_rgy.id
    is_manual_connection           = false
    subresource_names   = ["registry"]
  }
}
