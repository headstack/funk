#!/bin/sh
#

# REQUIRED DEPENDENCIES: net-tools, sipcalc, jq

# Text Color Variables http://misc.flogisoft.com/bash/tip_colors_and_formatting
tcLtG="\033[00;37m"   		 # LIGHT GRAY
tcDkG="\033[01;30m"   		 # DARK GRAY
tcLtR="\033[01;31m"   		 # LIGHT RED
tcLtGRN="\033[01;32m" 		 # LIGHT GREEN
tcLtBL="\033[01;34m"  		 # LIGHT BLUE
tcLtP="\033[01;35m"   		 # LIGHT PURPLE
tcLtC="\033[01;36m"   		 # LIGHT CYAN
tcW="\033[01;37m"      		 # WHITE
tcRESET="\033[0m"     		 # DROP ALL COLORS
tcORANGE="\033[38;5;209m"	 # ORANGE
#

SERVICES=(mariadb haproxy keepalived docker kubelet etcd postgresql patroni)
PADDING=16
CONTACTS="technical_support@example.com"
COMPANY="YOUR_COMPANY_NAME_HERE"

# Time of day
HOUR=$(date +"%H")
if [ $HOUR -lt 12  -a $HOUR -ge 0 ]; then TIME="morning"
  elif [ $HOUR -lt 17 -a $HOUR -ge 12 ]; then TIME="day"
  else TIME="evening"
fi
#

# System uptime
uptime=$(cat /proc/uptime | cut -f1 -d.)
upDays=$((uptime/60/60/24))
upHours=$((uptime/60/60%24))
upMins=$((uptime/60%60))
#

# System + Memory
SYS_LOADS=$(cat /proc/loadavg | awk '{print $1}')
MEMORY_USED=$(free -b | grep Mem | awk '{print $3/$2 * 100.0}')
SWAPON=$(swapon --show)
  if [[ "$SWAPON" != '' ]]; then
    SWAP_USED=$(free -b | grep Swap | awk '{print $3/$2 * 100.0, "%"}' 2>/dev/null)
  else
    SWAP_USED=""$tcORANGE"Swap disabled"
  fi
NUM_PROCS=$(ps aux | wc -l)

if [[ -f /etc/redhat-release ]]; then RELEASE=$(cat /etc/redhat-release 2>/dev/null | awk '{ print $2 }' 2>/dev/null)
elif [[ -f /etc/os-release ]]; then RELEASE=$(cat /etc/*release 2>/dev/null | grep "PRETTY_NAME" | sed 's|PRETT.*\=||; s|\"||g')
fi
#

# Check syntax in graph Users
USERS=$(users | wc -w)
if [ $USERS = 1 ]; then USERCOUNT="user"
else USERCOUNT="users"
fi
#

# Check cluster node status
check_ha () {
if [[ -d "/etc/keepalived/" ]]; then

  systemctl status keepalived.service &>/dev/null
  
     if [[ "$?" -eq 0 || "$?" -eq 3 ]]; then

        if [[ $(ip a | grep secondary | awk '{ print $5}' 2>/dev/null) = "secondary" ]]; then
                NODESTATE="$tcLtR This node is in Master state with VIP: $(ip a | grep secondary | awk '{ print $2 }' 2>/dev/null) on dev $(ip a | grep secondary | awk '{ print $6}' 2>/dev/null)"
                else NODESTATE="$tcLtC This node is in Slave state. Master VIP is: $(grep -A 1 "virtual_ipaddress" /etc/keepalived/keepalived.conf | grep -v "virtual" | awk '{print $1}' 2>/dev/null)"
        fi
        if [[ "$NODESTATE" != '' ]]; then echo -e        " $NODESTATE"; fi

     fi
fi
}

# Check MariaDB status
check_service () {
    for service in "${SERVICES[@]}"; do

    systemctl status $service.service &>/dev/null

      if [[ "$?" -eq 0 || "$?" -eq 3 ]]; then
        SRV=$(systemctl status $service.service | grep "Active:" | awk '{print $2}')
          if [ "$SRV" = "active" ]; then SRVRUN=$tcLtC"Running"
            else SRVRUN=$tcLtR"Not Running"
          fi
          if [[ "$SRVRUN" != '' ]]; then 
            SPACES=$(echo "$PADDING - ${#service}" | bc)
            SEC_PART=$(echo $SRVRUN | awk '{printf "%"'$SPACES'"s%s\n", ": ", $0}')
            echo -e $tcLtG " - $service$SEC_PART"
          fi
       fi
     done
}

# Check ip links
check_ip_link () {

# Interfaces list
LIST=$(ip -j link | jq -r '.[].ifname' | grep -e "^ens\|^enp\|^br\|^eth\|^bond")

for ip_link in ${LIST[*]}; do

  IPADDRlink=$(ip a s dev $ip_link | grep inet | head -n 1 | awk '{ print $2 }')
  STATElink=$(ip a s dev $ip_link | grep 'state' | awk '{ print $9}')
  SUBNET_MASK=$(ip a s dev $ip_link | grep inet | head -n 1 | awk '{ print $2 }' | sed 's|\(^.*\)\(\/[0-9][0-9]\)|\2|')
  ADDR_LINK=$(ip a s dev $ip_link | grep inet | head -n 1 | awk '{ print $2 }' | sed 's|\(^.*\)\(\/[0-9][0-9]\)|\1|')
  MTU=$(ip a s dev $ip_link | grep mtu | awk '{print $5}')
if [ "$STATElink" = "UP" ]; then FINALSTATElink=$tcLtC"$STATElink"
else FINALSTATElink=$tcLtR"$STATElink"
fi

# RX/TX ERRS CHECK FOR RHEL/CENTOS/FEDORA
if [[ $RELEASE = "Hat" ]]; then
  RXlink=$(ifconfig $ip_link | grep 'RX packets' | awk '{print $6 $7}' | sed 's/(//; s/)//')
  TXlink=$(ifconfig $ip_link | grep 'TX packets' | awk '{print $6 $7}' | sed 's/(//; s/)//')
  RXERRlink=$(ifconfig $ip_link | grep 'RX errors' | sed 's/^[ \s]*//; s/\(RX errors\s\)/ERR:/; s/dropped\s/DROPPS:/; s/overruns\s/OVERS:/; s/frame\s/FRM:/;')
  TXERRlink=$(ifconfig $ip_link | grep 'TX errors' | sed 's/^[ \s]*//; s/\(TX errors\s\)/ERR:/; s/dropped\s/DROPPS:/; s/overruns\s/OVERS:/; s/carrier\s/CARR:/; s/collisions\s/COLLS:/')

# RX/TX ERRS CHECK FOR UBUNTU
elif [[ $RELEASE =~ "Ubuntu" ]]; then
  RXlink=$(ifconfig $ip_link | grep 'RX packets' | awk '{print $6 $7}' | sed 's/(//; s/)//')
  TXlink=$(ifconfig $ip_link | grep 'TX packets' | awk '{print $6 $7}' | sed 's/(//; s/)//')
  RXERRlink=$(ifconfig $ip_link | grep 'RX errors' | sed 's/^[ \s]*//; s/\(RX errors\s\)/ERR:/; s/dropped\s/DROPPS:/; s/overruns\s/OVERS:/; s/frame\s/FRM:/;')
  TXERRlink=$(ifconfig $ip_link | grep 'TX errors' | sed 's/^[ \s]*//; s/\(TX errors\s\)/ERR:/; s/dropped\s/DROPPS:/; s/overruns\s/OVERS:/; s/carrier\s/CARR:/; s/collisions\s/COLLS:/')

# RX/TX ERRS CHECK FOR ALT LINUX AND OTHERS
else
  RXlink=$(ifconfig $ip_link | grep 'RX bytes' | awk '{print $3 $4}' | sed 's/(//; s/)//')
  TXlink=$(ifconfig $ip_link | grep 'TX bytes' | awk '{print $7 $8}' | sed 's/(//; s/)//')
  RXERRlink=$(netstat --interfaces=$ip_link | grep -v "Kernel" | grep -v "MTU" | awk '{ print "RX-OK:"$4, "RX-ERR:"$5, "RX-DRP:"$6, "RX-OVR:"$7 }')
  TXERRlink=$(netstat --interfaces=$ip_link | grep -v "Kernel" | grep -v "TX-OK" | awk '{ print "TX-OK:"$8, "TX-ERR:"$9, "TX-DRP:"$10, "TX-OVR:"$11 }')
fi

# RX/TX BUFFER CHECK FOR ALL
  RXBUFFlink=$(ethtool -g $ip_link | sed -n 7,11p | grep RX: | awk '{print $2}')
  TXBUFFlink=$(ethtool -g $ip_link | sed -n 7,11p | grep TX: | awk '{print $2}')

  NET=$(sipcalc -n $ip_link $IPADDRlink | grep current | awk '{print $3}')
  NET_ADDR="$NET$SUBNET_MASK"

echo -e $tcLtC ""$ip_link"[$ADDR_LINK]"$tcRESET" <-"$tcORANGE"MTU[$MTU]"$tcRESET"-> "$tcORANGE"Net[$NET_ADDR]"$tcRESET" LINK[$FINALSTATElink$tcRESET]"
echo -e $tcLtG " "$tcLtC"->"$tcRESET" RXS: $RXlink $RXERRlink BUFFER:$RXBUFFlink"
echo -e $tcLtG " "$tcORANGE"<-"$tcRESET" TXS: $TXlink $TXERRlink BUFFER:$TXBUFFlink"
echo -e $tcLtG "--------------------------------------------------------------------------"

done
}

# OUTPUT
echo -e $tcLtG "--------------------------------------------------------------------------"
echo -e $tcLtG "$tcLtGRN $COMPANY.                                      Good $TIME, $(whoami)!"
echo -e $tcLtG "--------------------------------------------------------------------------"
echo -e $tcLtG " - Hostname      :$tcW $(hostname -f)"
echo -e $tcLtG " - Release       :$tcW $RELEASE"
echo -e $tcLtG " - Kernel        : $(uname -a | awk '{print $1" "$3" "$12}')"
echo -e $tcLtG " - Users         : Currently $USERS $USERCOUNT logged on"
echo -e $tcLtG " - Server Time   : $(date)"
echo -e $tcLtG " - System load   : $SYS_LOADS / $NUM_PROCS processes running"
echo -e $tcLtG " - Memory used   : $MEMORY_USED %"
echo -e $tcLtG " - Swap used     : $SWAP_USED"
check_service
echo -e $tcLtG " - System uptime : $upDays days $upHours hours $upMins minutes"
echo -e $tcLtG "--------------------------------------------------------------------------"
check_ha
echo -e $tcLtG " $(hostname -f) interface list:"
echo -e $tcLtG "--------------------------------------------------------------------------"
check_ip_link
echo -e $tcW   " Contacts: $CONTACTS"
echo -e $tcRESET ""
#