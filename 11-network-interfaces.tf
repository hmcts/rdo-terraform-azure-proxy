resource "azurerm_public_ip" "proxy_pip" {
   name                                     = "${var.proxy_vm_name}-pip"
   location                                 = "${var.rg_location}"
   resource_group_name                      = "${var.rg_name}"
   allocation_method                        = "Static"
 }

resource "azurerm_network_interface" "proxy_nic" {
  name                                      = "${var.proxy_vm_name}-nic"
  location                                  = "${var.rg_location}"
  resource_group_name                       = "${var.rg_name}"

  ip_configuration {
    name                                    = "${var.proxy_vm_name}-ip"
    subnet_id                               = "${var.proxy_subnet_vip}"
    private_ip_address_allocation           = "Dynamic"
    public_ip_address_id                    = "${azurerm_public_ip.proxy_pip.id}"
  }
}
