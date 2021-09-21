#!/bin/bash -e

# First argument: Client identifier

source $HOME/variables.sh

KEY_DIR=$CLIENT_CONFIG_KEYS_PATH
OUTPUT_DIR=$CLIENT_CONFIG_FILES_PATH
BASE_CONFIG=$CLIENT_CONFIG_FOLDER/base.conf

cd $RSA_FOLDER
printf 'yes' | ./easyrsa revoke $1
printf '\n' | ./easyrsa gen-req $1 nopass
cp ./pki/private/$1.key $CLIENT_CONFIG_KEYS_PATH
printf 'yes' | ./easyrsa sign-req client $1
cp ./pki/issued/$1.crt $CLIENT_CONFIG_KEYS_PATH
sudo chown $USER.$USER ~/client-configs/keys/*

cat $BASE_CONFIG \
    <(echo -e '<ca>') \
    $KEY_DIR/ca.crt \
    <(echo -e '</ca>\n<cert>') \
    $KEY_DIR/$1.crt \
    <(echo -e '</cert>\n<key>') \
    $KEY_DIR/$1.key \
    <(echo -e '</key>\n<tls-crypt>') \
    $KEY_DIR/ta.key \
    <(echo -e '</tls-crypt>') \
    > $OUTPUT_DIR/$1.ovpn
