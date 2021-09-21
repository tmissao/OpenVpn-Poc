#! /bin/bash

source ./variables.sh

# Setup easy-rsa data and permissions
ln -sf /usr/share/easy-rsa/* $RSA_FOLDER
sudo chown ${USER} $RSA_FOLDER
sudo chmod -R 700 $RSA_FOLDER
cd $RSA_FOLDER
cp /tmp/rsa_values $RSA_VARS_FILE

# Creates Public Key Infrastructure (PKI) and
# Generates Server PrivateKey and Certificate Request
printf '\n' | ./easyrsa init-pki
printf '\n' | ./easyrsa gen-req server nopass
sudo cp ./pki/private/server.key /etc/openvpn/server/

# Creates Certificate Authority
printf '\n' | ./easyrsa build-ca nopass

# Signs Certificate Request
printf 'yes' | ./easyrsa sign-req server server

# Move Certificates to OpenVPN
sudo cp ./pki/issued/server.crt /etc/openvpn/server/
sudo cp ./pki/ca.crt /etc/openvpn/server/
