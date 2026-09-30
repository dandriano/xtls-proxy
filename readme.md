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
4. Copy `vless://` link in the `run.sh` terminal after docker startup.
```
================================================
XTLS-PROXY Configuration
================================================
Server IP : <Server IP>
SNI       : www.twitch.tv
Public Key: <PUBKEY>

URL #1: vless://<UUID>@<Server IP>:443?type=tcp&security=reality&flow=xtls-rprx-vision&pbk=<PUBKEY>&fp=firefox&sni=www.twitch.tv&sid=<SID>&spx=%2F#xtls-proxy

================================================
```
5. Paste `vless://` link to a client you like.
6. ...
7. Profit.

## Image variants and architectures

The default `default` image target uses Alpine 3.23 and supports `linux/amd64` and `linux/arm64`. It does not include `wgcf`. The `warp` target includes `wgcf` and is amd64-only. The setup script builds and runs the selected target automatically; enabling WARP selects `xtls-proxy:warp` and `linux/amd64`.

To build the default image for a specific architecture:

```
docker build --platform linux/amd64 --target default -t xtls-proxy:latest .
docker build --platform linux/arm64 --target default -t xtls-proxy:arm64 .
```

Build the WARP variant on amd64 with:

```
docker build --platform linux/amd64 --target warp -t xtls-proxy:warp .
```

## WARP

In case you're unable to guarantee proper client app configuration for direct access to domestic resources (or in case of censorship from the other side).
Rigth now this option routes all traffic thru Cloudflare network (see [here](/config.warp.json#L30-L34)), but configure as you see fit.
The WARP image uses [wgcf](https://github.com/ViRb3/wgcf) to generate its WireGuard profile at startup.
