# Disabled as using F5 provisioned subnets

#resource "azurerm_subnet" "subnet" {
#  name                                     = "${var.proxy_vm_name}-subnet"
#  resource_group_name                      = "${var.rg_name}"
#  virtual_network_name                     = "${var.vnet_name}"
  #address_prefix                           = "${element(azurerm_subnet.subnet.*.id, index(azurerm_subnet.subnet.*.name, var.proxy_subnet_vip))}"
#  address_prefix                           = "${var.address_prefix}"
#}

resource "azurerm_public_ip" "proxy_pip" {
   name                                     = "${var.proxy_vm_name}-pip"
   location                                 = "${var.rg_location}"
   resource_group_name                      = "${var.rg_name}"
   public_ip_address_allocation             = "Static"
   count                                    = 1
 }

resource "azurerm_network_interface" "proxy_nic" {
  name                                      = "${var.proxy_vm_name}-nic"
  location                                  = "${var.rg_location}"
  resource_group_name                       = "${var.rg_name}"

  ip_configuration {
    name                                    = "${var.proxy_vm_name}-ip"
    subnet_id                               = "${var.proxy_subnet_vip}"
    private_ip_address_allocation           = "Dynamic"
    public_ip_address_id                    = "${element(azurerm_public_ip.proxy_pip.*.id, count.index)}"
  }
}
