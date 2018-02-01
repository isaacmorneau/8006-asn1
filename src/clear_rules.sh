#!/bin/bash
if [[ $EUID -ne 0 ]]; then
    echo "Requesting Root" 1>&2
    exit `sudo ${0}`
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
