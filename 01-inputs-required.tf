
variable "arm_tenant_id" {}
variable "arm_client_id" {}
variable "arm_client_secret" {}

variable "subscription_id" {
  description = "Subscription ID to make the changes in"
}

variable "rg_name" {
  description = "Name of the rg to put the network in"
}

variable "rg_location" {
    description = "Azure Location"
}

variable "proxy_vm_name" {
    description = "Proxy VM Name"
}

variable "proxy_admin_username" {
    description = "Proxy Admin UserName"
}

variable "proxy_admin_password" {
    description = "Proxy Admin Password"
}

variable "proxy_subnet_vip" {
    description = ""  
}

variable "palo_subnet" {
  description = ""
}

variable "azcontainer-password" { }
