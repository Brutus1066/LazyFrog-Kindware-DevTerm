# 🐸 LazyFrog DevTerm - Release v2.0.0

**A keyboard-first terminal utility for developers who stay in the shell**

---

## 📦 Package Contents

| File | Description |
|------|-------------|
| LazyFrog-DevTerm-Setup-v2.0.0.exe | One-click installer (recommended) |
| LazyFrog-DevTerm-v2.0.0.zip | Portable package |
| LazyFrog-DevTerm-v2.0.0/ | Unpacked portable version |

---

## 🚀 Quick Start

### Option 1: Run the Installer (Recommended)
1. Double-click LazyFrog-DevTerm-Setup-v2.0.0.exe
2. Follow the prompts
3. Launch from Desktop or Start Menu

### Option 2: Portable Use
1. Extract LazyFrog-DevTerm-v2.0.0.zip
2. Run LazyFrog-DevTerm.bat or LazyFrog.exe

---

## ⚡ Requirements

- **Windows 10/11**
- **PowerShell 7+** ([Download](https://github.com/PowerShell/PowerShell/releases))
- **Windows Terminal** (recommended for best experience)

---

## 🎯 Features

- **GitHub Scanner** - Search repos, save results as JSON/Markdown
- **Task Runner** - Run saved commands with one keystroke
- **System Monitor** - Quick health check without leaving terminal
- **Help & Docs** - Built-in documentation

---

## ⌨️ Keyboard Shortcuts

| Key | Action |
|-----|--------|
| **1-4** | Jump to module |
| **↑/↓** | Navigate |
| **Enter** | Select |
| **Q** | Quit |
| **Esc** | Back |

---

## 📁 Data Locations

After installation:
- **App files:** %LOCALAPPDATA%\LazyFrog-DevTerm
- **GitHub results:** esults/
- **Task history:** history/task-history.json
- **Logs:** %LOCALAPPDATA%\LazyFrog-DevTerm\logs

---

## 🔧 Troubleshooting

**App doesn't start?**
- Ensure PowerShell 7+ is installed
- Try: pwsh -File src\main.ps1

**Git tasks fail (exit code 128)?**
- Start LazyFrog from inside a Git repository folder

**Need more help?**
- See docs/TROUBLESHOOTING.md
- Open an issue: https://github.com/Brutus1066/LazyFrog-Kindware-DevTerm/issues

---

## 📜 License

MIT License - See LICENSE file for details.

---

**Made with 🐸 by Kindware.dev**

GitHub: https://github.com/Brutus1066/LazyFrog-Kindware-DevTerm
