# Contributing to Zimbra Security Check

Thank you for your interest in the Zimbra Security Check project! The open-source ecosystem thrives on community support, and every contribution is greatly appreciated.

If you would like to contribute, please keep the following guidelines and instructions in mind:

---

## 🛠️ How You Can Contribute

### 1. Bug Reports and Feature Requests
* If you encounter any bugs or would like to suggest a new feature, please use the **GitHub Issues** tab.
* When reporting a bug, please include your system environment (Zimbra version, Operating System) and steps to reproduce it.

### 2. Localization and Language Support
* Our project supports multiple languages (`en`, `tr`, `de`, `fr`, `es`, `ru`). 
* If you would like to add a new language or improve existing localizations, you can update the `.conf` files under the `lang/` directory and submit a Pull Request (PR).

### 3. Code Contributions and Pull Requests
To submit code contributions directly to the repository, follow these steps:
1. **Fork** this repository.
2. Create a new feature branch (`git checkout -b feature/your-feature-name`).
3. Commit your changes with a clear commit message (`git commit -m "feat: add new feature"`).
4. Push to your remote repository (`git push origin feature/your-feature-name`).
5. Open a **Pull Request (PR)** against the main repository.

---

## 📋 Code and Contribution Guidelines

* **Clean Code:** Ensure that our scripts (`.sh`) are readable, POSIX-compliant, and adhere to standard Bash best practices.
* **False Positive Sensitivity:** Since we are developing a security scanning tool, make sure any rules or exceptions (*excludes*) you add do not produce misleading alerts (*false positives*) in production environments.
* **Disclaimer:** Keep in mind that this tool is strictly a reporting utility, and the final operational responsibility always lies with the system administrator.

## 💬 Communication
For questions, suggestions, or discussions, feel free to start a discussion via GitHub Issues.

*Thank you for helping improve this project!*
