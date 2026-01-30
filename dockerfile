FROM alpine:latest

ARG XRAY_CORE_VERSION=v26.1.23
ENV SNI=www.twitch.tv 
ENV SHORT_ID=aabbccdd

RUN apk add --no-cache curl unzip && \
    wget https://github.com/XTLS/Xray-core/releases/download/${XRAY_CORE_VERSION}/Xray-linux-64.zip && \
    mkdir -p /opt/xray && \
    unzip -q Xray-linux-64.zip -d /opt/xray/ && \
    rm Xray-linux-64.zip

WORKDIR /opt/xray

COPY config.json config/config.json
COPY entrypoint.sh .
RUN chmod +x entrypoint.sh

EXPOSE 443
ENTRYPOINT ["./entrypoint.sh"]
