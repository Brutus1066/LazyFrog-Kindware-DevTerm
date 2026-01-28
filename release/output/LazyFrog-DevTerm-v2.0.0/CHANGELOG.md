# Changelog

## 2.0.0 - 2026-01-28

### ✨ KINDWARE Rainbow CLI Styling
- **Rainbow KINDWARE ASCII Logo** - Beautiful multi-color ASCII art header with gradient colors
- **PowerShell 7+ Required** - Upgraded from PowerShell 5.1 to 7.0+ for ANSI color support
- **Modern Box Drawing** - Rounded corners (╭╮╯╰) on menus and UI elements
- **Emoji Icons** - Visual menu icons (🔍 📊 ⚙️ ❓) for better UX
- **ANSI Color System** - Full rainbow palette with Red, Yellow, Green, Cyan, Blue, Magenta
- **Status Message Helpers** - New `Write-KindSuccess`, `Write-KindError`, `Write-KindWarning`, `Write-KindInfo` functions
- **Rainbow Exit Screen** - Colorful KINDWARE goodbye message on exit

### Changed
- Version bumped to 2.0.0 to reflect major UI overhaul
- Updated all documentation with KINDWARE branding
- Cyan accent colors throughout the UI
- Modernized header with rainbow KINDWARE styling

---

## 1.2.0 - 2026-01-28

### Added
- **Complete Release Build System** - New `release/` folder with professional build tools
- **Build-Release.ps1** - One-command build script for creating distributable packages
- **Setup.exe** - One-click installer with embedded icon
- **LazyFrog.exe** - Launcher executable with embedded icon that persists after reboot
- **Icon embedding** - Application icon now baked into executables and shortcuts
- **Quick Start Guide** - New `docs/QUICK_START.md` for fast onboarding
- **Portable ZIP packaging** - Automatic ZIP creation for portable distribution
- **Silent install option** - `-Silent` flag for automated deployments
- **Auto-start option** - `-AutoStart` flag to enable launch on login

### Changed
- Installer now creates shortcuts with properly embedded icon references
- Improved shortcut icon persistence across system reboots
- Enhanced build documentation with complete release workflow
- Better error handling and logging in installer

### Fixed
- Desktop shortcut icons now persist after reboot
- Icon properly displayed in taskbar and Start Menu

---

## 1.1.1 - 2026-01-27

### Added
- Cleaner main menu header and layout polish.
- Help view cleanup and GitHub save guidance.
- System monitor refresh throttling to reduce flicker.

### Changed
- Branding simplified to "LazyFrog DevTerm".
- GitHub save actions now default to last search results.
- Installer source-path detection and copy logging improved.
