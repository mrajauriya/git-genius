# ✨ Git Genius v3.7 – Beautiful Developer-Focused GitHub CLI Helper

![GitHub](https://img.shields.io/github/license/moHaN-ShaArmA/git-genius?style=flat-square)
![Bash](https://img.shields.io/badge/made%20with-Bash-blue?style=flat-square)
![GitHub stars](https://img.shields.io/github/stars/moHaN-ShaArmA/git-genius?style=flat-square)

> **Smart Git Automation for Android Termux & AndroidIDE**  
> *Crafted with ♥ by [moHaN-ShaArmA](https://github.com/moHaN-ShaArmA)*

---

## 🚀 About

**Git Genius v3.7** is a beautiful, terminal-based GitHub CLI helper made especially for Android developers using Termux or AndroidIDE. It automates Git workflows, provides a visually pleasing GUI-like interface, and saves time with configuration memory, secure token handling, and one-command interactions.

---

## ✨ Features

| Feature                     | Description                                                                 |
|----------------------------|-----------------------------------------------------------------------------|
| 🔼 **Push Changes**         | Automatically stage, commit, and push to your GitHub repo with auth         |
| 🔽 **Pull Latest**          | Fetch and merge the latest changes from remote                              |
| 🔍 **View Status**          | See uncommitted changes and Git status                                      |
| 📝 **View Log**             | Beautifully formatted commit log (graph + decorations)                      |
| 🧾 **View Diff**            | See file differences before committing                                      |
| 🌿 **Switch/Create Branch** | Seamlessly switch or create branches and save the default                   |
| 📦 **Generate .gitignore**  | Auto-create a basic `.gitignore` file for Android projects                  |
| 👀 **View File History**    | View commit history of any file using `git log --follow`                    |
| 🔗 **Show Remote URL**      | Display your current GitHub repo remote URL                                 |
| ⚙ **Settings**              | Update user config, token, branch, or remote any time                       |
| ❓ **Help**                 | Understand every option in a clean format                                   |
| ✅ **Git Auto-Installer**   | Automatically installs `git` if not found on your system                    |

---

## ⚙️ Setup

Just run the script once, and Git Genius will:
1. Ask for your **GitHub username** and **email**
2. Securely store your **Personal Access Token (PAT)**
3. Initialize Git if needed
4. Ask for your **default branch** (main/master/etc.)
5. Add or update your **remote origin**

> All configs are securely saved inside `~/.git-*` files for reuse.

---

## 🧪 Requirements

- Android with **Termux** or **AndroidIDE**
- Internet connection
- A GitHub **PAT (Personal Access Token)**
- Bash shell

> Git Genius will auto-install `git` if it's not already available.

---

## ▶️ How to Use

```bash
bash git-genius.sh
