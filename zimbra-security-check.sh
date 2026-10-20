#!/bin/bash
# ==============================================================================
# Script Name : zimbra-security-check.sh
# Description : Daily integrity scanner and security reporter for Zimbra ZCS
# Tested On   : Zimbra Collaboration Suite 8.8.15 (ZCS 8.8.15 GA)
# Version     : 2.0.3
# Author      : EGTA Software (Ertan Günay)
# Repository  : https://github.com/xertgun/zimbra-security-check
# ==============================================================================

# ------------------------------------------------------------------------------
# CONFIGURATION AREA (User Specific Settings)
# ------------------------------------------------------------------------------
MAIL_FROM="Zimbra Security <zimbra@yourdomain.com>"
MAIL_TO="Zimbra Administrator <admin@yourdomain.com>"

# Language Selection: tr (Turkish), en (English), de (German), fr (French)
DEFAULT_LANG="tr"

VERSION="2.0.3"
HOSTNAME=$(hostname -f)
DATE=$(date +"%Y-%m-%d %H:%M")
REPORT_FILE="/tmp/sec_report_$$.html"

# Telegram Bot Credentials (Leave empty if not using Telegram alerts)
TELEGRAM_BOT_TOKEN="YOUR_TELEGRAM_BOT_TOKEN"
TELEGRAM_CHAT_ID="YOUR_TELEGRAM_CHAT_ID"

# ------------------------------------------------------------------------------
# LOCALIZATION (i18n) SETUP
# ------------------------------------------------------------------------------
SCRIPT_DIR="$(dirname "$0")"
LANG_FILE="${SCRIPT_DIR}/lang/${DEFAULT_LANG}.conf"

if [ -f "$LANG_FILE" ]; then
    source "$LANG_FILE"
else
    # Fallback to English if language file is missing
    source "${SCRIPT_DIR}/lang/en.conf"
fi

# ------------------------------------------------------------------------------
# SECURITY SCANS
# ------------------------------------------------------------------------------
ALERT=0

# 1. Directory and File Triage Scans
TMP_SCAN=$(find /tmp /var/tmp /dev/shm -type f \( -name "*.sh" -o -name "*.py" -o -name "*.php" -o -executable \) 2>/dev/null)
WEB_JSP_SCAN=$(find /opt/zimbra/jetty/webapps /opt/zimbra/mailboxd/webapps -type f -name "*.jsp" ! -path "*/zimbraAdmin/*" ! -path "*/zimbra/*" ! -path "*/service/*" 2>/dev/null)
NEW_WEB_FILES=$(find /opt/zimbra/jetty/webapps/ /opt/zimbra/mailboxd/webapps/ -type f -mtime -1 2>/dev/null | grep -vE "\.(xml|properties|html)$")

# 2. Process / Memory Inspection (Using external exclude file for clean code)
EXCLUDE_FILE="${SCRIPT_DIR}/zimbra-security-excludes.conf"
CONFIG_MISSING=0

if [ -f "$EXCLUDE_FILE" ]; then
    RAW_PROC_SCAN=$(ps aux | grep -E "zimbra|postfix" | grep -v -F -f "$EXCLUDE_FILE")
else
    # Fallback mechanism if exclude file is missing to prevent massive false positives
    CONFIG_MISSING=1
    ALERT=1
    RAW_PROC_SCAN=""
fi

if [ -n "$RAW_PROC_SCAN" ]; then
  ALERT=1
  DETECTED_PIDS=$(echo "$RAW_PROC_SCAN" | awk '{print $2}' | tr '\n' ' ' | sed 's/ $//')
fi

# 3. Zimbra Crontab Inspection
CRON_SCAN=$(crontab -u zimbra -l 2>/dev/null | grep -vE "^#|^$" | grep -v "zimbra")

# Status Label Definitions
TMP_STATUS="✅ ${MSG_STATUS_CLEAN}"
[ -n "$TMP_SCAN" ] && TMP_STATUS="❌ ${MSG_STATUS_SUSPICIOUS}" && ALERT=1

JSP_STATUS="✅ ${MSG_STATUS_CLEAN}"
[ -n "$WEB_JSP_SCAN" ] && JSP_STATUS="❌ ${MSG_STATUS_JSP}" && ALERT=1

NEW_FILES_STATUS="✅ ${MSG_STATUS_CLEAN}"
[ -n "$NEW_WEB_FILES" ] && NEW_FILES_STATUS="⚠️ ${MSG_STATUS_MODIFIED}"

PROC_STATUS="✅ ${MSG_STATUS_NORMAL}"
if [ $CONFIG_MISSING -eq 1 ]; then
    PROC_STATUS="⚠️ ${MSG_CONFIG_MISSING}"
elif [ -n "$RAW_PROC_SCAN" ]; then
    PROC_STATUS="❌ ${MSG_STATUS_UNKNOWN_PROC}"
fi

CRON_STATUS="✅ ${MSG_STATUS_CLEAN}"
[ -n "$CRON_SCAN" ] && CRON_STATUS="❌ ${MSG_STATUS_CRON}" && ALERT=1

# ------------------------------------------------------------------------------
# HTML REPORT GENERATION
# ------------------------------------------------------------------------------
cat <<EOF > "$REPORT_FILE"
<!DOCTYPE html>
<html>
<head>
<style>
  body { font-family: 'Segoe UI', Arial, sans-serif; background-color: #f4f6f9; color: #333; margin: 0; padding: 20px; }
  .card { background: #ffffff; border-radius: 8px; padding: 20px; max-width: 700px; margin: 0 auto; box-shadow: 0 4px 10px rgba(0,0,0,0.08); }
  .header { background: #1e293b; color: #fff; padding: 18px; border-radius: 6px; text-align: center; }
  .status-badge { padding: 12px; border-radius: 6px; font-weight: bold; margin-top: 15px; text-align: center; font-size: 15px; }
  .status-ok { background: #d1fae5; color: #065f46; border: 1px solid #a7f3d0; }
  .status-warn { background: #fee2e2; color: #991b1b; border: 1px solid #fca5a5; }
  table { width: 100%; border-collapse: collapse; margin-top: 15px; font-size: 13px; }
  th, td { padding: 8px 10px; border-bottom: 1px solid #e2e8f0; text-align: left; }
  th { background-color: #f8fafc; color: #475569; font-weight: 600; }
  .proc-table { font-family: monospace; font-size: 12px; background: #0f172a; color: #f8fafc; border-radius: 6px; overflow: hidden; }
  .proc-table th { background-color: #1e293b; color: #38bdf8; border-bottom: 1px solid #334155; }
  .proc-table td { border-bottom: 1px solid #0f172a; }
  .pid-col { color: #facc15; font-weight: bold; }
  pre { background: #0f172a; color: #38bdf8; padding: 10px; border-radius: 6px; font-size: 11px; overflow-x: auto; white-space: pre-wrap; }
  .cmd-box { background: #0f172a; border-left: 4px solid #10b981; border-radius: 6px; padding: 12px; margin-top: 10px; }
  .cmd-title { color: #38bdf8; font-size: 12px; font-weight: bold; margin-bottom: 8px; display: block; }
  .cmd-code { width: 100%; background: #1e293b; color: #a7f3d0; border: 1px solid #334155; border-radius: 4px; padding: 10px; font-family: monospace; font-size: 12px; box-sizing: border-box; resize: none; }
  .config-warn { background: #fffbeb; border: 1px solid #fde68a; color: #92400e; padding: 15px; border-radius: 6px; margin-top: 15px; font-size: 13px; line-height: 1.5; }
  h3 { border-bottom: 2px solid #e2e8f0; padding-bottom: 6px; color: #1e293b; margin-top: 25px; font-size: 14px; }
  .footer { font-size: 11px; color: #94a3b8; margin-top: 25px; text-align: center; }
</style>
</head>
<body>
<div class="card">
  <div class="header">
    <h2 style="margin:0;">🛡️ ${MSG_TITLE}</h2>
    <p style="margin:6px 0 0 0; font-size:13px; font-weight:500; color:#e2e8f0; letter-spacing:0.5px;">${MSG_SUBTITLE}</p>
    <p style="margin:5px 0 0 0; font-size:12px; color:#cbd5e1;">Server: ${HOSTNAME} | ${MSG_VERSION_LABEL}: v${VERSION} (${DEFAULT_LANG^^}) | ${MSG_DATE_LABEL}: ${DATE}</p>
  </div>
EOF

if [ $ALERT -eq 0 ]; then
  echo "<div class='status-badge status-ok'>✅ ${MSG_STATUS_OK}</div>" >> "$REPORT_FILE"
else
  echo "<div class='status-badge status-warn'>🚨 ${MSG_STATUS_WARN}</div>" >> "$REPORT_FILE"
fi

cat <<EOF >> "$REPORT_FILE"
  <h3>🔍 ${MSG_SUMMARY_TITLE}</h3>
  <table>
    <tr><th>${MSG_COL_CATEGORY}</th><th>${MSG_COL_SCOPE}</th><th>${MSG_COL_STATUS}</th></tr>
    <tr><td><b>${MSG_ROW_TEMP}</b></td><td>/tmp, /var/tmp, /dev/shm</td><td>${TMP_STATUS}</td></tr>
    <tr><td><b>${MSG_ROW_JSP}</b></td><td>Jetty & Mailboxd Webapps</td><td>${JSP_STATUS}</td></tr>
    <tr><td><b>${MSG_ROW_NEW}</b></td><td>Jetty & Mailboxd Webapps</td><td>${NEW_FILES_STATUS}</td></tr>
    <tr><td><b>${MSG_ROW_PROC}</b></td><td>Zimbra Active Processes (ps aux)</td><td>${PROC_STATUS}</td></tr>
    <tr><td><b>${MSG_ROW_CRON}</b></td><td>crontab -u zimbra</td><td>${CRON_STATUS}</td></tr>
  </table>
EOF

# Configuration Warning Box if Exclude File is Missing
if [ $CONFIG_MISSING -eq 1 ]; then
  cat <<EOF >> "$REPORT_FILE"
  <div class="config-warn">
    <strong>⚠️ ${MSG_CONFIG_WARN_TITLE}</strong><br>
    ${MSG_CONFIG_WARN_TEXT}
  </div>
EOF
fi

# 1. Suspicious Temp Files
if [ -n "$TMP_SCAN" ]; then
  echo "<h3>❌ Suspicious Files in Temp Directories</h3><pre>${TMP_SCAN}</pre>" >> "$REPORT_FILE"
  
  CLEAN_FILE_CMDS=""
  for file in $TMP_SCAN; do
    CLEAN_FILE_CMDS="${CLEAN_FILE_CMDS}sudo rm -fv ${file}&#10;"
  done

  cat <<EOF >> "$REPORT_FILE"
  <div class="cmd-box">
    <span class="cmd-title">📋 ${MSG_CMD_REMEDIATION}</span>
    <textarea class="cmd-code" rows="2" onclick="this.select();" readonly>${CLEAN_FILE_CMDS}</textarea>
  </div>
EOF
fi

# 2. Webshell (.jsp) Files
if [ -n "$WEB_JSP_SCAN" ]; then
  echo "<h3>❌ Unauthorized .jsp Files Detected (Webshell)</h3><pre>${WEB_JSP_SCAN}</pre>" >> "$REPORT_FILE"
  
  CLEAN_JSP_CMDS=""
  for jsp in $WEB_JSP_SCAN; do
    CLEAN_JSP_CMDS="${CLEAN_JSP_CMDS}sudo rm -fv ${jsp}&#10;"
  done

  cat <<EOF >> "$REPORT_FILE"
  <div class="cmd-box">
    <span class="cmd-title">📋 ${MSG_CMD_REMEDIATION}</span>
    <textarea class="cmd-code" rows="2" onclick="this.select();" readonly>${CLEAN_JSP_CMDS}</textarea>
  </div>
EOF
fi

# 3. Suspicious Processes (Only if config exists and raw scan has output)
if [ -n "$RAW_PROC_SCAN" ]; then
  echo "<h3>❌ ${MSG_PROC_TABLE_TITLE}</h3>" >> "$REPORT_FILE"
  echo "<table class='proc-table'><tr><th>USER</th><th>PID</th><th>%CPU</th><th>%MEM</th><th>COMMAND</th></tr>" >> "$REPORT_FILE"
  
  echo "$RAW_PROC_SCAN" | while read -r user pid cpu mem vsz rss tty stat start time cmd; do
    echo "<tr><td>$user</td><td class='pid-col'>$pid</td><td>$cpu</td><td>$mem</td><td>$cmd</td></tr>" >> "$REPORT_FILE"
  done
  
  echo "</table>" >> "$REPORT_FILE"
  
  PROC_CMDS=""
  for pid in $DETECTED_PIDS; do
    PROC_CMDS="${PROC_CMDS}sudo ls -la /proc/${pid}/exe; sudo lsof -p ${pid}; sudo kill -9 ${pid}&#10;"
  done

  cat <<EOF >> "$REPORT_FILE"
  <div class="cmd-box">
    <span class="cmd-title">📋 ${MSG_CMD_REMEDIATION}</span>
    <textarea class="cmd-code" rows="3" onclick="this.select();" readonly>${PROC_CMDS}</textarea>
  </div>
EOF
fi

# 4. Cron Audits
if [ -n "$CRON_SCAN" ]; then
  echo "<h3>❌ Suspicious Lines in Zimbra Crontab</h3><pre>${CRON_SCAN}</pre>" >> "$REPORT_FILE"
fi

if [ -n "$NEW_WEB_FILES" ]; then
  echo "<h3>ℹ️ Web Files Created/Modified in last 24h</h3><pre>${NEW_WEB_FILES}</pre>" >> "$REPORT_FILE"
fi

cat <<EOF >> "$REPORT_FILE"
  <div class="footer">${MSG_FOOTER}</div>
</div>
</body>
</html>
EOF

# ------------------------------------------------------------------------------
# ALERT & EMAIL DISPATCH
# ------------------------------------------------------------------------------
SUBJECT="${MSG_SUBJ_OK} ${HOSTNAME} - ${DATE}"
if [ $ALERT -eq 1 ]; then
    if [ $CONFIG_MISSING -eq 1 ]; then
        SUBJECT="${MSG_SUBJ_WARN} ${HOSTNAME} - ${MSG_SUBJ_MISSING_EXC} - ${DATE}"
    else
        SUBJECT="${MSG_SUBJ_ALERT} ${HOSTNAME} - ${MSG_STATUS_WARN} - ${DATE}"
    fi

    # Send Telegram Notification (if Token and Chat ID are configured)
    if [ "$TELEGRAM_BOT_TOKEN" != "YOUR_TELEGRAM_BOT_TOKEN" ] && [ -n "$TELEGRAM_BOT_TOKEN" ]; then
        TG_MSG="🚨 <b>[ZIMBRA SECURITY ALERT]</b>%0A<b>Server:</b> ${HOSTNAME}%0A<b>Date:</b> ${DATE}%0A%0A⚠️ Security warning or missing configuration detected! Check your email inbox."
        curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
             -d "chat_id=${TELEGRAM_CHAT_ID}" \
             -d "parse_mode=HTML" \
             -d "text=${TG_MSG}" > /dev/null
    fi
fi

mail -a "Content-Type: text/html; charset=UTF-8" -a "From: ${MAIL_FROM}" -s "$SUBJECT" "$MAIL_TO" < "$REPORT_FILE"
rm -f "$REPORT_FILE"
