# Input variables for LTM deployment within Azure

variable "subscription_id"  { default = "3af8783d-70df-45ae-ab6f-1c56945e6fe1" }
variable "lab_prefix"       { default = "bigip-westus2-dev" }
variable "node_count"       { default = 1 }                 # Number of client and server nodes
variable "bigip_count"      { default = 2 }                 # Number of BIG-IP VEs to deploy
variable "use_vmss"         { default = true }
variable "vnet_cidr"        { default = "10.210.0.0/16" }   # ignore this if using existing vnet


# Whether resource-group and virtual-network have already
# been deployed outside of this terraform package
variable "rg_deployed"      { default = false }             # default is to create new F5 rg
variable "vnet_deployed"    { default = true }              # default is to use existing vnet
variable "subnets_deployed" { default = false }             # default is to create new F5 subnets

# If existing subnets are specified, provide the subnet names here
locals {
  subnets = {
    mgmt                    = format("%s-mgmt", local.vnet.name)
    data                    = format("%s-data", local.vnet.name)
  }
}



# customize the following tags with your own values
locals {
  metadata = {
    project                 = "bigip"
    env                     = "dev"
    attuid                  = "yz4898@att.com"
    created_by              = "yz4898@att.com"
    automated_by            = "ado"
    contact_dl              = "yz4898@att.com"
    mots_id                 = "25899"
    auto_fix                = "no"
  }
}


locals {
  secrets                   = jsondecode(file("${path.root}/secrets.json"))
  rg = {                    # Resource Group
    name                    = format("%s-rg", var.lab_prefix)
    location                = "westus2"
  }
  vnet = {                  # virtual networks
    name                    = "existing-westus2-dev-vnet"
    rg_name                 = "existing-westus2-dev-rg"
    cidr                    = var.vnet_cidr
    # yz4898 
    # customize with your own subnet cidr
    mgmt_subnet_cidr        = ["10.210.0.0/24"]
    data_subnet_cidr        = ["10.210.10.0/24"]
  }
  nsg = {                   # Network security group
    mgmt = {
      name                    = format("%s-mgmt-nsg", var.lab_prefix)
      dst_ports               = ["22","443", "8443"]
      src_addrs               = ["144.160.96.0/24"] # Replace with your source addess(es)
    }
    data = {
      name                    = format("%s-data-nsg", var.lab_prefix)
      dst_ports               = ["80","443"]
      src_addrs               = ["0.0.0.0/0"] # Replace with your source addess(es)
    }
  }
  log_analytics = {         # Log Analytics Workspace
    name                    = format("%s-law", var.lab_prefix)
    retention               = "30"
    sku                     = "PerNode"
    ts_region               = "us-west-2"
    ts_type                 = "Azure_Log_Analytics"
    ts_log_group            = "f5telemetry"
    ts_log_stream           = "default"
    internet_ingestion      = true
    internet_query          = true
    use_ampls               = true                                 # Azure Monitory Private Link Scope (AMPLS)
    ampls_name              = "ampls_monitor"
    ampls_ple_name          = "ampls_ple"
    ampls_dns_name          = "ampls_dns"
    workbook_name           = "VE_usage"
    workbook_type           = "workbook"
  }
  lb = {                    # load-balancer; required for Private-Link Service
    use_lb                  = 1
    name                    = format("%s-lb", var.lab_prefix)
    pool_name               = "lb_pool"
    sku                     = "Standard"
    priv_allocation         = "Dynamic"
    priv_version            = "IPv4"
  }
  # default does not use bigiq
  bigiq = {                 # BIG-IQ License Manager (for BYOL licensing)
    use_bigiq_lm            = false
    use_bigiq_pls           = false
    pls_name                = "bigiq-westus2-dev-pls"
    vnet_name               = "bigiq-westus2-dev-vnet"
    ple_name                = format("%s-bigiq_ple", var.lab_prefix)
    resource_group          = "bigiq-westus2-dev-rg"                    # Resource-Group containing BIG-IQ virtual-network and PLS
    host                    = local.secrets.bigiq_host
    user                    = local.secrets.bigiq_user
    pass                    = local.secrets.bigiq_pass
    lic_type                = "licensePool"
    lic_pool                = "azure_test"
    lic_measure             = "yearly"
    lic_hypervisor          = "azure"
    reachable               = false
  }
  f5_common = {             # Common variables used by many modules
    bigip_user              = local.secrets.bigip_user
    bigip_pass              = local.secrets.bigip_pass
    # yz4898
    public_key              = "azure_f5.pub"           # Public key for SSH authentication

    pls_name                = "perflab_pls"
    cloud_init_log          = "startup_script.log"            # cloud-init custom log file
    cfg_dir                 = "/shared/cloud_init"            # cloud-init custom working directory (mainly for troubleshooting)

    uai_name                = local.secrets.uai_name          # UAI for container access

    AS3_file                = "https://github.com/F5Networks/f5-appsvcs-extension/releases/download/v3.31.0/f5-appsvcs-3.31.0-6.noarch.rpm"
    DO_file                 = "https://github.com/F5Networks/f5-declarative-onboarding/releases/download/v1.24.0/f5-declarative-onboarding-1.24.0-6.noarch.rpm"
    TS_file                 = "https://github.com/F5Networks/f5-telemetry-streaming/releases/download/v1.23.0/f5-telemetry-1.23.0-4.noarch.rpm"

    # bigip.conf file suitable for merging into the running configuration
    ltm_initial_cfg_file    = "bigip_common.conf"
  }
}


# These variables will be populated by the vars_bigips.tfvars, vars_clients.tfvars,
# and vars_servers.tfvars files respectively
variable "vmss"             {}
variable "clients"          {}
variable "servers"          {}
variable "storage"          {}
