#!/bin/sh

LOCK_FILE=config/.LOCK_FILE
CRED_FILE=${CRED_PATH:-/tmp/xtls-proxy.credentials}
if [ "$USE_WGCF" = "true" ]; then
  WGCF_PROFILE=config/wgcf-profile.conf
  CONFIG_FILE=config/config.warp.json
else
  CONFIG_FILE=config/config.json
fi

if [ ! -f "$LOCK_FILE" ]; then
  ./xray x25519 > config/keys

  EXT_IP=$(wget -qO- https://api.ipify.org 2>/dev/null || \
    wget -qO- https://icanhazip.com 2>/dev/null || echo unknown)
  PRIVATE=$(awk '/PrivateKey:/{print $2}' config/keys)
  PUBLIC=$(awk '/Password:/{print $2}' config/keys)

  USER_COUNT=${USER_COUNT:-1}
  case "$USER_COUNT" in
    ''|*[!0-9]*) echo "USER_COUNT must be a positive integer" >&2; exit 1 ;;
  esac
  if [ "$USER_COUNT" -lt 1 ]; then
    echo "USER_COUNT must be a positive integer" >&2
    exit 1
  fi

  UUIDS=
  clients='['
  shortids='['
  i=1
  while [ "$i" -le "$USER_COUNT" ]; do
    uuid=$(./xray uuid)
    shortid=$(./xray uuid | tr -d '-' | cut -c1-8)

    [ -z "$UUIDS" ] || UUIDS="$UUIDS "
    UUIDS="${UUIDS}${uuid}"

    [ "$clients" = '[' ] || clients="$clients,"
    clients="${clients}{\"id\":\"${uuid}\",\"flow\":\"xtls-rprx-vision\"}"

    [ "$shortids" = '[' ] || shortids="$shortids,"
    shortids="${shortids}\"${shortid}\""
    i=$((i + 1))
  done
  clients="$clients]"
  shortids="$shortids]"

  if [ "$USE_WGCF" = "true" ]; then
    mkdir -p wgcfconfig
    (cd wgcfconfig && wgcf register --accept-tos && wgcf generate)
    mv wgcfconfig/wgcf-profile.conf "$WGCF_PROFILE"
    rm -f wgcfconfig/wgcf-account.toml
    rmdir wgcfconfig

    WARP_PRIVATE_KEY=$(awk -F'= ' '/PrivateKey/{print $2}' "$WGCF_PROFILE")
    WARP_IPV4=$(awk -F'= ' '/Address/{print $2}' "$WGCF_PROFILE" | cut -d',' -f1 | tr -d ' ')
    WARP_IPV6=$(awk -F'= ' '/Address/{print $2}' "$WGCF_PROFILE" | cut -d',' -f2 | tr -d ' ')
    WARP_PUBLIC_KEY=$(awk -F'= ' '/PublicKey/{print $2}' "$WGCF_PROFILE")
    WARP_ENDPOINT=$(awk -F'= ' '/Endpoint/{print $2}' "$WGCF_PROFILE")
    # WARP_ENDPOINT="162.159.192.1:2408"
  fi

  # Escape sed replacement characters in the user-provided SNI.
  SNI_SED=$(printf '%s' "$SNI" | sed 's/[\\&|]/\\&/g')

  sed -i "s|\"XRAY_CLIENTS\"|${clients}|g" "$CONFIG_FILE"
  sed -i "s|\"XRAY_SHORT_IDS\"|${shortids}|g" "$CONFIG_FILE"
  sed -i "s|XRAY_PRIVATE_KEY|${PRIVATE}|g" "$CONFIG_FILE"
  sed -i "s|XRAY_TARGET|${SNI_SED}:443|g" "$CONFIG_FILE"
  sed -i "s|\"XRAY_SERVER_NAMES\"|[\"${SNI_SED}\"]|g" "$CONFIG_FILE"

  if [ "$USE_WGCF" = "true" ]; then
    sed -i "s|WARP_PRIVATE_KEY|${WARP_PRIVATE_KEY}|g" "$CONFIG_FILE"
    sed -i "s|WARP_IPV4|${WARP_IPV4}|g" "$CONFIG_FILE"
    sed -i "s|WARP_IPV6|${WARP_IPV6}|g" "$CONFIG_FILE"
    sed -i "s|WARP_PUBLIC_KEY|${WARP_PUBLIC_KEY}|g" "$CONFIG_FILE"
    sed -i "s|WARP_ENDPOINT|${WARP_ENDPOINT}|g" "$CONFIG_FILE"
  fi

  touch "$LOCK_FILE"

  umask 077
  CRED="${CRED_FILE}.tmp"
  {
    echo "================================================"
    echo "XTLS-PROXY Configuration"
    echo "================================================"
    echo "Server IP : ${EXT_IP}"
    echo "SNI       : ${SNI}"
    echo "Public Key: ${PUBLIC}"
    echo "WARP:       ${USE_WGCF}"
    echo ""

    i=1
    for uuid in $UUIDS; do
      shortid=$(printf '%s\n' "$shortids" | tr -d '[]"' | cut -d',' -f"$i")
      URL="vless://${uuid}@${EXT_IP}:443?type=tcp&security=reality&flow=xtls-rprx-vision&pbk=${PUBLIC}&fp=firefox&sni=${SNI}&sid=${shortid}&spx=%2F#xtls-proxy"
      echo "URL #${i}: ${URL}"
      echo ""
      i=$((i + 1))
    done
    echo "================================================"
  } > "$CRED"
  mv "$CRED" "$CRED_FILE"
fi

exec ./xray run -config "$CONFIG_FILE"
