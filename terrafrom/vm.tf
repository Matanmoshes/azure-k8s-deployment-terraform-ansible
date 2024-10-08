# terraform/vm.tf

# ---------------------------------------------------------------------------
# Network Interfaces (NICs) without network_security_group_id
# ---------------------------------------------------------------------------

# Bastion Host NIC
resource "azurerm_network_interface" "bastion_nic" {
  name                = "bastion-nic"
  location            = var.location
  resource_group_name = var.resource_group

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.public_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.bastion_public_ip.id
  }
}

# Ansible Control Machine NIC
resource "azurerm_network_interface" "ansible_nic" {
  name                = "ansible-control-nic"
  location            = var.location
  resource_group_name = var.resource_group

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.private_subnet.id
    private_ip_address_allocation = "Dynamic"
    # No public IP
  }
}

# Control Plane VM NIC
resource "azurerm_network_interface" "control_plane_nic" {
  name                = "control-plane-nic"
  location            = var.location
  resource_group_name = var.resource_group

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.private_subnet.id
    private_ip_address_allocation = "Dynamic"
    # No public IP
  }
}

# Worker Nodes NICs
resource "azurerm_network_interface" "worker_nic" {
  count               = 2
  name                = "worker-node-${count.index + 1}-nic"
  location            = var.location
  resource_group_name = var.resource_group

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.private_subnet.id
    private_ip_address_allocation = "Dynamic"
    # No public IP
  }
}

# ---------------------------------------------------------------------------
# Network Interface Security Group Associations
# ---------------------------------------------------------------------------

# Bastion Host NIC and NSG Association
resource "azurerm_network_interface_security_group_association" "bastion_nic_nsg_association" {
  network_interface_id      = azurerm_network_interface.bastion_nic.id
  network_security_group_id = azurerm_network_security_group.bastion_nsg.id
}

# Ansible Control Machine NIC and NSG Association
resource "azurerm_network_interface_security_group_association" "ansible_nic_nsg_association" {
  network_interface_id      = azurerm_network_interface.ansible_nic.id
  network_security_group_id = azurerm_network_security_group.k8s_nsg.id
}

# Control Plane NIC and NSG Association
resource "azurerm_network_interface_security_group_association" "control_plane_nic_nsg_association" {
  network_interface_id      = azurerm_network_interface.control_plane_nic.id
  network_security_group_id = azurerm_network_security_group.k8s_nsg.id
}

# Worker Nodes NICs and NSG Associations
resource "azurerm_network_interface_security_group_association" "worker_nic_nsg_association" {
  count                     = 2
  network_interface_id      = azurerm_network_interface.worker_nic[count.index].id
  network_security_group_id = azurerm_network_security_group.k8s_nsg.id
}

# ---------------------------------------------------------------------------
# Public IP for Bastion Host
# ---------------------------------------------------------------------------

resource "azurerm_public_ip" "bastion_public_ip" {
  name                = "bastion-public-ip"
  location            = var.location
  resource_group_name = var.resource_group
  allocation_method   = "Static"
  sku                 = "Basic"
}

# ---------------------------------------------------------------------------
# Virtual Machines
# ---------------------------------------------------------------------------

# Bastion Host VM
resource "azurerm_linux_virtual_machine" "bastion_vm" {
  name                  = "bastion-vm"
  resource_group_name   = var.resource_group
  location              = var.location
  size                  = var.vm_size
  admin_username        = var.ansible_username
  network_interface_ids = [azurerm_network_interface.bastion_nic.id]
  disable_password_authentication = true

  admin_ssh_key {
    username   = var.ansible_username
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = split(":", var.image)[0]
    offer     = split(":", var.image)[1]
    sku       = split(":", var.image)[2]
    version   = split(":", var.image)[3]
  }

  tags = {
    Role = "Bastion"
  }
}

# Ansible Control Machine VM
resource "azurerm_linux_virtual_machine" "ansible_control_machine" {
  name                  = "ansible-control"
  resource_group_name   = var.resource_group
  location              = var.location
  size                  = var.vm_size
  admin_username        = var.ansible_username
  network_interface_ids = [azurerm_network_interface.ansible_nic.id]
  disable_password_authentication = true

  admin_ssh_key {
    username   = var.ansible_username
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = split(":", var.image)[0]
    offer     = split(":", var.image)[1]
    sku       = split(":", var.image)[2]
    version   = split(":", var.image)[3]
  }
  #custom_data = filebase64("install_ansible.sh")
  tags = {
    Role = "AnsibleControl"
  }
}

# Control Plane VM
resource "azurerm_linux_virtual_machine" "control_plane_vm" {
  name                  = "control-plane-vm"
  resource_group_name   = var.resource_group
  location              = var.location
  size                  = var.vm_size
  admin_username        = var.ansible_username
  network_interface_ids = [azurerm_network_interface.control_plane_nic.id]
  disable_password_authentication = true

  admin_ssh_key {
    username   = var.ansible_username
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = split(":", var.image)[0]
    offer     = split(":", var.image)[1]
    sku       = split(":", var.image)[2]
    version   = split(":", var.image)[3]
  }

  tags = {
    Role = "ControlPlane"
  }
}

# Worker Nodes VMs
resource "azurerm_linux_virtual_machine" "worker_vm" {
  count                = 2
  name                 = "worker-node-${count.index + 1}"
  resource_group_name  = var.resource_group
  location             = var.location
  size                 = var.vm_size
  admin_username       = var.ansible_username
  network_interface_ids = [azurerm_network_interface.worker_nic[count.index].id]
  disable_password_authentication = true

  admin_ssh_key {
    username   = var.ansible_username
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = split(":", var.image)[0]
    offer     = split(":", var.image)[1]
    sku       = split(":", var.image)[2]
    version   = split(":", var.image)[3]
  }

  tags = {
    Role = "WorkerNode"
  }
}
