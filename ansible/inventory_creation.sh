#!/bin/bash
# Configuration initiale
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""  # Création d'une nouvelle clé SSH sans passphrase
START=101
END=103
SPECIAL_IP="192.168.50.199"  # Adresse IP spéciale à vérifier
SUBNET="192.168.50"
USERNAME="ansible"
PASSWORD="ansible"

INVENTORY_FILE="inventory.ini"

# Initialisation du fichier d'inventaire avec les groupes nécessaires
if [ ! -f "$INVENTORY_FILE" ]; then
    echo "[ZooKeeper_nodes]" > "$INVENTORY_FILE"
    echo "[CLDB_nodes]" >> "$INVENTORY_FILE"
    echo "[ResourceManager_nodes]" >> "$INVENTORY_FILE"
    echo "[FileServer_nodes]" >> "$INVENTORY_FILE"
    echo "[NFS_nodes]" >> "$INVENTORY_FILE"
    echo "[NodeManager_nodes]" >> "$INVENTORY_FILE"
    echo "[HistoryServer_nodes]" >> "$INVENTORY_FILE"
    echo "[WebServer_nodes]" >> "$INVENTORY_FILE"
    echo "[ApiServer_nodes]" >> "$INVENTORY_FILE"   
    echo "[TimelineServer_nodes]" >> "$INVENTORY_FILE"
    echo "[Hue_nodes]" >> "$INVENTORY_FILE"
    echo "[Drill_nodes]" >> "$INVENTORY_FILE"
    echo "[Hive_nodes]" >> "$INVENTORY_FILE"  
    echo "[OpenTSDB_nodes]" >> "$INVENTORY_FILE"
    echo "[CollecTD_nodes]" >> "$INVENTORY_FILE"
    echo "[Gateway_nodes]" >> "$INVENTORY_FILE"
    echo "[Httpfs_nodes]" >> "$INVENTORY_FILE"
    echo "[Licence_node]" >> "$INVENTORY_FILE"
    echo "[edge_node]" >> "$INVENTORY_FILE"
    echo "[all_nodes]" >> "$INVENTORY_FILE"
fi

# Vérification de la connectivité et de la configuration pour la machine spéciale
echo "Vérification de la joignabilité de $SPECIAL_IP par ping..."
if ping -c 1 $SPECIAL_IP &> /dev/null; then
    echo "$SPECIAL_IP est joignable."
else
    echo "$SPECIAL_IP n'est pas joignable via ping."
fi

# Boucle sur la plage d'adresses IP
for IP in $(seq $START $END) $SPECIAL_IP; do
    
    if [ "$IP" == "$SPECIAL_IP" ]; then
        FULL_IP=$SPECIAL_IP
    else
        FULL_IP="$SUBNET.$IP"
    fi
    echo "Vérification de la joignabilité de $FULL_IP par ping..."
    
    if ping -c 1 $FULL_IP &> /dev/null; then
        echo "$FULL_IP est joignable."
        
        # Tentative de copie de la clé SSH vers le hôte distant
        echo "Tentative de copie de la clé SSH vers $FULL_IP"
        ssh-keygen -R $FULL_IP
        sshpass -p "$PASSWORD" ssh-copy-id -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa.pub $USERNAME@$FULL_IP
        
        # Récupère le nom d'hôte et l'OS
        HOSTNAME=$(sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa $USERNAME@$FULL_IP 'hostname' 2>/dev/null)
        OS=$(sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa $USERNAME@$FULL_IP 'cat /etc/os-release | grep PRETTY_NAME | cut -d "=" -f2' 2>/dev/null)
        DISKS=$(sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa $USERNAME@$FULL_IP "lsblk -dno NAME | egrep 'sdb|sdc|sdd|sde|sdf' | wc -l" 2>/dev/null)

        # Formate l'entrée d'inventaire
        INVENTORY_ENTRY="$HOSTNAME ansible_host=$FULL_IP ansible_user=$USERNAME OS=$OS nfs_disks=$DISKS"

        # Vérifie si l'entrée existe déjà pour éviter les doublons
        if ! grep -Fxq "$INVENTORY_ENTRY" "$INVENTORY_FILE"; then
            if [ ! -z "$HOSTNAME" ]; then
                echo "Le nom d'hôte de $FULL_IP est $HOSTNAME avec OS $OS."
                # Ajoute l'hôte à la section [all_nodes] et à ses rôles spécifiques
                echo "$INVENTORY_ENTRY" >> "$INVENTORY_FILE"
            else
                echo "Échec de la récupération du nom d'hôte pour $FULL_IP."
            fi
        else
            echo "Entrée existante pour $HOSTNAME, pas de mise à jour nécessaire."
        fi
    else
        echo "$FULL_IP n'est pas joignable via ping."
    fi
done

echo "Fichier d'inventaire mis à jour : $INVENTORY_FILE"
