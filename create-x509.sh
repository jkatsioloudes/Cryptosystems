#!/bin/bash

# this script assumes that the folders ca/gateway, ca/intermediate, gateway and mobile worker pre-exist having a corresponding openssl.cnf scirpt inside.


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


########## GATEWAY ####################
# prep the gateway dirs
cd ${X509DIR}
cd gateway
touch ipsec.conf ipsec.conf.x509 ipsec.secrets
mkdir ipsec
cd ipsec
mkdir cacerts certs csr private
cd ../

# generate the gateway key (no aes256 this time to permit gateway unattended restart)
openssl genrsa  -out ipsec/private/gateway.key.pem 1024
chmod 400 ipsec/private/gateway.key.pem

# generate the gateway cert
openssl req -config ./openssl.cnf \
      -key ipsec/private/gateway.key.pem \
      -new -sha256 \
      -out ipsec/csr/gateway.csr.pem


######### INTERMDEDIATE CA SIGNS GATEWAY CSR #################
# send the gateway cert csr to the intermediate ca
cd ${X509DIR}
cp ./gateway/ipsec/csr/gateway.csr.pem ./ca/intermediate/unsigned/

# get the gateway cert signed by the intermediate cert
cd ./ca/intermediate/
openssl ca -config ./openssl.cnf \
      -days 375 \
      -notext -md sha256 \
      -in unsigned/gateway.csr.pem \
      -out signed/gateway.cert.pem

# verify the cert
openssl x509 -noout -text -in signed/gateway.cert.pem
 
# return it to the gateway
cd ${X509DIR}
cp ./ca/intermediate/signed/gateway.cert.pem ./gateway/ipsec/certs
chmod 444 ./gateway/ipsec/certs/gateway.cert.pem


################# MOBILE-WORKER-0 ########
# prep the mobile worker dirs
cd ${X509DIR}
cd mobile-worker-0
touch ipsec.conf ipsec.conf.x509 ipsec.secrets
mkdir ipsec
cd ipsec
mkdir cacerts certs csr private
cd ../

# generate the first's mobile worker key
openssl genrsa  -out ipsec/private/mobile-worker-0.key.pem 1024
chmod 400 ipsec/private/mobile-worker-0.key.pem

# generate the mobile-worker-0 cert
openssl req -config ./openssl.cnf \
      -key ipsec/private/mobile-worker-0.key.pem \
      -new -sha256 \
      -out ipsec/csr/mobile-worker-0.csr.pem


######### INTERMDEDIATE CA SIGNS MOBILE-WORKER-0 CSR #################
# send the mobile-worker-0 cert csr to the intermediate ca
cd ${X509DIR}
cp ./mobile-worker-0/ipsec/csr/mobile-worker-0.csr.pem ./ca/intermediate/unsigned/

# get the mobile-worker-0 cert signed by the intermediate cert
cd ./ca/intermediate/
openssl ca -config ./openssl.cnf \
      -days 375 \
      -notext -md sha256 \
      -in unsigned/mobile-worker-0.csr.pem \
      -out signed/mobile-worker-0.cert.pem

# verify the cert
openssl x509 -noout -text -in signed/mobile-worker-0.cert.pem
 
# return it to the mobile-worker-0
cd ${X509DIR}
cp ./ca/intermediate/signed/mobile-worker-0.cert.pem ./mobile-worker-0/ipsec/certs  
chmod 444 ./mobile-worker-0/ipsec/certs/mobile-worker-0.cert.pem


################# PUT THE ROOT CERT ON ALL CLIENTS ########
cd ${X509DIR}
cp ./ca/root/certs/ca.cert.pem ./gateway/ipsec/cacerts/
cp ./ca/root/certs/ca.cert.pem ./mobile-worker-0/ipsec/cacerts/


echo "/// SCRIPT FINISHED ///"
