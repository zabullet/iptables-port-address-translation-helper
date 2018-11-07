#!/bin/bash
#Bash script to help with setting up Port Address Translation using iptables
#Provides a command line for installing port forwarding rules
#Provides a Simple "UI" for removing rules
#https://github.com/zabullet/iptables-port-address-translation-helper 

# Call getopt to validate the provided input. 
options=$(getopt -o adi: --long interface:,proto:,sourcep:,dest:,destp:,nosave,nobackup -- "$@")
[ $? -eq 0 ] || { 
    echo "Incorrect options provided"
    exit 1
}

NOSAVE=false
NOBACKUP=false

function usage() {
	echo "Usage: pathelp.sh -a | -d [options]"
	echo ""
	echo "-a            Add a rule based on other parameters"
	echo "-d            Interactive removal of rules"
	echo "--interface   Interface to apply the rule to e.g. eth0"
	echo "--proto       Protocol to apply the rule to e.g. udp or tcp"
	echo "--sourcep     Source Port to forward"
	echo "--dest        Destination IP to forward to"
	echo "--destp       Destination Port to forward to"
	echo "--nosave .    Do not persist the iptable rules between reboots. Default is to save them"
	echo "--nobackup    Do not produce an iptable rule backup file pathelp.[datetime].backup. Default is to create a backup"
	echo ""
	echo "example:  add a forwarding rule to map incoming port 2222 to 172.31.15.26:22 and don't make the rule persistent"
	echo "          ./pathelp.sh -a -i eth0 --proto tcp --sourcep 2222 --dest 172.31.15.26 --destp 22 --nosave"
	echo ""
	echo "example:  delete forwarding rules interactively and don't create a backup file"
	echo "          ./pathelp.sh -d --nobackup"
	echo ""
}

function delete_rules() {
TABLE_NAME=$1
CHAIN_NAME=$2

while :
do
	echo "Select rule to delete:"
	iptables -t $TABLE_NAME -L $CHAIN_NAME -n --line-numbers
	read -p "Rule # [q to quit]: " -e -i q SELECTION
	case "$SELECTION" in
		[0-9])
			iptables -t $TABLE_NAME -D $CHAIN_NAME $SELECTION
			;;
		q)
			break
			;;
	esac
done
}

function backup_iptables() {
	datetime=`date +%Y%m%d.%H%M%S`
	iptables-save > "pathelp.$datetime.backup"
}

eval set -- "$options"
while true; do
	case "$1" in
		-a)
			ADD=true
			;;
		-d)
			DELETE=true
			;;
		--proto)
			shift; # The arg is next in position args
			PROTOCOL=$1
			;;
		--sourcep)
			shift;
			SOURCE_PORT=$1
			;;
		--dest)
			shift;
			DESTINATION=$1
			;;
		--destp)
			shift;
			DESTINATION_PORT=$1
			;;
		--interface|-i)
			shift;
			INTERFACE=$1
			;;
		--nosave)
			NOSAVE=true
			;;
		--nobackup)
			NOBACKUP=true
			;;
		--)
			shift;
			break;;
		*)
			echo "Internal error!" ; exit 1 ;;
	esac
	shift
done

if [ "$ADD" = true ] && [ "$DELETE" = true ]; then
	echo "ERROR: You can't add and delete at the same time"
	usage
	exit 1
fi

if [ -z "$ADD" ] && [ -z "$DELETE" ]; then
	echo "You need to add or delete i.e. -a or -d"
	usage
	exit 1
fi

if [ "$ADD" = true ]; then
	#Check that all parameters are provided
	if [ -z "$PROTOCOL" ] || [ -z "$SOURCE_PORT" ] || [ -z "DESTINATION" ] || [ -z "$DESTINATION_PORT" ] || [ -z "$INTERFACE" ]; then
		echo "You must provide all parameters for adding a rule"
		usage
		exit 1
	fi
	
	if [ "$NOBACKUP" = false ]; then
		backup_iptables
	fi
	
	iptables -C PREROUTING -t nat -i $INTERFACE -p $PROTOCOL --dport $SOURCE_PORT -j DNAT --to $DESTINATION:$DESTINATION_PORT 2> /dev/null ||
	iptables -A PREROUTING -t nat -i $INTERFACE -p $PROTOCOL --dport $SOURCE_PORT -j DNAT --to $DESTINATION:$DESTINATION_PORT
	
	iptables -C FORWARD -p $PROTOCOL -d $DESTINATION --dport $DESTINATION_PORT -j ACCEPT 2> /dev/null ||
	iptables -A FORWARD -p $PROTOCOL -d $DESTINATION --dport $DESTINATION_PORT -j ACCEPT
	
	if [ "$NOSAVE" = false ]; then
		service iptables save
	fi
fi

if [ "$DELETE" = true ]; then
	
	if [ "$NOBACKUP" = false ]; then
		backup_iptables
	fi
	
	delete_rules "filter" "FORWARD"
	delete_rules "nat" "PREROUTING"
	
	if [ "$NOSAVE" = false ]; then
		service iptables save
	fi
fi
