#!/usr/bin/env bash

# Launch
# chmod +x x2r_alternative_install.sh
# sudo bash ./x2r_alternative_install.sh or # sudo ./x2r_alternative_install.sh

set -euo pipefail

############################################
# Xray VLESS + REALITY Installer
# Ubuntu 22.04 / 24.04
############################################

XRAY_CONFIG="/usr/local/etc/xray/config.json"
XRAY_PORT="443"
XRAY_FLOW="xtls-rprx-vision"
XRAY_SNI="www.cloudflare.com"
XRAY_SHORT_ID="$(openssl rand -hex 8)"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

require_root() {
    if [[ "$EUID" -ne 0 ]]; then
        error "Run this script as root"
        exit 1
    fi
}

detect_ip() {
    SERVER_IP=$(curl -s https://api.ipify.org)

    if [[ -z "$SERVER_IP" ]]; then
        error "Failed to detect public IP"
        exit 1
    fi
}

install_packages() {
    log "Installing dependencies..."

    apt update -y

    DEBIAN_FRONTEND=noninteractive apt install -y \
        curl \
        unzip \
        openssl \
        qrencode \
        ufw \
        ca-certificates
}

install_xray() {
    log "Installing Xray..."

    bash <(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)
}

generate_keys() {
    log "Generating UUID and REALITY keys..."

    UUID=$(cat /proc/sys/kernel/random/uuid)

    KEY_OUTPUT=$(xray x25519)

    PRIVATE_KEY=$(echo "$KEY_OUTPUT" | awk '/Private key:/ {print $3}')
    PUBLIC_KEY=$(echo "$KEY_OUTPUT" | awk '/Public key:/ {print $3}')

    if [[ -z "$PRIVATE_KEY" || -z "$PUBLIC_KEY" ]]; then
        error "Failed to generate REALITY keys"
        exit 1
    fi
}

configure_firewall() {
    log "Configuring firewall..."

    ufw allow 22/tcp || true
    ufw allow 443/tcp || true

    ufw --force enable

    log "Firewall configured"
}

create_config() {
    log "Creating Xray REALITY config..."

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
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "$UUID",
            "flow": "$XRAY_FLOW"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
          "show": false,
          "dest": "$XRAY_SNI:443",
          "xver": 0,
          "serverNames": [
            "$XRAY_SNI"
          ],
          "privateKey": "$PRIVATE_KEY",
          "shortIds": [
            "$XRAY_SHORT_ID"
          ]
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls",
          "quic"
        ]
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

    if ! xray -test -config "$XRAY_CONFIG"; then
        error "Config validation failed"
        exit 1
    fi
}

enable_service() {
    log "Starting Xray service..."

    systemctl daemon-reload
    systemctl enable xray
    systemctl restart xray

    sleep 2

    if ! systemctl is-active --quiet xray; then
        error "Xray failed to start"
        systemctl status xray --no-pager
        exit 1
    fi

    log "Xray is running"
}

generate_vless_link() {
    VLESS_URL="vless://${UUID}@${SERVER_IP}:${XRAY_PORT}?security=reality&sni=${XRAY_SNI}&fp=chrome&pbk=${PUBLIC_KEY}&sid=${XRAY_SHORT_ID}&type=tcp&flow=${XRAY_FLOW}#xray-reality"
}

show_info() {
    echo
    echo "=================================================="
    echo " Xray VLESS + REALITY Installed"
    echo "=================================================="
    echo
    echo "Server IP     : $SERVER_IP"
    echo "Port          : $XRAY_PORT"
    echo "Protocol      : VLESS"
    echo "Transport     : TCP"
    echo "Security      : REALITY"
    echo "UUID          : $UUID"
    echo "Public Key    : $PUBLIC_KEY"
    echo "Short ID      : $XRAY_SHORT_ID"
    echo "SNI           : $XRAY_SNI"
    echo
    echo "=================================================="
    echo " VLESS URL"
    echo "=================================================="
    echo
    echo "$VLESS_URL"
    echo
    echo "=================================================="
    echo " QR CODE"
    echo "=================================================="
    echo

    qrencode -t ANSIUTF8 "$VLESS_URL"

    echo
    echo "=================================================="
}

main() {
    require_root
    detect_ip
    install_packages
    install_xray
    generate_keys
    configure_firewall
    create_config
    validate_config
    enable_service
    generate_vless_link
    show_info
}

main "$@"