#!/bin/bash

#download and install openssl (same version as provided via Slack 10.2 packages)

#create workingdir
mkdir -p /opt/fh/src/
cd /opt/fh/src
#download the source
wget https://www.openssl.org/source/old/1.0.2/openssl-1.0.2l.tar.gz
tar xfvz openssl-1*.tar.gz
cd openssl-1*
#read install introductions
cat INSTALL
#configure automatically
./config
#Build, test , install
make
make test
make install
#make openSSL available in the path
ln -s /usr/local/ssl/bin/openssl /usr/bin/openssl

#install apache from source (2.2)
mkdir -p /opt/apache2
wget http://www-us.apache.org/dist//httpd/httpd-2.2*.tar.gz
tar xfvz httpd-2.2*.tar.gz
cd /opt/fh/src/httpd-2.2*
#configure apache and enable modSSL - path to OpenSSL-Installation is needed
./configure --enable-ssl --with-ssl=/usr/local/ssl --prefix=/opt/apache2
make 
make install
