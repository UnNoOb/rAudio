#!/bin/bash

# Fonction pour acquérir le verrou
acquire_lock() {
    lock_path=$1
    while ! mkdir $lock_path 2>/dev/null; do
        #echo "Service 1 : Impossible d'acquérir le verrou. Retrying..."
        sleep 0.01
    done
}

step=1
Volume=0
VolumeUpmp=0
lock_path="/root/camilladsp/LockFile"


# Acquérir le verrou
acquire_lock "$lock_path"

# Lire la valeur de la variable depuis le fichier partagé
Volume=$(cat /root/camilladsp/VolumeFile)
VolumeUpmpOLD=$(cat /root/camilladsp/VolumeUpmpFile)


VolumeUpmp=$1
echo $VolumeUpmp > /root/camilladsp/VolumeUpmpFile
# Écrire la valeur de la variable dans un fichier partagé
nombre=$((VolumeUpmp - VolumeUpmpOLD))

if [ $nombre -lt 0 ] || [ $VolumeUpmp -lt 1 ]; then
    if [ $((Volume - step)) -lt -99 ]; then
        echo -99 > /root/camilladsp/VolumeFile
    else
        echo $((Volume - step)) > /root/camilladsp/VolumeFile
    fi
elif [ $nombre -gt 0 ] || [ $VolumeUpmp -gt 99 ]; then
    if [ $((Volume + step)) -gt 0 ]; then
        echo 0 > /root/camilladsp/VolumeFile
    else
        echo $((Volume + step)) > /root/camilladsp/VolumeFile
    fi
fi


# Libérer le verrou
rmdir "$lock_path"

#echo $VolumeUpmp
