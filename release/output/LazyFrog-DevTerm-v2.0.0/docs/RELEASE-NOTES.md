# Release Notes

## 1.2.0 - January 2026

### Complete Release Build System 🎉

This release introduces a professional build and distribution system for LazyFrog DevTerm.

**New Features:**
- **Build-Release.ps1** - One-command script to create distributable packages
- **Setup.exe** - One-click installer with embedded application icon
- **LazyFrog.exe** - Launcher executable with embedded icon
- **Icon persistence** - Desktop shortcut icons now survive system reboots
- **Quick Start Guide** - New `docs/QUICK_START.md` for fast onboarding
- **Portable ZIP** - Automatic ZIP creation for portable distribution
- **Silent install** - `-Silent` flag for automated deployments
- **Auto-start option** - `-AutoStart` flag to launch on login

**Improvements:**
- Installer creates shortcuts with properly embedded icon references
- Better error handling and logging throughout
- Enhanced build documentation with complete release workflow

**How to Build:**
```powershell
cd release
pwsh -File Build-Release.ps1 -Version "1.2.0"
```

---

## 1.1.1 - January 2026

This release focuses on polish and reliability. The UI is cleaner, help content is easier to read, and installer behavior is more predictable.

- Branding simplified to **LazyFrog DevTerm**
- Help and menu layout cleaned up for better readability
- GitHub save actions improved (no extra prompts)
- Installer copy and source detection hardened
- System monitor refresh throttling to reduce flicker
