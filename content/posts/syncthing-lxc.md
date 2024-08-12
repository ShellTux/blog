---
title: "Syncthing Service"
date: 2024-08-12T17:28:27+01:00
draft: true
description: Syncthing Service using Systemd
categories:
  - Syncthing
  - Systemd
tags:
  - syncthing
  - systemd
math: false
author: "Me"
type: "post"
layout: "post"
cover:
  hidden: false # hide everywhere but not in structured data
  image: "covers/syncthing.png"
  alt: 
  caption: 
  relative: true
---

Building a Syncthing Service using Systemd on a Debian Based Distro

<!--more-->

# Syncthing

## Syncthing Systemd Service

### Install

```sh
# apt install syncthing
```

### Setup

1. Create the user who should run the service, or choose an existing one.

```sh
# adduser syncthing
```

2. Enable/Start Service

```sh
# systemctl enable syncthing@syncthing.service
# systemctl start syncthing@syncthing.service
```

### Check Service

```sh
# systemctl status syncthing@syncthing
```

### Edit Service

```sh
# systemctl edit syncthing@syncthing
```

Or edit manually, for example to listen on all interfaces besides localhost

```sh
# vim /lib/systemd/system/syncthing@.service
```

```service
[Unit]
Description=Syncthing - Open Source Continuous File Synchronization for %I
Documentation=man:syncthing(1)
After=network.target
StartLimitIntervalSec=60
StartLimitBurst=4

[Service]
User=%i
ExecStart=/usr/bin/syncthing serve --no-browser --no-restart --logflags=0 --gui-address=0.0.0.0:8384
Restart=on-failure
RestartSec=1
SuccessExitStatus=3 4
RestartForceExitStatus=3 4

# Hardening
ProtectSystem=full
PrivateTmp=true
SystemCallArchitectures=native
MemoryDenyWriteExecute=true
NoNewPrivileges=true

# Elevated permissions to sync ownership (disabled by default),
# see https://docs.syncthing.net/advanced/folder-sync-ownership
#AmbientCapabilities=CAP_CHOWN CAP_FOWNER

[Install]
WantedBy=multi-user.target
```

```sh
# systemctl daemon-reload
# systemctl restart syncthing@syncthing
```

## Reverse Proxy

### Caddy

```caddy
syncthing.example.org {
    # Gui Access
    reverse_proxy http://192.168.5.54:8384 {
        header_up Host {upstream_hostport}
    }

    # Discovery Setup
    reverse_proxy 192.168.5.54:8443 {
        header_up X-Forwarded-For {http.request.remote.host}
        header_up X-Client-Port {http.request.remote.port}
        header_up X-Tls-Client-Cert-Der-Base64 {http.request.tls.client.certificate_der_base64}
    }
}
```
