# 📱 How to Set Up Telegram Bot for Security Alerts

Follow these simple steps to create a Telegram Bot and obtain your `TELEGRAM_BOT_TOKEN` and `TELEGRAM_CHAT_ID` to receive real-time push alerts from `zimbra-security-check.sh`.

---

## Step 1: Create a Telegram Bot
   1. Open your Telegram app and search for **`@BotFather`** (the official Telegram bot manager).
   2. Start a chat and send the command:
      ```text
      /newbot
      ```
      1. Enter a Name for your bot (`e.g., My Server Monitor`).
      2. Enter a unique Username ending in bot (e.g., `ZimbraAlerts_bot`).
      3. BotFather will reply with your HTTP API Token.
         > **Example Token:** `123456789:ABCdefGhIJKlmNoPQRsTUVwxyZ1234567`
         > 
         > 📌 Save this token as your **`TELEGRAM_BOT_TOKEN`**.
## Step 2: Get Your Chat ID
   ### Option A: For Personal Direct Messages (Simplest)
   1. Search for `@userinfobot` or `@raw_data_bot` in Telegram and send any message.
   2. The bot will instantly reply with your personal Id (a series of numbers like `987654321`).
   3. Send at least one initial message to your newly created bot (`@YourBotUsername`) so Telegram allows it to message you.

   ### Option B: For Telegram Group Channels
   1. Create a Telegram Group and add your newly created bot as a member/administrator.
   2. Send a dummy message in the group.
   3. Open your browser and visit the following URL (replace `<YOUR_BOT_TOKEN>` with your real token):
      ```text
      https://api.telegram.org/bot<YOUR_BOT_TOKEN>/getUpdates
      ```
   4. Look for `"chat":{"id": -100xxxxxxxxxx}` in the JSON response.
      > 📌 Save this number (including the minus - sign) as your `TELEGRAM_CHAT_ID`.
## Step 3: Configure the Script
   Open zimbra-security-check.sh and insert your credentials:
   ```bash
   TELEGRAM_BOT_TOKEN="123456789:ABCdefGhIJKlmNoPQRsTUVwxyZ1234567"
   TELEGRAM_CHAT_ID="987654321"
   ```
   Test your setup by running the script manually:
   ```bash
   ./zimbra-security-check.sh
   ```
