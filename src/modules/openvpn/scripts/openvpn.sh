#! /bin/bash -e

source ./variables.sh

# Creates OpenVPN Cryptography
cd $RSA_FOLDER
openvpn --genkey --secret ta.key
sudo cp ./ta.key /etc/openvpn/server/

# Creates Client Configs Directory
mkdir -p $CLIENT_CONFIG_KEYS_PATH
mkdir -p $CLIENT_CONFIG_FILES_PATH
cp $RSA_FOLDER/ta.key $CLIENT_CONFIG_KEYS_PATH
sudo cp /etc/openvpn/server/ca.crt $CLIENT_CONFIG_KEYS_PATH
sudo chmod -R 700 $CLIENT_CONFIG_FOLDER
sudo chown -R $USER $CLIENT_CONFIG_FOLDER
cp /tmp/base.conf $CLIENT_CONFIG_FOLDER/base.conf
sudo chmod -R 700 $CLIENT_CONFIG_FILES_PATH
sudo chmod -R 700 $CLIENT_CONFIG_FOLDER/base.conf
sudo chown -R $USER.$USER $CLIENT_CONFIG_FILES_PATH

# Creates Client Generate Script
cp /tmp/create_vpn_client.sh $CLIENT_MAKE_CONFIG_PATH
chown $USER.$USER $CLIENT_MAKE_CONFIG_PATH
chmod -R 700 $CLIENT_MAKE_CONFIG_PATH

# Allows Virtual Machine forward traffic
echo "net.ipv4.ip_forward = 1" | sudo tee "/etc/sysctl.conf"
sudo sysctl -p

# OPENVPN configuration X
sudo cp /tmp/server.conf "/etc/openvpn/server/server.conf"

sudo systemctl enable openvpn-server@server.service
sudo systemctl start openvpn-server@server.service