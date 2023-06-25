#!/usr/bin/env bash

# 设置各变量
WSPATH=${WSPATH:-'argo'}
UUID=${UUID:-'de04add9-5c68-8bab-950c-08cd5320df18'}
# WEB_USERNAME=${WEB_USERNAME:-'admin'}
# WEB_PASSWORD=${WEB_PASSWORD:-'password'}

generate_config() {
  cat > /tmp/config.json << EOF
{
  "log": {
    "access": "/dev/null",
    "error": "/dev/null",
    "loglevel": "none"
  },
  "inbounds": [
    {
      "port": 8080,
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "${UUID}",
            "flow": "xtls-rprx-vision"
          }
        ],
        "decryption": "none",
        "fallbacks": [
          {
            "path": "/${WSPATH}/vm",
            "dest": 3003
          }
        ]
      },
      "streamSettings": {
        "network": "tcp"
      }
    },
    {
      "port": 3003,
      "listen": "127.0.0.1",
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "id": "${UUID}",
            "alterId": 0
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "/${WSPATH}/vm"
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": ["http", "tls"],
        "metadataOnly": false
      }
    }
  ],
  "dns": {
    "servers": ["https+local://8.8.8.8/dns-query"]
  },
  "outbounds": [
    {
      "protocol": "freedom"
    },
    {
      "tag": "WARP",
      "protocol": "wireguard",
      "settings": {
        "secretKey": "cKE7LmCF61IhqqABGhvJ44jWXp8fKymcMAEVAzbDF2k=",
        "address": [
          "172.16.0.2/32",
          "fd01:5ca1:ab1e:823e:e094:eb1c:ff87:1fab/128"
        ],
        "peers": [
          {
            "publicKey": "bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo=",
            "endpoint": "162.159.193.10:2408"
          }
        ]
      }
    }
  ],
  "routing": {
    "domainStrategy": "AsIs",
    "rules": [
      {
        "type": "field",
        "domain": ["domain:openai.com", "domain:ai.com"],
        "outboundTag": "WARP"
      }
    ]
  }
}
EOF
}

generate_pm2_file() {
  cp -f /usr/src/app/web.js /tmp/web.js
  cat > /tmp/ecosystem.config.js << EOF
module.exports = {
  apps: [
    {
      name: "web",
      script: "/tmp/web.js run -c /tmp/config.json"
    }
  ]
}
EOF
}


generate_config
generate_pm2_file

[ -e /tmp/ecosystem.config.js ] && pm2 start /tmp/ecosystem.config.js