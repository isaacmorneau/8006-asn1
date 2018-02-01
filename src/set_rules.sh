#!/bin/bash
if [[ $EUID -ne 0 ]]; then
   echo "Needs Root!" 1>&2
   exit 1
fi
IPA='iptables -A'
TCP='-m tcp -p tcp'
UDP='-m udp -p udp'

#drop tcp existing rules and user chains
iptables -F
iptables -X

#create allow rule chain
iptables -N ENTRY
#create forward rule chain
iptables -N REST

#set drop as default
iptables -P INPUT DROP
iptables -P OUTPUT DROP
iptables -P FORWARD DROP


#initialize acounting rules
iptables -A  INPUT -m tcp -p tcp --sport www -j ENTRY
iptables -A  INPUT -m tcp -p tcp --dport www -j ENTRY
iptables -A  INPUT -m tcp -p tcp --sport ssh -j ENTRY
iptables -A  INPUT -m tcp -p tcp --dport ssh -j ENTRY
iptables -A OUTPUT -m tcp -p tcp --sport www -j ENTRY
iptables -A OUTPUT -m tcp -p tcp --dport www -j ENTRY
iptables -A OUTPUT -m tcp -p tcp --sport ssh -j ENTRY
iptables -A OUTPUT -m tcp -p tcp --dport ssh -j ENTRY

#if theres no match, forward it to the REST rule chain
iptables -A INPUT  -p all -j REST
iptables -A OUTPUT -p all -j REST

#disalow entry from any port less thatn 1024 when dest is 80
iptables -A ENTRY -m tcp -p tcp --sport 0:1023 --dport 80 -j DROP

#load the configs into arrays
IFS="\n"
cat tcp_acpt.txt | read -ra ACC_TCP_ARR
cat udp_acpt.txt | read -ra ACC_UDP_ARR
cat tcp_drop.txt | read -ra DRP_TCP_ARR
cat udp_drop.txt | read -ra DRP_UDP_ARR
#add accept and drop riles for TCP to the ENTRY and REST chains
for i in ${ACC_TCP_ARR[@]}; do
    $IPA ENTRY $TCP --sport $i -j ACCEPT
    $IPA ENTRY $TCP --dport $i -j ACCEPT
    $IPA REST  $TCP --sport $i -j ACCEPT
    $IPA REST  $TCP --dport $i -j ACCEPT
done
for i in ${DRP_TCP_ARR[@]}; do
    $IPA ENTRY $TCP --sport $i -j DROP
    $IPA ENTRY $TCP --dport $i -j DROP
    $IPA REST  $TCP --sport $i -j DROP
    $IPA REST  $TCP --dport $i -j DROP
done

for i in ${ACC_UDP_ARR[@]}; do
    $IPA ENTRY $UDP --sport $i -j ACCEPT
    $IPA ENTRY $UDP --dport $i -j ACCEPT
    $IPA REST  $UDP --sport $i -j ACCEPT
    $IPA REST  $UDP --dport $i -j ACCEPT
done
for i in ${DRP_UDP_ARR[@]}; do
    $IPA ENTRY $UDP --sport $i -j DROP
    $IPA ENTRY $UDP --dport $i -j DROP
    $IPA REST  $UDP --sport $i -j DROP
    $IPA REST  $UDP --dport $i -j DROP
done
