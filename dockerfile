FROM alpine:latest

ARG XRAY_VERSION=26.2.6
ARG WGCF_VERSION=2.2.31
ENV USE_WGCF=false
ENV SNI=www.twitch.tv 
ENV USER_COUNT=1

RUN apk add --no-cache bash curl openssl unzip && \
    wget https://github.com/XTLS/Xray-core/releases/download/v${XRAY_VERSION}/Xray-linux-64.zip && \
    mkdir -p /opt/xray && \
    unzip -q Xray-linux-64.zip -d /opt/xray/ && \
    apk del unzip && rm Xray-linux-64.zip

RUN wget -O /usr/local/bin/wgcf https://github.com/ViRb3/wgcf/releases/download/v${WGCF_VERSION}/wgcf_${WGCF_VERSION}_linux_amd64 && \
    chmod +x /usr/local/bin/wgcf

WORKDIR /opt/xray

COPY config.json config/config.json
COPY config.warp.json config/config.warp.json
COPY entrypoint.sh .
RUN chmod +x entrypoint.sh

EXPOSE 443
ENTRYPOINT ["./entrypoint.sh"]
