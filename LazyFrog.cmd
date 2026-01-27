@echo off
title LazyFrog Developer Tools - powered by Kindware.dev
cd /d "%~dp0"

:: Check for PowerShell 7
if exist "C:\Program Files\PowerShell\7\pwsh.exe" (
    "C:\Program Files\PowerShell\7\pwsh.exe" -NoProfile -ExecutionPolicy Bypass -NoLogo -File "%~dp0src\main.ps1"
) else (
    echo PowerShell 7 is required but not found.
    echo Please install PowerShell 7 from: https://github.com/PowerShell/PowerShell/releases
    pause
)
