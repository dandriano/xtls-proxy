FROM alpine:latest

ARG XRAY_VERSION=v26.2.6
ARG WGCF_VERSION=v2.2.26
ENV SNI=www.twitch.tv 
ENV USER_COUNT=1

RUN apk add --no-cache bash curl openssl unzip && \
    wget https://github.com/XTLS/Xray-core/releases/download/${XRAY_VERSION}/Xray-linux-64.zip && \
    mkdir -p /opt/xray && \
    unzip -q Xray-linux-64.zip -d /opt/xray/ && \
    apk del unzip && rm Xray-linux-64.zip

RUN wget -O /usr/local/bin/wgcf https://github.com/ViRb3/wgcf/releases/download/v2.2.26/wgcf_2.2.26_linux_amd64 && \
    chmod +x /usr/local/bin/wgcf

WORKDIR /opt/xray

COPY config.json config/config.json
COPY entrypoint.sh .
RUN chmod +x entrypoint.sh

EXPOSE 443
ENTRYPOINT ["./entrypoint.sh"]
