
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
    destination                           = "~/rdo-docker-proxy/"

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
      "sudo hostname > /etc/ansible/hosts",
      "curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash",
      "sudo az login --service-principal -u $ARM_CLIENT_ID -p $ARM_CLIENT_SECRET --tenant $ARM_TENANT_ID",
      "az vm assign -g dmz -n proxy-sbox --identities '/subscriptions/bf308a5c-0624-4334-8ff8-8dca9fd43783/resourcegroups/dmz/providers/Microsoft.ManagedIdentity/userAssignedIdentities/isher-has-mi'",
      "sudo export token=`curl -s 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fvault.azure.net' -H Metadata:true | cut -d, -f1 | cut -d: -f2 | sed 's/"//g'`",
      "sudo export gh_user=`curl -s https://infra-ops-kv.vault.azure.net/secrets/github-devops-access-credentials?api-version=2016-10-01 -H \"Authorization: Bearer $token\" | cut -d, -f1 | cut -d: -f2 | sed 's/\"//g' | cut -d/ -f1`",
      "sudo export gh_token=`curl -s https://infra-ops-kv.vault.azure.net/secrets/github-devops-personal-access-token?api-version=2016-10-01 -H \"Authorization: Bearer $token\" | cut -d, -f1 | cut -d: -f2 | sed 's/\"//g'`",
      "sudo git clone https://${gh_username}:${gh_token}@github.com/hmcts/rdo-ansible-squid.git",
      "cd rdo-ansible-squid",
      "sudo ansible-playbook ~/rdo-ansible-squid/squid.yml",
      "sudo ansible-playbook ~/rdo-docker-proxy/proxy.yml"
    ]

    connection {
      type                                = "ssh"
      user                                = "${var.proxy_admin_username}"
      password                            = "${var.proxy_admin_password}"
      host                                = "${azurerm_public_ip.proxy_pip.ip_address}"
    }
  }
}