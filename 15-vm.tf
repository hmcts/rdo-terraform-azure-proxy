
resource "azurerm_virtual_machine" "proxy_vm" {
  name                                    = "proxy-${var.environment}"
  location                                = "${var.rg_location}"
  resource_group_name                     = "${var.rg_name}"
  network_interface_ids                   = ["${azurerm_network_interface.proxy-nic.id}"]
  vm_size                                 = "Standard_B2s"
  delete_os_disk_on_termination = true
  storage_image_reference {
    publisher                             = "Canonical"
    offer                                 = "UbuntuServer"
    sku                                   = "18.04-LTS"
    version                               = "latest"
  }

  storage_os_disk {
    name                                  = "proxy-${var.environment}-os"
    caching                               = "ReadWrite"
    create_option                         = "FromImage"
    managed_disk_type                     = "Standard_LRS"
  }

  os_profile {
    computer_name                         = "proxy-${var.environment}"
    admin_username                        = "${var.proxy_admin_username}"
    admin_password                        = "${var.proxy_admin_password}"
  }

  os_profile_linux_config {
      disable_password_authentication       = false
      ssh_keys {
      path     = "/home/${var.proxy_admin_username}/.ssh/authorized_keys"
      key_data = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDLv/CBfl16lq6ehzT0zmFRJqB370q4FiV5e4Q7mOsH6qV6RN01Lhvsme7LhEwz/FzJBQKxYrs2NNh2uMe8apwrgBGOubVjP5FLrkKq3vyeF8FzuNIngqxWu8WiTSJF/vGfV+VDFEDo/HJL60BhH1hsAP3YToFOo2gnA/ndKulBYuqqWYX/BqvFrIwfGb32AcrarvuS+3JRMobehuhdYx6TNFo3Nv961VtU5XajVDxLIJZAT35fKcGRHNNMCuOsabshycY06u8wsFZSON6nLiRUfWwQGeMYm8G5c4N5HvyWE2Rf6AQWJiwojTcP5M12umbD7gmZ7k+r7+EOoVLFEPIZ"
    }
  }

  provisioner "remote-exec" {
      inline = [
        "mkdir ~/ansible"
      ]
        connection {
      type                                = "ssh"
      user                                = "${var.proxy_admin_username}"
      password                            = "${var.proxy_admin_password}"
      host                                = "${azurerm_public_ip.proxy-pip.ip_address}"
      }
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
      host                                = "${azurerm_public_ip.proxy-pip.ip_address}"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "hostname > ~/ansible/hosts",
      "cd ~/ansible",
      "sudo ansible-playbook ~/ansible/proxy.yml -i ~/ansible/hosts -e arm_tenant_id=${var.arm_tenant_id} -e arm_client_id=${var.arm_client_id} -e arm_client_secret=${var.arm_client_secret} -e palo_subnet=${var.palo_subnet} -e azcontainer_password=${var.azcontainer_password}",
    ]

    connection {
      type                                = "ssh"
      user                                = "${var.proxy_admin_username}"
      password                            = "${var.proxy_admin_password}"
      host                                = "${azurerm_public_ip.proxy-pip.ip_address}"
    }
  }
}

