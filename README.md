# 🛡️ Zimbra Daily Security & Integrity Scanner

An automated Bash-based integrity scanner and incident response tool for Zimbra Collaboration Suite (ZCS).
> 📌 **Tested & Compatible with:** Zimbra Collaboration Suite 8.8.15 (ZCS 8.8.15 GA).

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
      MAIL_FROM="Zimbra Security <zimbra@yourdomain.com>"
      MAIL_TO="admin@yourdomain.com"

      # Optional: Configure Telegram Bot for instant mobile push alerts
      TELEGRAM_BOT_TOKEN="YOUR_TELEGRAM_BOT_TOKEN"
      TELEGRAM_CHAT_ID="YOUR_TELEGRAM_CHAT_ID"
   ```
   > 💡 *Need help setting up Telegram notifications? Check out the [Telegram Setup Guide](TELEGRAM_SETUP.md).*

3. Add to root crontab to run daily at 07:00 AM:
   ```cron
      0 7 * * * /your_script_folder/zimbra-security-check.sh > /dev/null 2>&1
   ```

## 💡 Why This Project Exists

This project was developed in response to real-world security incidents and stealthy intrusion attempts targeting Zimbra 8.8.15 servers. Standard monitoring tools often miss low-profile threats that bypass basic log checks. 

This automated scanner was specifically created to provide instant visibility against:

- **Webshell Uploads:** Unauthorized `.jsp` backdoors injected into Jetty & Mailboxd web applications.
- **Rogue Executables:** Suspicious `.sh`, `.py`, or binary execution attempts inside `/tmp`, `/var/tmp`, and `/dev/shm`.
- **Memory Persistence:** Stealthy background processes masquerading under Zimbra system privilege.
- **Crontab Backdoors:** Unauthorized scheduled tasks added to the `zimbra` user crontab.

Instead of just sending generic alerts, it automatically generates **Click & Copy** terminal commands to empower sysadmins with zero-delay incident response.

## 🔗 Related Projects
- [zimbra-fail2ban](https://github.com/xertgun/zimbra-fail2ban) - Fail2Ban filters, jail rules, and daily HTML defense reporter for Zimbra.
