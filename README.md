# 🛡️ Zimbra Daily Security & Integrity Scanner

An automated Bash-based integrity scanner and incident response tool for Zimbra Collaboration Suite (ZCS).

## ✨ Features
- **Webshell Detection:** Scans Jetty & Mailboxd web application paths for unauthorized `.jsp` files.
- **Temp Directory Audit:** Scans `/tmp`, `/var/tmp`, and `/dev/shm` for rogue scripts and binary executables.
- **Process Memory Inspection:** Filters out legitimate Zimbra/Postfix daemons and highlights unknown running processes.
- **Crontab Audit:** Checks for unauthorized persistence mechanisms added to the `zimbra` user crontab.
- **Interactive HTML Email Reports:** Sends a responsive HTML report with **Click & Copy** remediation commands.
- **Instant Telegram Alerts:** Sends real-time emergency notifications directly to your Telegram chat/channel when threats or anomalies are detected.

## 🚀 Quick Start

1. Download the script and make it executable:
```bash
wget https://raw.githubusercontent.com/xertgun/zimbra-security-check/main/zimbra-security-check.sh
chmod +x zimbra-security-check.sh
```

2. Edit configuration parameters inside the script:
```bash
   MAIL_TO="admin@yourdomain.com"

   # Optional: Configure Telegram Bot for instant mobile push alerts
   TELEGRAM_BOT_TOKEN="your_bot_token"
   TELEGRAM_CHAT_ID="your_chat_id"
```

3. Add to root crontab to run daily at 07:00 AM:
```cron
   0 7 * * * /your_script_folder/zimbra-security-check.sh > /dev/null 2>&1
```
