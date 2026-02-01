# XTLS-PROXY

Yet another one dockerized slim proxy setup. For something a little more serious, see [here](https://docs.rw/docs/overview/introduction) and [there](https://github.com/gozargah/marzban).

## Quick start

1. Ssh into your server (of course, there's a git/docker installed already).
2. `git clone` this repo.
3. Spin up proxy container (urge you to change environment variables as you see fit).
```
docker build -t xtls-proxy .
docker run -d --rm -p 443:443 -e SNI=www.twitch.tv -e SHORT_ID=abcd1234 -v xtls-proxy-cache:/opt/xray/config --name xtls-proxy xtls-proxy
```
4. Check the logs via `docker logs -f xtls-proxy` for connection url (shown once, see [here](/entrypoint.sh#L24-L40)). If there's no log, check `docker ps` for a container existance.
```
================================================
XTLS-PROXY Configuration:
================================================

Server: <Server IP>
UUID: <UUID>
Public Key: <PUBKEY>
SNI: www.twitch.tv
Short ID: abcd1234

Connection URL:
vless://<UUID>@<Server IP>?type=tcp&security=reality&flow=xtls-rprx-vision&pbk=<PUBKEY>&fp=firefox&sni=www.twitch.tv&sid=abcd1234&spx=%2F#xtls-proxy

================================================
Xray 26.1.23 (Xray, Penetrates Everything.) 0a42dba (go1.25.6 linux/amd64)
```
5. Paste `vless://` link to a client you like.
6. ...
7. Profit.

If anything goes bad, your configuration (pub/priv keys, uuids) is cached in a docker volume and preserved between runs (but [beware](entrypoint.sh#L4-L7)). For clean up use `docker volume rm xtls-proxy-cache`.
