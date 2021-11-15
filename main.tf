terraform {
  # yz4898 use remote tfstate
  backend "azurerm" {
  }

  required_providers {
    azurerm = {
      version = ">= 2.20"
    }
  }
}

provider "azurerm" {
  features {
    virtual_machine {
      graceful_shutdown                   = true      # Necessary for license revocation when using BIG-IQ LM. 
      delete_os_disk_on_deletion          = true
    }
    template_deployment {
      delete_nested_items_during_deletion = true      # defaults to true, but meh...
    }
  }
}


# Resource-Group
module "rg" {
  source                      = "./modules/resource_group"
  rg                          = local.rg
  rg_deployed                 = var.rg_deployed
}
 
# Create BIG-IP virtual-network and subnets
module "bigip_network" {
  source                      = "./modules/network"
  rg                          = module.rg.out
  vnet                        = local.vnet
  f5_common                   = local.f5_common
  vnet_deployed               = var.vnet_deployed
  subnets_deployed            = var.subnets_deployed
  subnets                     = local.subnets
}

# Management Network-Security Group
module "mgmt_nsg" {
  source                      = "./modules/nsg"
  rg                          = module.rg.out
  nsg                         = local.nsg.mgmt
}

# Data Network-Security Group
module "data_nsg" {
  source                      = "./modules/nsg"
  rg                          = module.rg.out
  nsg                         = local.nsg.data
}

# Storage and secure-container
module "storage" {
  source                      = "./modules/storage"
  rg                          = module.rg.out
  storage                     = var.storage
  ip_rules                    = local.nsg.mgmt.src_addrs
  subnet_ids                  = [
                                  module.bigip_network.data_subnet.id,
                                  module.bigip_network.mgmt_subnet.id,
                                  # yz4898
                                  "/subscriptions/3af8783d-70df-45ae-ab6f-1c56945e6fe1/resourceGroups/25899-westus2-nprd-devops-rg/providers/Microsoft.Network/virtualNetworks/westus2-devops-vnet/subnets/westus2-devops-vnet-agentpool-snet"
                                ]
}

# User-Assigned Identity for secure-container access
module "uai" {
  source                      = "./modules/user_assigned_identity"
  rg                          = module.rg.out
  uai_name                    = local.f5_common.uai_name
  storage                     = module.storage.out
}

# Create Log Analytics Workspace
module "analytics" {
  source                      = "./modules/log_analytics"
  rg                          = module.rg.out
  law                         = local.log_analytics
  vnet                        = module.bigip_network.vnet
  subnet                      = module.bigip_network.mgmt_subnet
}

# Load-Balancer
# Mainly serves as a service connection for the Private-Link Service to 
# BIG-IP 
module "lb" {
  source                      = "./modules/load-balancer"
  rg                          = module.rg.out
  subnet                      = module.bigip_network.data_subnet
  lb                          = local.lb
}

# Create VMSS pool with BIG-IP members
module "vmss" {
  source                      = "./modules/vmss"
  vmss                        = var.vmss
  rg                          = module.rg.out
  mgmt_subnet                 = module.bigip_network.mgmt_subnet
  data_subnet                 = module.bigip_network.data_subnet 
  mgmt_nsg                    = module.mgmt_nsg.out
  data_nsg                    = module.data_nsg.out
  lb_pool                     = module.lb.pool
  f5_common                   = local.f5_common
  metadata                    = local.metadata
  bigiq_host                  = local.bigiq.host
  bigiq                       = local.bigiq
  analytics                   = local.log_analytics
  law                         = module.analytics.out
  uai                         = module.uai.out
#  servers                     = module.servers.hosts.priv_addr.*
  storage                     = module.storage.out
# yz4898
#  depends_on                  = [module.lb]
}

/*
# Clients
module "clients" {
  source                      = "./modules/clients"
  rg                          = module.rg.out
  nsg                         = module.mgmt_nsg.out
  client                      = var.clients
  f5_common                   = local.f5_common
  uai                         = module.uai.out
}

# Servers
module "servers" {
  source                      = "./modules/servers"
  rg                          = module.rg.out
  nsg                         = module.mgmt_nsg.out
  server                      = var.servers
  f5_common                   = local.f5_common
  uai                         = module.uai.out
}

# VNET peering
module "peering" {
  source                      = "./modules/vnet_peering"
  rg                          = module.rg.out
  transit_vnet                = module.bigip_network.vnet
  client_vnet                 = module.clients.net
  server_vnet                 = module.servers.net
}
*/
