#!/bin/bash

apt update
apt install wget curl openssl binutils -y
clear


read -p "Input domain: " domain
echo -e "$domain" > /root/.domain

# Create ssh websocket
wget -O /usr/local/bin/ssh-ws "https://github.com/risqinf/websocket-proxy/releases/download/v1.1/ssh-ws.x86"
chmod +x /usr/local/bin/ssh-ws
cat <<EOF> /etc/systemd/system/ssh-ws.service
Description=WS Service
Documentation=https://github.com/risqinf/websocket-proxy
After=network.target nss-lookup.target

[Service]
User=www-data
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/ssh-ws -b 0.0.0.0 -p 700 -t 127.0.0.1:143 -l /var/log/ssh-ws.log
Restart=on-failure
RestartPreventExitStatus=23
LimitNPROC=10000
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable ssh-ws
systemctl start ssh-ws

# Install TLS Multiplex
apt install sslh -y
systemctl stop sslh
systemctl disable sslh
cat <<EOF> /etc/default/sslh
# Default options for sslh initscript
# sourced by /etc/init.d/sslh

# binary to use: forked (sslh) or single-thread (sslh-select) version
# systemd users: don't forget to modify /lib/systemd/system/sslh.service
DAEMON=/usr/sbin/sslh

DAEMON_OPTS="--listen 0.0.0.0:443 --tls 127.0.0.1:700 --http 127.0.0.1:700"
EOF
systemctl daemon-reload
systemctl enable sslh
systemctl start sslh

# Install 
