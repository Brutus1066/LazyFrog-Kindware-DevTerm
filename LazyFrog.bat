@echo off
title LazyFrog Developer Tools
cd /d "%~dp0"
"C:\Program Files\PowerShell\7\pwsh.exe" -NoProfile -ExecutionPolicy Bypass -NoLogo -File "%~dp0src\main.ps1"
