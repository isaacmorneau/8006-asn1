#!/bin/bash
if [[ $EUID -ne 0 ]]; then
   echo "Needs Root!" 1>&2
   exit 1
fi
#declare the ports to accept and drop
TCP_ACCEPT=`cat tcp_acpt.txt`
UDP_ACCEPT=`cat udp_acpt.txt`
TCP_DROP=`cat tcp_drop.txt`
UDP_DROP=`cat udp_drop.txt`
#turn into arrays the easy way
IFS=',' read -ra ACC_TCP_ARR <<< "$TCP_ACCEPT"
IFS=',' read -ra ACC_UDP_ARR <<< "$UDP_ACCEPT"
IFS=',' read -ra DRP_TCP_ARR <<< "$TCP_DROP"
IFS=',' read -ra DRP_UDP_ARR <<< "$UDP_DROP"

#drop tcp existing rules and user chains
iptables -F
iptables -X

#set drop as default
iptables -P INPUT DROP
iptables -P OUTPUT DROP
iptables -P FORWARD DROP

#create allow rule chain
iptables -N ENTRY
#create forward rule chain
iptables -N REST


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
iptables -A ENTRY -m tcp -p tcp --sport :1023 --dport 80 -j DROP

#add accept and drop riles for TCP to the ENTRY and REST chains
for i in "${ACC_TCP_ARR[@]}"; do
    iptables -A ENTRY -m tcp -p tcp --sport $i -j ACCEPT
    iptables -A ENTRY -m tcp -p tcp --dport $i -j ACCEPT
    iptables -A REST  -m tcp -p tcp --sport $i -j ACCEPT
    iptables -A REST  -m tcp -p tcp --dport $i -j ACCEPT
done
for i in "${DRP_TCP_ARR[@]}"; do
    iptables -A ENTRY -m tcp -p tcp --sport $i -j DROP
    iptables -A ENTRY -m tcp -p tcp --dport $i -j DROP
    iptables -A REST  -m tcp -p tcp --sport $i -j DROP
    iptables -A REST  -m tcp -p tcp --dport $i -j DROP
done

for i in "${ACC_UDP_ARR[@]}"; do
    iptables -A ENTRY -m udp -p udp --sport $i -j ACCEPT
    iptables -A ENTRY -m udp -p udp --dport $i -j ACCEPT
    iptables -A REST  -m udp -p udp --sport $i -j ACCEPT
    iptables -A REST  -m udp -p udp --dport $i -j ACCEPT
done
for i in "${DRP_UDP_ARR[@]}"; do
    iptables -A ENTRY -m udp -p udp --sport $i -j DROP
    iptables -A ENTRY -m udp -p udp --dport $i -j DROP
    iptables -A REST  -m udp -p udp --sport $i -j DROP
    iptables -A REST  -m udp -p udp --dport $i -j DROP
done
