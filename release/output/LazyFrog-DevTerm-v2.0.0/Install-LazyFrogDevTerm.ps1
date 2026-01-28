<#
.SYNOPSIS
    LazyFrog DevTerm - Installer
.DESCRIPTION
    Installs LazyFrog Developer Tools to your system with:
    - Desktop shortcut (with embedded icon)
    - Start Menu shortcut
    - Optional auto-start on login
.AUTHOR
    Kindware.dev
.NOTES
    Run: pwsh -File Install-LazyFrogDevTerm.ps1
    Uninstall: pwsh -File Install-LazyFrogDevTerm.ps1 -Uninstall
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$InstallPath = "$env:LOCALAPPDATA\LazyFrog-DevTerm",
    
    [Parameter(Mandatory = $false)]
    [switch]$NoShortcut,

    [Parameter(Mandatory = $false)]
    [switch]$NoStartMenu,
    
    [Parameter(Mandatory = $false)]
    [switch]$AutoStart,
    
    [Parameter(Mandatory = $false)]
    [switch]$Uninstall,
    
    [Parameter(Mandatory = $false)]
    [switch]$Silent
)

$ErrorActionPreference = "Stop"

# Setup logging
$logRoot = Join-Path $env:LOCALAPPDATA "LazyFrog-DevTerm\logs"
if (-not (Test-Path $logRoot)) {
    New-Item -ItemType Directory -Path $logRoot -Force | Out-Null
}
$logFile = Join-Path $logRoot "installer-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

function Write-Log {
    param([string]$Message)
    $line = "[{0}] {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Message
    Add-Content -Path $logFile -Value $line
}

Write-Log "Installer started with args: InstallPath=$InstallPath, Uninstall=$Uninstall"

# Configuration
$AppName = "LazyFrog Developer Tools"
$ShortcutName = "LazyFrog DevTerm"
$AppExeName = "LazyFrog.exe"

function Write-Banner {
    if ($Silent) { return }
    Write-Host ""
    Write-Host "  ╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "  ║                                                               ║" -ForegroundColor Cyan
    Write-Host "  ║    🐸  LazyFrog DevTerm - Installer                           ║" -ForegroundColor Cyan
    Write-Host "  ║    ─────────────────────────────────────────                  ║" -ForegroundColor Cyan
    Write-Host "  ║    powered by Kindware.dev                                    ║" -ForegroundColor Cyan
    Write-Host "  ║                                                               ║" -ForegroundColor Cyan
    Write-Host "  ╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Step {
    param([string]$Message, [string]$Status = "INFO")
    if ($Silent -and $Status -eq "INFO") { return }
    $color = switch ($Status) { "SUCCESS" { "Green" } "ERROR" { "Red" } "WARNING" { "Yellow" } default { "White" } }
    $icon = switch ($Status) { "SUCCESS" { "✓" } "ERROR" { "✗" } "WARNING" { "!" } default { "○" } }
    Write-Host "  [$icon] $Message" -ForegroundColor $color
}

function Get-PwshPath {
    $cmd = Get-Command pwsh -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }

    $paths = @(
        "C:\Program Files\PowerShell\7\pwsh.exe",
        "$env:ProgramFiles\PowerShell\7\pwsh.exe",
        "$env:LOCALAPPDATA\Microsoft\PowerShell\7\pwsh.exe"
    )
    foreach ($p in $paths) {
        if (Test-Path $p) { return $p }
    }
    return $null
}

function Confirm-Pwsh {
    Write-Log "Checking for PowerShell 7..."
    $pwsh = Get-PwshPath
    if ($null -ne $pwsh) {
        Write-Step "PowerShell 7 detected: $pwsh" -Status "SUCCESS"
        Write-Log "Found: $pwsh"
        return $pwsh
    }

    Write-Step "PowerShell 7 not found" -Status "WARNING"
    if (-not $Silent) {
        $answer = Read-Host "  Install PowerShell 7 using winget? (Y/n)"
        if ($answer -eq "n" -or $answer -eq "N") {
            Write-Log "User declined PowerShell 7 install"
            return $null
        }
    }

    $winget = Get-Command winget -ErrorAction SilentlyContinue
    if ($null -eq $winget) {
        Write-Step "winget not found - please install PowerShell 7 manually" -Status "ERROR"
        Write-Host "  Download: https://github.com/PowerShell/PowerShell/releases" -ForegroundColor Cyan
        return $null
    }

    Write-Step "Installing PowerShell 7..." -Status "INFO"
    Start-Process -FilePath $winget.Source -ArgumentList "install","--id","Microsoft.PowerShell","--source","winget","--accept-source-agreements","--accept-package-agreements" -Wait
    
    $pwsh = Get-PwshPath
    if ($null -ne $pwsh) {
        Write-Step "PowerShell 7 installed successfully" -Status "SUCCESS"
    }
    else {
        Write-Step "PowerShell 7 installation may have failed" -Status "WARNING"
    }
    return $pwsh
}

function Get-SourcePath {
    # When running as compiled EXE, find the package folder next to the EXE
    $searchPaths = @()
    
    # Try to get the directory of the running executable
    try {
        $exePath = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
        if (-not [string]::IsNullOrWhiteSpace($exePath)) {
            $exeDir = Split-Path -Parent $exePath
            $searchPaths += $exeDir
            Write-Log "EXE directory: $exeDir"
        }
    }
    catch { Write-Log "Could not get EXE path: $_" }
    
    # Try AppContext.BaseDirectory (works for compiled EXEs)
    try {
        $baseDir = [System.AppContext]::BaseDirectory
        if (-not [string]::IsNullOrWhiteSpace($baseDir)) {
            $searchPaths += $baseDir.TrimEnd('\')
            Write-Log "BaseDirectory: $baseDir"
        }
    }
    catch { Write-Log "Could not get BaseDirectory: $_" }
    
    # Try PSScriptRoot and PSCommandPath
    if (-not [string]::IsNullOrWhiteSpace($PSScriptRoot)) {
        $searchPaths += $PSScriptRoot
        Write-Log "PSScriptRoot: $PSScriptRoot"
    }
    if (-not [string]::IsNullOrWhiteSpace($PSCommandPath)) {
        $searchPaths += (Split-Path -Parent $PSCommandPath)
        Write-Log "PSCommandPath parent: $(Split-Path -Parent $PSCommandPath)"
    }
    
    # Try current working directory
    if ($null -ne $PWD -and -not [string]::IsNullOrWhiteSpace($PWD.Path)) {
        $searchPaths += $PWD.Path
        Write-Log "PWD: $($PWD.Path)"
    }
    
    # Search each path for source files
    foreach ($basePath in $searchPaths) {
        if ([string]::IsNullOrWhiteSpace($basePath)) { continue }
        
        # Direct check - src\main.ps1 in this folder
        $directCheck = Join-Path $basePath "src\main.ps1"
        if (Test-Path $directCheck) {
            Write-Log "Found source at: $basePath (direct)"
            return $basePath
        }
        
        # Check for LazyFrog-DevTerm-v* subfolder (package folder next to Setup.exe)
        try {
            $packageFolders = Get-ChildItem -Path $basePath -Directory -Filter "LazyFrog-DevTerm-v*" -ErrorAction SilentlyContinue
            foreach ($folder in $packageFolders) {
                $checkPath = Join-Path $folder.FullName "src\main.ps1"
                if (Test-Path $checkPath) {
                    Write-Log "Found source at: $($folder.FullName) (package folder)"
                    return $folder.FullName
                }
            }
        }
        catch { Write-Log "Error searching for package folders: $_" }
        
        # Check for LazyFrog-DevTerm-Package subfolder
        $packagePath = Join-Path $basePath "LazyFrog-DevTerm-Package"
        $packageCheck = Join-Path $packagePath "src\main.ps1"
        if (Test-Path $packageCheck) {
            Write-Log "Found source at: $packagePath (Package subfolder)"
            return $packagePath
        }
    }
    
    Write-Log "Could not find source files in any searched path"
    return ""
}

function Install-Application {
    Write-Log "Starting installation..."
    Write-Banner

    $pwshPath = Confirm-Pwsh
    if ($null -eq $pwshPath) {
        Write-Host ""
        Write-Host "  PowerShell 7 is required to run LazyFrog." -ForegroundColor Red
        Write-Log "PowerShell 7 not available"
        if (-not $Silent) { Read-Host "  Press Enter to exit" | Out-Null }
        exit 1
    }
    
    Write-Step "Installing to: $InstallPath" -Status "INFO"
    Write-Host ""
    
    # Create/reset installation directory
    if (Test-Path $InstallPath) {
        Remove-Item -Path (Join-Path $InstallPath "src") -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -Path (Join-Path $InstallPath "LazyFrog.exe") -Force -ErrorAction SilentlyContinue
    }
    else {
        New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null
        Write-Step "Created installation directory" -Status "SUCCESS"
    }

    # Find source files
    $SourcePath = Get-SourcePath
    Write-Log "Source path: $SourcePath"
    if ([string]::IsNullOrWhiteSpace($SourcePath)) {
        Write-Step "Could not locate source files" -Status "ERROR"
        Write-Log "Source path resolution failed"
        if (-not $Silent) { Read-Host "  Press Enter to exit" | Out-Null }
        exit 1
    }
    
    # Copy files
    Write-Step "Copying application files..."
    
    $filesToCopy = @(
        "src",
        $AppExeName,
        "icon.ico",
        "config.json",
        "tasks.json",
        "watchlist.json",
        "CHANGELOG.md",
        "README.md",
        "LICENSE",
        "docs"
    )
    
    foreach ($item in $filesToCopy) {
        $sourceFull = Join-Path $SourcePath $item
        if (Test-Path $sourceFull) {
            $destFull = Join-Path $InstallPath $item
            if (Test-Path $sourceFull -PathType Container) {
                Copy-Item -Path $sourceFull -Destination $destFull -Recurse -Force
            }
            else {
                Copy-Item -Path $sourceFull -Destination $destFull -Force
            }
            Write-Log "Copied: $item"
        }
    }
    
    Write-Step "Files copied successfully" -Status "SUCCESS"
    
    # Create required directories
    foreach ($dir in @("results", "history")) {
        $path = Join-Path $InstallPath $dir
        if (-not (Test-Path $path)) {
            New-Item -ItemType Directory -Path $path -Force | Out-Null
        }
    }
    
    # Prepare shortcut target
    $exePath = Join-Path $InstallPath $AppExeName
    $iconPath = Join-Path $InstallPath "icon.ico"
    $mainPath = Join-Path $InstallPath "src\main.ps1"
    
    if (Test-Path $exePath) {
        $targetPath = $exePath
        $targetArgs = ""
        $iconLocation = "$exePath,0"
    }
    else {
        $targetPath = $pwshPath
        $targetArgs = "-NoProfile -ExecutionPolicy Bypass -NoLogo -File `"$mainPath`""
        $iconLocation = if (Test-Path $iconPath) { "$iconPath,0" } else { "" }
    }

    # Create WScript.Shell object for shortcuts
    $WshShell = New-Object -ComObject WScript.Shell

    # Create Desktop shortcut
    if (-not $NoShortcut) {
        Write-Step "Creating desktop shortcut..."
        
        $desktopPath = [Environment]::GetFolderPath("Desktop")
        $shortcutPath = Join-Path $desktopPath "$ShortcutName.lnk"
        
        $Shortcut = $WshShell.CreateShortcut($shortcutPath)
        $Shortcut.TargetPath = $targetPath
        $Shortcut.Arguments = $targetArgs
        $Shortcut.WorkingDirectory = $InstallPath
        $Shortcut.Description = "LazyFrog Developer Tools - powered by Kindware.dev"
        if (-not [string]::IsNullOrEmpty($iconLocation)) {
            $Shortcut.IconLocation = $iconLocation
        }
        $Shortcut.Save()
        
        Write-Step "Desktop shortcut created" -Status "SUCCESS"
    }
    
    # Create Start Menu shortcut
    if (-not $NoStartMenu) {
        Write-Step "Creating Start Menu shortcut..."
        
        $startMenuPath = Join-Path ([Environment]::GetFolderPath("StartMenu")) "Programs"
        $startShortcutPath = Join-Path $startMenuPath "$ShortcutName.lnk"
        
        $StartShortcut = $WshShell.CreateShortcut($startShortcutPath)
        $StartShortcut.TargetPath = $targetPath
        $StartShortcut.Arguments = $targetArgs
        $StartShortcut.WorkingDirectory = $InstallPath
        $StartShortcut.Description = "LazyFrog Developer Tools - powered by Kindware.dev"
        if (-not [string]::IsNullOrEmpty($iconLocation)) {
            $StartShortcut.IconLocation = $iconLocation
        }
        $StartShortcut.Save()
        
        Write-Step "Start Menu shortcut created" -Status "SUCCESS"
    }

    # Create Startup shortcut (auto-start on login)
    if ($AutoStart) {
        Write-Step "Enabling auto-start..."
        
        $startupPath = [Environment]::GetFolderPath("Startup")
        $startupShortcutPath = Join-Path $startupPath "$ShortcutName.lnk"
        
        $StartupShortcut = $WshShell.CreateShortcut($startupShortcutPath)
        $StartupShortcut.TargetPath = $targetPath
        $StartupShortcut.Arguments = $targetArgs
        $StartupShortcut.WorkingDirectory = $InstallPath
        $StartupShortcut.Description = "LazyFrog Developer Tools - powered by Kindware.dev"
        if (-not [string]::IsNullOrEmpty($iconLocation)) {
            $StartupShortcut.IconLocation = $iconLocation
        }
        $StartupShortcut.Save()
        
        Write-Step "Startup shortcut created" -Status "SUCCESS"
    }
    
    Write-Host ""
    Write-Host "  ╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "  ║                                                               ║" -ForegroundColor Green
    Write-Host "  ║    ✓  Installation Complete!                                  ║" -ForegroundColor Green
    Write-Host "  ║                                                               ║" -ForegroundColor Green
    Write-Host "  ╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Installation path: $InstallPath" -ForegroundColor White
    Write-Host "  Log file: $logFile" -ForegroundColor DarkGray
    Write-Host ""
    Write-Log "Installation completed successfully"

    if (-not $Silent) {
        $runNow = Read-Host "  Launch LazyFrog now? (Y/n)"
        if ($runNow -ne "n" -and $runNow -ne "N") {
            if (Test-Path $exePath) {
                Start-Process -FilePath $exePath -WorkingDirectory $InstallPath
            }
            else {
                Start-Process -FilePath $pwshPath -ArgumentList @("-NoProfile","-ExecutionPolicy","Bypass","-NoLogo","-File",$mainPath) -WorkingDirectory $InstallPath
            }
        }
    }
}

function Uninstall-Application {
    Write-Banner
    Write-Step "Uninstalling $AppName..."
    Write-Host ""
    
    # Remove installation directory
    if (Test-Path $InstallPath) {
        Remove-Item -Path $InstallPath -Recurse -Force
        Write-Step "Removed installation directory" -Status "SUCCESS"
    }
    else {
        Write-Step "Installation directory not found" -Status "WARNING"
    }
    
    # Remove shortcuts
    $shortcuts = @(
        (Join-Path ([Environment]::GetFolderPath("Desktop")) "$ShortcutName.lnk"),
        (Join-Path ([Environment]::GetFolderPath("StartMenu")) "Programs\$ShortcutName.lnk"),
        (Join-Path ([Environment]::GetFolderPath("Startup")) "$ShortcutName.lnk")
    )
    
    foreach ($shortcut in $shortcuts) {
        if (Test-Path $shortcut) {
            Remove-Item -Path $shortcut -Force
            Write-Step "Removed: $(Split-Path $shortcut -Leaf)" -Status "SUCCESS"
        }
    }
    
    Write-Host ""
    Write-Host "  ╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "  ║    ✓  Uninstallation Complete!                                ║" -ForegroundColor Green
    Write-Host "  ╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    Write-Log "Uninstallation completed"
}

# Main execution
try {
    if ($Uninstall) {
        Uninstall-Application
    }
    else {
        Install-Application
    }
}
catch {
    Write-Log "ERROR: $_"
    Write-Host ""
    Write-Host "  ERROR: $_" -ForegroundColor Red
    Write-Host "  Log file: $logFile" -ForegroundColor Yellow
    Write-Host ""
    if (-not $Silent) { Read-Host "  Press Enter to exit" | Out-Null }
    exit 1
}
