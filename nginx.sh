#!/bin/bash

set -e

# === CẤU HÌNH DOMAIN & BACKEND ===
declare -A DOMAINS
DOMAINS=(
  ["bookiepal.icu"]="0.0.0.0:30001"
  ["host.bookiepal.icu"]="0.0.0.0:30002"
  ["sms.bookiepal.icu"]="0.0.0.0:30019"
  ["api.bookiepal.icu"]="0.0.0.0:30015"
)

SSL_DIR="./ssl"
CERT_SRC="${SSL_DIR}/cert.pem"
KEY_SRC="${SSL_DIR}/key.pem"

NGINX_SSL_DIR="/etc/nginx/ssl"
NGINX_SITES_AVAILABLE="/etc/nginx/sites-available"
NGINX_SITES_ENABLED="/etc/nginx/sites-enabled"

CERT_DEST="${NGINX_SSL_DIR}/pro-test.crt"
KEY_DEST="${NGINX_SSL_DIR}/pro-test.key"

# === 1. Cài Nginx nếu cần ===
if ! command -v nginx >/dev/null 2>&1; then
  echo "Installing Nginx..."
  sudo apt update
  sudo apt install -y nginx
fi

# === 2. Kiểm tra cert chung ===
if [[ ! -f "$CERT_SRC" || ! -f "$KEY_SRC" ]]; then
  echo "❌ Missing cert.pem or key.pem in $SSL_DIR"
  exit 1
fi

# === 3. Copy cert/key nếu chưa có ===
echo "📁 Setting up wildcard SSL cert..."
sudo mkdir -p "$NGINX_SSL_DIR"
sudo cp "$CERT_SRC" "$CERT_DEST"
sudo cp "$KEY_SRC" "$KEY_DEST"
sudo chmod 600 "$KEY_DEST"

# === 4. Loop các domain để tạo config ===
for DOMAIN in "${!DOMAINS[@]}"; do
  BACKEND="${DOMAINS[$DOMAIN]}"
  CONF_FILE="${NGINX_SITES_AVAILABLE}/${DOMAIN}"

  echo "▶️ Generating config for $DOMAIN → $BACKEND"
  sudo tee "$CONF_FILE" > /dev/null <<EOF
server {
    listen 80;
    server_name $DOMAIN;
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl;
    server_name $DOMAIN;

    ssl_certificate     $CERT_DEST;
    ssl_certificate_key $KEY_DEST;

    ssl_protocols       TLSv1.2 TLSv1.3;
    ssl_ciphers         HIGH:!aNULL:!MD5;

    location / {
        proxy_pass http://$BACKEND;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

  # Enable site
  sudo ln -sf "$CONF_FILE" "${NGINX_SITES_ENABLED}/${DOMAIN}"
done

# === 5. Reload Nginx ===
echo "🔁 Testing and reloading Nginx..."
sudo nginx -t && sudo systemctl reload nginx
echo "✅ All subdomains configured with shared SSL!"
