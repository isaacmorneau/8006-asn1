#!/bin/bash
if [[ $EUID -ne 0 ]]; then
    echo "Requesting Root" 1>&2
    exit `sudo ${0}`
fi
IPA='iptables -A'
TCP='-m tcp -p tcp'
UDP='-m udp -p udp'

echo "Clearing existing tables"
#drop tcp existing rules and user chains
iptables -F
iptables -X

echo "Creating user tables"
#create allow rule chain
iptables -N ENTRY
#create everything else accounting chain
iptables -N CATCH_ALL

echo "Setting default policy to DROP"
#set drop as default
iptables -P INPUT DROP
iptables -P OUTPUT DROP
iptables -P FORWARD DROP


#initialize acounting rules
IO_ARR=('INPUT' 'OUTPUT')
for t in ${IO_ARR[@]}; do
    echo "Setting accounting rules for $t"
    $IPA $t $TCP --sport www -j ENTRY
    $IPA $t $TCP --dport www -j ENTRY
    $IPA $t $TCP --sport ssh -j ENTRY
    $IPA $t $TCP --dport ssh -j ENTRY
done

echo "Setting forward for CATCH_ALL"
#if theres no match, forward it to the everything else rule chain
iptables -A INPUT  -p all -j CATCH_ALL
iptables -A OUTPUT -p all -j CATCH_ALL

#disalow entry from any port less thatn 1024 when dest is 80
iptables -A ENTRY -m tcp -p tcp --sport 0:1023 --dport 80 -j DROP

#load the configs into arrays
declare -a ACC_TCP_ARR
declare -a ACC_UDP_ARR
declare -a DRP_TCP_ARR
declare -a DRP_UDP_ARR
readarray -t ACC_TCP_ARR < tcp_acpt.txt
readarray -t ACC_UDP_ARR < udp_acpt.txt
readarray -t DRP_TCP_ARR < tcp_drop.txt
readarray -t DRP_UDP_ARR < udp_drop.txt
#add accept and drop riles for TCP to the ENTRY and CATCH_ALLchains
for p in ${ACC_TCP_ARR[@]}; do
    echo "Setting ACCEPT for TCP port $p"
    $IPA ENTRY     $TCP --sport $p -j ACCEPT
    $IPA ENTRY     $TCP --dport $p -j ACCEPT
    $IPA CATCH_ALL $TCP --sport $p -j ACCEPT
    $IPA CATCH_ALL $TCP --dport $p -j ACCEPT
done
for p in ${DRP_TCP_ARR[@]}; do
    echo "Setting DROP for TCP port $p"
    $IPA ENTRY     $TCP --sport $p -j DROP
    $IPA ENTRY     $TCP --dport $p -j DROP
    $IPA CATCH_ALL $TCP --sport $p -j DROP
    $IPA CATCH_ALL $TCP --dport $p -j DROP
done

for p in ${ACC_UDP_ARR[@]}; do
    echo "Setting ACCEPT for UDP port $p"
    $IPA ENTRY     $UDP --sport $p -j ACCEPT
    $IPA ENTRY     $UDP --dport $p -j ACCEPT
    $IPA CATCH_ALL $UDP --sport $p -j ACCEPT
    $IPA CATCH_ALL $UDP --dport $p -j ACCEPT
done
for p in ${DRP_UDP_ARR[@]}; do
    echo "Setting DROP for UDP port $p"
    $IPA ENTRY     $UDP --sport $p -j DROP
    $IPA ENTRY     $UDP --dport $p -j DROP
    $IPA CATCH_ALL $UDP --sport $p -j DROP
    $IPA CATCH_ALL $UDP --dport $p -j DROP
done
