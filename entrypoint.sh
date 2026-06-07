#!/bin/bash
LOCKFILE=config/.lockfile
if [ "$USE_WGCF" = "true" ]; then
  WGCF_PROFILE=config/wgcf-profile.conf
  CONFIG_FILE=config/config.warp.json
else
  CONFIG_FILE=config/config.json
fi


if [ ! -f "$LOCKFILE" ]; then
  # Generate Xray configuration
  ./xray x25519 > config/keys

  EXT_IP=$(curl -s https://api.ipify.org || curl -s https://icanhazip.com || echo "unknown")
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
  clients="[\n"
  for uuid in "${UUIDS[@]}"; do
    [ "$clients" != "[\n" ] && clients="$clients,\n"
    clients="$clients {\n \"id\": \"$uuid\",\n \"flow\": \"xtls-rprx-vision\"\n }"
  done
  clients="$clients\n]"

  # Build shortID section
  shortids="["
  for sid in "${SHORTIDS[@]}"; do
    [ "$shortids" != "[" ] && shortids="$shortids, "
    shortids="${shortids}\"$sid\""
  done
  shortids="$shortids]"

  if [ "$USE_WGCF" = "true" ]; then
    # Generate WARP configuration
    mkdir -p wgcfconfig
    cd wgcfconfig
    wgcf register --accept-tos
    wgcf generate
    mv wgcf-profile.conf ../$WGCF_PROFILE
    cd ..
    rm -rf wgcfconfig

    WARP_PRIVATE_KEY=$(awk -F'= ' '/PrivateKey/{print $2}' "$WGCF_PROFILE")
    WARP_IPV4=$(awk -F'= ' '/Address/{print $2}' "$WGCF_PROFILE" | cut -d',' -f1 | tr -d ' ')
    WARP_IPV6=$(awk -F'= ' '/Address/{print $2}' "$WGCF_PROFILE" | cut -d',' -f2 | tr -d ' ')
    WARP_PUBLIC_KEY=$(awk -F'= ' '/PublicKey/{print $2}' "$WGCF_PROFILE")
    WARP_ENDPOINT=$(awk -F'= ' '/Endpoint/{print $2}' "$WGCF_PROFILE")
    # Force IPv4 right now ...
    WARP_ENDPOINT="162.159.192.1:2408"
  fi

  # Do replacements
  sed -i "s|\"XRAY_CLIENTS\"|${clients}|g" "$CONFIG_FILE"
  sed -i "s|\"XRAY_SHORT_IDS\"|${shortids}|g" "$CONFIG_FILE"
  sed -i "s|XRAY_PRIVATE_KEY|${PRIVATE}|g" "$CONFIG_FILE"
  sed -i "s|XRAY_TARGET|${SNI}:443|g" "$CONFIG_FILE"
  sed -i "s|\"XRAY_SERVER_NAMES\"|[\"${SNI}\"]|g" "$CONFIG_FILE"

  if [ "$USE_WGCF" = "true" ]; then
    sed -i "s|WARP_PRIVATE_KEY|${WARP_PRIVATE_KEY}|g" "$CONFIG_FILE"
    sed -i "s|WARP_IPV4|${WARP_IPV4}|g" "$CONFIG_FILE"
    sed -i "s|WARP_IPV6|${WARP_IPV6}|g" "$CONFIG_FILE"
    sed -i "s|WARP_PUBLIC_KEY|${WARP_PUBLIC_KEY}|g" "$CONFIG_FILE"
    sed -i "s|WARP_ENDPOINT|${WARP_ENDPOINT}|g" "$CONFIG_FILE"
  fi

  touch "$LOCKFILE"

  echo "================================================"
  echo "XTLS-PROXY Configuration"
  echo "================================================"
  echo "Server IP : ${EXT_IP}"
  echo "SNI       : ${SNI}"
  echo "Public Key: ${PUBLIC}"
  echo "WARP:       ${USE_WGCF}"
  echo ""

  for i in "${!UUIDS[@]}"; do
    URL="vless://${UUIDS[$i]}@${EXT_IP}:443?type=tcp&security=reality&flow=xtls-rprx-vision&pbk=${PUBLIC}&fp=firefox&sni=${SNI}&sid=${SHORTIDS[$i]}&spx=%2F#xtls-proxy"
    echo "URL #$((i+1)): ${URL}"
    echo ""
  done
  echo "================================================"
fi

./xray run -config "$CONFIG_FILE"