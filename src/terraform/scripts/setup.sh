#! /bin/bash -ex
# https://medium.com/@bjammal/site-to-site-vpn-on-a-single-host-using-openvpn-e9c5cdb22f92
# https://askubuntu.com/questions/338857/automatically-enter-input-in-command-line
# https://forums.openvpn.net/viewtopic.php?t=8819
# https://www.digitalocean.com/community/tutorials/how-to-set-up-an-openvpn-server-on-ubuntu-14-04

set -o pipefail;

apt update
apt install openvpn easy-rsa bind9 azure-cli -y

USER_HOME="/home/${USER}"
RSA_FOLDER="$USER_HOME/easy-rsa"
RSA_VARS_FILE="vars"
CLIENT_CONFIG_FOLDER="$USER_HOME/client-configs"
CLIENT_MAKE_CONFIG_PATH="$CLIENT_CONFIG_FOLDER/make_config.sh"
CLIENT_CONFIG_KEYS_PATH="$CLIENT_CONFIG_FOLDER/keys"
CLIENT_CONFIG_FILES_PATH="$CLIENT_CONFIG_FOLDER/files"
CLIENT="tiagomissao"

# Setup easy-rsa data and permissions
su - ${USER} -c "
mkdir $RSA_FOLDER
ln -s /usr/share/easy-rsa/* $RSA_FOLDER
sudo chown ${USER} $RSA_FOLDER
sudo chmod -R 700 $RSA_FOLDER
cd $RSA_FOLDER
echo ${RSA_CA_VALUES} | base64 --decode > $RSA_VARS_FILE
"

# Creates Public Key Infrastructure (PKI) and
# Generates Server PrivateKey and Certificate Request
su - ${USER} -c "
cd $RSA_FOLDER
./easyrsa init-pki
printf '\n' | ./easyrsa gen-req server nopass
sudo cp ./pki/private/server.key /etc/openvpn/server/
"

# Creates Certificate Authority
su - ${USER} -c "
cd $RSA_FOLDER
printf '\n' | ./easyrsa build-ca nopass
"

# Signs Certificate Request
su - ${USER} -c "
cd $RSA_FOLDER
printf 'yes' | ./easyrsa sign-req server server
"

# Move Certificates to OpenVPN
su - ${USER} -c "
cd $RSA_FOLDER
sudo cp ./pki/issued/server.crt /etc/openvpn/server/
sudo cp ./pki/ca.crt /etc/openvpn/server/
"

# Creates OpenVPN Cryptography
su - ${USER} -c "
cd $RSA_FOLDER
openvpn --genkey --secret ta.key
sudo cp ./ta.key /etc/openvpn/server/
"

# Creates Client Configs Directory
su - ${USER} -c "
mkdir -p $CLIENT_CONFIG_KEYS_PATH
mkdir -p $CLIENT_CONFIG_FILES_PATH
cp $RSA_FOLDER/ta.key $CLIENT_CONFIG_KEYS_PATH
sudo cp /etc/openvpn/server/ca.crt $CLIENT_CONFIG_KEYS_PATH
sudo chmod -R 700 $CLIENT_CONFIG_FOLDER
sudo chown ${USER} $CLIENT_CONFIG_FOLDER
echo ${OPENVPN_CLIENT_CONF_VALUES} | base64 --decode > $CLIENT_CONFIG_FOLDER/base.conf
sudo chmod -R 700 $CLIENT_CONFIG_FILES_PATH
sudo chmod -R 700 $CLIENT_CONFIG_FOLDER/base.conf
sudo chown ${USER} $CLIENT_CONFIG_FILES_PATH
"

cat <<EOF > $CLIENT_MAKE_CONFIG_PATH
#!/bin/bash

# First argument: Client identifier

KEY_DIR=$CLIENT_CONFIG_KEYS_PATH
OUTPUT_DIR=$CLIENT_CONFIG_FILES_PATH
BASE_CONFIG=$CLIENT_CONFIG_FOLDER/base.conf

cat \$BASE_CONFIG \
    <(echo -e '<ca>') \
    \$KEY_DIR/ca.crt \
    <(echo -e '</ca>\n<cert>') \
    \$KEY_DIR/\$1.crt \
    <(echo -e '</cert>\n<key>') \
    \$KEY_DIR/\$1.key \
    <(echo -e '</key>\n<tls-crypt>') \
    \$KEY_DIR/ta.key \
    <(echo -e '</tls-crypt>') \
    > \$OUTPUT_DIR/\$1.ovpn
EOF
chown ${USER}.${USER} $CLIENT_MAKE_CONFIG_PATH
chmod -R 700 $CLIENT_MAKE_CONFIG_PATH

# Creates Client Certificate
# This should be a pipeline
su - ${USER} -c "
cd $RSA_FOLDER
printf '\n' | ./easyrsa gen-req $CLIENT nopass
cp ./pki/private/$CLIENT.key $CLIENT_CONFIG_KEYS_PATH
printf 'yes' | ./easyrsa sign-req client $CLIENT
cp ./pki/issued/$CLIENT.crt $CLIENT_CONFIG_KEYS_PATH
sudo chown ${USER}.${USER} ~/client-configs/keys/*
. $CLIENT_MAKE_CONFIG_PATH $CLIENT
"

# OPENVPN configuration
echo ${OPENVPN_SERVER_CONF_VALUES} | base64 --decode > "/etc/openvpn/server/server.conf"

# Allows Virtual Machine forward traffic
echo "net.ipv4.ip_forward = 1" > "/etc/sysctl.conf"
sysctl -p

IP=$(ip -4 addr | grep inet | grep -vE '127(\.[0-9]{1,3}){3}' | cut -d '/' -f 1 | grep -oE '[0-9]{1,3}(\.[0-9]{1,3}){3}')
IPTABLES_PATH=$(command -v iptables)
PROTOCOL=${OPENVPN_PROTOCOL}
PORT=${OPENVPN_PORT}

echo "[Unit]
Before=network.target
[Service]
Type=oneshot
ExecStart=$IPTABLES_PATH -t nat -A POSTROUTING -s ${OPENVPN_ADDRESS} ! -d ${OPENVPN_ADDRESS} -j SNAT --to $IP
ExecStart=$IPTABLES_PATH -I INPUT -p $PROTOCOL --dport $PORT -j ACCEPT
ExecStart=$IPTABLES_PATH -I FORWARD -s ${OPENVPN_ADDRESS} -j ACCEPT
ExecStart=$IPTABLES_PATH -I FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
ExecStop=$IPTABLES_PATH -t nat -D POSTROUTING -s ${OPENVPN_ADDRESS} ! -d ${OPENVPN_ADDRESS} -j SNAT --to $IP
ExecStop=$IPTABLES_PATH -D INPUT -p $PROTOCOL --dport $PORT -j ACCEPT
ExecStop=$IPTABLES_PATH -D FORWARD -s ${OPENVPN_ADDRESS} -j ACCEPT
ExecStop=$IPTABLES_PATH -D FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT" > /etc/systemd/system/openvpn-iptables.service

echo "RemainAfterExit=yes
[Install]
WantedBy=multi-user.target" >> /etc/systemd/system/openvpn-iptables.service

echo ${BIND9_VALUES} | base64 --decode > /etc/bind/named.conf.options

# the bind9 service is an alias for named service
systemctl enable named # done
systemctl enable --now openvpn-iptables.service
systemctl -f enable openvpn-server@server.service
systemctl restart bind9 # done
systemctl start openvpn-server@server.service