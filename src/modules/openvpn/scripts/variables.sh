#! /bin/bash -e

export USER_HOME="$HOME"
export RSA_FOLDER="$USER_HOME/easy-rsa"
export RSA_VARS_FILE="vars"
export CLIENT_CONFIG_FOLDER="$USER_HOME/client-configs"
export CLIENT_MAKE_CONFIG_PATH="$CLIENT_CONFIG_FOLDER/make_config.sh"
export CLIENT_CONFIG_KEYS_PATH="$CLIENT_CONFIG_FOLDER/keys"
export CLIENT_CONFIG_FILES_PATH="$CLIENT_CONFIG_FOLDER/files"

mkdir -p $RSA_FOLDER
mkdir -p $CLIENT_CONFIG_KEYS_PATH
mkdir -p $CLIENT_CONFIG_FILES_PATH