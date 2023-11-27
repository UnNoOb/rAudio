#!/bin/bash

. /srv/http/bash/common.sh

. $dirsystem/rotaryencoder.conf

# Fonction pour acquérir le verrou
acquire_lock() {
    lock_path=$1
    while ! mkdir $lock_path 2>/dev/null; do
        echo "Service 1 : Impossible d'acquérir le verrou. Retrying..."
        sleep 0.1
    done
}

# play/pause
dtoverlay gpio-key gpio=$pins label=PLAYCD keycode=200
sleep 1
devinputbutton=$( realpath /dev/input/by-path/*button* )
evtest $devinputbutton | while read line; do
	[[ $line =~ .*EV_KEY.*KEY_PLAYCD.*1 ]] && python /root/camilladsp/CamillaVolumeScript.py KEY_PUSH #$dirbash/cmd.sh mpcplayback
	#python /root/camilladsp/CamillaVolumeScript.py KEY_PUSH
done &

dtoverlay rotary-encoder pin_a=$pina pin_b=$pinb relative_axis=1 steps-per-period=$step
sleep 1
devinputrotary=$( realpath /dev/input/by-path/*rotary* )
if [[ -e $dirshm/btreceiver ]]; then
	control=$( < $dirshm/btreceiver )
	evtest $devinputrotary | while read line; do
		if [[ $line =~ 'value 1'$ ]]; then
			volumeUpDnBt 1%+ "$control"
		elif [[ $line =~ 'value -1'$ ]]; then
			volumeUpDnBt 1%- "$control"
		fi
	done
#elif [[ -e $dirshm/amixercontrol ]]; then
#	card=$( < $dirsystem/asoundcard )
#	control=$( < $dirshm/amixercontrol )
#	evtest $devinputrotary | while read line; do
#		if [[ $line =~ 'value 1'$ ]]; then
#			volumeUpDn 1%+ "$control" $card
#		elif [[ $line =~ 'value -1'$ ]]; then
#			volumeUpDn 1%- "$control" $card
#		fi
#	done
else
#	tmpCount=0
#	increment=1
#	interval=0.5  # Intervalle en secondes pour effectuer l'opération
#	lastOperation=$(date +%s)

	Volume=0
	lock_path="/root/camilladsp/LockFile"
	rmdir $lock_path
	
	evtest $devinputrotary | while read line; do
		if [[ $line =~ 'value 1'$ ]]; then
			
			# Acquérir le verrou
			#lock_path="/root/camilladsp/LockFile"
			acquire_lock $lock_path	

			# Lire la valeur de la variable depuis le fichier partagé
			Volume=$(cat /root/camilladsp/VolumeFile)

			# Écrire la valeur de la variable dans un fichier partagé
			if [ $((Volume + step)) -gt 0 ]; then
				echo 0 > /root/camilladsp/VolumeFile
			else
				echo $((Volume + step)) > /root/camilladsp/VolumeFile
			fi

			# Libérer le verrou
			rmdir $lock_path
			
		elif [[ $line =~ 'value -1'$ ]]; then
			tmpCount=$((tmpCount - step))

			# Acquérir le verrou
			#lock_path="/root/camilladsp/LockFile"
			acquire_lock $lock_path

			# Lire la valeur de la variable depuis le fichier partagé
			Volume=$(cat /root/camilladsp/VolumeFile)

			# Écrire la valeur de la variable dans un fichier partagé
			if [ $((Volume - step)) -lt -99 ]; then
				echo -99 > /root/camilladsp/VolumeFile
			else
				echo $((Volume - step)) > /root/camilladsp/VolumeFile
			fi

			# Libérer le verrou
			rmdir $lock_path
			
		#else
		#	if [ $tmpCount -gt 0 ]; then
		#		echo $tmpCount
		#		python /root/camilladsp/CamillaVolumeScript.py KEY_UP $tmpCount
		#		tmpCount=0
		#	elif [ $tmpCount -lt 0 ]; then
		#		echo $tmpCount
		#		python /root/camilladsp/CamillaVolumeScript.py KEY_DOWN $tmpCount
		#		tmpCount=0
		#+	fi
		fi

		
	done
	

fi