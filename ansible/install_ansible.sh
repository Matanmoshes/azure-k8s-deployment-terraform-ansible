#!/bin/bash

# Update the system
sudo apt update

# Install required dependencies
sudo apt install -y software-properties-common

# Add Ansible PPA
sudo add-apt-repository --yes --update ppa:ansible/ansible

# Install Ansible
sudo apt install -y ansible

# Verify installation
ansible --version

# Install git
sudo apt install git

# clone the the github repo with the ansible configuration files
git clone https://github.com/Matanmoshes/azure-k8s-deployment-terraform-ansible.git