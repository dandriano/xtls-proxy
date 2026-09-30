ARG ALPINE_VERSION=3.23

FROM alpine:${ALPINE_VERSION} AS xray-setup
ARG TARGETARCH
ARG XRAY_VERSION=26.2.6
RUN apk add --no-cache ca-certificates unzip wget && \
    case "$TARGETARCH" in \
      amd64) XRAY_ARCH=64 ;; \
      arm64) XRAY_ARCH=arm64-v8a ;; \
      *) echo "Unsupported Xray architecture: $TARGETARCH" >&2; exit 1 ;; \
    esac && \
    wget -q -O /tmp/xray.zip "https://github.com/XTLS/Xray-core/releases/download/v${XRAY_VERSION}/Xray-linux-${XRAY_ARCH}.zip" && \
    mkdir -p /opt/xray && \
    unzip -q /tmp/xray.zip -d /opt/xray

FROM alpine:${ALPINE_VERSION} AS xray-node
ENV USE_WGCF=false \
    SNI=www.twitch.tv \
    USER_COUNT=1
RUN apk add --no-cache ca-certificates
WORKDIR /opt/xray
COPY --from=xray-setup /opt/xray/ ./
COPY config.json config/config.json
COPY config.warp.json config/config.warp.json
COPY entrypoint.sh ./entrypoint.sh
RUN chmod +x ./entrypoint.sh
EXPOSE 443
ENTRYPOINT ["./entrypoint.sh"]

FROM xray-node AS default

FROM xray-node AS warp
ARG TARGETARCH
ARG WGCF_VERSION=2.2.31
RUN test "$TARGETARCH" = "amd64" || \
    (echo "The WARP image is only supported on amd64" >&2; exit 1) && \
    wget -q -O /usr/local/bin/wgcf "https://github.com/ViRb3/wgcf/releases/download/v${WGCF_VERSION}/wgcf_${WGCF_VERSION}_linux_amd64" && \
    chmod +x /usr/local/bin/wgcf
ENV USE_WGCF=true
