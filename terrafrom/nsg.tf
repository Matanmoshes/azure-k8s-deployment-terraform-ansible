
# Bastion NSG
resource "azurerm_network_security_group" "bastion_nsg" {
  name                = "bastion-nsg"
  location            = var.location
  resource_group_name = var.resource_group

  security_rule {
    name                       = "Allow-SSH-Inbound"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.my_public_ip
    destination_address_prefix = "*"
  }
}

# Associate public subnet with the bastion NSG
resource "azurerm_subnet_network_security_group_association" "associate-public" {
  subnet_id                 = azurerm_subnet.public_subnet.id
  network_security_group_id = azurerm_network_security_group.bastion_nsg.id
}

# Kubernetes NSG
resource "azurerm_network_security_group" "k8s_nsg" {
  name                = "kubernetes-nsg"
  location            = var.location
  resource_group_name = var.resource_group

  # Allow SSH from Bastion Subnet
  security_rule {
    name                       = "Allow-SSH-From-Bastion"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.public_subnet_cidr
    destination_address_prefix = var.private_subnet_cidr
  }

  # Allow Kubernetes API Server
  security_rule {
    name                       = "Allow-K8s-API"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "6443"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  # Allow NodePort Services (Optional)
  security_rule {
    name                       = "Allow-K8s-NodePorts"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "30000-32767"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  # Allow Flannel Pod Networking (Optional)
  security_rule {
    name                       = "Allow-Flannel"
    priority                   = 130
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "10.244.0.0/16" # Adjust based on pod network
    destination_address_prefix = "10.244.0.0/16"
  }
}

# Associate private subnet with the k8s NSG
resource "azurerm_subnet_network_security_group_association" "associate-private" {
  subnet_id                 = azurerm_subnet.private_subnet.id
  network_security_group_id = azurerm_network_security_group.k8s_nsg.id
}