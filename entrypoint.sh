#!/bin/bash
LOCKFILE=config/.lockfile

# SNI updates always, for rebuilds (beware)
sed -i 's|"address": ""|"address": "'"${SNI}"'"|' config/config.json
sed -i 's|"domain": \[""\]|"domain": \["'"${SNI}"'"\]|' config/config.json
sed -i 's|"serverNames": \[""\]|"serverNames": \["'"${SNI}"'"\]|' config/config.json

if [ ! -f "$LOCKFILE" ]; then
  # uuids / short ids updates once
  ./xray x25519 > config/keys

  EXT_IP=$(curl -s ifconfig.me)
  PRIVATE=$(awk '/PrivateKey:/{print $2}' config/keys)
  PUBLIC=$(awk '/Password:/{print $2}' config/keys)

  USER_COUNT=${USER_COUNT:-1}
  UUIDS=()
  SHORTIDS=()

  for ((i = 1; i <= USER_COUNT; i++)); do
    uuid=$(./xray uuid)
    shortid=$(openssl rand -hex 4)
    UUIDS+=("$uuid")
    SHORTIDS+=("$shortid")
  done

  # Build clients ids sections
  clients="["
  for uuid in "${UUIDS[@]}"; do
    [ "$clients" != "[" ] && clients="$clients,"
    clients="${clients}{\"id\":\"$uuid\",\"flow\":\"xtls-rprx-vision\"}"
  done
  clients="$clients]"

  # Build shortID section
  shortids="["
  for sid in "${SHORTIDS[@]}"; do
    [ "$shortids" != "[" ] && shortids="$shortids,"
    shortids="${shortids}\"$sid\""
  done
  shortids="$shortids]"

  sed -i 's|"clients": \[[^]]*\]|"clients": '"$clients"'|' config/config.json
  sed -i 's|"shortIds": \[[^]]*\]|"shortIds": '"$shortids"'|' config/config.json
  sed -i 's|"privateKey": ""|"privateKey": "'"${PRIVATE}"'"|' config/config.json

  touch "$LOCKFILE"

  # Show configuration once
  echo "================================================"
  echo "XTLS-PROXY Configuration"
  echo "================================================"
  echo "Server IP : ${EXT_IP}"
  echo "SNI       : ${SNI}"
  echo "Public Key: ${PUBLIC}"
  echo ""

  for i in "${!UUIDS[@]}"; do
    URL="vless://${UUIDS[$i]}@${EXT_IP}:443?type=tcp&security=reality&flow=xtls-rprx-vision&pbk=${PUBLIC}&fp=firefox&sni=${SNI}&sid=${SHORTIDS[$i]}&spx=%2F#xtls-proxy"
    echo "URL #$((i+1)): ${URL}"
    echo ""
  done
  echo "================================================"
fi

./xray run -config config/config.json