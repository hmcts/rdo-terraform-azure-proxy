resource "azurerm_public_ip" "proxy-pip" {
   name                                     = "proxy-${var.environment}-pip"
   location                                 = "${var.rg_location}"
   resource_group_name                      = "${var.rg_name}"
   allocation_method                        = "Static"
 }

resource "azurerm_network_interface" "proxy-nic" {
  name                                      = "proxy-${var.environment}-nic"
  location                                  = "${var.rg_location}"
  resource_group_name                       = "${var.rg_name}"

  ip_configuration {
    name                                    = "proxy-${var.environment}-ip"
    subnet_id                               = "${var.proxy_subnet_vip}"
    private_ip_address_allocation           = "Dynamic"
    public_ip_address_id                    = "${azurerm_public_ip.proxy_pip.id}"
  }
}

