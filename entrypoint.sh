#!/bin/sh
LOCKFILE=config/.lockfile

# Update always, for rebuilds
sed -i 's|"dest": ""|"dest": "'"${SNI}"':443"|' config/config.json
sed -i 's|"serverNames": \[""\]|"serverNames": \["'"${SNI}"'"\]|' config/config.json
sed -i 's|"shortIds": \["aabbccdd"\]|"shortIds": \["'"${SHORT_ID}"'"\]|' config/config.json

if [ ! -f "$LOCKFILE" ]; then
  # Update once
  ./xray uuid > config/uuid
  ./xray x25519 > config/keys
  
  EXT_IP=$(curl -s ifconfig.me)
  UUID=$(cat config/uuid)
  PRIVATE=$(awk '/PrivateKey:/{print $2}' config/keys)
  PUBLIC=$(awk '/Password:/{print $2}' config/keys)
  
  sed -i 's|"id": ""|"id": "'"${UUID}"'"|' config/config.json
  sed -i 's|"privateKey": ""|"privateKey": "'"${PRIVATE}"'"|' config/config.json
  
  touch "$LOCKFILE"

  # Show configuration once
  VLESS_URL="vless://${UUID}@${EXT_IP}:443?type=tcp&security=reality&flow=xtls-rprx-vision&pbk=${PUBLIC}&fp=firefox&sni=${SNI}&sid=${SHORT_ID}&spx=%2F#xtls-proxy"
  
  echo "================================================"
  echo "XTLS-PROXY Configuration:"
  echo "================================================"
  echo ""
  echo "Server: ${EXT_IP}:443"
  echo "UUID: ${UUID}"
  echo "Public Key: ${PUBLIC}"
  echo "SNI: ${SNI}"
  echo "Short ID: ${SHORT_ID}"
  echo ""
  echo "Raw connection string:"
  echo "${VLESS_URL}"
  echo ""
  echo "================================================"
fi

./xray run -config config/config.json