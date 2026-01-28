# Changelog

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
