#!/bin/bash
# ==============================================================================
# Script Name : zimbra-security-check.sh
# Description : Daily integrity scanner and security reporter for Zimbra ZCS
# Tested On   : Zimbra Collaboration Suite 8.8.15 (ZCS 8.8.15 GA)
# Author      : EGTA Software (Ertan Günay)
# Repository  : https://github.com/xertgun/zimbra-security-check
# ==============================================================================

# ------------------------------------------------------------------------------
# CONFIGURATION AREA (User Specific Settings)
# ------------------------------------------------------------------------------
MAIL_TO="your-email@domain.com"
HOSTNAME=$(hostname -f)
DATE=$(date +"%Y-%m-%d %H:%M")
REPORT_FILE="/tmp/sec_report_$$.html"

# Telegram Bot Credentials (Leave empty if not using Telegram alerts)
TELEGRAM_BOT_TOKEN="YOUR_TELEGRAM_BOT_TOKEN"
TELEGRAM_CHAT_ID="YOUR_TELEGRAM_CHAT_ID"

# ------------------------------------------------------------------------------
# SECURITY SCANS
# ------------------------------------------------------------------------------
ALERT=0

# 1. Directory and File Triage Scans
TMP_SCAN=$(find /tmp /var/tmp /dev/shm -type f \( -name "*.sh" -o -name "*.py" -o -name "*.php" -o -executable \) 2>/dev/null)
WEB_JSP_SCAN=$(find /opt/zimbra/jetty/webapps /opt/zimbra/mailboxd/webapps -type f -name "*.jsp" ! -path "*/zimbraAdmin/*" ! -path "*/zimbra/*" ! -path "*/service/*" 2>/dev/null)
NEW_WEB_FILES=$(find /opt/zimbra/jetty/webapps/ /opt/zimbra/mailboxd/webapps/ -type f -mtime -1 2>/dev/null | grep -vE "\.(xml|properties|html)$")

# 2. Process / Memory Inspection (Excluding known Zimbra & Postfix internal daemons)
RAW_PROC_SCAN=$(ps aux | grep -E "zimbra|postfix" | grep -v -E "java|mailboxd|mysqld|amavis|postfix/|slapd|nginx|sasl|log|unbound|clamd|freshclam|opendkim|httpd|perl|swatchdog|zmstat|iostat|vmstat|grep|master|zimbra-security-check|pickup|qmgr|tlsmgr|postscreen|smtpd|showq|anvil|cleanup|proxymap|bounce|trace|verify|flush|trivial-rewrite|lmtp|zmantispamctl|smtp" 2>/dev/null)

if [ -n "$RAW_PROC_SCAN" ]; then
  ALERT=1
  DETECTED_PIDS=$(echo "$RAW_PROC_SCAN" | awk '{print $2}' | tr '\n' ' ' | sed 's/ $//')
fi

# 3. Zimbra Crontab Inspection
CRON_SCAN=$(crontab -u zimbra -l 2>/dev/null | grep -vE "^#|^$" | grep -v "zimbra")

# Status Label Definitions
TMP_STATUS="✅ Clean"
[ -n "$TMP_SCAN" ] && TMP_STATUS="❌ Suspicious File!" && ALERT=1

JSP_STATUS="✅ Clean"
[ -n "$WEB_JSP_SCAN" ] && JSP_STATUS="❌ Unauthorized .jsp File!" && ALERT=1

NEW_FILES_STATUS="✅ Clean"
[ -n "$NEW_WEB_FILES" ] && NEW_FILES_STATUS="⚠️ Modified in last 24h"

PROC_STATUS="✅ Normal"
[ -n "$RAW_PROC_SCAN" ] && PROC_STATUS="❌ Unknown Process!"

CRON_STATUS="✅ Clean"
[ -n "$CRON_SCAN" ] && CRON_STATUS="❌ Unauthorized Job!" && ALERT=1

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
  .proc-table td { border-bottom: 1px solid #1e293b; }
  .pid-col { color: #facc15; font-weight: bold; }
  pre { background: #0f172a; color: #38bdf8; padding: 10px; border-radius: 6px; font-size: 11px; overflow-x: auto; white-space: pre-wrap; }
  .cmd-box { background: #0f172a; border-left: 4px solid #10b981; border-radius: 6px; padding: 12px; margin-top: 10px; }
  .cmd-title { color: #38bdf8; font-size: 12px; font-weight: bold; margin-bottom: 8px; display: block; }
  .cmd-code { width: 100%; background: #1e293b; color: #a7f3d0; border: 1px solid #334155; border-radius: 4px; padding: 10px; font-family: monospace; font-size: 12px; box-sizing: border-box; resize: none; }
  h3 { border-bottom: 2px solid #e2e8f0; padding-bottom: 6px; color: #1e293b; margin-top: 25px; font-size: 14px; }
  .footer { font-size: 11px; color: #94a3b8; margin-top: 25px; text-align: center; }
</style>
</head>
<body>
<div class="card">
  <div class="header">
    <h2 style="margin:0;">🛡️ Zimbra Daily Integrity & Security Report</h2>
    <p style="margin:5px 0 0 0; font-size:12px; color:#cbd5e1;">Server: ${HOSTNAME} | Date: ${DATE}</p>
  </div>
EOF

if [ $ALERT -eq 0 ]; then
  echo "<div class='status-badge status-ok'>✅ Security Scan Completed - No Threats or Intrusions Detected</div>" >> "$REPORT_FILE"
else
  echo "<div class='status-badge status-warn'>🚨 WARNING: Suspicious Activity / Unauthorized Files Detected!</div>" >> "$REPORT_FILE"
fi

cat <<EOF >> "$REPORT_FILE"
  <h3>🔍 Scan & Audit Summary</h3>
  <table>
    <tr><th>Audit Category</th><th>Scanned Scope / Directory</th><th>Status</th></tr>
    <tr><td><b>Temp Directory Scan</b></td><td>/tmp, /var/tmp, /dev/shm</td><td>${TMP_STATUS}</td></tr>
    <tr><td><b>Webshell (.jsp) Scan</b></td><td>Jetty & Mailboxd Webapps</td><td>${JSP_STATUS}</td></tr>
    <tr><td><b>24-Hour File Modifications</b></td><td>Jetty & Mailboxd Webapps</td><td>${NEW_FILES_STATUS}</td></tr>
    <tr><td><b>Memory / Process Audit</b></td><td>Zimbra Active Processes (ps aux)</td><td>${PROC_STATUS}</td></tr>
    <tr><td><b>Backdoor (Cron) Audit</b></td><td>crontab -u zimbra</td><td>${CRON_STATUS}</td></tr>
  </table>
EOF

# 1. Suspicious Temp Files
if [ -n "$TMP_SCAN" ]; then
  echo "<h3>❌ Suspicious Files in Temp Directories</h3><pre>${TMP_SCAN}</pre>" >> "$REPORT_FILE"
  
  CLEAN_FILE_CMDS=""
  for file in $TMP_SCAN; do
    CLEAN_FILE_CMDS="${CLEAN_FILE_CMDS}sudo rm -fv ${file}&#10;"
  done

  cat <<EOF >> "$REPORT_FILE"
  <div class="cmd-box">
    <span class="cmd-title">📋 Remediation Commands for Suspicious Files (Click & Copy):</span>
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
    <span class="cmd-title">📋 Remediation Commands for Webshells (Click & Copy):</span>
    <textarea class="cmd-code" rows="2" onclick="this.select();" readonly>${CLEAN_JSP_CMDS}</textarea>
  </div>
EOF
fi

# 3. Suspicious Processes
if [ -n "$RAW_PROC_SCAN" ]; then
  echo "<h3>❌ Suspicious Running Processes</h3>" >> "$REPORT_FILE"
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
    <span class="cmd-title">📋 Process Inspection & Termination Commands (Click & Copy):</span>
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
  <div class="footer">This report was automatically generated by EGTA Defense System.</div>
</div>
</body>
</html>
EOF

# ------------------------------------------------------------------------------
# ALERT & EMAIL DISPATCH
# ------------------------------------------------------------------------------
SUBJECT="[ZIMBRA SECURITY OK] ${HOSTNAME} - ${DATE}"
if [ $ALERT -eq 1 ]; then
  SUBJECT="[🚨 ZIMBRA ALERT] ${HOSTNAME} - Suspicious Activity Detected - ${DATE}"
  
  # Send Telegram Notification (if Token and Chat ID are configured)
  if [ "$TELEGRAM_BOT_TOKEN" != "YOUR_TELEGRAM_BOT_TOKEN" ] && [ -n "$TELEGRAM_BOT_TOKEN" ]; then
    TG_MSG="🚨 <b>[ZIMBRA SECURITY ALERT]</b>%0A<b>Server:</b> ${HOSTNAME}%0A<b>Date:</b> ${DATE}%0A%0A⚠️ Unauthorized file, webshell, or suspicious process detected on server!%0ACheck your email inbox for remediation commands."
    curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
         -d "chat_id=${TELEGRAM_CHAT_ID}" \
         -d "parse_mode=HTML" \
         -d "text=${TG_MSG}" > /dev/null
  fi
fi

mail -a "Content-Type: text/html; charset=UTF-8" -s "$SUBJECT" "$MAIL_TO" < "$REPORT_FILE"
rm -f "$REPORT_FILE"
