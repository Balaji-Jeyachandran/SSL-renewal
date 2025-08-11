#!/bin/bash

# === CONFIGURATION ===
WEBROOT_PATH="/var/www/certbot"
REVERSE_PROXY_CONTAINER="temple-reverse-proxy-1"
LOG_DIR="/home/ubuntu/ssl_logs"
LOG_FILE="$LOG_DIR/renewal_$(date +%F).log"

# === TELEGRAM CONFIG ===
TELEGRAM_BOT_TOKEN="your telegram bot token"
TELEGRAM_CHAT_ID="your chat ID"

send_telegram() {
  curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
       -d chat_id="$TELEGRAM_CHAT_ID" \
       -d text="$1"
}

# === SETUP ===
mkdir -p "$LOG_DIR"
echo "==== SSL Renewal Started on $(date) ====" >> "$LOG_FILE"

# === RUN CERTBOT RENEWAL ===
sudo certbot renew --webroot -w "$WEBROOT_PATH" --deploy-hook \
"docker restart $REVERSE_PROXY_CONTAINER" >> "$LOG_FILE" 2>&1

# === CHECK RESULT ===
if grep -q "Congratulations" "$LOG_FILE"; then
  send_telegram "✅ SSL renewal SUCCESSFUL on $(date) for Temple domain."
elif grep -q "Certificate not yet due for renewal" "$LOG_FILE"; then
  send_telegram "ℹ️ SSL certificates are not yet due for renewal. Next expiry: Nov 3, 2025."
else
  send_telegram "❌ SSL renewal FAILED on $(date). Check log: $LOG_FILE"
fi

echo "==== SSL Renewal Finished on $(date) ====" >> "$LOG_FILE"