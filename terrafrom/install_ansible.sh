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