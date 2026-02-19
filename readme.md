# XTLS-PROXY

Yet another one dockerized slim proxy setup. For something a little more serious, see [here](https://docs.rw/docs/overview/introduction) and [there](https://github.com/gozargah/marzban).

## Quick start

1. Ssh into your server (of course, there's a git/docker installed already).
2. `git clone` this repo.
3. Spin up proxy container (urge you to change environment variables as you see fit).
```
docker build -t xtls-proxy .
docker run -d -p 443:443 -e SNI=www.twitch.tv -e USER_COUNT=1 --restart=always --name xtls-proxy xtls-proxy
```
4. Check the logs via `docker logs -f xtls-proxy` for connection url (shown once, see [here](/entrypoint.sh#L48-L55)).
```
================================================
XTLS-PROXY Configuration
================================================
Server IP : <Server IP>
SNI       : www.twitch.tv
Public Key: <PUBKEY>

URL #1: vless://<UUID>@<Server IP>:443?type=tcp&security=reality&flow=xtls-rprx-vision&pbk=<PUBKEY>&fp=firefox&sni=www.twitch.tv&sid=<SID>&spx=%2F#xtls-proxy

================================================
Xray 26.1.23 (Xray, Penetrates Everything.) 0a42dba (go1.25.6 linux/amd64)
A unified platform for anti-censorship.
```
5. Paste `vless://` link to a client you like.
6. ...
7. Profit.
