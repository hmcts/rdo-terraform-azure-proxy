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
variable "proxy_admin_ssh_public_key" {
    description = "Proxy Admin SSH Public Key"
} 
variable "address_prefix" {
    description = ""
}

variable "proxy_subnet_vip" {
    description = ""  
}

variable "vnet_name" {
    description = ""    
}

variable "ARM_TENANT_ID" {
  description                             = ""
}