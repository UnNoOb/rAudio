#!/bin/bash

# Fonction pour acquérir le verrou
acquire_lock() {
    lock_path=$1
    while ! mkdir $lock_path 2>/dev/null; do
        #echo "Service 1 : Impossible d'acquérir le verrou. Retrying..."
        sleep 0.01
    done
}

Volume=0
VolumeUpmp=0
lock_path="/root/camilladsp/LockFile"

# Acquérir le verrou
acquire_lock "$lock_path"

# Lire la valeur de la variable depuis le fichier partagé
Volume=$(cat /root/camilladsp/VolumeFile)

# Libérer le verrou
rmdir "$lock_path"

VolumeUpmp=$((Volume + 100))
echo $VolumeUpmp

