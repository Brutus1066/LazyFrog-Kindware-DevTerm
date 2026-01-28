# 🐸 LazyFrog DevTerm - Quick Start Guide

Get up and running in under 2 minutes!

---

## ⚡ Super Quick Install

### Method 1: One-Click Installer (Easiest)

1. Download `LazyFrog-DevTerm-Setup-vX.X.X.exe`
2. Double-click to run
3. Follow the prompts
4. Done! Launch from Desktop or Start Menu

### Method 2: Portable (No Install)

1. Download `LazyFrog-DevTerm-vX.X.X.zip`
2. Extract anywhere
3. Run `LazyFrog.exe` or `LazyFrog-DevTerm.bat`

---

## 📋 Prerequisites

You need **PowerShell 7+** installed:

- **Already have it?** You're good to go!
- **Need to install it?** The installer will offer to do it for you via winget
- **Manual install:** [Download here](https://github.com/PowerShell/PowerShell/releases)

---

## 🎮 Basic Controls

| Key | What it does |
|-----|--------------|
| **↑/↓** | Move up/down |
| **Enter** | Select |
| **1-4** | Jump to module |
| **Q** | Quit |
| **Esc** | Go back |

---

## 🗂️ Main Modules

### 1️⃣ GitHub Scanner
Search public repositories, save results as JSON or Markdown.

### 2️⃣ Task Runner
Run saved commands with one keystroke. Perfect for common workflows.

### 3️⃣ System Monitor
Quick health check - CPU, RAM, disk usage.

### 4️⃣ Help
Built-in documentation and keyboard shortcuts.

---

## 💡 Pro Tips

- **Start from a Git folder** - Some Task Runner commands need to be inside a Git repository
- **Use Windows Terminal** - Best colors and experience
- **Save your searches** - Press **J** for JSON, **M** for Markdown in GitHub Scanner

---

## 📁 Where's My Stuff?

| What | Where |
|------|-------|
| App files | `%LOCALAPPDATA%\LazyFrog-DevTerm` |
| Search results | `results/` folder |
| Task history | `history/task-history.json` |
| Logs | `%LOCALAPPDATA%\LazyFrog-DevTerm\logs` |

---

## ❓ Need Help?

- **Built-in help:** Press **4** in the main menu
- **Documentation:** Check the `docs/` folder
- **Issues:** [GitHub Issues](https://github.com/Brutus1066/LazyFrog-Kindware-DevTerm/issues)

---

## 🗑️ Uninstall

Run the installer with the uninstall flag:
```powershell
pwsh -File Install-LazyFrogDevTerm.ps1 -Uninstall
```

Or just delete the install folder: `%LOCALAPPDATA%\LazyFrog-DevTerm`

---

**Enjoy your new developer workflow! 🐸**

*Made by Kindware.dev*
