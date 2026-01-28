# Installation

This guide covers both the packaged installer and a direct run from source.

---

## Requirements

- Windows 10/11
- PowerShell 7+
- Windows Terminal (recommended)

---

## Option A: Install from package (recommended)

1. Build the package:
   ```powershell
   .\installer\build-installer.ps1
   ```
2. Run the installer:
   ```powershell
   .\dist\LazyFrog-DevTerm-Package\Install-LazyFrogDevTerm.ps1
   ```
3. Approve the PowerShell 7 prompt if it appears.
4. Launch from the Start Menu or desktop shortcut.

---

## Option B: Run without installing

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\src\main.ps1
```

This is useful for testing changes or running from a cloned repo.

---

## Uninstall

- Re-run the installer and choose **Uninstall**, or delete the folder:
  %LOCALAPPDATA%\LazyFrog-DevTerm

Shortcuts live in the Start Menu and Desktop and are removed by uninstall.
