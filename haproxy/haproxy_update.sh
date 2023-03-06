#!/bin/bash

HAPROXYPATH=/etc/haproxy
HOMER=/root
INSTALLDIR=$HOMER/haproxy_install
NEW=haproxy-2.0.13

#Backup create
echo -e "\n\n\n\nStart create backup haproxy dir"
mkdir -p $HOMER/backup/
cp -rp $HAPROXYPATH/ $HOMER/backup/

#Prepar old haproxy
echo -e "\n\n\n\nStop old haproxy"
systemctl stop haproxy && systemctl status haproxy

echo -e "\n\n\n\nRemove old haproxy package"
yum remove haproxy -y

#Install prereq for haproxy
echo -e "\n\n\n\nInstall prereq for haproxy"
yum install gcc pcre-static pcre-devel openssl-devel -y

#Install new HAProxy
echo -e "\n\n\n\n install new haproxy. New ver = $NEW"
echo -e "\n\n\n\nCreate dir for install"
mkdir -p $INSTALLDIR/

echo -e "\n\n\n\nDownload HAPROXY=$NEW"
cd $INSTALLDIR
wget http://www.haproxy.org/download/2.0/src/haproxy-2.0.13.tar.gz

echo -e "\n\n\n\nUNPACK HAPROXY SRC"
tar -xzvf $INSTALLDIR/haproxy-2.0.13.tar.gz -C $INSTALLDIR/
cd $INSTALLDIR/$NEW/

echo -e "\n\n\n\nMAKE PREREQS..."
make TARGET=linux-glibc USE_PCRE=1 USE_OPENSSL=1 USE_ZLIB=1 USE_CRYPT_H=1 USE_LIBCRYPT=1

echo -e "\n\n\n\nMAKE INSTALL HAPROXY..."
make install

mkdir -p /etc/haproxy
mkdir -p /var/lib/haproxy
ln -s /usr/local/sbin/haproxy /usr/sbin/haproxy
cp examples/haproxy.init /etc/init.d/haproxy
chmod 755 /etc/init.d/haproxy
systemctl daemon-reload
chkconfig haproxy on
useradd -r haproxy
haproxy -v

yes | cp -rp $HOMER/backup/haproxy/* $HAPROXYPATH/

haproxy -f $HAPROXYPATH/haproxy.cfg

systemctl start haproxy && systemctl enable haproxy && systemctl status haproxy
