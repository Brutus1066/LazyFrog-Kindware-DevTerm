# 🐸 LazyFrog DevTerm - Release Guide

This folder contains the build system for creating distributable releases of LazyFrog DevTerm.

---

## 📦 What Gets Built

Running the build script creates:

| File | Description |
|------|-------------|
| `LazyFrog-DevTerm-Setup-v{VERSION}.exe` | One-click installer with embedded icon |
| `LazyFrog-DevTerm-v{VERSION}.zip` | Portable ZIP package |
| `LazyFrog-DevTerm-v{VERSION}/` | Complete package folder |
| `LazyFrog-DevTerm-v{VERSION}/LazyFrog.exe` | Launcher executable with embedded icon |

---

## 🚀 Building a Release

### Prerequisites

1. **PowerShell 7+** - Required for build scripts
2. **PS2EXE module** - Auto-installed if missing (creates .exe files)

### Build Commands

```powershell
# Full build (creates all artifacts)
cd release
pwsh -File Build-Release.ps1

# Build with specific version
pwsh -File Build-Release.ps1 -Version "1.2.0"

# Clean build (removes previous artifacts first)
pwsh -File Build-Release.ps1 -Clean

# Skip EXE creation (for systems without PS2EXE)
pwsh -File Build-Release.ps1 -SkipExe
```

### Build Output

After a successful build, the `output/` folder contains:

```
output/
├── README.md                           # Release notes
├── LazyFrog-DevTerm-Setup-v1.1.1.exe  # Installer EXE
├── LazyFrog-DevTerm-v1.1.1.zip        # Portable ZIP
└── LazyFrog-DevTerm-v1.1.1/           # Package folder
    ├── LazyFrog.exe                    # Launcher (with icon)
    ├── LazyFrog-DevTerm.bat           # Batch launcher
    ├── Install-LazyFrogDevTerm.ps1    # PowerShell installer
    ├── icon.ico                        # Application icon
    ├── config.json                     # Default config
    ├── tasks.json                      # Default tasks
    ├── watchlist.json                  # Empty watchlist
    ├── README.md                       # User documentation
    ├── CHANGELOG.md                    # Version history
    ├── LICENSE                         # MIT License
    ├── src/                            # Application source
    │   ├── main.ps1
    │   ├── lib/
    │   └── tools/
    ├── docs/                           # Documentation
    │   ├── INSTALL.md
    │   ├── USAGE.md
    │   ├── TROUBLESHOOTING.md
    │   └── assets/
    ├── results/                        # For GitHub search output
    └── history/                        # For task history
```

---

## 🔧 How the Build Works

### 1. Source Collection
- Copies all required files from project root
- Includes source, docs, config, and icon

### 2. Script Generation
- Creates `Install-LazyFrogDevTerm.ps1` (full installer)
- Creates `LazyFrog-DevTerm.bat` (batch launcher)

### 3. EXE Creation (via PS2EXE)
- **LazyFrog.exe** - Compiled from `LazyFrog-Launcher.ps1`
  - Icon is embedded at compile time
  - Runs without console window
  - Launches PowerShell 7 with main.ps1
  
- **Setup.exe** - Compiled from installer script
  - Icon is embedded
  - Runs with console for user interaction
  - Handles installation to user's system

### 4. Packaging
- Creates ZIP archive for portable distribution
- Generates release README with install instructions

---

## 🎨 Icon Handling

The build system looks for icons in this order:

1. `{project}/icon.ico`
2. `{project}/desktop.launcher.icon.ico/icon.ico`
3. `{release}/icon.ico`

Icons are:
- **Embedded** into the EXE files at compile time
- **Copied** to the package for shortcut creation
- **Referenced** by shortcuts created during installation

### Shortcut Icon Persistence

The installer creates shortcuts with proper icon paths:
- If `LazyFrog.exe` exists: uses `LazyFrog.exe,0` (embedded icon)
- Otherwise: uses `icon.ico,0` (separate icon file)

This ensures icons persist after system reboots.

---

## 📋 Release Checklist

Before building a release:

- [ ] Update version in `config.json`
- [ ] Update version in `Build-Release.ps1` (or use `-Version` flag)
- [ ] Update `CHANGELOG.md` with new changes
- [ ] Test the application locally
- [ ] Commit all changes to git

After building:

- [ ] Test the installer on a clean system
- [ ] Test the portable ZIP
- [ ] Verify icon appears on desktop shortcut
- [ ] Verify app launches correctly
- [ ] Create GitHub Release and upload artifacts

---

## 🐛 Troubleshooting Build Issues

### PS2EXE Installation Fails
```powershell
# Manual install
Install-Module -Name ps2exe -Scope CurrentUser -Force

# Or skip EXE creation
pwsh -File Build-Release.ps1 -SkipExe
```

### Icon Not Embedded
- Ensure `icon.ico` exists in project root or `desktop.launcher.icon.ico/` folder
- ICO file must be a valid Windows icon format

### Build Script Errors
- Ensure you're running from the `release/` folder
- Use PowerShell 7+: `pwsh -File Build-Release.ps1`
- Check that all source files exist in project root

---

## 📤 Uploading to GitHub

1. Go to: https://github.com/Brutus1066/LazyFrog-Kindware-DevTerm/releases
2. Click "Create a new release"
3. Tag: `v1.1.1` (match your version)
4. Title: `LazyFrog DevTerm v1.1.1`
5. Upload:
   - `LazyFrog-DevTerm-Setup-v1.1.1.exe`
   - `LazyFrog-DevTerm-v1.1.1.zip`
6. Add release notes from CHANGELOG
7. Publish!

---

**Made with 🐸 by Kindware.dev**
