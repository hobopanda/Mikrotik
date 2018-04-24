#!/bin/bash
if [[ $1 ]] && [[ $2 ]]; then
    if [ $1 -le "1005" -a  $1 -ge "1001" ] || [ $1 -le "1" ] || [ $1 -gt "4094" ]; then
        echo Invallid start VLAN
        exit
    fi
    if [ $2 -le "1005" -a  $2 -ge "1001" ] || [ $2 -le "1" ] || [ $2 -gt "4094" ]; then
        echo Invallid end VLAN
        exit
    fi

    if (( $1 <= $2 )); then
        startVLAN=$1
        endVLAN=$2
    else
        echo ERROR start VLAN is greater then end VLAN
    fi
else
    startVLAN=100
    endVLAN=199
fi
linebreak=0
VLAN=$(echo $startVLAN)
Octet1=100
Octet2=64
Octet3=0
Octet4=0

while [ $VLAN -le $endVLAN ]; do
    if [ $VLAN -le "1005" -a  $VLAN -ge "1001" ] || [ $VLAN -le "1" ] || [ $VLAN -gt "4094" ]; then
        ((VLAN++))
        continue  2    # Skip rest of this particular loop iteration.
    fi
    if (( $linebreak < "10" )); then
        ((linebreak++))
        printf '\n'
    else
        printf '\n\n\n\n\n'
        linebreak=1
    fi

    Octet3=$(( $VLAN % 256 )) #to get Octet3 take $VLAN mod 256 this will give the remaining /24 block for Octet3
    Octet2=$((( $VLAN / 256) + 64))   # to get Octet2 tke $VLAN / 256 this will give the /16 block your /24 will sit in + 64 for start block of 64

    echo /interface vlan add interface=sfp-sfpplus2 name=sfpplus2_V$VLAN vlan-id=$VLAN
    echo /interface bridge add name=BR_V$VLAN protocol-mode=none
    echo /interface bridge port add bridge=BR_V$VLAN interface=sfpplus2_V$VLAN
    echo /ip addres add address=$Octet1.$Octet2.$Octet3.1/24 interface=BR_V$VLAN
    echo /ip pool add name=pool_$VLAN ranges=$Octet1.$Octet2.$Octet3.20-$Octet1.$Octet2.$Octet3.255
    echo /ip dhcp-server network add address=$Octet1.$Octet2.$Octet3.0/24 dns-server=50.30.184.16,66.253.214.16 gateway=$Octet1.$Octet2.$Octet3.1
    echo /ip dhcp-server add add-arp=yes address-pool=pool_$VLAN  disabled=no interface=BR_V$VLAN lease-time=40s name=VLAN$VLAN
    ((VLAN++))
done
