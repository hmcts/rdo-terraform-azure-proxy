
resource "azurerm_virtual_machine" "proxy_vm" {
  name                                    = "${var.proxy_vm_name}"
  location                                = "${var.rg_location}"
  resource_group_name                     = "${var.rg_name}"
  network_interface_ids                   = ["${azurerm_network_interface.proxy_nic.id}"]
  vm_size                                 = "Standard_B2s"
  delete_os_disk_on_termination = true
  storage_image_reference {
    publisher                             = "Canonical"
    offer                                 = "UbuntuServer"
    sku                                   = "18.04-LTS"
    version                               = "latest"
  }

  storage_os_disk {
    name                                  = "${var.proxy_vm_name}-os"
    caching                               = "ReadWrite"
    create_option                         = "FromImage"
    managed_disk_type                     = "Standard_LRS"
  }

  os_profile {
    computer_name                         = "${var.proxy_vm_name}"
    admin_username                        = "${var.proxy_admin_username}"
    admin_password                        = "${var.proxy_admin_password}"
  }

provisioner "remote-exec" {
      inline = [
        "mkdir ~/ansible"
      ]
        connection {
      type                                = "ssh"
      user                                = "${var.proxy_admin_username}"
      password                            = "${var.proxy_admin_password}"
      }
}

 os_profile_linux_config {
    disable_password_authentication       = false

  }

}

resource "azurerm_virtual_machine_extension" "ansible_extension" {
  name                                    = "Ansible-Agent-Install"
  location                                = "${var.rg_location}"
  resource_group_name                     = "${var.rg_name}"
  virtual_machine_name                    = "${azurerm_virtual_machine.proxy_vm.name}"
  publisher                               = "Microsoft.Azure.Extensions"
  type                                    = "CustomScript"
  type_handler_version                    = "2.0"

  settings = <<SETTINGS
    {
        "commandToExecute": "sudo apt-get install -y software-properties-common",
        "commandToExecute": "sudo apt-add-repository --yes --update ppa:ansible/ansible",
        "commandToExecute": "sudo apt-get install -y ansible"
    }
SETTINGS
}


resource "null_resource" "ansible-runs" {
    triggers = {
      always_run = "${timestamp()}"
    }

    depends_on = [
        "azurerm_virtual_machine_extension.ansible_extension",
        "azurerm_virtual_machine.proxy_vm"
    ]
  provisioner "file" {
    source                                = "${path.module}/ansible/"
    destination                           = "~/ansible/"

    connection {
      type                                = "ssh"
      user                                = "${var.proxy_admin_username}"
      password                            = "${var.proxy_admin_password}"
      host                                = "${azurerm_public_ip.proxy_pip.ip_address}"
    }
  }

  provisioner "remote-exec" {
    inline = [
      #"ansible-galaxy install -r ~/ansible/requirements.yml",
      "sudo mkdir -p /etc/rdo-docker-proxy/squid",
      "sudo mkdir -p /var/log/rdo-docker-proxy/squid",
      "hostname > ~/ansible/hosts",
      "cd ~/ansible/",
      "curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash",
      "sudo az login --service-principal -u $ARM_CLIENT_ID -p $ARM_CLIENT_SECRET --tenant $ARM_TENANT_ID",
      "sudo ansible-playbook proxy.yml"
    ]

    connection {
      type                                = "ssh"
      user                                = "${var.proxy_admin_username}"
      password                            = "${var.proxy_admin_password}"
      host                                = "${azurerm_public_ip.proxy_pip.ip_address}"
    }
  }
}