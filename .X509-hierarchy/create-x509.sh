#!/bin/bash

# Assumptions:
# 1) this script assumes that the folders ca/router, ca/intermediate, router, mobile-user-N (where 0 <= N <= 2) and apache pre-exist having a corresponding openssl.cnf scirpt inside.  
# 2) The openssl.cnf used is the one provided with the lab example `x509`, provided as part of the module material.  Therefore, Root's CA openssl.cnf differs from the rest of openssl.cnf, including intermediate.

######### ROOT CA ###########
X509DIR=$PWD
cd ./ca/root/

mkdir certs crl newcerts private unsigned signed
chmod 700 private
touch index.txt
echo 1000 > serial

# create the root ca key (should really be 4096 bits) "ca_secret"
openssl genrsa -aes256 -out private/ca.key.pem 1024
chmod 400 private/ca.key.pem

# create the root cert
openssl req -config ./openssl.cnf \
      -key private/ca.key.pem \
      -new -x509 \
      -days 7300 \
      -sha256 \
      -extensions v3_ca \
      -out certs/ca.cert.pem

# verify the root cert
openssl x509 -noout -text -in certs/ca.cert.pem


######### INTERMEDIATE CA ###########
# prep the intermediate ca dirs
cd ${X509DIR}
cd ./ca/intermediate/

mkdir certs crl newcerts private csr signed unsigned
chmod 700 private
touch index.txt
echo 1000 > serial

echo 1000 > ./crlnumber

# create the intermediate CA key "intermediate_secret"
openssl genrsa -aes256 -out private/intermediate.key.pem 1024
chmod 400 private/intermediate.key.pem

# create the intermediate cert
openssl req -config ./openssl.cnf \
      -new -sha256 \
      -key private/intermediate.key.pem \
      -out csr/intermediate.csr.pem


########## ROOT CA SIGNS INTERMEDIATE CA ##############
# send the intermediate cert csr to the root ca
cd ${X509DIR}
cp ./ca/intermediate/csr/intermediate.csr.pem ./ca/root/unsigned/

# get the intermdiate cert signed by the root cert
cd ./ca/root/
openssl ca -config ./openssl.cnf \
      -extensions v3_intermediate_ca \
      -days 3650 -notext -md sha256 \
      -in unsigned/intermediate.csr.pem \
      -out signed/intermediate.cert.pem
      
# verify the intermediate cert
openssl x509 -noout -text -in signed/intermediate.cert.pem
      
# verify against root cert      
openssl verify -CAfile certs/ca.cert.pem \
      signed/intermediate.cert.pem      
      
# return it to the intermediate ca
cd ${X509DIR}
cp ./ca/root/signed/intermediate.cert.pem ./ca/intermediate/certs/
chmod 444 ./ca/intermediate/certs/intermediate.cert.pem


########## ROUTER ####################
# prep the router dirs
cd ${X509DIR}
cd router
touch ipsec.conf ipsec.secrets
mkdir ipsec
cd ipsec
mkdir cacerts certs csr private
cd ../

# generate the router key (no aes256 this time to permit router unattended restart)
openssl genrsa  -out ipsec/private/router.key.pem 1024
chmod 400 ipsec/private/router.key.pem

# generate the router cert
openssl req -config ./openssl.cnf \
      -key ipsec/private/router.key.pem \
      -new -sha256 \
      -out ipsec/csr/router.csr.pem


######### INTERMDEDIATE CA SIGNS ROUTER CSR #################
# send the router cert csr to the intermediate ca
cd ${X509DIR}
cp ./router/ipsec/csr/router.csr.pem ./ca/intermediate/unsigned/

# get the router cert signed by the intermediate cert
cd ./ca/intermediate/
openssl ca -config ./openssl.cnf \
      -days 375 \
      -notext -md sha256 \
      -in unsigned/router.csr.pem \
      -out signed/router.cert.pem

# verify the cert
openssl x509 -noout -text -in signed/router.cert.pem
 
# return it to the router
cd ${X509DIR}
cp ./ca/intermediate/signed/router.cert.pem ./router/ipsec/certs
chmod 444 ./router/ipsec/certs/router.cert.pem


################# MOBILE-USER-0 ########
# prep the mobile user dirs
cd ${X509DIR}
cd mobile-user-0
touch ipsec.conf ipsec.secrets
mkdir ipsec
cd ipsec
mkdir cacerts certs csr private
cd ../

# generate the first's mobile user key
openssl genrsa  -out ipsec/private/mobile-user-0.key.pem 1024
chmod 400 ipsec/private/mobile-user-0.key.pem

# generate the mobile-user-0 cert
openssl req -config ./openssl.cnf \
      -key ipsec/private/mobile-user-0.key.pem \
      -new -sha256 \
      -out ipsec/csr/mobile-user-0.csr.pem


######### INTERMDEDIATE CA SIGNS MOBILE-USER-0 CSR #################
# send the mobile-user-0 cert csr to the intermediate ca
cd ${X509DIR}
cp ./mobile-user-0/ipsec/csr/mobile-user-0.csr.pem ./ca/intermediate/unsigned/

# get the mobile-user-0 cert signed by the intermediate cert
cd ./ca/intermediate/
openssl ca -config ./openssl.cnf \
      -days 375 \
      -notext -md sha256 \
      -in unsigned/mobile-user-0.csr.pem \
      -out signed/mobile-user-0.cert.pem

# verify the cert
openssl x509 -noout -text -in signed/mobile-user-0.cert.pem
 
# return it to the mobile-user-0
cd ${X509DIR}
cp ./ca/intermediate/signed/mobile-user-0.cert.pem ./mobile-user-0/ipsec/certs  
chmod 444 ./mobile-user-0/ipsec/certs/mobile-user-0.cert.pem


################# MOBILE-USER-1 ########
# prep the mobile user dirs
X509DIR=$PWD
cd ${X509DIR}
cd mobile-user-1
touch ipsec.conf ipsec.secrets
mkdir ipsec
cd ipsec
mkdir cacerts certs csr private
cd ../

# generate the second mobile user key
openssl genrsa  -out ipsec/private/mobile-user-1.key.pem 1024
chmod 400 ipsec/private/mobile-user-1.key.pem

# generate the mobile-user-1 cert
openssl req -config ./openssl.cnf \
      -key ipsec/private/mobile-user-1.key.pem \
      -new -sha256 \
      -out ipsec/csr/mobile-user-1.csr.pem


######### INTERMDEDIATE CA SIGNS MOBILE-USER-1 CSR #################
# send the mobile-user-1 cert csr to the intermediate ca
cd ${X509DIR}
cp ./mobile-user-1/ipsec/csr/mobile-user-1.csr.pem ./ca/intermediate/unsigned/

# get the mobile-user-1 cert signed by the intermediate cert
cd ./ca/intermediate/
openssl ca -config ./openssl.cnf \
      -days 375 \
      -notext -md sha256 \
      -in unsigned/mobile-user-1.csr.pem \
      -out signed/mobile-user-1.cert.pem

# verify the cert
openssl x509 -noout -text -in signed/mobile-user-1.cert.pem
 
# return it to the mobile-user-1
cd ${X509DIR}
cp ./ca/intermediate/signed/mobile-user-1.cert.pem ./mobile-user-1/ipsec/certs  
chmod 444 ./mobile-user-1/ipsec/certs/mobile-user-1.cert.pem


################# MOBILE-USER-2 ########
# prep the mobile user dirs
X509DIR=$PWD
cd ${X509DIR}
cd mobile-user-2
touch ipsec.conf ipsec.secrets
mkdir ipsec
cd ipsec
mkdir cacerts certs csr private
cd ../

# generate the second mobile user key
openssl genrsa  -out ipsec/private/mobile-user-2.key.pem 1024
chmod 400 ipsec/private/mobile-user-2.key.pem

# generate the mobile-user-2 cert
openssl req -config ./openssl.cnf \
      -key ipsec/private/mobile-user-2.key.pem \
      -new -sha256 \
      -out ipsec/csr/mobile-user-2.csr.pem


######### INTERMDEDIATE CA SIGNS MOBILE-USER-2 CSR #################
# send the mobile-user-2 cert csr to the intermediate ca
cd ${X509DIR}
cp ./mobile-user-2/ipsec/csr/mobile-user-2.csr.pem ./ca/intermediate/unsigned/

# get the mobile-user-2 cert signed by the intermediate cert
cd ./ca/intermediate/
openssl ca -config ./openssl.cnf \
      -days 375 \
      -notext -md sha256 \
      -in unsigned/mobile-user-2.csr.pem \
      -out signed/mobile-user-2.cert.pem

# verify the cert
openssl x509 -noout -text -in signed/mobile-user-2.cert.pem
 
# return it to the mobile-user-2
cd ${X509DIR}
cp ./ca/intermediate/signed/mobile-user-2.cert.pem ./mobile-user-2/ipsec/certs  
chmod 444 ./mobile-user-2/ipsec/certs/mobile-user-2.cert.pem


################# APACHE ########
# prep the apache user dirs
X509DIR=$PWD
cd ${X509DIR}
cd apache
touch ipsec.conf ipsec.secrets
mkdir ipsec
cd ipsec
mkdir cacerts certs csr private
cd ../

# generate the apache's private key
openssl genrsa  -out ipsec/private/apache.key.pem 1024
chmod 400 ipsec/private/apache.key.pem

# generate the apache cert
openssl req -config ./openssl.cnf \
      -key ipsec/private/apache.key.pem \
      -new -sha256 \
      -out ipsec/csr/apache.csr.pem


######### INTERMDEDIATE CA SIGNS APACHE CSR #################
# send the apache cert csr to the intermediate ca
cd ${X509DIR}
cp ./apache/ipsec/csr/apache.csr.pem ./ca/intermediate/unsigned/

# get the apache cert signed by the intermediate cert
cd ./ca/intermediate/
openssl ca -config ./openssl.cnf \
      -days 375 \
      -notext -md sha256 \
      -in unsigned/apache.csr.pem \
      -out signed/apache.cert.pem

# verify the cert
openssl x509 -noout -text -in signed/apache.cert.pem
 
# return it to the apache
cd ${X509DIR}
cp ./ca/intermediate/signed/apache.cert.pem ./apache/ipsec/certs  
chmod 444 ./apache/ipsec/certs/apache.cert.pem


######### CREATE PMA HIERARCHY #################
cd ${X509DIR}
mkdir CDP-PMA; cd CDP-PMA
PMA=$PWD

# Creation of CA hierarchy
mkdir ca; cd ca
mkdir etc; cd etc
mkdir ipsec.d; cd ipsec.d
mkdir cacerts private

# Copy certificates and private keys from x509 files to above ca directories
cd ${X509DIR}

# cert copy
cp ca/root/certs/ca.cert.pem CDP-PMA/ca/etc/ipsec.d/cacerts/
cp ca/intermediate/certs/intermediate.cert.pem CDP-PMA/ca/etc/ipsec.d/cacerts/

# key copy
cp ca/root/private/ca.key.pem CDP-PMA/ca/etc/ipsec.d/private/
cp ca/intermediate/private/intermediate.key.pem CDP-PMA/ca/etc/ipsec.d/private/

# Creation of router and mobile-user-N
cd ${PMA}
mkdir router; cd router
mkdir etc; cd etc
mkdir ipsec.d
touch ipsec.conf ipsec.secrets
cd ipsec.d
mkdir cacerts certs private

# Create mobile-users based on the above
cd ${PMA}
cp -r router mobile-user-0
cp -r router mobile-user-1
cp -r router mobile-user-2

# Copy certificates to router accordingly
# cacerts
cd ${X509DIR}
cp ca/root/certs/ca.cert.pem CDP-PMA/router/etc/ipsec.d/cacerts/
cp ca/intermediate/certs/intermediate.cert.pem CDP-PMA/router/etc/ipsec.d/cacerts/

# certs
cp router/ipsec/certs/router.cert.pem CDP-PMA/router/etc/ipsec.d/certs/
cp router/ipsec/certs/router.cert.pem CDP-PMA/mobile-user-0/etc/ipsec.d/certs/
cp router/ipsec/certs/router.cert.pem CDP-PMA/mobile-user-1/etc/ipsec.d/certs/
cp router/ipsec/certs/router.cert.pem CDP-PMA/mobile-user-2/etc/ipsec.d/certs/

# keys
cp router/ipsec/private/router.key.pem CDP-PMA/router/etc/ipsec.d/private/

# Copy certificates to mobile-user-0
# cacerts
cp ca/intermediate/certs/intermediate.cert.pem CDP-PMA/mobile-user-0/etc/ipsec.d/cacerts/

# certs
cp mobile-user-0/ipsec/certs/mobile-user-0.cert.pem CDP-PMA/mobile-user-0/etc/ipsec.d/certs/
cp mobile-user-0/ipsec/certs/mobile-user-0.cert.pem CDP-PMA/router/etc/ipsec.d/certs/

# keys
cp mobile-user-0/ipsec/private/mobile-user-0.key.pem CDP-PMA/mobile-user-0/etc/ipsec.d/private/

# Copy certificates to mobile-user-1
# cacerts
cp ca/intermediate/certs/intermediate.cert.pem CDP-PMA/mobile-user-1/etc/ipsec.d/cacerts/

# certs
cp mobile-user-1/ipsec/certs/mobile-user-1.cert.pem CDP-PMA/mobile-user-1/etc/ipsec.d/certs/
cp mobile-user-1/ipsec/certs/mobile-user-1.cert.pem CDP-PMA/router/etc/ipsec.d/certs/

# keys
cp mobile-user-1/ipsec/private/mobile-user-1.key.pem CDP-PMA/mobile-user-1/etc/ipsec.d/private/

# Copy certificates to mobile-user-2
# cacerts
cp ca/intermediate/certs/intermediate.cert.pem CDP-PMA/mobile-user-2/etc/ipsec.d/cacerts/

# certs
cp mobile-user-2/ipsec/certs/mobile-user-2.cert.pem CDP-PMA/mobile-user-2/etc/ipsec.d/certs/
cp mobile-user-2/ipsec/certs/mobile-user-2.cert.pem CDP-PMA/router/etc/ipsec.d/certs/

# keys
cp mobile-user-2/ipsec/private/mobile-user-2.key.pem CDP-PMA/mobile-user-2/etc/ipsec.d/private/

# Create Apache directory
cd ${PMA}
mkdir apache; cd apache
mkdir etc; cd etc
mkdir apache2; cd apache2
mkdir sites-available ssl; cd ssl

# Copy apache certicates
cd ${X509DIR}
cp apache/ipsec/certs/apache.cert.pem CDP-PMA/apache/etc/apache2/ssl/
cp apache/ipsec/private/apache.key.pem CDP-PMA/apache/etc/apache2/ssl/

echo "/// SCRIPT FINISHED SUCCESSFULLY! ///"
