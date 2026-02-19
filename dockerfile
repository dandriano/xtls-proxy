FROM alpine:latest

ARG XRAY_CORE_VERSION=v26.2.6
ENV SNI=www.twitch.tv 
ENV USER_COUNT=1

RUN apk add --no-cache bash curl openssl unzip && \
    wget https://github.com/XTLS/Xray-core/releases/download/${XRAY_CORE_VERSION}/Xray-linux-64.zip && \
    mkdir -p /opt/xray && \
    unzip -q Xray-linux-64.zip -d /opt/xray/ && \
    apk del unzip && rm Xray-linux-64.zip

WORKDIR /opt/xray

COPY config.json config/config.json
COPY entrypoint.sh .
RUN chmod +x entrypoint.sh

EXPOSE 443
ENTRYPOINT ["./entrypoint.sh"]
