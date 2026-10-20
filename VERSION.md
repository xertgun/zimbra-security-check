# Zimbra Security Check - Version History

## [v2.0.2] - 2026-03-31
- **i18n Enhancement:** Moved "Version" and "Date" labels inside language configuration files (`lang/*.conf`) for full multi-language header support.
- **Version Management:** Version number and history are now officially tracked via `VERSION.md`.

## [v2.0.1] - 2026-03-31
- **French Language Support:** Added `lang/fr.conf` for complete French localization.
- **Installer Update:** Updated `install.sh` with interactive French language selection option.
- **Documentation:** Updated `README.md` to display structured multi-language support.

## [v2.0.0] - 2026-03-30
- **Modular Architecture:** Introduced multi-language support architecture (`en`, `tr`, `de`).
- **Enhanced Scans:** Improved temp directory triage, `.jsp` webshell detection, and process memory inspection using external excludes.
- **HTML & Telegram Reporting:** Upgraded to rich responsive HTML email reports with click-and-copy remediation commands and instant Telegram alerts.
