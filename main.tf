terraform{
required_providers {
azurerm = {
    source  = "hashicorp/azurerm"
    version = "3.27.0"
  }
}
}
provider "azurerm" {
  features {}
}

data "azurerm_application_gateway" "rearcapplicationgateway" {
  name                = "gw-${var.env}-${var.application}"
  resource_group_name = "rg-${var.env}-${var.application}"

  depends_on = [
    azurerm_application_gateway.rearcapplicationgateway
  ]

}

data "azurerm_resource_group" "rearcresourcegroup" {
  name = "rg-${var.env}-${var.application}"
}

resource "azurerm_virtual_network" "rearcvirtualnetwork" {
  name                = "vnet-${var.env}-${var.application}"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.rearcresourcegroup.name
  address_space       = [var.cidr]
}

resource "azurerm_subnet" "rearcSubnet" {
  name                 = var.name
  resource_group_name  = data.azurerm_resource_group.rearcresourcegroup.name
  virtual_network_name = azurerm_virtual_network.rearcvirtualnetwork.name
  address_prefixes     = ["10.240.0.0/20"]
}

resource "azurerm_subnet" "rearcgatewaySubnet" {
  name                 = "gateway-${var.name}"
  resource_group_name  = data.azurerm_resource_group.rearcresourcegroup.name
  virtual_network_name = azurerm_virtual_network.rearcvirtualnetwork.name
  address_prefixes     = ["10.240.16.0/24"]
}

resource "azurerm_kubernetes_cluster" "rearcAKS" {
  name       = "aks-${var.env}-${var.application}"
  location   = var.location
  dns_prefix = "${var.env}-${var.application}"

  resource_group_name = data.azurerm_resource_group.rearcresourcegroup.name

  http_application_routing_enabled = var.boolean_http_routing

#  linux_profile {
#    admin_username = var.vm_user_name
#
#    ssh_key {
#      key_data = file(var.public_ssh_key_path)
#    }
#  }

  default_node_pool {
    name            = "rearcportl"
    node_count      = var.aks_agent_count
    vm_size         = var.aks_agent_vm_size
    os_disk_size_gb = var.aks_agent_os_disk_size
    vnet_subnet_id  = azurerm_subnet.rearcSubnet.id
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin     = "azure"
    dns_service_ip     = var.aks_dns_service_ip
    docker_bridge_cidr = var.aks_docker_bridge_cidr
    service_cidr       = var.aks_service_cidr
  }
  ingress_application_gateway {
    gateway_id         = data.azurerm_application_gateway.rearcapplicationgateway.id
        }

  role_based_access_control_enabled = false
}

resource "azurerm_container_registry" "rearcacr" {
  name                = "acr${var.env}${var.application}"
  resource_group_name = data.azurerm_resource_group.rearcresourcegroup.name
  location            = var.location
  sku                 = "Premium"
  admin_enabled       = true
}

resource "azurerm_network_security_group" "rearcsecgroup" {
  name                = var.name
  location            = var.location
  resource_group_name = data.azurerm_resource_group.rearcresourcegroup.name
}

resource "azurerm_public_ip" "rearcspublicip" {
  name                = var.name
  location            = var.location
  resource_group_name = data.azurerm_resource_group.rearcresourcegroup.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "rearcnetworkinterface" {
  name                = var.name
  location            = var.location
  resource_group_name = data.azurerm_resource_group.rearcresourcegroup.name

  ip_configuration {
    name                          = "ipc-${var.env}-${var.application}"
    subnet_id                     = azurerm_subnet.rearcSubnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_application_gateway" "rearcapplicationgateway" {
  name                = "gw-${var.env}-${var.application}"
  resource_group_name = data.azurerm_resource_group.rearcresourcegroup.name
  location            = var.location

  sku {
    name     = var.app_gateway_sku
    tier     = var.app_gateway_sku_tier
  }

  gateway_ip_configuration {
    name      = "gw-${var.env}-${var.application}"
    subnet_id = azurerm_subnet.rearcgatewaySubnet.id
  }

  autoscale_configuration {
    max_capacity = 2
    min_capacity = 1
  }
  frontend_port {
    name = "feip-${var.env}-${var.application}"
    port = 80
  }

  frontend_port {
    name = "httpsPort"
    port = 443
  }

  frontend_ip_configuration {
    name                 = "feip-${var.env}-${var.application}"
    public_ip_address_id = azurerm_public_ip.rearcspublicip.id
  }

  backend_address_pool {
    name = "beap-${var.env}-${var.application}"
  }

  backend_http_settings {
    name                  = "behs-${var.env}-${var.application}"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 20
  }

  http_listener {
    name                           = "hl-${var.env}-${var.application}"
    frontend_ip_configuration_name = "feip-${var.env}-${var.application}"
    frontend_port_name             = "feip-${var.env}-${var.application}"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "rrr-${var.env}-${var.application}"
    rule_type                  = "Basic"
    priority                   = 25
    http_listener_name         = "hl-${var.env}-${var.application}"
    backend_address_pool_name  = "beap-${var.env}-${var.application}"
    backend_http_settings_name = "behs-${var.env}-${var.application}"
  }
}