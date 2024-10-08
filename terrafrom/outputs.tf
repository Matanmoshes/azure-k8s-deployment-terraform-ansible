# terraform/outputs.tf

output "bastion_public_ip" {
  description = "Public IP address of the Bastion Host"
  value       = azurerm_public_ip.bastion_public_ip.ip_address
}

output "ansible_control_private_ip" {
  description = "Private IP address of the Ansible Control Machine"
  value       = azurerm_linux_virtual_machine.ansible_control_machine.private_ip_address
}

output "control_plane_private_ip" {
  description = "Private IP address of the Control Plane VM"
  value       = azurerm_linux_virtual_machine.control_plane_vm.private_ip_address
}

output "worker_nodes_private_ips" {
  description = "Private IP addresses of the Worker Nodes"
  value       = azurerm_linux_virtual_machine.worker_vm[*].private_ip_address
}
