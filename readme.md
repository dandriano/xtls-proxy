# XTLS-PROXY

Just another one dockerized slim proxy setup

## Quick start

Please change environment variables as needed. After running the container, check the logs to get your VLESS connection string url.

```
docker build -t xtls-proxy .
docker run -d --rm -p 443:443 -e SNI=www.twitch.tv -e SHORT_ID=abcd1234 -v xtls-proxy-cache:/opt/xray/config --name xtls-proxy xtls-proxy
docker logs -f xtls-proxy
```