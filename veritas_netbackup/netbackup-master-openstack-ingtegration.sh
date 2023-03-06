#!/bin/bash

#CONFIGURE THIS PARAMS
ACCESS_PROTO="https://"
AUTH_SUB_URL="auth/tokens"
OS_MGMT_INT_TYPE="public"
API_VER="2"
REGION="OS_CRED"
source /root/regions/$REGION
adminproj="PROJECT"
backupproj="PROJECT"
# Do not edit the deployer passwd.
deployerpasswd="PASSWD"
# Do not edit the backup_admin passwd.
bkppasswd="PASSWD"

echo "Collecting data for OpenStack BCPA network.."
#AGENTLESS NETWORK PARAMS | VLAN = 0000
BCPS_NET_ID=$(openstack network list --max-width 180 | grep BCPS | awk '{print $2}')
BCPS_NET_NAME=$(openstack network list --max-width 180 | grep BCPS | awk '{print $4}')
BCPS_SUB_ID=$(openstack subnet list --max-width 180 | grep BCPS | awk '{print $2}')
BCPS_SUB_NAME=$(openstack subnet list --max-width 180 | grep BCPS | awk '{print $4}')
BCPS_SUB_CIDR=$(openstack subnet show --max-width 180 $BCPS_SUB_ID | grep cidr | awk '{print $4}')
BCPS_SUB_GW=$(openstack subnet show --max-width 180 $BCPS_SUB_ID | grep "gateway_ip" | awk '{print $4}')
#Network address of netbackup master server. Value - cidr of the master network. 
BCPS_SUB_DST_ADDR="11.22.33.44/11"
echo "Done.."

echo "Collecting data for OpenStack BCPS network.."
#AGENT NETWORK PARAMS | VLAN = 0000
BCPA_NET_ID=$(openstack network list --max-width 180 | grep BCPA | awk '{print $2}')
BCPA_NET_NAME=$(openstack network list --max-width 180 | grep BCPA | awk '{print $4}')
BCPA_SUB_ID=$(openstack subnet list --max-width 180 | grep BCPA | awk '{print $2}')
BCPA_SUB_NAME=$(openstack subnet list --max-width 180 | grep BCPA | awk '{print $4}')
BCPA_SUB_CIDR=$(openstack subnet show --max-width 180 $BCPA_SUB_ID | grep cidr | awk '{print $4}')
BCPA_SUB_GW=$(openstack subnet show --max-width 180 $BCPA_SUB_ID | grep "gateway_ip" | awk '{print $4}')
#Network address of netbackup master server. Value - cidr of the master network. 
BCPA_SUB_DST_ADDR="11.22.33.44/11"
echo "Done.."

#Create users
echo "Creating users deployer and backup_admin.."
openstack user create deployer --project $adminproj --password $deployerpasswd --email user1@example.com --enable --max-width 100 --or-show 
openstack user create backup_admin --project $adminproj --password $bkppasswd --email netbackup@example.com --enable --max-width 100 --or-show
echo "Done.."
#Create projects
echo "Creating projects $backupproj .."
openstack project create $backupproj --description "NETBACKUP TENANT" --enable
echo "Done.."
#Add user roles
echo "Adding roles.."
openstack role add admin --project $adminproj --user user
openstack role add admin --project $backupproj --user user
openstack role add admin --project $backupproj --user user
openstack role add member --project $backupproj --user user
openstack role add admin --project $adminproj --user user
openstack role add member --project $adminproj --user user
openstack role add admin --project $backupproj --user user
openstack role add member --project $backupproj --user user
echo "Done.."
#Setting subnet BCPS Route
echo "Adding subnet route to backup master net"
openstack subnet set $BCPS_SUB_ID --host-route destination=$BCPS_SUB_DST_ADDR,gateway=$BCPS_SUB_GW
openstack subnet set $BCPA_SUB_ID --host-route destination=$BCPA_SUB_DST_ADDR,gateway=$BCPA_SUB_GW
echo "Done.."

#Echo network parameters for terraform
echo -e "--------------------------------------------------------"
echo -e "See BCPA network parameters for terraform usage on $backupproj"
echo -e "------------------------- BCPA -------------------------\nnet:$BCPA_NET_NAME\nsub:$BCPA_SUB_NAME\ncidr:$BCPA_SUB_CIDR\n-------------------------------------------------------"
echo -e "See BCPS network parameters for terraform usage on $backupproj"
echo -e "------------------------- BCPS -------------------------\nnet:$BCPS_NET_NAME\nsub:$BCPS_SUB_NAME\ncidr:$BCPS_SUB_CIDR\n--------------------------------------------------------"

# Generate config for master server
echo -e "\nGenerate config for master netbackup server based on created tenant $backupproj.."
CONETPTH=/root/netbackup_master_configs
CONFIGNAME="CONFIG"
NBKCFGMASTER="/usr/openv/var/global/$CONFIGNAME"

echo "Collecting data for OpenStack Endpoint addr.."
backupprojid=$(openstack project list | grep "$backupproj" | awk '{print $2}')
ENDPHOST=$(openstack endpoint list | grep "int.ksc\|int.zq" | grep keystone | grep internal | awk '{print $14'} | sed --regexp-extended 's|:[0-9]+||' | sed 's|^\(https\:\/\/\)||')
ENDPADDR=$(grep $ENDPHOST /etc/hosts | awk '{print $1}')
echo "Done.."

echo -e "Sup! Config will be storaged on $(hostname -f) in $CONETPTH/$CONFIGNAME"
mkdir -p $CONETPTH
touch $CONETPTH/$CONFIGNAME

#GENERATE CONFIG

echo -e "{" > $CONETPTH/$CONFIGNAME
echo -e "\"$ENDPADDR\_backup_admin_name\":\"backup_admin\"," >> $CONETPTH/$CONFIGNAME
echo -e "\"$ENDPADDR\_backup_admin_domain_name\":\"default\"," >> $CONETPTH/$CONFIGNAME
echo -e "\"$ENDPADDR\_backup_admin_password\":\"$bkppasswd\"," >> $CONETPTH/$CONFIGNAME
echo -e "\"$ENDPADDR\_backup_admin_project_name\":\"$backupproj\"," >> $CONETPTH/$CONFIGNAME
echo -e "\"$ENDPADDR\_backup_admin_project_id\":\"$backupprojid\"," >> $CONETPTH/$CONFIGNAME
echo -e "\"$ENDPADDR\_backup_admin_project_domain_name\":\"default\"," >> $CONETPTH/$CONFIGNAME
echo -e "" >> $CONETPTH/$CONFIGNAME
echo -e "\"$ENDPADDR\_management_interface\":\"$OS_MGMT_INT_TYPE\"," >> $CONETPTH/$CONFIGNAME
echo -e "\"$ENDPADDR\_volume_api_version\":\"$API_VER\"," >> $CONETPTH/$CONFIGNAME
echo -e "\"$ENDPADDR\_ep_keystone\":\"https://$ENDPADDR:5000/v3\"," >> $CONETPTH/$CONFIGNAME
echo -e "\"$ENDPADDR\_os_access_protocol\":\"$ACCESS_PROTO\"," >> $CONETPTH/$CONFIGNAME
echo -e "\"$ENDPADDR\_domain_id\":\"default\"," >> $CONETPTH/$CONFIGNAME
echo -e "\"$ENDPADDR\_auth_sub_url\":\"$AUTH_SUB_URL\"," >> $CONETPTH/$CONFIGNAME
echo -e "\"$ENDPADDR\_ep_compute\":\"https://$ENDPADDR:8774\"," >> $CONETPTH/$CONFIGNAME
echo -e "\"$ENDPADDR\_ep_volume\":\"https://$ENDPADDR:8776\"," >> $CONETPTH/$CONFIGNAME
echo -e "\"$ENDPADDR\_ep_volumesnapshot\":\"https://$ENDPADDR:8776\"," >> $CONETPTH/$CONFIGNAME
echo -e "\"$ENDPADDR\_ep_network\":\"https://$ENDPADDR:9696\"," >> $CONETPTH/$CONFIGNAME
echo -e "\"$ENDPADDR\_ep_image\":\"https://$ENDPADDR:9292\"," >> $CONETPTH/$CONFIGNAME
echo -e "" >> $CONETPTH/$CONFIGNAME
echo -e "\"$ENDPADDR\_$backupprojid\": {\"keystone_user\":\"backup_admin\", \"keystone_password\":\"$bkppasswd\", \"keystone_user_domain_name\":\"default\", \"project_domain_name\":\"default\", \"project_name\":\"$backupproj\"}," >> $CONETPTH/$CONFIGNAME
echo -e "" >> $CONETPTH/$CONFIGNAME
echo -e "\"$ENDPADDR\_$backupproj\": {\"keystone_user\":\"backup_admin\",\"keystone_password\":\"$bkppasswd\", \"keystone_user_domain_name\":\"default\", \"project_domain_name\":\"default\", \"project_name\":\"$backupproj\"}" >> $CONETPTH/$CONFIGNAME
echo -e "" >> $CONETPTH/$CONFIGNAME
echo -e "}" >> $CONETPTH/$CONFIGNAME

echo "Finally prepare config in progress.."
sed -i 's|\(\\_\)|_|g' $CONETPTH/$CONFIGNAME
echo "Done."

echo -e "Done. New config stored in $CONETPTH/$CONFIGNAME"

echo "Start sending config to the master host.. Ensure password for privatekey.pem"
scp -rp $CONETPTH/$CONFIGNAME root@backupmaster:$NBKCFGMASTER
