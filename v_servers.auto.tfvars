# NOT USED.  SAFE TO IGNORE.
servers = {
  bigip_ple_name        = "ple_bigip_servers"
  vnet = {
    name                  = "jessnet-servers"
    cidr                  = "10.212.0.0/16"
  }
  node = {
    count                 = 1
    prefix                = "mvms"
    domain                = "westus2.cloudapp.azure.com"
    user                  = "azadmin"
    public_ip_name        = "server_pub_ip"
    host_workdir          = "/tmp/cloud_init"
    image = {
      publisher           = "Canonical"
      offer               = "UbuntuServer"
      sku                 = "18.04-LTS"
      version             = "latest"
      disk                = "Standard_LRS"
      size                = "Standard_DS4_v2"
    }
  }
}
