#!/bin/bash
# ==============================================================================
# Project Name : Zimbra Security & Integrity Checker
# Description  : Automated installer for Zimbra ZCS Security Monitoring (v2.0.0)
# Author       : EGTA Software (Ertan Günay)
# ==============================================================================

INSTALL_DIR="/opt/zimbra-security"
REPO_URL="https://raw.githubusercontent.com/xertgun/zimbra-security-check/v2-multilingual"

echo "--------------------------------------------------------"

# 1. Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "❌ ERROR: This installer must be run as root! Please run: sudo ./install.sh"
    exit 1
fi

# 2. Early Language Selection (Multilingual Prompt)
echo "🌍 Please select your language:"
echo "   1) Select Language: English (en) - Default"
echo "   2) Dili Seçiniz: Türkçe (tr)"
echo "   3) Sprache Wählen: Deutsch (de)"
read -p "👉 Choose language [1-3, default: 1]: " LANG_CHOICE

case "$LANG_CHOICE" in
    2) USER_LANG="tr" ;;
    3) USER_LANG="de" ;;
    *) USER_LANG="en" ;;
esac

# 3. Create installation and language directories
mkdir -p "$INSTALL_DIR/lang"
cd "$INSTALL_DIR" || exit 1

# 4. Download core files and language files from GitHub
echo "📥 Downloading core & language files..."
curl -s -O "${REPO_URL}/zimbra-security-check.sh"
curl -s -O "${REPO_URL}/zimbra-security-excludes.conf"
curl -s "${REPO_URL}/lang/en.conf" -o "lang/en.conf"
curl -s "${REPO_URL}/lang/tr.conf" -o "lang/tr.conf"
curl -s "${REPO_URL}/lang/de.conf" -o "lang/de.conf"

# 5. Source the selected language file to get all messages dynamically
if [ -f "lang/${USER_LANG}.conf" ]; then
    source "lang/${USER_LANG}.conf"
else
    source "lang/en.conf"
fi

# Optional friendly language notification
echo "${MSG_LANG_NOFIFY}"

# 6. Set execution permissions
chmod +x zimbra-security-check.sh

# 7. Interactive Configuration using language variables
echo "--------------------------------------------------------"
read -p "$MSG_PROMPT_DOMAIN" USER_DOMAIN
USER_DOMAIN=${USER_DOMAIN:-domain.com}

read -p "$MSG_PROMPT_TG_TOKEN" USER_TG_TOKEN
read -p "$MSG_PROMPT_TG_CHAT" USER_TG_CHAT

USER_FROM="Zimbra Security <zimbra@${USER_DOMAIN}>"
USER_TO="Zimbra Administrator <admin@${USER_DOMAIN}>"

# Update variables inside the script dynamically using sed
sed -i "s|MAIL_FROM=\".*\"|MAIL_FROM=\"${USER_FROM}\"|g" zimbra-security-check.sh
sed -i "s|MAIL_TO=\".*\"|MAIL_TO=\"${USER_TO}\"|g" zimbra-security-check.sh
sed -i "s|DEFAULT_LANG=\".*\"|DEFAULT_LANG=\"${USER_LANG}\"|g" zimbra-security-check.sh

if [ -n "$USER_TG_TOKEN" ]; then
    sed -i "s|TELEGRAM_BOT_TOKEN=\".*\"|TELEGRAM_BOT_TOKEN=\"${USER_TG_TOKEN}\"|g" zimbra-security-check.sh
fi

if [ -n "$USER_TG_CHAT" ]; then
    sed -i "s|TELEGRAM_CHAT_ID=\".*\"|TELEGRAM_CHAT_ID=\"${USER_TG_CHAT}\"|g" zimbra-security-check.sh
fi

echo "--------------------------------------------------------"
echo "$MSG_SETUP_SUCCESS"
echo "${MSG_LABEL_LANG}${USER_LANG^^}"
echo "${MSG_LABEL_FROM}${USER_FROM}"
echo "${MSG_LABEL_TO}${USER_TO}"
[ -n "$USER_TG_TOKEN" ] && echo "$MSG_LABEL_TG_OK" || echo "$MSG_LABEL_TG_SKIP"
echo "--------------------------------------------------------"
echo "🎉 ${MSG_SETUP_DONE}!"
echo "${MSG_LABEL_LOC:-📍 Location: } $INSTALL_DIR"
echo "${MSG_TEST_RUN}${INSTALL_DIR}/zimbra-security-check.sh"
echo "--------------------------------------------------------"
