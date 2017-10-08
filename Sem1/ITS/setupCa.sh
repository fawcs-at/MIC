#!/bin/bash
function createClient() 
{
	echo -e "\e[32m ~~~ Createing Client $1 ~~~ \e[0m"
	#create a client 
	client=$1
	type=$2
	#create Key
	openssl genrsa -out private/$client.key.pem 4096
	#csr	
	openssl req -new \
    -config intermediate.conf \
	-key private/$client.key.pem \
	-subj "/C=AT/ST=Vienna/L=Vienna/O=fh-technikum/OU=MIC/CN=$client" \
    -out csr/$client.csr.pem
	
	
	#sign the cert
	openssl ca \
    -config intermediate.conf \
    -in csr/$client.csr.pem \
    -out certs/$client.crt.pem \
	-subj "/C=AT/ST=Vienna/L=Vienna/O=fh-technikum/OU=MIC/CN=$client" \
	-passin pass:pass \
    -extensions $type
	
	#der & pkcs#12
	openssl x509 -in certs/$client.crt.pem -out certs/$client.crt.pem.der -outform DER 
	openssl pkcs12 -export -in certs/$client.crt.pem -inkey private/$client.key.pem -out certs/$client.crt.pem.p12 -passout pass:pass -passin pass:pass
	ls -lisa certs | grep --color $client
	
}



echo -e "\e[32m ~~~ Setup RootCA - DIRs ~~~ \e[0m"
mkdir -p /opt/fh/CA
cd /opt/fh/CA

mypath=$(pwd)
echo $mypath

mkdir FHCA
cd FHCA

#create directories:
mkdir -p certs crl newcerts private csr


touch .db
openssl rand -hex 16 > .serial
openssl rand -hex 16 > .crlnumber
#create config file:
 
cat << EOF > rootCA.conf
#ROOT
[ ca ]
default_ca = ca_default

[default]
name                    = root

[ ca_default ] 
# Directory and file locations.
dir               = $(pwd)
certs             = \$dir/certs
crl_dir           = \$dir/crl
csr_dir			  = \$dir/csr
new_certs_dir     = \$dir/newcerts
database          = \$dir/.db
serial            = \$dir/.serial
RANDFILE          = \$dir/private/.rand

# The root key and root certificate.
private_key       = \$dir/private/ca.key.pem
certificate       = \$dir/certs/ca.crt.pem

# For certificate revocation lists.
crlnumber         = \$dir/.crlnumber
crl               = \$dir/crl/ca.crl
crl_extensions    = crl_ext
default_crl_days  = 30

default_md        = sha256

# Extension to add when the -x509 option is used.
#x509_extensions     = ca_ext

name_opt          = ca_default
cert_opt          = ca_default
default_days      = 1000
preserve          = no
policy            = policy_strict
email_in_dn		  = no

[ policy_strict ]
countryName             = match
stateOrProvinceName     = match
organizationName        = match
organizationalUnitName  = match
commonName              = supplied
emailAddress            = optional


[ req ]
default_bits        = 4096
distinguished_name  = req_distinguished_name
string_mask         = utf8only
default_md          = sha256


[ req_distinguished_name ]
#specify some defaults.
countryName_default             = AT
stateOrProvinceName_default     = Vienna
localityName_default            = Vienna
0.organizationName_default      = fh-technikum
organizationalUnitName_default 	= MIC


[ ca_ext ]
# Extensions for a typical CA 
subjectKeyIdentifier = hash
basicConstraints = critical, CA:true
keyUsage = critical, digitalSignature, cRLSign, keyCertSign



[ sub_ca_ext ]
authorityKeyIdentifier  = keyid:always
basicConstraints        = critical,CA:true,pathlen:0
extendedKeyUsage        = clientAuth,serverAuth
keyUsage                = critical,keyCertSign,cRLSign
subjectKeyIdentifier    = hash

[ crl_ext ]
# CRL extensions.
# Only issuerAltName and authorityKeyIdentifier make any sense in a CRL.
# issuerAltName=issuer:copy
authorityKeyIdentifier=keyid:always


EOF

cat << EOF > intermediate.conf
#Intermediate
[ ca ]
default_ca = ca_default
[default]
name                    = intermediate
[ ca_default ] 
# Directory and file locations.
dir               = $(pwd)
certs             = \$dir/certs
crl_dir           = \$dir/crl
csr_dir			  = \$dir/csr
new_certs_dir     = \$dir/newcerts
database          = \$dir/.db
serial            = \$dir/.serial
RANDFILE          = \$dir/private/.rand

# The root key and root certificate.
private_key       = \$dir/private/intermediate.key.pem
certificate       = \$dir/certs/intermediate.crt.pem

# For certificate revocation lists.
crlnumber         = \$dir/.crlnumber
crl               = \$dir/crl/intermediate.crl
crl_extensions    = crl_ext
default_crl_days  = 30

default_md        = sha256

# Extension to add when the -x509 option is used.
#x509_extensions     = ca_ext

name_opt          = ca_default
cert_opt          = ca_default
default_days      = 365
preserve          = no
policy            = policy_strict
email_in_dn		  = no
copy_extensions         = copy


[ policy_strict ]
countryName             = match
stateOrProvinceName     = match
organizationName        = match
organizationalUnitName  = match
commonName              = supplied
emailAddress            = optional


[ req ]
default_bits        = 4096
distinguished_name  = req_distinguished_name
string_mask         = utf8only
default_md          = sha256


[ req_distinguished_name ]
#specify some defaults.
countryName_default             = AT
stateOrProvinceName_default     = Vienna
localityName_default            = Vienna
0.organizationName_default      = fh-technikum
organizationalUnitName_default 	= MIC


[ ca_ext ]
# Extensions for a typical CA 
subjectKeyIdentifier = hash
basicConstraints = critical, CA:true
keyUsage = critical, digitalSignature, cRLSign, keyCertSign



[ sub_ca_ext ]
authorityKeyIdentifier  = keyid:always
basicConstraints        = critical,CA:true,pathlen:0
extendedKeyUsage        = clientAuth,serverAuth
keyUsage                = critical,keyCertSign,cRLSign
subjectKeyIdentifier    = hash

[ crl_ext ]
# CRL extensions.
# Only issuerAltName and authorityKeyIdentifier make any sense in a CRL.
# issuerAltName=issuer:copy
authorityKeyIdentifier=keyid:always


[server_ext]
authorityKeyIdentifier  = keyid:always
basicConstraints        = critical,CA:false
extendedKeyUsage        = clientAuth,serverAuth
keyUsage                = critical,digitalSignature,keyEncipherment
subjectKeyIdentifier    = hash
subjectAltName			= @altNames

[ altNames ]
DNS.1 = $(hostname)
DNS.2 = localhost
IP.1 = 127.0.0.1
IP.2 = $(ifconfig eth0 | grep "inet addr" | awk '{print $2}' | cut -d":" -f2)


[client_ext]
authorityKeyIdentifier  = keyid:always
basicConstraints        = critical,CA:false
extendedKeyUsage        = clientAuth
keyUsage                = critical,digitalSignature
subjectKeyIdentifier    = hash


EOF

echo -e "\e[32m ~~~ Creating RootCA Key & Cert ~~~ \e[0m"

#Create Key and CSR for Root CA
openssl req -new \
-config rootCA.conf \
-out csr/ca.csr.pem \
-keyout private/ca.key.pem \
-subj "/C=AT/ST=Vienna/L=Vienna/O=fh-technikum/OU=MIC/CN=fhtechnikum.mic.root" \
-passout pass:pass

#sign the certificate
openssl ca -selfsign \
-config rootCA.conf \
-in csr/ca.csr.pem \
-out certs/ca.crt.pem \
-passin pass:pass \
-extensions ca_ext

#create CRL
echo -e "\e[32m ~~~ Creating CRL ~~~ \e[0m"
openssl ca -gencrl \
-config rootCA.conf \
-out crl/root-ca.crl.pem \
-passin pass:pass


echo -e "\e[32m ~~~ Creating Intermediate CA Key & CSR &  sign Cert ~~~ \e[0m"
#create CSR & KEY for Intermediate CA
openssl req -new \
-config intermediate.conf \
-out csr/intermediate.csr.pem \
-keyout private/intermediate.key.pem \
-subj "/C=AT/ST=Vienna/L=Vienna/O=fh-technikum/OU=MIC/CN=fhtechnikum.mic.intermediate" \
-passout pass:pass
#Sign Certificate
openssl ca \
-config rootCA.conf \
-in csr/intermediate.csr.pem \
-out certs/intermediate.crt.pem \
-passin pass:pass \
-extensions sub_ca_ext


echo -e "\e[32m ~~~ Creating CA-Chain ~~~ \e[0m"
#create certificate chain
cat certs/intermediate.crt.pem certs/ca.crt.pem > certs/ca-chain.crt.pem





echo -e "\e[32m ~~~ Add Client Cert ~~~ \e[0m"
#call the create client funtion
createClient $(hostname) "server_ext"

###############################################################################################################################
# ~~~~~~~~~~~~~~~~~ Apache preperation ~~~~~~~~~~~~~~~~~
###############################################################################################################################


echo -e "\e[32m ~~~ prepare Apache ~~~ \e[0m"
#copy files to use it with apache modssl
cp certs/ca.crt.pem /opt/apache2/conf/ca.crt
cp certs/ca-chain.crt.pem /opt/apache2/conf/ca-chain.crt.pem
cp certs/$(hostname).crt.pem /opt/apache2/conf/server.crt.pem
cp private/$(hostname).key.pem /opt/apache2/conf/server.key.pem


echo -e "\e[32m ~~~ Create PKCS#12 files ~~~ \e[0m"

#rootCA
openssl pkcs12 -export -in certs/ca.crt.pem -inkey private/ca.key.pem -out certs/rootCA.crt.pem.p12 -passout pass:pass -passin pass:pass
openssl x509 -in certs/ca.crt.pem -out certs/ca.crt.pem.der -outform DER 
#intermediate
openssl pkcs12 -export -in certs/intermediate.crt.pem -inkey private/intermediate.key.pem -out certs/intermediate.crt.pem.p12 -passout pass:pass -passin pass:pass
openssl x509 -in certs/intermediate.crt.pem -out certs/intermediate.crt.pem.der -outform DER
#ca-chain
openssl pkcs12 -export -in certs/ca-chain.crt.pem -inkey private/intermediate.key.pem -out certs/ca-chain.crt.p12 -passout pass:pass -passin pass:pass
openssl x509 -in certs/ca-chain.crt.pem -out certs/ca-chain.crt.pem.der -outform DER

echo -e "\e[32m ~~~ Copy Certs to Webroot ~~~ \e[0m"
#copy root-ca to www-directory for download via browser	
certWebRoot="/opt/apache2/htdocs/certs"
mkdir -p $certWebRoot
cp certs/* $certWebRoot

echo -e "\e[32m ~~~ Setting Modssl-Settings ~~~ \e[0m"
#setip of eth0 instead of hostname in apache configuration for modssl
varServerName=$(openssl x509 -in certs/$(hostname).crt.pem -subject -noout | cut -d"/" -f6 | cut -d"=" -f2)
sed -i 's/^ServerName.*/ServerName '$varServerName':443/g' /opt/apache2/conf/extra/httpd-ssl.conf

#enable ssl
sed -i 's/^#Include conf\/extra\/httpd-ssl.conf/Include conf\/extra\/httpd-ssl.conf/g' /opt/apache2/conf/httpd.conf
#add and enabled certificate chain
sed -i 's/^#SSLCertificateChainFile/SSLCertificateChainFile/g' /opt/apache2/conf/extra/httpd-ssl.conf
#set SSLCertificateFile
sed -i 's/^SSLCertificateFile.*/SSLCertificateFile "\/opt\/apache2\/conf\/server.crt.pem"/g' /opt/apache2/conf/extra/httpd-ssl.conf
#set SSLCertificateKeyFile
sed -i 's/^SSLCertificateKeyFile.*/SSLCertificateKeyFile "\/opt\/apache2\/conf\/server.key.pem"/g' /opt/apache2/conf/extra/httpd-ssl.conf
#set SSLCertificateChainFile
sed -i 's/^SSLCertificateChainFile.*/SSLCertificateChainFile "\/opt\/apache2\/conf\/ca-chain.crt.pem"/g' /opt/apache2/conf/extra/httpd-ssl.conf



echo -e "\e[32m ~~~ Settings /etc/hosts ~~~ \e[0m"
#add hostname to /etc/hosts
if [[ -z $(cat /etc/hosts | grep $(hostname)) ]];
then
#delete old  hostname
sed -i '/vmwarebase.*/d' /etc/hosts
varHosts=$(echo -e $(ifconfig eth0 | grep "inet addr" | awk '{print $2}' | cut -d":" -f2)"\t\t"$(cat /etc/HOSTNAME)" "$(hostname))
sed  -i "/^127.0.0.1/a \
$varHosts" /etc/hosts
fi

echo -e "\e[32m ~~~ Restart Apache ~~~ \e[0m"
#restart apache
/opt/apache2/bin/apachectl stop
#sleep to make sure apache is shut down
sleep 2	
/opt/apache2/bin/apachectl start

#verify that apache is running on port 80 and 443
netstat -tulpen | grep httpd
