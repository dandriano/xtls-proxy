# XTLS-PROXY

Yet another one dockerized slim proxy setup. For something a little more serious, see [here](https://docs.rw/docs/overview/introduction) and [there](https://github.com/gozargah/marzban).

## Quick start

1. Ssh into your server.
2. Get setup script.
```
wget -O run.sh https://raw.githubusercontent.com/dandriano/xtls-proxy/master/run.sh
chmod +x run.sh
```
3. Spin up proxy container via setup script `./run.sh` (it will promt for SNI/user count/etc and install docker/git if needed).
4. Check the logs via `docker logs -f xtls-proxy` for connection url (see [here](/entrypoint.sh#L48-L55)).
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

## WARP

In case you're unable to guarantee proper client app configuration for direct access to domestic resources (or in case of censorship from the other side).
Rigth now this option routes all traffic thru Cloudflare network (see [here](/config.warp.json#L30-L34)), but configure as you see fit.
Also worth mentioning [wgcf](https://github.com/ViRb3/wgcf).