#!/usr/bin/env bash

# Launch
# chmod +x x2r_simple_install.sh
# sudo ./install-xray.sh

set -euo pipefail

XRAY_CONFIG="/usr/local/etc/xray/config.json"
XRAY_PORT="10000"
XRAY_WS_PATH="/v2ray"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

require_root() {
    if [[ "$EUID" -ne 0 ]]; then
        error "Please run as root"
        exit 1
    fi
}

install_dependencies() {
    log "Installing dependencies..."
    apt update -y
    apt install -y curl unzip
}

install_xray() {
    log "Installing Xray..."
    bash <(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)
}

generate_uuid() {
    cat /proc/sys/kernel/random/uuid
}

create_config() {
    local uuid="$1"

    log "Creating Xray config..."

    mkdir -p /usr/local/etc/xray

    cat > "$XRAY_CONFIG" <<EOF
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "listen": "0.0.0.0",
      "port": $XRAY_PORT,
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "id": "$uuid",
            "alterId": 0
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "$XRAY_WS_PATH"
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom"
    }
  ]
}
EOF
}

validate_config() {
    log "Validating Xray config..."

    if xray -test -config "$XRAY_CONFIG"; then
        log "Config validation successful"
    else
        error "Config validation failed"
        exit 1
    fi
}

enable_service() {
    log "Enabling and restarting Xray service..."

    systemctl daemon-reload
    systemctl enable xray
    systemctl restart xray
    systemctl status xray --no-pager
}

show_connection_info() {
    local uuid="$1"
    local ip

    ip=$(curl -s https://api.ipify.org || echo "YOUR_SERVER_IP")

    echo
    echo "======================================"
    echo " Xray Installation Complete"
    echo "======================================"
    echo "Server IP : $ip"
    echo "Port      : $XRAY_PORT"
    echo "UUID      : $uuid"
    echo "Transport : WebSocket"
    echo "WS Path   : $XRAY_WS_PATH"
    echo "======================================"
    echo
}

main() {
    
    sudo ufw allow 10000/tcp
    sudo ufw reload

    require_root
    install_dependencies
    install_xray

    UUID=$(generate_uuid)

    create_config "$UUID"
    validate_config
    enable_service
    show_connection_info "$UUID"
}

main "$@"