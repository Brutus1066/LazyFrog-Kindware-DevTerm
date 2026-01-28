<#
.SYNOPSIS
    LazyFrog DevTerm - Complete Release Builder
.DESCRIPTION
    Creates a complete distributable release package including:
    - Setup.exe (installer with embedded icon)
    - LazyFrog.exe (launcher with embedded icon)
    - Complete documentation
    - Portable ZIP package
.AUTHOR
    Kindware.dev
.VERSION
    2.0.0
.NOTES
    Run this script from the release folder:
    pwsh -File Build-Release.ps1
    
    Optional parameters:
    -SkipExe    : Skip EXE creation (for systems without PS2EXE)
    -Clean      : Remove previous build artifacts before building
#>

param(
    [Parameter(Mandatory = $false)]
    [switch]$SkipExe,
    
    [Parameter(Mandatory = $false)]
    [switch]$Clean,
    
    [Parameter(Mandatory = $false)]
    [string]$Version = "1.1.1"
)

$ErrorActionPreference = "Stop"

# ============================================================================
# CONFIGURATION
# ============================================================================

$script:Config = @{
    AppName        = "LazyFrog DevTerm"
    AppVersion     = $Version
    Publisher      = "Kindware.dev"
    Copyright      = "Copyright (c) 2026 Kindware.dev"
    Description    = "A modern TUI-based developer utility suite for Windows Terminal"
    GitHubUrl      = "https://github.com/Brutus1066/LazyFrog-Kindware-DevTerm"
    
    # Paths
    ProjectRoot    = (Split-Path -Parent $PSScriptRoot)
    ReleaseDir     = $PSScriptRoot
    OutputDir      = ""  # Set dynamically
    
    # Files to include in package
    CoreFiles      = @("config.json", "tasks.json", "watchlist.json")
    DocFiles       = @("CHANGELOG.md", "README.md", "LICENSE", "CONTRIBUTING.md", "CODE_OF_CONDUCT.md", "SECURITY.md")
    IconFile       = ""  # Set dynamically
}

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

function Write-Banner {
    $banner = @"

  ╔═══════════════════════════════════════════════════════════════╗
  ║                                                               ║
  ║    🐸  LazyFrog DevTerm - Release Builder                     ║
  ║    ─────────────────────────────────────────                  ║
  ║    Version: $($script:Config.AppVersion.PadRight(48))║
  ║    powered by Kindware.dev                                    ║
  ║                                                               ║
  ╚═══════════════════════════════════════════════════════════════╝

"@
    Write-Host $banner -ForegroundColor Cyan
}

function Write-Step {
    param(
        [string]$Message,
        [ValidateSet("INFO", "SUCCESS", "WARNING", "ERROR")]
        [string]$Status = "INFO"
    )
    
    $colors = @{
        "INFO"    = "White"
        "SUCCESS" = "Green"
        "WARNING" = "Yellow"
        "ERROR"   = "Red"
    }
    
    $icons = @{
        "INFO"    = "○"
        "SUCCESS" = "✓"
        "WARNING" = "!"
        "ERROR"   = "✗"
    }
    
    Write-Host "  [$($icons[$Status])] " -ForegroundColor $colors[$Status] -NoNewline
    Write-Host $Message -ForegroundColor $colors[$Status]
}

function Write-Section {
    param([string]$Title)
    Write-Host ""
    Write-Host "  ── $Title ──" -ForegroundColor Magenta
    Write-Host ""
}

function Test-PowerShellVersion {
    $version = $PSVersionTable.PSVersion
    if ($version.Major -lt 7) {
        Write-Step "PowerShell 7+ required (current: $version)" -Status "ERROR"
        return $false
    }
    Write-Step "PowerShell version: $version" -Status "SUCCESS"
    return $true
}

function Resolve-IconPath {
    $candidates = @(
        (Join-Path $script:Config.ProjectRoot "icon.ico"),
        (Join-Path $script:Config.ProjectRoot "desktop.launcher.icon.ico\icon.ico"),
        (Join-Path $script:Config.ReleaseDir "icon.ico")
    )
    
    foreach ($candidate in $candidates) {
        if (Test-Path $candidate) {
            return $candidate
        }
    }
    return $null
}

function Install-PS2EXE {
    $module = Get-Module -ListAvailable -Name ps2exe
    if ($null -eq $module) {
        Write-Step "Installing PS2EXE module..." -Status "INFO"
        try {
            Install-Module -Name ps2exe -Scope CurrentUser -Force -AllowClobber
            Import-Module ps2exe -Force
            Write-Step "PS2EXE installed successfully" -Status "SUCCESS"
            return $true
        }
        catch {
            Write-Step "Failed to install PS2EXE: $_" -Status "ERROR"
            return $false
        }
    }
    Import-Module ps2exe -Force
    return $true
}

# ============================================================================
# BUILD FUNCTIONS
# ============================================================================

function New-OutputDirectory {
    $outputPath = Join-Path $script:Config.ReleaseDir "output"
    $packagePath = Join-Path $outputPath "LazyFrog-DevTerm-v$($script:Config.AppVersion)"
    
    if ($Clean -and (Test-Path $outputPath)) {
        Write-Step "Cleaning previous build..." -Status "INFO"
        Remove-Item -Path $outputPath -Recurse -Force
    }
    
    if (-not (Test-Path $packagePath)) {
        New-Item -ItemType Directory -Path $packagePath -Force | Out-Null
    }
    
    # Create subdirectories
    $subdirs = @("docs", "src", "history", "results")
    foreach ($dir in $subdirs) {
        $path = Join-Path $packagePath $dir
        if (-not (Test-Path $path)) {
            New-Item -ItemType Directory -Path $path -Force | Out-Null
        }
    }
    
    $script:Config.OutputDir = $packagePath
    Write-Step "Output directory: $packagePath" -Status "SUCCESS"
    return $packagePath
}

function Copy-SourceFiles {
    Write-Section "Copying Source Files"
    
    $projectRoot = $script:Config.ProjectRoot
    $outputDir = $script:Config.OutputDir
    
    # Copy src directory
    $srcSource = Join-Path $projectRoot "src"
    $srcDest = Join-Path $outputDir "src"
    if (Test-Path $srcSource) {
        Copy-Item -Path "$srcSource\*" -Destination $srcDest -Recurse -Force
        Write-Step "Copied source files (src/)" -Status "SUCCESS"
    }
    else {
        Write-Step "Source directory not found!" -Status "ERROR"
        return $false
    }
    
    # Copy core config files
    foreach ($file in $script:Config.CoreFiles) {
        $source = Join-Path $projectRoot $file
        if (Test-Path $source) {
            Copy-Item -Path $source -Destination $outputDir -Force
            Write-Step "Copied: $file" -Status "SUCCESS"
        }
        else {
            Write-Step "Not found (creating default): $file" -Status "WARNING"
        }
    }
    
    # Copy documentation
    foreach ($file in $script:Config.DocFiles) {
        $source = Join-Path $projectRoot $file
        if (Test-Path $source) {
            Copy-Item -Path $source -Destination $outputDir -Force
            Write-Step "Copied: $file" -Status "SUCCESS"
        }
    }
    
    # Copy docs folder
    $docsSource = Join-Path $projectRoot "docs"
    $docsDest = Join-Path $outputDir "docs"
    if (Test-Path $docsSource) {
        Copy-Item -Path "$docsSource\*" -Destination $docsDest -Recurse -Force
        Write-Step "Copied documentation (docs/)" -Status "SUCCESS"
    }
    
    # Copy icon
    $iconPath = Resolve-IconPath
    if ($null -ne $iconPath) {
        Copy-Item -Path $iconPath -Destination (Join-Path $outputDir "icon.ico") -Force
        $script:Config.IconFile = Join-Path $outputDir "icon.ico"
        Write-Step "Copied: icon.ico" -Status "SUCCESS"
    }
    else {
        Write-Step "No icon.ico found" -Status "WARNING"
    }
    
    return $true
}

function New-LauncherBatch {
    Write-Section "Creating Launcher Scripts"
    
    $outputDir = $script:Config.OutputDir
    
    # Main batch launcher
    $batchContent = @"
@echo off
:: ╔═══════════════════════════════════════════════════════════════╗
:: ║  LazyFrog DevTerm - Developer Tools Launcher                  ║
:: ║  Powered by Kindware.dev                                      ║
:: ╚═══════════════════════════════════════════════════════════════╝

title LazyFrog Developer Tools - powered by Kindware.dev
cd /d "%~dp0"

:: Check for PowerShell 7
where pwsh >nul 2>nul
if %ERRORLEVEL% neq 0 (
    if exist "C:\Program Files\PowerShell\7\pwsh.exe" (
        "C:\Program Files\PowerShell\7\pwsh.exe" -NoProfile -ExecutionPolicy Bypass -NoLogo -File "%~dp0src\main.ps1"
        exit /b %ERRORLEVEL%
    )
    echo.
    echo   ERROR: PowerShell 7+ is required!
    echo.
    echo   Download from: https://github.com/PowerShell/PowerShell/releases
    echo.
    pause
    exit /b 1
)

pwsh -NoProfile -ExecutionPolicy Bypass -NoLogo -File "%~dp0src\main.ps1"
"@

    $batchPath = Join-Path $outputDir "LazyFrog-DevTerm.bat"
    $batchContent | Set-Content -Path $batchPath -Encoding ASCII
    Write-Step "Created: LazyFrog-DevTerm.bat" -Status "SUCCESS"
    
    return $batchPath
}

function New-InstallerScript {
    Write-Section "Creating Installer Script"
    
    $outputDir = $script:Config.OutputDir
    $version = $script:Config.AppVersion
    
    $installerContent = @'
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
'@

    $installerPath = Join-Path $outputDir "Install-LazyFrogDevTerm.ps1"
    $installerContent | Set-Content -Path $installerPath -Encoding UTF8
    Write-Step "Created: Install-LazyFrogDevTerm.ps1" -Status "SUCCESS"
    
    return $installerPath
}

function New-LauncherExe {
    Write-Section "Creating LazyFrog.exe (Launcher)"
    
    $outputDir = $script:Config.OutputDir
    $projectRoot = $script:Config.ProjectRoot
    
    # Find launcher script
    $launcherScript = $null
    $candidates = @(
        (Join-Path $projectRoot "LazyFrog-Launcher.ps1"),
        (Join-Path $projectRoot "Launcher.ps1"),
        (Join-Path $projectRoot "Start-LazyFrog.ps1")
    )
    
    foreach ($candidate in $candidates) {
        if (Test-Path $candidate) {
            $launcherScript = $candidate
            break
        }
    }
    
    if ($null -eq $launcherScript) {
        Write-Step "No launcher script found - skipping EXE creation" -Status "WARNING"
        return $null
    }
    
    $exePath = Join-Path $outputDir "LazyFrog.exe"
    $iconFile = $script:Config.IconFile
    
    $ps2exeParams = @{
        InputFile    = $launcherScript
        OutputFile   = $exePath
        Title        = $script:Config.AppName
        Description  = $script:Config.Description
        Company      = $script:Config.Publisher
        Copyright    = $script:Config.Copyright
        Version      = $script:Config.AppVersion
        NoConsole    = $true
        RequireAdmin = $false
        Sta          = $true
    }
    
    if (-not [string]::IsNullOrEmpty($iconFile) -and (Test-Path $iconFile)) {
        $ps2exeParams.IconFile = $iconFile
        Write-Step "Icon will be embedded: icon.ico" -Status "INFO"
    }
    
    try {
        Invoke-ps2exe @ps2exeParams 2>$null
        Write-Step "Created: LazyFrog.exe (with embedded icon)" -Status "SUCCESS"
        return $exePath
    }
    catch {
        Write-Step "Failed to create LazyFrog.exe: $_" -Status "ERROR"
        return $null
    }
}

function New-SetupExe {
    Write-Section "Creating Setup.exe (Installer)"
    
    $outputDir = $script:Config.OutputDir
    $outputRoot = Split-Path $outputDir -Parent
    
    $installerScript = Join-Path $outputDir "Install-LazyFrogDevTerm.ps1"
    
    if (-not (Test-Path $installerScript)) {
        Write-Step "Installer script not found - skipping Setup.exe" -Status "WARNING"
        return $null
    }
    
    $exePath = Join-Path $outputRoot "LazyFrog-DevTerm-Setup-v$($script:Config.AppVersion).exe"
    $iconFile = $script:Config.IconFile
    
    $ps2exeParams = @{
        InputFile    = $installerScript
        OutputFile   = $exePath
        Title        = "$($script:Config.AppName) Setup"
        Description  = "Installer for $($script:Config.Description)"
        Company      = $script:Config.Publisher
        Copyright    = $script:Config.Copyright
        Version      = $script:Config.AppVersion
        NoConsole    = $false
        RequireAdmin = $false
        Sta          = $true
    }
    
    if (-not [string]::IsNullOrEmpty($iconFile) -and (Test-Path $iconFile)) {
        $ps2exeParams.IconFile = $iconFile
    }
    
    try {
        Invoke-ps2exe @ps2exeParams 2>$null
        Write-Step "Created: $(Split-Path $exePath -Leaf)" -Status "SUCCESS"
        return $exePath
    }
    catch {
        Write-Step "Failed to create Setup.exe: $_" -Status "ERROR"
        return $null
    }
}

function New-ZipPackage {
    Write-Section "Creating ZIP Package"
    
    $outputDir = $script:Config.OutputDir
    $outputRoot = Split-Path $outputDir -Parent
    
    $zipPath = Join-Path $outputRoot "LazyFrog-DevTerm-v$($script:Config.AppVersion).zip"
    
    if (Test-Path $zipPath) {
        Remove-Item -Path $zipPath -Force
    }
    
    Compress-Archive -Path "$outputDir\*" -DestinationPath $zipPath -CompressionLevel Optimal
    Write-Step "Created: $(Split-Path $zipPath -Leaf)" -Status "SUCCESS"
    
    return $zipPath
}

function New-ReleaseReadme {
    Write-Section "Creating Release Documentation"
    
    $outputRoot = Join-Path $script:Config.ReleaseDir "output"
    
    $readmeContent = @"
# 🐸 LazyFrog DevTerm - Release v$($script:Config.AppVersion)

**A keyboard-first terminal utility for developers who stay in the shell**

---

## 📦 Package Contents

| File | Description |
|------|-------------|
| `LazyFrog-DevTerm-Setup-v$($script:Config.AppVersion).exe` | One-click installer (recommended) |
| `LazyFrog-DevTerm-v$($script:Config.AppVersion).zip` | Portable package |
| `LazyFrog-DevTerm-v$($script:Config.AppVersion)/` | Unpacked portable version |

---

## 🚀 Quick Start

### Option 1: Run the Installer (Recommended)
1. Double-click `LazyFrog-DevTerm-Setup-v$($script:Config.AppVersion).exe`
2. Follow the prompts
3. Launch from Desktop or Start Menu

### Option 2: Portable Use
1. Extract `LazyFrog-DevTerm-v$($script:Config.AppVersion).zip`
2. Run `LazyFrog-DevTerm.bat` or `LazyFrog.exe`

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
- **App files:** `%LOCALAPPDATA%\LazyFrog-DevTerm`
- **GitHub results:** `results/`
- **Task history:** `history/task-history.json`
- **Logs:** `%LOCALAPPDATA%\LazyFrog-DevTerm\logs`

---

## 🔧 Troubleshooting

**App doesn't start?**
- Ensure PowerShell 7+ is installed
- Try: `pwsh -File src\main.ps1`

**Git tasks fail (exit code 128)?**
- Start LazyFrog from inside a Git repository folder

**Need more help?**
- See `docs/TROUBLESHOOTING.md`
- Open an issue: $($script:Config.GitHubUrl)/issues

---

## 📜 License

MIT License - See LICENSE file for details.

---

**Made with 🐸 by Kindware.dev**

GitHub: $($script:Config.GitHubUrl)
"@

    $readmePath = Join-Path $outputRoot "README.md"
    $readmeContent | Set-Content -Path $readmePath -Encoding UTF8
    Write-Step "Created: README.md (release notes)" -Status "SUCCESS"
    
    return $readmePath
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

Write-Banner

if (-not (Test-PowerShellVersion)) {
    exit 1
}

# Initialize
New-OutputDirectory

# Copy source files
if (-not (Copy-SourceFiles)) {
    Write-Host ""
    Write-Step "Build failed - could not copy source files" -Status "ERROR"
    exit 1
}

# Create scripts
New-LauncherBatch
New-InstallerScript

# Create executables (if not skipped)
if (-not $SkipExe) {
    if (Install-PS2EXE) {
        New-LauncherExe
        New-SetupExe
    }
    else {
        Write-Step "Skipping EXE creation (PS2EXE unavailable)" -Status "WARNING"
    }
}
else {
    Write-Step "Skipping EXE creation (-SkipExe specified)" -Status "INFO"
}

# Create ZIP
$zipPath = New-ZipPackage

# Create release readme
New-ReleaseReadme

# Final summary
$outputDir = $script:Config.OutputDir
$outputRoot = Split-Path $outputDir -Parent

Write-Host ""
Write-Host "  ╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "  ║                                                               ║" -ForegroundColor Green
Write-Host "  ║    ✓  Build Complete!                                         ║" -ForegroundColor Green
Write-Host "  ║                                                               ║" -ForegroundColor Green
Write-Host "  ╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "  Output location:" -ForegroundColor White
Write-Host "    $outputRoot" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Files created:" -ForegroundColor White

# List created files
Get-ChildItem -Path $outputRoot -File | ForEach-Object {
    Write-Host "    • $($_.Name)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "  Next steps:" -ForegroundColor Magenta
Write-Host "    1. Test the installer: LazyFrog-DevTerm-Setup-v$Version.exe" -ForegroundColor White
Write-Host "    2. Upload to GitHub Releases" -ForegroundColor White
Write-Host "    3. Share the ZIP for portable users" -ForegroundColor White
Write-Host ""
