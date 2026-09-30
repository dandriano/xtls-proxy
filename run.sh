#!/bin/bash
set -e

read -p "Enter SNI [www.twitch.tv]: " SNI
SNI=${SNI:-www.twitch.tv}

read -p "Enter user count [1]: " USER_COUNT
USER_COUNT=${USER_COUNT:-1}

read -p "Enable WARP? [y/N]: " WGCF_INPUT
if [[ "$WGCF_INPUT" =~ ^[Yy]$ ]]; then
    USE_WGCF="true"
    BUILD_TARGET="warp"
    IMAGE="xtls-proxy:warp"
    PLATFORM_ARGS=(--platform linux/amd64)
else
    USE_WGCF="false"
    BUILD_TARGET="default"
    IMAGE="xtls-proxy:latest"
    PLATFORM_ARGS=()
fi

NAME="xtls-proxy"
CRED="/tmp/xtls-proxy.credentials"

apt install -y docker.io git
git clone https://github.com/dandriano/xtls-proxy.git

docker build "${PLATFORM_ARGS[@]}" \
           --target "$BUILD_TARGET" \
           -t "$IMAGE" \
           xtls-proxy
docker run "${PLATFORM_ARGS[@]}" -d \
           -p 443:443 \
           -e SNI="$SNI" \
           -e USER_COUNT="$USER_COUNT" \
           -e USE_WGCF="$USE_WGCF" \
           -e CRED_PATH="$CRED" \
           --restart=unless-stopped \
           --tmpfs /var/log/xray:size=5m \
           --tmpfs /tmp:size=5m \
           --log-driver=none \
           --name "$NAME" \
           "$IMAGE")

ATTEMPT=0
while (( ATTEMPT < 90 )); do
    if docker exec "$NAME" test -f "$CRED" 2>/dev/null; then
        break
    fi

    CONTAINER_STATUS=$(docker inspect --format '{{.State.Status}}' "$NAME" 2>/dev/null || true)
    if [[ "$CONTAINER_STATUS" == "exited" || "$CONTAINER_STATUS" == "dead" ]]; then
        echo "Container $NAME stopped before credentials at $CRED were ready." >&2
        exit 1
    fi

    sleep 2
    ATTEMPT=$((ATTEMPT + 1))
done

if ! docker exec "$NAME" test -f "$CRED" 2>/dev/null; then
    echo "Timed out waiting for credentials at $CRED in container $NAME." >&2
    exit 1
fi

if ! CONNECTION=$(docker exec "$NAME" cat "$CRED"); then
    echo "Could not retrieve credentials at $CRED from container $NAME." >&2
    exit 1
fi

if ! docker exec "$NAME" rm -f "$CRED"; then
    echo "Could not remove temporary credentials at $CRED from container $NAME." >&2
    exit 1
fi

printf '%s\n' "$CONNECTION"
