#! /bin/bash -ex

IPTABLES_PATH=$(command -v iptables)
PROTOCOL=${OPENVPN_PROTOCOL}
PORT=${OPENVPN_PORT}

echo "[Unit]
Before=network.target
[Service]
Type=oneshot
ExecStart=$IPTABLES_PATH -t nat -A POSTROUTING -s ${OPENVPN_ADDRESS} ! -d ${OPENVPN_ADDRESS} -j SNAT --to ${IP}
ExecStart=$IPTABLES_PATH -I INPUT -p $PROTOCOL --dport $PORT -j ACCEPT
ExecStart=$IPTABLES_PATH -I FORWARD -s ${OPENVPN_ADDRESS} -j ACCEPT
ExecStart=$IPTABLES_PATH -I FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
ExecStop=$IPTABLES_PATH -t nat -D POSTROUTING -s ${OPENVPN_ADDRESS} ! -d ${OPENVPN_ADDRESS} -j SNAT --to ${IP}
ExecStop=$IPTABLES_PATH -D INPUT -p $PROTOCOL --dport $PORT -j ACCEPT
ExecStop=$IPTABLES_PATH -D FORWARD -s ${OPENVPN_ADDRESS} -j ACCEPT
ExecStop=$IPTABLES_PATH -D FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
RemainAfterExit=yes
[Install]
WantedBy=multi-user.target" |  sudo tee /etc/systemd/system/openvpn-iptables.service

sudo systemctl enable --now openvpn-iptables.service