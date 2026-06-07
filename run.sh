#!/bin/bash
read -p "Enter SNI [www.twitch.tv]: " SNI
SNI=${SNI:-www.twitch.tv}

read -p "Enter user count [1]: " USER_COUNT
USER_COUNT=${USER_COUNT:-1}

read -p "Enable WARP? [y/N]: " WGCF_INPUT
if [[ "$WGCF_INPUT" =~ ^[Yy]$ ]]; then
    USE_WGCF="true"
else
    USE_WGCF="false"
fi

apt install -y docker.io git
git clone https://github.com/dandriano/xtls-proxy.git

docker build -t xtls-proxy xtls-proxy
docker run -d \
           -p 443:443 \
           -e SNI="$SNI" \
           -e USER_COUNT="$USER_COUNT" \
           -e USE_WGCF="$USE_WGCF" \
           --restart=unless-stopped \
           --tmpfs /var/log/xray:size=5m \
           --tmpfs /tmp:size=5m \
           --log-opt max-size=1m \
           --log-opt max-file=1 \
           --name xtls-proxy \
           xtls-proxy

# docker logs -f xtls-proxy
