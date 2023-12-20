#!/bin/bash

alias=r1

. /srv/http/bash/settings/addons.sh

# 20231216
if [[ ! -e /boot/kernel.img && $( pacman -Q python-websockets ) != 'python-websockets 12.0-1' ]]; then
	pacman -Sy --needed --noconfirm python-websockets
	systemctl restart websocket
fi

# 202312010
file=$dirsystem/display.json
for k in albumyear composername conductorname; do
	! grep -q $k $file && sed -i '/"artist"/ i\  "'$k'": false,' $file
done

[[ ! -e /usr/bin/websocat ]] && pacman -Sy --noconfirm websocat

# 20231125
grep -q connect $dirbash/websocket-server.py && websocketrestart=1

file=$dirmpdconf/conf/camilladsp.conf
if [[ -e /usr/bin/camilladsp && ! -e $file ]]; then
	echo 'audio_output {
	name           "CamillaDSP"
	device         "hw:Loopback,1"
	type           "alsa"
	auto_resample  "no"
	mixer_type     "none"
}' > $file
	echo 'include_optional    "camilladsp.conf"' >> $dirmpdconf/mpd.conf
	[[ -e $dirsystem/camilladsp ]] && mpdrestart=1
fi

file=/etc/systemd/system/cava.service
if [[ ! -e $file ]]; then
	echo '[Unit]
Description=VU level for VU LED and VU meter

[Service]
ExecStart=/srv/http/bash/cava.sh
ExecStop=/srv/http/bash/cava.sh stop' > $file
	systemctl daemon-reload
	[[ -e $dirsystem/vuled ]] && killall -9 cava &> /dev/null && rm $dirsystem/vuled
fi

if [[ ! -e /lib/libfdt.so ]]; then
	pacman -Sy --noconfirm dtc
	systemctl try-restart rotaryencoder
fi

# 20231118
grep -q dhcpcd /etc/pacman.conf && sed -i -E 's/(IgnorePkg   =).*/#\1/' /etc/pacman.conf

# 20231111
file=$dirsystem/scrobble.conf
[[ -e $file ]] && sed -i '/notify/ d' $file

if [[ -e /boot/kernel8.img ]]; then
	pacman -Q wiringpi | grep 181 && pacman -Sy --noconfirm wiringpi
fi

# 29231101
[[ ! -e /usr/bin/vcgencmd ]] && cp /opt/vc/bin/{dtoverlay,vcgencmd} /usr/bin

# 20231022
if [[ -e /boot/kernel.img && ! -e /lib/python3.10/site-packages/websocket ]]; then
	echo '
[alarm]
SigLevel = PackageRequired
Include = /etc/pacman.d/mirrorlist

[community]
SigLevel = PackageRequired
Include = /etc/pacman.d/mirrorlist' >> /etc/pacman.conf
	pacman -Sy --noconfirm python-websocket-client
	systemctl restart websocket
fi

# 20231020
file=$dirsystem/localbrowser.conf
if [[ -e $file ]] && ! grep -q runxinitrcd $file; then
	sed -i -e '/hdmi/ d
' -e '$ a\
runxinitrcd=
' $file
fi

#-------------------------------------------------------------------------------
installstart "$1"

rm -rf /srv/http/assets/{css,js}

getinstallzip

. $dirbash/common.sh
dirPermissions
cacheBust
[[ -e $dirsystem/color ]] && $dirbash/cmd.sh color

installfinish

# 20231125
[[ $websocketrestart ]] && systemctl restart websocket
[[ $mpdrestart ]] && $dirsettings/player-conf.sh
