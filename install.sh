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

# 5. Interactive Configuration for MAIL_FROM and MAIL_TO
echo "--------------------------------------------------------"
read -p "📤 Enter sender email / From address [Zimbra Security <zimbra@yourdomain.com>]: " USER_FROM
USER_FROM=${USER_FROM:-Zimbra Security <zimbra@yourdomain.com>}

read -p "📧 Enter notification recipient email / To address [admin@yourdomain.com]: " USER_TO
USER_TO=${USER_TO:-admin@yourdomain.com}

# Update MAIL_FROM and MAIL_TO inside the script dynamically
sed -i "s|MAIL_FROM=\".*\"|MAIL_FROM=\"${USER_FROM}\"|g" zimbra-security-check.sh
sed -i "s|MAIL_TO=\".*\"|MAIL_TO=\"${USER_TO}\"|g" zimbra-security-check.sh

echo "✅ Sender (From) updated to: ${USER_FROM}"
echo "✅ Recipient (To) updated to: ${USER_TO}"

echo "--------------------------------------------------------"
echo "🎉 Installation Completed Successfully!"
echo "📍 Location: $INSTALL_DIR"
echo "🚀 You can now test it by running: sudo ${INSTALL_DIR}/zimbra-security-check.sh"
echo "--------------------------------------------------------"
