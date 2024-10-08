# terraform/variables.tf

variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

variable "resource_group" {
  description = "Name of the Resource Group"
  type        = string
}

variable "tenant_id" {
  description = "Azure Tenant ID"
  type        = string
}

variable "client_id" {
  description = "Azure Client ID"
  type        = string
}

variable "client_secret" {
  description = "Azure Client Secret"
  type        = string
  sensitive   = true
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "East US"
}

variable "vnet_cidr" {
  description = "CIDR block for the Virtual Network"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the Public Subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block for the Private Subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
}

variable "image" {
  description = "Azure VM Image"
  type        = string
  default     = "canonical:0001-com-ubuntu-server-jammy:22_04-lts:latest"
}

variable "vm_size" {
  description = "Azure VM Size"
  type        = string
  default     = "Standard_D2s_v3" # size
}

variable "ansible_username" {
  description = "Username for Ansible Control Machine"
  type        = string
  default     = "azureuser"
}

variable "my_public_ip" {
  description = "Your public IP address with CIDR"
  type        = string
}
