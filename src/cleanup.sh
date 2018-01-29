#!/bin/bash
if [[ $EUID -ne 0 ]]; then
   echo "Needs Root!" 1>&2
   exit 1
fi
#drop existing rules
iptables -F
#drop existing user defined chains
iptables -X
#reset defaults
iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT
iptables -P FORWARD ACCEPT
#zero out counters
iptables -Z
