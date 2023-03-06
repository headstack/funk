#!/bin/bash

TYPE="$1"

if [[ "$TYPE" = "--agentinstall" ]]; then

NBK="NetBackup_9.0.0.1_RHEL"
RTD=/root 
source $RTD/.bashrc
INDIR=/tmp/backcli
NKBIN=$INDIR/$NBK
LIBA="libaapipgnopenstack.so"
hostn=$(hostname -f)
config=$(ip a s dev eth0 | grep "inet" | grep -v "inet6" | awk '{print $2}' | sed 's|\(\/.*\)||')
NETBACKUP_MASTER="HOSTNAME"

echo -e "$config $hostn" >> /etc/hosts
mkdir -p $INDIR 
yes | cp -rp $RTD/$NBK $INDIR 
cd $NBKIN
printf 'y\n y\n %s\n y\n y\n SERIAL\n 1\n' "$NETBACKUP_MASTER" | "$NBKIN"/install

echo 'ACCEPT_REVERSE_CONNECTION = TRUE' >> /usr/openv/netbackup/bp.conf
/usr/openv/netbackup/bin/bp.kill_all
/usr/openv/netbackup/bin/bp.start_all
bpre
yes | cp -rp $RTD/$LIBA /usr/openv/lib/psf-plugins/openstack/
/usr/openv/netbackup/bin/bp.kill_all
/usr/openv/netbackup/bin/bp.start_all
bpre

elif [[ "$TYPE" = "--agentlessinstall" ]]; then

NBK="NetBackup_9.0.0.1_RHEL" 
RTD=/root 
source $RTD/.bashrc
INDIR=/tmp/backcli
NKBIN=$INDIR/$NBK
LIBA="libaapipgnopenstack.so"
hostn=$(hostname -f)
config=$(ip a s dev eth0 | grep "inet" | grep -v "inet6" | awk '{print $2}' | sed 's|\(\/.*\)||')
NETBACKUP_MASTER="HOSTNAME"

echo -e "$config $hostn" >> /etc/hosts
mkdir -p $INDIR 
yes | cp -rp $RTD/$NBK $INDIR 
cd $NBKIN
printf 'y\n y\n %s\n y\n y\n SERIAL\n 1\n' "$NETBACKUP_MASTER" | "$NBKIN"/install

echo 'ACCEPT_REVERSE_CONNECTION = TRUE' >> /usr/openv/netbackup/bp.conf
/usr/openv/netbackup/bin/bp.kill_all
/usr/openv/netbackup/bin/bp.start_all
bpre
yes | cp -rp $RTD/$LIBA /usr/openv/lib/psf-plugins/openstack/
/usr/openv/netbackup/bin/bp.kill_all
/usr/openv/netbackup/bin/bp.start_all
bpre

else
echo -e "Help usage. Type agentinstall.sh with two one of the two available options:"
echo -e "\"--agentinstall\" - install agent for usage on agent networks like BCPA"
echo -e "\"--agentinstall\" - install agent for usage on agent networks like BCPS"
fi