# All resources required for servers

## VNET
resource "azurerm_virtual_network" "vnet" {
  name                  = var.server.vnet.name
  address_space         = [var.server.vnet.cidr]
  resource_group_name   = var.rg.name
  location              = var.rg.location
}

# create mgmt subnet
resource "azurerm_subnet" "mgmt_subnet" {
  name                  = format("%s-mgmt", var.server.vnet.name)
  address_prefixes      = [cidrsubnet(var.server.vnet.cidr, 8, 0)]
  resource_group_name   = var.rg.name
  virtual_network_name  = azurerm_virtual_network.vnet.name
}

# create data subnet
resource "azurerm_subnet" "data_subnet" {
  name                  = format("%s-data", var.server.vnet.name)
  address_prefixes      = [cidrsubnet(var.server.vnet.cidr, 8, 10)]
  resource_group_name   = var.rg.name
  virtual_network_name  = azurerm_virtual_network.vnet.name
  service_endpoints     = ["Microsoft.Storage"]

  enforce_private_link_endpoint_network_policies = true
}

# Create Public IP
resource "azurerm_public_ip" "node_public_ip" {
  count                           = var.server.node.count
  name                            = format("${var.server.node.prefix}%02d_pub_ip", count.index+1)
  location                        = var.rg.location
  resource_group_name             = var.rg.name
  allocation_method               = "Static"
}

# Create NIC
resource "azurerm_network_interface" "node_nic" {
  count                           = var.server.node.count
  name                            = format("${var.server.node.prefix}%02d_nic", count.index+1)
  location                        = var.rg.location
  resource_group_name             = var.rg.name

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.data_subnet.id
    public_ip_address_id          = azurerm_public_ip.node_public_ip.*.id[count.index]
    private_ip_address_allocation = "Dynamic"
  }
}

# Associate NSG with NIC
resource "azurerm_network_interface_security_group_association" "node_sec" {
  count                           = var.server.node.count
  network_interface_id            = azurerm_network_interface.node_nic.*.id[count.index]
  network_security_group_id       = var.nsg.id
}

# Create VM
resource "azurerm_linux_virtual_machine" "host" {
  count                           = var.server.node.count
  computer_name                   = format("${var.server.node.prefix}%02d.${var.server.node.domain}", count.index+1)
  name                            = format("${var.server.node.prefix}%02d", count.index+1)
  location                        = var.rg.location
  resource_group_name             = var.rg.name
  network_interface_ids           = [azurerm_network_interface.node_nic.*.id[count.index]]
  size                            = var.server.node.image.size
  admin_username                  = var.server.node.user
  disable_password_authentication = true

  custom_data                     = base64gzip(local_file.linux_host_init.content)

  identity {
    type                          = var.uai.id != "" ? "UserAssigned" : "SystemAssigned"
    identity_ids                  = var.uai.id != "" ? [var.uai.id] : [""]
  }

  os_disk {
    name                          = format("${var.server.node.prefix}%02d_disk", count.index+1)
    caching                       = "ReadWrite"
    storage_account_type          = var.server.node.image.disk
  }

  source_image_reference {
    publisher                     = var.server.node.image.publisher
    offer                         = var.server.node.image.offer
    sku                           = var.server.node.image.sku
    version                       = var.server.node.image.version
  }

  admin_ssh_key {
    username                      = var.server.node.user
    public_key                    = file(var.f5_common.public_key)
  }

  # Update local hosts file with system address
  provisioner "local-exec" {
    command   = "${path.root}/scripts/update_hosts.bash ${self.name} ${self.public_ip_address}"
  }
}

resource "local_file" "linux_host_init" {
  content = templatefile("${path.root}/templates/linux_host_init.template", {
    sudoers                       = filebase64("${path.root}/templates/host_sudoers")
    test_script                   = ""
  })
  filename                        = "${path.root}/work_tmp/linux_host_init.bash"
}

