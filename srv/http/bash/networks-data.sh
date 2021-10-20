#!/bin/bash

# bluetooth
if systemctl -q is-active bluetooth; then
	readarray -t lines <<< $( bluetoothctl paired-devices | cut -d' ' -f2,3- )
	if [[ -n $lines ]]; then
		for line in "${lines[@]}"; do
			devices+="
		${line#* }^${line/ *}"
		done
		readarray -t lines <<< "$( echo "$devices" | sort -f | grep . )"
		for line in "${lines[@]}"; do
			mac=${line#*^}
			name=${line/^*}
			connected=$( bluetoothctl info $mac | grep -q 'Connected: yes' && echo true )
			listbt+=',{
  "name"      : "'${name//\"/\\\"}'"
, "connected" : '$connected'
, "mac"       : "'$mac'"
}'
		done
		listbt="[ ${listbt:1} ]"
	fi
fi
[[ $1 == bt ]] && echo $listbt && exit

ipeth=$( ifconfig eth0 2> /dev/null | awk '/^\s*inet / {print $2}' )
if [[ -n $ipeth ]]; then
	ipr=$( ip r | grep ^default.*eth0 )
	static=$( [[ $ipr == *"dhcp src $ipeth "* ]] && echo false || echo true )
	gateway=$( echo $ipr | cut -d' ' -f3 )
	[[ -z $gateway ]] && gateway=$( ip r | grep ^default | head -1 | cut -d' ' -f3 )
	if [[ -n $ipeth ]]; then
		hostname=$( avahi-resolve -a4 $ipeth | awk '{print $NF}' )
		if [[ -z $hostname ]]; then
			systemctl restart avahi-daemon
			hostname=$( avahi-resolve -a4 $ipeth | awk '{print $NF}' )
		fi
	fi
	listeth='{
  "gateway"  : "'$gateway'"
, "hostname" : "'$hostname'"
, "ip"       : "'$ipeth'"
, "static"   : '$static'
}'
fi

ifconfig wlan0 up &> /dev/null # force up
ipr=$( ip r | grep "^default.*wlan0" )
if [[ -n $ipr ]]; then
	gateway=$( echo $ipr | cut -d' ' -f3 )
	ipwlan=$( ifconfig wlan0 | awk '/^\s*inet / {print $2}' )
	static=$( [[ $ipr != *"dhcp src $ipwlan "* ]] && echo true )
	[[ -n $ipwlan ]] && hostname=$( avahi-resolve -a4 $ipwlan | awk '{print $NF}' )
	ssid=$( iwgetid wlan0 -r )
	netctl=$( cat "/etc/netctl/$ssid" )
	wep=$( [[ $( echo "$netctl" | grep ^Security | cut -d= -f2 ) == wep ]] && echo true )
	password=$( echo "$netctl" | grep ^Key | cut -d= -f2- | tr -d '"' )
	hidden=$( echo "$netctl" | grep -q ^Hidden && echo true )
	dbm=$( awk '/wlan0/ {print $4}' /proc/net/wireless | tr -d . )
	[[ -z $dbm ]] && dbm=0
	listwl=',{
  "dbm"      : '$dbm'
, "gateway"  : "'$gateway'"
, "hidden"   : '$hidden'
, "hostname" : "'$hostname'"
, "ip"       : "'$ipwlan'"
, "password" : "'$password'"
, "ssid"     : "'$ssid'"
, "static"   : '$static'
, "wep"      : '$wep'
}'
fi

readarray -t notconnected <<< $( netctl list | grep -v '^\s*\*' | sed 's/^\s*//' )
if [[ -n $notconnected ]]; then
	for ssid in "${notconnected[@]}"; do
		netctl=$( cat "/etc/netctl/$ssid" )
		static=$( ! echo "$netctl" | grep -q ^IP=dhcp && echo true )
		hidden=$( echo "$netctl" | grep -q ^Hidden && echo true )
		wep=$( echo "$netctl" | grep -q ^Security=wep && echo true )
		password=$( echo "$netctl" | grep ^Key | cut -d= -f2- | tr -d '"' )
		if [[ $static == true ]]; then
			gateway=$( echo "$netctl" | grep ^Gateway | cut -d= -f2 )
			ip=$( echo "$netctl" | grep ^Address | cut -d= -f2 | cut -d/ -f1 )
		else
			gateway=
			ip=
		fi
		listwl+=',{
  "gateway"  : "'$gateway'"
, "hidden"   : '$hidden'
, "ip"       : "'$ip'"
, "password" : "'$password'"
, "ssid"     : "'$ssid'"
, "static"   : '$static'
, "wep"      : '$wep'
}'
	done
fi
[[ -n $listwl ]] && listwl="[ ${listwl:1} ]"

# hostapd
if systemctl -q is-active hostapd; then
	ssid=$( awk -F'=' '/^ssid/ {print $2}' /etc/hostapd/hostapd.conf )
	passphrase=$( awk -F'=' '/^wpa_passphrase/ {print $2}' /etc/hostapd/hostapd.conf )
	ip=$( awk -F',' '/router/ {print $2}' /etc/dnsmasq.conf )
	ap='{
  "ssid"       : "'${ssid//\"/\\\"}'"
, "passphrase" : "'${passphrase//\"/\\\"}'"
, "ip"         : "'$ip'"
, "conf"       : '$( /srv/http/bash/features.sh hostapdget )'
}'
fi

data='
  "page"       : "networks"
, "activebt"   : '$( systemctl -q is-active bluetooth && echo true )'
, "activeeth"  : '$( ifconfig eth0 &> /dev/null && echo true )'
, "activewlan" : '$( rfkill | grep -q wlan && echo true )'
, "listbt"     : '$listbt'
, "listeth"    : '$listeth'
, "listwl"     : '$listwl'
, "hostapd"    : '$ap'
, "hostname"   : "'$( hostname )'"'

echo {$data} | sed 's/:\s*,/: false,/g; s/:\s*}/: false}/g' # sed - null > false
