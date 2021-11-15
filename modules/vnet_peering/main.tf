# Reering relationships

# The 'transit' network is where BIG-IP is located

# Server to Transit
resource "azurerm_virtual_network_peering" "server_to_transit" {
  name                        = "server_to_transit"
  resource_group_name         = var.rg.name
  virtual_network_name        = var.server_vnet.name
  remote_virtual_network_id   = var.transit_vnet.id
}

# Transit to Server
resource "azurerm_virtual_network_peering" "transit_to_server" {
  name                        = "transit_to_server"
  resource_group_name         = var.rg.name
  virtual_network_name        = var.transit_vnet.name
  remote_virtual_network_id   = var.server_vnet.id
}

# Client to Transit
resource "azurerm_virtual_network_peering" "client_to_transit" {
  name                        = "client_to_transit"
  resource_group_name         = var.rg.name
  virtual_network_name        = var.client_vnet.name
  remote_virtual_network_id   = var.transit_vnet.id
}

# Transit to Client
resource "azurerm_virtual_network_peering" "transit_to_client" {
  name                        = "transit_to_client"
  resource_group_name         = var.rg.name
  virtual_network_name        = var.transit_vnet.name
  remote_virtual_network_id   = var.client_vnet.id
}

# Client to Server
resource "azurerm_virtual_network_peering" "client_to_server" {
  name                        = "client_to_server"
  resource_group_name         = var.rg.name
  virtual_network_name        = var.client_vnet.name
  remote_virtual_network_id   = var.server_vnet.id
}

# Server to Client
resource "azurerm_virtual_network_peering" "server_to_client" {
  name                        = "server_to_client"
  resource_group_name         = var.rg.name
  virtual_network_name        = var.server_vnet.name
  remote_virtual_network_id   = var.client_vnet.id
}


