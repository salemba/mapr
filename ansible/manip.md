
bash script_ansible.sh
ansible-playbook -i inventory.ini deploy_mapr.yml --ask-vault-pass -K
ansible-vault edit "/home/ansible/Vagrant_Ansible_Cluster/ansible/mapr_configuration/vars/creds.yml"
ansible-playbook -i inventory.ini deploy_mapr.yml --ask-vault-pass --tags "configure_cluster"
ssh-keygen -R 192.168.50.101

ansible-playbook -i inventory.ini deploy_mapr.yml --ask-vault-pass -K --tags "modify_config_file"
ansible-playbook -i inventory.ini add_services.yml --ask-vault-pass -K 

ansible-playbook -i inventory.ini restart_history_server.yml --ask-vault-pass