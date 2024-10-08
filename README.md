# Kubernetes Cluster Deployment on Azure using Terraform and Ansible

This project automates the deployment of a Kubernetes cluster on Microsoft Azure using Terraform for infrastructure provisioning and Ansible for configuration management. The infrastructure includes a bastion host, an Ansible control machine, a Kubernetes control plane node, and multiple Kubernetes worker nodes.

---

## Project Overview

This project provides an automated way to deploy a Kubernetes cluster on Azure using Infrastructure as Code (IaC) principles. By leveraging Terraform and Ansible, you can quickly spin up a fully functional Kubernetes cluster that is customizable and reproducible.

## Infrastructure Architecture

The infrastructure deployed consists of the following components:

- **Virtual Network (VNet)** with public and private subnets.
- **Network Security Groups (NSGs)** to control inbound and outbound traffic.
- **Virtual Machines (VMs)**:
  - **Bastion Host**: A jump server with a public IP to securely access the private network.
  - **Ansible Control Machine**: Used to run Ansible playbooks for configuring the Kubernetes cluster.
  - **Kubernetes Control Plane Node**: The master node that manages the Kubernetes cluster.
  - **Kubernetes Worker Nodes**: Nodes where containerized applications run.

**Diagram:**

```SCSS
                                    Internet
                                        |
                                        |
                                 [Public IP Address]
                                        |
                                        |
                                   ┌───────────┐
                                   │ Bastion   │
                                   │   Host    │
                                   └───────────┘
                                        |
                         SSH over Public IP (Port 22)
                                        |
                             ───────────────────────
                             |                    |
                      ┌─────────────┐       ┌─────────────┐
                      │  Virtual    │       │  Network    │
                      │  Network    │       │  Security   │
                      │  (VNet)     │       │  Groups     │
                      └─────────────┘       └─────────────┘
                             |                    |
                ┌──────────────────────────┐      |
                |        10.0.0.0/16       |      |
                |                          |      |
        ┌──────────────────┐      ┌──────────────────┐
        |  Public Subnet   |      |  Private Subnet  |
        |   10.0.1.0/24    |      |   10.0.2.0/24    |
        └──────────────────┘      └──────────────────┘
                |                          |
                |                          |
        ┌─────────────┐             ┌───────────────────────┐
        │ Bastion     │             │ Ansible Control VM    │
        │   Host      │             │ Control Plane VM      │
        └─────────────┘             │ Worker Node 1         │
                                    │ Worker Node 2         │
                                    └───────────────────────┘
                |                          | 
                |                          |
         SSH via Private IP           Internal Networking
          (Port 22 allowed)             (Kubernetes Traffic)
                |                          |
                |                          |
        ┌─────────────┐             ┌───────────────────────┐
        │  Storage    │────────────▶│ Managed Disks for VMs │
        │  Accounts   │             └───────────────────────┘
        └─────────────┘

```

## Prerequisites

- **Azure Subscription**: An active Microsoft Azure account.
- **Azure CLI**: Installed on your local machine.
- **Terraform**: Version >= 1.0.0 installed on your local machine.
- **SSH Key Pair**: An SSH key pair generated in Azure for authentication with Azure VMs.


---

## Project Structure

```
azure-k8s-deployment-terraform-ansible/
├── ansible/
│   ├── ansible.cfg
│   ├── install_ansible.sh
│   ├── inventory.ini
│   ├── setup_control_plane.yml
│   ├── setup_worker_nodes.yml
└── terraform/
    ├── main.tf
    ├── variables.tf
    ├── outputs.tf
    ├── provider.tf
    ├── nsg.tf
    ├── vm.tf
    ├── vnet.tf
    ├── terraform.tfvars.example
    └── terraform.tfvars
```

- **ansible/**: Contains Ansible playbooks and configuration.
  - **install_ansible.sh**: Script to install Ansible on the Ansible Control Machine.
- **terraform/**: Contains Terraform configuration files.

---

## Getting Started

### 1. Clone the Repository

Clone the GitHub repository to your local machine:

```bash
git clone https://github.com/Matanmoshes/azure-k8s-deployment-terraform-ansible.git
cd azure-k8s-deployment-terraform-ansible
```

### 2. Set Up Azure Credentials

You need to provide Azure credentials to Terraform. There are several ways to authenticate:

#### Option 1: Azure CLI Authentication

If you are logged in with Azure CLI, Terraform can use that session.

```bash
az login
```

#### Option 2: Service Principal Authentication

Create a Service Principal and provide the credentials to Terraform.

```bash
az ad sp create-for-rbac --name "k8s-terraform-sp" --role="Contributor" --scopes="/subscriptions/<your_subscription_id>"
```

This command will output the following:

```json
{
  "appId": "<client_id>",
  "displayName": "k8s-terraform-sp",
  "password": "<client_secret>",
  "tenant": "<tenant_id>"
}
```

Take note of the `appId`, `password`, and `tenant` values.

### 3. Configure Terraform Variables

Navigate to the `terraform` directory and copy the example variables file:

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:

```hcl
# Azure authentication
subscription_id = "your_subscription_id"
tenant_id       = "your_tenant_id"
client_id       = "your_client_id"
client_secret   = "your_client_secret"

# Resource group and location
resource_group  = "k8s-cluster-rg"
location        = "eastus"

# SSH key
ssh_public_key  = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQ..."  # Paste your Azure-generated public key content

# Your public IP (for NSG rules)
my_public_ip    = "your_public_ip_address/32"
```

**Notes:**

- **ssh_public_key**: Paste the content of your Azure-generated public key. This key should be generated in Azure before deploying the Terraform files.
- **my_public_ip**: You can find your public IP by visiting `https://ipinfo.io/ip` or using `curl`:

  ```bash
  curl ifconfig.me
  ```

  Append `/32` to specify a single IP address in CIDR notation.

### 4. Deploy Infrastructure with Terraform

Initialize Terraform and apply the configuration:

```bash
terraform init
terraform plan -out=tfplan
terraform apply "tfplan"
```

- **Review** the plan carefully before applying.
- **Confirm** the apply by typing `yes` when prompted.

### 5. Transfer SSH Key to Ansible Control Machine

After the Terraform deployment, you need to transfer your private SSH key to the Ansible Control Machine.

#### 5.1 Connect to the Bastion Host

First, connect to the Bastion Host via SSH:

```bash
ssh -i ~/.ssh/ansible-key.pem azureuser@<bastion_public_ip>
```

Replace `<bastion_public_ip>` with the public IP of your Bastion Host, which is outputted by Terraform.

#### 5.2 Transfer the SSH Key to the Ansible Control Machine

From the Bastion Host, transfer the `.pem` file to the Ansible Control Machine using `scp`:

```bash
sudo chmod 600 ~/.ssh/ansible-key.pem
scp -i ~/.ssh/ansible-key.pem ~/.ssh/ansible-key.pem azureuser@<ansible_control_private_ip>:/home/azureuser/.ssh/
```

Replace `<ansible_control_private_ip>` with the private IP of the Ansible Control Machine.

#### 5.3 Set Permissions on the Ansible Control Machine

SSH into the Ansible Control Machine:

```bash
ssh -i ~/.ssh/ansible-key.pem azureuser@<ansible_control_private_ip>
```

On the Ansible Control Machine, set the correct permissions for the SSH key:

```bash
sudo chmod 600 ~/.ssh/ansible-key.pem
```

### 6. Install Ansible on Ansible Control Machine

On the Ansible Control Machine, clone the repository and install Ansible:

#### 6.1 Clone the Repository

```bash
git clone https://github.com/Matanmoshes/azure-k8s-deployment-terraform-ansible.git
cd azure-k8s-deployment-terraform-ansible/ansible
```

#### 6.2 Run the Install Ansible Script

Run the provided script to install Ansible:

```bash
./install_ansible.sh
```

Alternatively, you can install Ansible manually:

```bash
sudo apt update
sudo apt install -y ansible
```

### 7. Configure Ansible Inventory

Edit the `inventory.ini` file with the private IPs of your VMs:

```ini
[control_plane]
control-plane-vm ansible_host=<control_plane_private_ip> ansible_user=azureuser ansible_ssh_private_key_file=~/.ssh/ansible-key.pem

[worker_nodes]
worker-node-1 ansible_host=<worker_node_1_private_ip> ansible_user=azureuser ansible_ssh_private_key_file=~/.ssh/ansible-key.pem
worker-node-2 ansible_host=<worker_node_2_private_ip> ansible_user=azureuser ansible_ssh_private_key_file=~/.ssh/ansible-key.pem

[all:vars]
ansible_python_interpreter=/usr/bin/python3
```

**Replace** the placeholders with the actual IP addresses output by Terraform.

### 8. Run Ansible Playbooks

Ensure you have SSH access from the Ansible Control Machine to the Kubernetes nodes.

#### 8.1 Check Ansible Connectivity

Test the connection to all hosts:

```bash
ansible all -i inventory.ini -m ping
```

#### 8.2 Run the Control Plane Playbook

Run the playbook to set up the Kubernetes Control Plane:

```bash
ansible-playbook -i inventory.ini setup_control_plane.yml
```

#### 8.3 Run the Worker Nodes Playbook

Run the playbook to set up the Kubernetes Worker Nodes:

```bash
ansible-playbook -i inventory.ini setup_worker_nodes.yml
```

#### 8.4 Verify the Cluster

SSH into the Control Plane node and check the status of the nodes:

```bash
ssh -i ~/.ssh/ansible-key.pem azureuser@<control_plane_private_ip>
kubectl get nodes
```

You should see all nodes in a `Ready` state.

---


## Cleanup

To destroy all resources created by Terraform:

```bash
cd terraform
terraform destroy
```

**Warning:** This will delete all resources created. Ensure you have backups if necessary.

---

## Troubleshooting

- **SSH Authentication Issues**:
  - Ensure that your SSH keys are correctly configured and that the private key has appropriate permissions (`chmod 600`).
  - Verify that the public key provided to Terraform matches your private key.

- **Terraform Errors**:
  - Double-check your `terraform.tfvars` file for typos or incorrect values.
  - Ensure that the Azure resource providers are registered in your subscription.

- **Ansible Playbook Failures**:
  - Run playbooks with increased verbosity for more details: `ansible-playbook -i inventory.ini playbook.yml -vvv`
  - Ensure that Ansible can reach the hosts: `ansible all -i inventory.ini -m ping`

- **Kubernetes Cluster Issues**:
  - Check the status of the pods: `kubectl get pods --all-namespaces`
  - Look at the logs of failing pods: `kubectl logs <pod_name> -n <namespace>`
  - Verify network connectivity between nodes.

---

### Reference:
- https://medium.com/@kvihanga/how-to-set-up-a-kubernetes-cluster-on-ubuntu-22-04-lts-433548d9a7d0
- https://medium.com/@venkataramarao.n/kubernetes-setup-using-ansible-script-8dd6607745f6