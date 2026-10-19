#!/bin/bash

# ==============================================================================
# Project Name : Zimbra Security & Integrity Checker
# Description  : Automated installer for Zimbra ZCS Security Monitoring
# Author       : EGTA Software (Ertan Günay)
# ==============================================================================

INSTALL_DIR="/opt/zimbra-security"
REPO_URL="https://raw.githubusercontent.com/xertgun/zimbra-security-check/main"

echo "--------------------------------------------------------"
echo "🛡️ Installing Zimbra Security & Integrity Checker..."
echo "--------------------------------------------------------"

# 1. Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "❌ ERROR: This installer must be run as root!"
    echo "   Please run: sudo ./install.sh"
    exit 1
fi

# 2. Create installation directory
if [ ! -d "$INSTALL_DIR" ]; then
    mkdir -p "$INSTALL_DIR"
    echo "📁 Created installation directory: $INSTALL_DIR"
fi

cd "$INSTALL_DIR" || exit 1

# 3. Download required files from GitHub
echo "📥 Downloading files from GitHub repository..."
curl -s -O "${REPO_URL}/zimbra-security-check.sh"
curl -s -O "${REPO_URL}/zimbra-security-excludes.conf"

# 4. Set execution permissions
chmod +x zimbra-security-check.sh
echo "🔒 Execution permissions set."

# 5. Interactive Configuration (Domain & Emails & Telegram)
echo "--------------------------------------------------------"
read -p "🌐 Enter your mail domain [yourdomain.com]: " USER_DOMAIN
USER_DOMAIN=${USER_DOMAIN:-yourdomain.com}

read -p "📧 Enter notification recipient email [admin@${USER_DOMAIN}]: " USER_TO
USER_TO=${USER_TO:-admin@${USER_DOMAIN}}

read -p "🤖 Enter Telegram Bot Token (Optional, press ENTER to skip): " USER_TG_TOKEN
read -p "💬 Enter Telegram Chat ID (Optional, press ENTER to skip): " USER_TG_CHAT

# Construct MAIL_FROM automatically using the domain
USER_FROM="Zimbra Security <zimbra@${USER_DOMAIN}>"

# Update variables inside the script dynamically using sed
sed -i "s|MAIL_FROM=\".*\"|MAIL_FROM=\"${USER_FROM}\"|g" zimbra-security-check.sh
sed -i "s|MAIL_TO=\".*\"|MAIL_TO=\"${USER_TO}\"|g" zimbra-security-check.sh

# Update Telegram credentials if provided
if [ -n "$USER_TG_TOKEN" ]; then
    sed -i "s|TELEGRAM_BOT_TOKEN=\".*\"|TELEGRAM_BOT_TOKEN=\"${USER_TG_TOKEN}\"|g" zimbra-security-check.sh
fi

if [ -n "$USER_TG_CHAT" ]; then
    sed -i "s|TELEGRAM_CHAT_ID=\".*\"|TELEGRAM_CHAT_ID=\"${USER_TG_CHAT}\"|g" zimbra-security-check.sh
fi

echo "--------------------------------------------------------"
echo "✅ Configuration Applied Successfully!"
echo "   - Sender (From) : ${USER_FROM}"
echo "   - Recipient (To): ${USER_TO}"
[ -n "$USER_TG_TOKEN" ] && echo "   - Telegram      : Configured ✅" || echo "   - Telegram      : Skipped ℹ️"
echo "--------------------------------------------------------"
echo "🎉 Installation Completed Successfully!"
echo "📍 Location: $INSTALL_DIR"
echo "🚀 You can now test it by running: sudo ${INSTALL_DIR}/zimbra-security-check.sh"
echo "--------------------------------------------------------"
