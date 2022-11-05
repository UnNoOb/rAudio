#!/bin/bash

. /srv/http/bash/common.sh

# bluetooth
rfkill | grep -q -m1 bluetooth && systemctl -q is-active bluetooth && activebt=1
if [[ $activebt ]]; then
	readarray -t devices <<< $( bluetoothctl devices Paired | sort -k3 -fh  )
	if [[ $devices ]]; then
		for dev in "${devices[@]}"; do
			mac=$( cut -d' ' -f2 <<< $dev )
			info=$( bluetoothctl info $mac )
			listbt+=',{
  "mac"       : "'$mac'"
, "name"      : "'$( cut -d' ' -f3- <<< $dev )'"
, "connected" : '$( grep -q -m1 'Connected: yes' <<< $info && echo true || echo false )'
, "type"      : "'$( awk '/UUID: Audio/ {print $3}' <<< $info )'"
}'
		done
		listbt="[ ${listbt:1} ]"
		grep -q -m1 '"type" : "Sink"' <<< $listbt && btreceiver=true || btreceiver=false
		grep -q -m1 '"connected" : true' <<< $listbt && connected=true || connected=false
		pushstream bluetooth '{"connected":'$connected',"btreceiver":'$btreceiver'}'
		
		[[ $1 == pushbt ]] && pushstream bluetooth "$listbt" && exit
	fi
else
	listbt=false
fi

ipeth=$( ifconfig eth0 2> /dev/null | awk '/inet.*broadcast/ {print $2}' )
if [[ $ipeth ]]; then
	ipr=$( ip r | grep ^default.*eth0 )
	static=$( [[ $ipr != *"dhcp src $ipeth "* ]] && echo true )
	gateway=$( cut -d' ' -f3 <<< $ipr )
	[[ ! $gateway ]] && gateway=$( ip r | awk '/^default/ {print $3;exit}' )
	if [[ $ipeth ]]; then
		hostname=$( avahi-resolve -a4 $ipeth | awk '{print $NF}' )
		if [[ ! $hostname ]]; then
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
if [[ -e $dirshm/wlan ]]; then
	wldev=$( < $dirshm/wlan )
	readarray -t profiles <<< $( ls -1p /etc/netctl | grep -v /$ )
	if [[ $profiles ]]; then
		for profile in "${profiles[@]}"; do
			! grep -q -m1 Interface=$wldev "/etc/netctl/$profile" && continue
			if netctl is-active "$profile" &> /dev/null; then
				for i in {1..10}; do
					ipwl=$( ifconfig $wldev | awk '/inet.*broadcast/ {print $2}' )
					[[ $ipwl ]] && break || sleep 1
				done
				gateway=$( ip r | grep "^default.*$wldev" | cut -d' ' -f3 )
				dbm=$( awk '/'$wldev'/ {print $4}' /proc/net/wireless | tr -d . )
				[[ ! $dbm ]] && dbm=0
				listwl=',{
	  "dbm"      : '$dbm'
	, "gateway"  : "'$gateway'"
	, "ip"       : "'$ipwl'"
	, "ssid"     : "'${profile//\"/\\\"}'"
	}'
			else
				listwlnotconnected+=',{
	  "ssid"     : "'${profile//\"/\\\"}'"
	}'
			fi
		done
	fi
	listwl+="$listwlnotconnected"
	[[ $listwl ]] && listwl="[ ${listwl:1} ]"
fi

# hostapd
if systemctl -q is-active hostapd; then
	ssid=$( awk -F'=' '/^ssid/ {print $2}' /etc/hostapd/hostapd.conf )
	passphrase=$( awk -F'=' '/^wpa_passphrase/ {print $2}' /etc/hostapd/hostapd.conf )
	ip=$( awk -F',' '/router/ {print $2}' /etc/dnsmasq.conf )
	ap='{
  "ssid"       : "'${ssid//\"/\\\"}'"
, "passphrase" : "'${passphrase//\"/\\\"}'"
, "ip"         : "'$ip'"
, "conf"       : '$( $dirsettings/features.sh hostapdget )'
}'
fi

data='
  "page"        : "networks"
, "activebt"    : '$activebt'
, "activeeth"   : '$( ip -br link | grep -q -m1 ^e && echo true )'
, "activewl"    : '$( rfkill | grep -q -m1 wlan && echo true )'
, "camilladsp"  : '$( exists $dirsystem/camilladsp )'
, "connectedwl" : '$( netctl list | grep -q -m1 '^\*' && echo true )'
, "ipeth"       : "'$ipeth'"
, "ipwl"        : "'$ipwl'"
, "listbt"      : '$listbt'
, "listeth"     : '$listeth'
, "listwl"      : '$listwl'
, "hostapd"     : '$ap'
, "hostname"    : "'$( hostname )'"'

data2json "$data" $1
