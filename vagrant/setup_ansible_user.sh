#!/bin/bash

# Créer l'utilisateur ansible
useradd -m -s /bin/bash ansible

# Définir un mot de passe pour l'utilisateur ansible
echo ansible:ansible | chpasswd

 
echo "ansible ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ansible
chmod 0440 /etc/sudoers.d/ansible

# Configuration initiale pour SSH (facultatif, dépend de votre setup Ansible)
mkdir -p /home/ansible/.ssh
chmod 700 /home/ansible/.ssh
touch /home/ansible/.ssh/authorized_keys
chmod 600 /home/ansible/.ssh/authorized_keys
chown -R ansible:ansible /home/ansible/.ssh
