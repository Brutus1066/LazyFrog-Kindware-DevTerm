<#
.SYNOPSIS
    Installer Builder for LazyFrog Developer Tools
.DESCRIPTION
    Creates an installer package for LazyFrog Developer Tools.
    Handles PowerShell version checking, file deployment, and shortcut creation.
.AUTHOR
    Kindware.dev
.VERSION
    1.0.0
.NOTES
    This script can optionally use PS2EXE to create an executable,
    or create a self-contained installer script.
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = "",
    
    [Parameter(Mandatory = $false)]
    [switch]$CreateExe,
    
    [Parameter(Mandatory = $false)]
    [switch]$CreateAppExe,
    
    [Parameter(Mandatory = $false)]
    [string]$InstallPath = "$env:LOCALAPPDATA\LazyFrog-DevTerm"
)

$ErrorActionPreference = "Stop"

# ============================================================================
# CONFIGURATION
# ============================================================================

$script:Config = @{
    AppName         = "LazyFrog DevTerm"
    AppVersion      = "1.2.0"
    Publisher       = "Kindware.dev"
    ProjectRoot     = Split-Path -Parent $PSScriptRoot
    ShortcutName    = "LazyFrog DevTerm"
    Description     = "A modern TUI-based developer utility suite"
    GitHubUrl       = "https://github.com/Brutus1066/LazyFrog-Kindware-DevTerm"
}

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

function Write-Banner {
    Write-Host ""
    Write-Host "  +=======================================================+" -ForegroundColor Cyan
    Write-Host "  |                                                       |" -ForegroundColor Cyan
    Write-Host "  |   LazyFrog DevTerm - Installer Builder                |" -ForegroundColor Cyan
    Write-Host "  |   -----------------------------------------------     |" -ForegroundColor Cyan
    Write-Host "  |   powered by Kindware.dev                             |" -ForegroundColor Cyan
    Write-Host "  |                                                       |" -ForegroundColor Cyan
    Write-Host "  +=======================================================+" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Step {
    param(
        [string]$Message,
        [string]$Status = "INFO"
    )
    
    $color = switch ($Status) {
        "INFO"    { "White" }
        "SUCCESS" { "Green" }
        "WARNING" { "Yellow" }
        "ERROR"   { "Red" }
        default   { "White" }
    }
    
    $prefix = switch ($Status) {
        "INFO"    { "[i]" }
        "SUCCESS" { "[OK]" }
        "WARNING" { "[!!]" }
        "ERROR"   { "[X]" }
        default   { "[ ]" }
    }
    
    Write-Host "  $prefix $Message" -ForegroundColor $color
}

function Test-PowerShellVersion {
    $version = $PSVersionTable.PSVersion
    if ($version.Major -lt 7) {
        Write-Step "PowerShell 7+ is required. Current: $version" -Status "ERROR"
        return $false
    }
    Write-Step "PowerShell version: $version" -Status "SUCCESS"
    return $true
}

function Resolve-IconPath {
    $candidates = @(
        (Join-Path $script:Config.ProjectRoot "icon.ico"),
        (Join-Path $script:Config.ProjectRoot "desktop.launcher.icon.ico\icon.ico")
    )
    foreach ($candidate in $candidates) {
        if (Test-Path $candidate) {
            return $candidate
        }
    }
    return $null
}

# ============================================================================
# INSTALLER SCRIPT GENERATOR
# ============================================================================

function New-InstallerScript {
    param(
        [string]$OutputPath
    )
    
    $installerContent = @'
<#
.SYNOPSIS
    LazyFrog Developer Tools - Installer
.DESCRIPTION
    Installs LazyFrog Developer Tools to your system.
.AUTHOR
    Kindware.dev
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$InstallPath = "$env:LOCALAPPDATA\LazyFrog-DevTerm",
    
    [Parameter(Mandatory = $false)]
    [switch]$NoShortcut,

    [Parameter(Mandatory = $false)]
    [switch]$NoStartup,
    
    [Parameter(Mandatory = $false)]
    [switch]$Uninstall
)

$ErrorActionPreference = "Stop"

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

Write-Log "Installer started"
Write-Log "Installer script loaded"

# Configuration
$AppName = "LazyFrog Developer Tools"
$ShortcutName = "LazyFrog DevTerm"
$AppExeName = "LazyFrog.exe"

function Write-Banner {
    Write-Host ""
    Write-Host "  +=======================================================+" -ForegroundColor Cyan
    Write-Host "  |                                                       |" -ForegroundColor Cyan
    Write-Host "  |   LazyFrog DevTerm - Installer                         |" -ForegroundColor Cyan
    Write-Host "  |   -----------------------------------------------     |" -ForegroundColor Cyan
    Write-Host "  |   powered by Kindware.dev                             |" -ForegroundColor Cyan
    Write-Host "  |                                                       |" -ForegroundColor Cyan
    Write-Host "  +=======================================================+" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Step {
    param([string]$Message, [string]$Status = "INFO")
    $color = switch ($Status) { "SUCCESS" { "Green" } "ERROR" { "Red" } "WARNING" { "Yellow" } default { "White" } }
    $prefix = switch ($Status) { "SUCCESS" { "[OK]" } "ERROR" { "[X]" } "WARNING" { "[!!]" } default { "[i]" } }
    Write-Host "  $prefix $Message" -ForegroundColor $color
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
    Write-Log "Confirm-Pwsh: start"
    $pwsh = Get-PwshPath
    if ($null -ne $pwsh) {
        Write-Step "PowerShell 7 detected" -Status "SUCCESS"
        Write-Log "Confirm-Pwsh: found $pwsh"
        return $pwsh
    }

    Write-Step "PowerShell 7 not found" -Status "WARNING"
    $answer = Read-Host "Install PowerShell 7 using winget now? (Y/n)"
    if ($answer -eq "n" -or $answer -eq "N") {
        Write-Log "Confirm-Pwsh: user declined install"
        return $null
    }

    $winget = Get-Command winget -ErrorAction SilentlyContinue
    if ($null -eq $winget) {
        Write-Step "winget not found" -Status "ERROR"
        Write-Log "Confirm-Pwsh: winget not found"
        Write-Host "  Download PowerShell 7 from:" -ForegroundColor Yellow
        Write-Host "  https://github.com/PowerShell/PowerShell/releases" -ForegroundColor Cyan
        return $null
    }

    Write-Step "Installing PowerShell 7 via winget..." -Status "INFO"
    Write-Log "Confirm-Pwsh: winget install start"
    Start-Process -FilePath $winget.Source -ArgumentList "install","--id","Microsoft.PowerShell","--source","winget","--accept-source-agreements","--accept-package-agreements" -Wait

    $pwsh = Get-PwshPath
    if ($null -ne $pwsh) {
        Write-Step "PowerShell 7 installed" -Status "SUCCESS"
        Write-Log "Confirm-Pwsh: install success $pwsh"
    }
    else {
        Write-Step "PowerShell 7 install failed" -Status "ERROR"
        Write-Log "Confirm-Pwsh: install failed"
    }
    return $pwsh
}

function Show-InstallSummary {
    Write-Host ""
    Write-Host "  Installation path: $InstallPath" -ForegroundColor White
    Write-Host "  Launch: $InstallPath\$AppExeName" -ForegroundColor Yellow
    Write-Host "  Log file: $logFile" -ForegroundColor DarkGray
    Write-Host ""
}

function Install-Application {
    Write-Log "Install-Application: start"
    Write-Banner

    $pwshPath = Confirm-Pwsh
    if ($null -eq $pwshPath) {
        Write-Host ""
        Write-Host "  PowerShell 7 is required to run LazyFrog." -ForegroundColor Red
        Write-Host "  Log file: $logFile" -ForegroundColor Yellow
        Write-Log "PowerShell 7 unavailable"
        Write-Host ""
        Read-Host "Press Enter to exit" | Out-Null
        exit 1
    }
    
    Write-Step "Installing to: $InstallPath"
    Write-Host ""
    
    # Create or reset install directory
    if (Test-Path $InstallPath) {
        try {
            Remove-Item -Path (Join-Path $InstallPath "src") -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item -Path (Join-Path $InstallPath "LazyFrog.exe") -Force -ErrorAction SilentlyContinue
        }
        catch {}
    }
    else {
        New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null
        Write-Step "Created installation directory" -Status "SUCCESS"
    }

    # Get source path (same directory as installer)
    function Get-SourcePath {
        $candidates = @(
            $PSScriptRoot,
            $(if (-not [string]::IsNullOrWhiteSpace($PSCommandPath)) { Split-Path -Parent $PSCommandPath } else { $null })
        )

        foreach ($candidate in $candidates) {
            if ([string]::IsNullOrWhiteSpace($candidate)) { continue }
            if (Test-Path (Join-Path $candidate "src\main.ps1")) { return $candidate }
            $packageCandidate = Join-Path $candidate "LazyFrog-DevTerm-Package"
            if (Test-Path (Join-Path $packageCandidate "src\main.ps1")) { return $packageCandidate }
        }

        try {
            $path = $MyInvocation.MyCommand.Path
            if (-not [string]::IsNullOrWhiteSpace($path)) {
                $dir = Split-Path -Parent $path
                if (Test-Path (Join-Path $dir "src\main.ps1")) { return $dir }
                $packageCandidate = Join-Path $dir "LazyFrog-DevTerm-Package"
                if (Test-Path (Join-Path $packageCandidate "src\main.ps1")) { return $packageCandidate }
            }
        }
        catch {}

        try {
            $baseDir = [System.AppContext]::BaseDirectory
            if (-not [string]::IsNullOrWhiteSpace($baseDir)) {
                $dir = $baseDir.TrimEnd('\\')
                if (Test-Path (Join-Path $dir "src\main.ps1")) { return $dir }
                $packageCandidate = Join-Path $dir "LazyFrog-DevTerm-Package"
                if (Test-Path (Join-Path $packageCandidate "src\main.ps1")) { return $packageCandidate }
            }
        }
        catch {}

        if ($null -ne $PWD -and -not [string]::IsNullOrWhiteSpace($PWD.Path)) {
            $dir = $PWD.Path
            if (Test-Path (Join-Path $dir "src\main.ps1")) { return $dir }
            $packageCandidate = Join-Path $dir "LazyFrog-DevTerm-Package"
            if (Test-Path (Join-Path $packageCandidate "src\main.ps1")) { return $packageCandidate }
        }

        return ""
    }

    $SourcePath = Get-SourcePath
    Write-Log "Install-Application: SourcePath=$SourcePath"
    if ([string]::IsNullOrWhiteSpace($SourcePath)) {
        Write-Step "Installer source path not found" -Status "ERROR"
        Write-Log "Install-Application: SourcePath is empty"
        Write-Host "  Log file: $logFile" -ForegroundColor Yellow
        Read-Host "Press Enter to exit" | Out-Null
        exit 1
    }
    
    # Copy files
    Write-Step "Copying application files..."
    
    $filesToCopy = @(
        "src",
        $AppExeName,
        "config.json",
        "tasks.json",
        "watchlist.json",
        "CHANGELOG.md",
        "README.md",
        "LICENSE"
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
        }
        else {
            Write-Log "Install-Application: missing source item $sourceFull"
        }
    }
    
    # Copy icon if exists
    $iconSource = Join-Path $SourcePath "icon.ico"
    if (Test-Path $iconSource) {
        Copy-Item -Path $iconSource -Destination (Join-Path $InstallPath "icon.ico") -Force
    }
    
    Write-Step "Files copied successfully" -Status "SUCCESS"
    Write-Log "Install-Application: files copied"
    
    # Create required directories
    $resultsPath = Join-Path $InstallPath "results"
    $historyPath = Join-Path $InstallPath "history"
    
    if (-not (Test-Path $resultsPath)) {
        New-Item -ItemType Directory -Path $resultsPath -Force | Out-Null
    }
    if (-not (Test-Path $historyPath)) {
        New-Item -ItemType Directory -Path $historyPath -Force | Out-Null
    }
    
    # Prepare shortcut targets
    $exePath = Join-Path $InstallPath $AppExeName
    $iconPath = Join-Path $InstallPath "icon.ico"
    if (Test-Path $exePath) {
        $targetPath = $exePath
        $targetArgs = ""
    }
    else {
        $mainPath = Join-Path $InstallPath 'src\main.ps1'
        $targetPath = $pwshPath
        $targetArgs = "-NoProfile -ExecutionPolicy Bypass -NoLogo -File `"$mainPath`""
        Write-Log "Shortcut target uses pwsh: $targetPath $targetArgs"
    }

    # Create shortcut
    if (-not $NoShortcut) {
        Write-Step "Creating desktop shortcut..."
        
        $desktopPath = [Environment]::GetFolderPath("Desktop")
        $shortcutPath = Join-Path $desktopPath "$ShortcutName.lnk"
        
        $WshShell = New-Object -ComObject WScript.Shell
        $Shortcut = $WshShell.CreateShortcut($shortcutPath)
        $Shortcut.TargetPath = $targetPath
        $Shortcut.Arguments = $targetArgs
        $Shortcut.WorkingDirectory = $InstallPath
        $Shortcut.Description = "LazyFrog Developer Tools"
        
        # Set icon if available
        if (Test-Path $exePath) {
            $Shortcut.IconLocation = $exePath
        }
        elseif (Test-Path $iconPath) {
            $Shortcut.IconLocation = $iconPath
        }
        
        $Shortcut.Save()
        
        Write-Step "Desktop shortcut created" -Status "SUCCESS"
        
        # Create Start Menu shortcut
        $startMenuPath = Join-Path ([Environment]::GetFolderPath("StartMenu")) "Programs"
        $startShortcutPath = Join-Path $startMenuPath "$ShortcutName.lnk"
        
        $StartShortcut = $WshShell.CreateShortcut($startShortcutPath)
        $StartShortcut.TargetPath = $targetPath
        $StartShortcut.Arguments = $targetArgs
        $StartShortcut.WorkingDirectory = $InstallPath
        $StartShortcut.Description = "LazyFrog Developer Tools"
        
        if (Test-Path $exePath) {
            $StartShortcut.IconLocation = $exePath
        }
        elseif (Test-Path $iconPath) {
            $StartShortcut.IconLocation = $iconPath
        }
        
        $StartShortcut.Save()
        
        Write-Step "Start Menu shortcut created" -Status "SUCCESS"
    }

    # Create startup shortcut (auto-launch on reboot)
    if (-not $NoStartup) {
        Write-Step "Enabling auto-start on reboot..."
        $startupPath = [Environment]::GetFolderPath("Startup")
        $startupShortcutPath = Join-Path $startupPath "$ShortcutName.lnk"
        
        $WshShell = New-Object -ComObject WScript.Shell
        $StartupShortcut = $WshShell.CreateShortcut($startupShortcutPath)
        $StartupShortcut.TargetPath = $targetPath
        $StartupShortcut.Arguments = $targetArgs
        $StartupShortcut.WorkingDirectory = $InstallPath
        $StartupShortcut.Description = "LazyFrog Developer Tools"
        
        if (Test-Path $exePath) {
            $StartupShortcut.IconLocation = $exePath
        }
        elseif (Test-Path $iconPath) {
            $StartupShortcut.IconLocation = $iconPath
        }
        
        $StartupShortcut.Save()
        Write-Step "Startup shortcut created" -Status "SUCCESS"
    }
    
    Write-Host ""
    Write-Host "  ===============================================" -ForegroundColor Green
    Write-Host "  Installation complete" -ForegroundColor Green
    Write-Host "  ===============================================" -ForegroundColor Green
    Write-Log "Install-Application: completed"
    Show-InstallSummary

    $runNow = Read-Host "  Launch LazyFrog now? (Y/n)"
    if ($runNow -ne "n" -and $runNow -ne "N") {
        $exePath = Join-Path $InstallPath $AppExeName
        try {
            if (Test-Path $exePath) {
                Write-Log "Launch: starting $exePath"
                Start-Process -FilePath $exePath -WorkingDirectory $InstallPath
            }
            else {
                $mainPath = Join-Path $InstallPath 'src\main.ps1'
                Write-Log "Launch: exe missing, using pwsh $pwshPath -File $mainPath"
                $pwshArgs = @("-NoExit","-NoProfile","-ExecutionPolicy","Bypass","-NoLogo","-File",$mainPath)
                Start-Process -FilePath $pwshPath -ArgumentList $pwshArgs -WorkingDirectory $InstallPath
            }
        }
        catch {
            Write-Log "Launch failed: $_"
            Write-Host "  Failed to launch LazyFrog: $_" -ForegroundColor Red
            Write-Host "  You can start it manually from: $InstallPath" -ForegroundColor Yellow
            Read-Host "Press Enter to exit" | Out-Null
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
    $desktopPath = [Environment]::GetFolderPath("Desktop")
    $shortcutPath = Join-Path $desktopPath "$ShortcutName.lnk"
    if (Test-Path $shortcutPath) {
        Remove-Item -Path $shortcutPath -Force
        Write-Step "Removed desktop shortcut" -Status "SUCCESS"
    }
    
    $startMenuPath = Join-Path ([Environment]::GetFolderPath("StartMenu")) "Programs"
    $startShortcutPath = Join-Path $startMenuPath "$ShortcutName.lnk"
    if (Test-Path $startShortcutPath) {
        Remove-Item -Path $startShortcutPath -Force
        Write-Step "Removed Start Menu shortcut" -Status "SUCCESS"
    }

    $startupPath = [Environment]::GetFolderPath("Startup")
    $startupShortcutPath = Join-Path $startupPath "$ShortcutName.lnk"
    if (Test-Path $startupShortcutPath) {
        Remove-Item -Path $startupShortcutPath -Force
        Write-Step "Removed Startup shortcut" -Status "SUCCESS"
    }
    
    Write-Host ""
    Write-Host "  ===============================================" -ForegroundColor Green
    Write-Host "  Uninstallation complete" -ForegroundColor Green
    Write-Host "  ===============================================" -ForegroundColor Green
    Write-Host ""
}

# Main execution
try {
    Write-Log "Main execution started"
    if ($Uninstall) {
        Uninstall-Application
    }
    else {
        Install-Application
    }
    Write-Log "Main execution completed"
}
catch {
    Write-Log "Installer exception: $_"
    Write-Host "" 
    Write-Host "  Installer error: $_" -ForegroundColor Red
    Write-Host "  Log file: $logFile" -ForegroundColor Yellow
    Write-Host "" 
    Read-Host "Press Enter to close" | Out-Null
}
'@

    $installerPath = Join-Path $OutputPath "Install-LazyFrogDevTerm.ps1"
    $installerContent | Set-Content -Path $installerPath -Encoding UTF8
    
    return $installerPath
}

# ============================================================================
# LAUNCHER SCRIPT GENERATOR
# ============================================================================

function New-LauncherScript {
    param(
        [string]$OutputPath
    )
    
    $launcherContent = @'
@echo off
:: LazyFrog Developer Tools Launcher
:: Powered by Kindware.dev

title LazyFrog Developer Tools

:: Check for PowerShell 7
where pwsh >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo.
    echo  ERROR: PowerShell 7+ is required!
    echo.
    echo  Download from: https://github.com/PowerShell/PowerShell/releases
    echo.
    pause
    exit /b 1
)

:: Get the directory where this script is located
set "SCRIPT_DIR=%~dp0"

:: Run the application
pwsh -NoExit -ExecutionPolicy Bypass -File "%SCRIPT_DIR%src\main.ps1"
'@

    $launcherPath = Join-Path $OutputPath "LazyFrog-DevTerm.bat"
    $launcherContent | Set-Content -Path $launcherPath -Encoding ASCII
    
    return $launcherPath
}

# ============================================================================
# BUILD PACKAGE
# ============================================================================

function New-Package {
    param(
        [string]$OutputPath
    )
    
    Write-Step "Building installation package..."
    Write-Host ""
    
    # Create output directory
    $packagePath = Join-Path $OutputPath "LazyFrog-DevTerm-Package"
    if (Test-Path $packagePath) {
        Remove-Item -Path $packagePath -Recurse -Force
    }
    New-Item -ItemType Directory -Path $packagePath -Force | Out-Null
    
    # Copy source files
    Write-Step "Copying source files..."
    
    $projectRoot = $script:Config.ProjectRoot
    
    # Copy src directory
    $srcDest = Join-Path $packagePath "src"
    Copy-Item -Path (Join-Path $projectRoot "src") -Destination $srcDest -Recurse -Force
    
    # Copy configuration files
    $configFiles = @("config.json", "tasks.json", "watchlist.json", "CHANGELOG.md", "README.md", "LICENSE")
    foreach ($file in $configFiles) {
        $sourcePath = Join-Path $projectRoot $file
        if (Test-Path $sourcePath) {
            Copy-Item -Path $sourcePath -Destination (Join-Path $packagePath $file) -Force
        }
    }
    
    # Copy icon if exists
    $iconPath = Resolve-IconPath
    if ($null -ne $iconPath) {
        Copy-Item -Path $iconPath -Destination (Join-Path $packagePath "icon.ico") -Force
        Write-Step "Icon file included" -Status "SUCCESS"
    }
    else {
        Write-Step "No icon.ico found (optional)" -Status "WARNING"
    }
    
    Write-Step "Source files copied" -Status "SUCCESS"

    # Optionally build app EXE (launcher)
    if ($CreateAppExe) {
        Write-Step "Creating app EXE with PS2EXE..." -Status "INFO"
        $ps2exeModule = Get-Module -ListAvailable -Name ps2exe
        if ($null -eq $ps2exeModule) {
            Write-Step "PS2EXE not installed. Installing..." -Status "WARNING"
            try {
                Install-Module -Name ps2exe -Scope CurrentUser -Force
                Import-Module ps2exe
                Write-Step "PS2EXE installed" -Status "SUCCESS"
            }
            catch {
                Write-Step "Failed to install PS2EXE: $_" -Status "ERROR"
            }
        }

        try {
            $launcherScript = Join-Path $projectRoot "LazyFrog-Launcher.ps1"
            if (-not (Test-Path $launcherScript)) {
                $launcherScript = Join-Path $projectRoot "Launcher.ps1"
            }
            $appExePath = Join-Path $packagePath "LazyFrog.exe"

            if (Test-Path $launcherScript) {
                $ps2exeParams = @{
                    InputFile    = $launcherScript
                    OutputFile   = $appExePath
                    Title        = $script:Config.AppName
                    Description  = $script:Config.Description
                    Company      = $script:Config.Publisher
                    Version      = $script:Config.AppVersion
                    NoConsole    = $true
                    RequireAdmin = $false
                    Sta          = $true
                }
                if ($null -ne $iconPath) {
                    $ps2exeParams.IconFile = $iconPath
                }
                Invoke-ps2exe @ps2exeParams
                Write-Step "App EXE created: $(Split-Path $appExePath -Leaf)" -Status "SUCCESS"
            }
            else {
                Write-Step "Launcher script not found; skipping app EXE" -Status "WARNING"
            }
        }
        catch {
            Write-Step "Failed to create app EXE: $_" -Status "ERROR"
        }
    }
    
    # Create directories
    New-Item -ItemType Directory -Path (Join-Path $packagePath "results") -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $packagePath "history") -Force | Out-Null
    
    # Generate installer script
    Write-Step "Generating installer script..."
    $installerPath = New-InstallerScript -OutputPath $packagePath
    Write-Step "Installer script created: $(Split-Path $installerPath -Leaf)" -Status "SUCCESS"
    
    # Generate launcher batch file
    Write-Step "Generating launcher script..."
    $launcherPath = New-LauncherScript -OutputPath $packagePath
    Write-Step "Launcher script created: $(Split-Path $launcherPath -Leaf)" -Status "SUCCESS"
    
    # Create ZIP package
    Write-Step "Creating ZIP package..."
    $zipPath = Join-Path $OutputPath "LazyFrog-DevTerm-v$($script:Config.AppVersion).zip"
    if (Test-Path $zipPath) {
        Remove-Item -Path $zipPath -Force
    }
    Compress-Archive -Path "$packagePath\*" -DestinationPath $zipPath -CompressionLevel Optimal
    Write-Step "ZIP package created: $(Split-Path $zipPath -Leaf)" -Status "SUCCESS"
    
    return @{
        PackagePath   = $packagePath
        ZipPath       = $zipPath
        InstallerPath = $installerPath
        LauncherPath  = $launcherPath
    }
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

Write-Banner

if (-not (Test-PowerShellVersion)) {
    exit 1
}

# Set output path
if ([string]::IsNullOrEmpty($OutputPath)) {
    $OutputPath = Join-Path $script:Config.ProjectRoot "dist"
}

if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}

Write-Step "Output directory: $OutputPath"
Write-Host ""

# Build package
$result = New-Package -OutputPath $OutputPath

Write-Host ""
Write-Host "  ═══════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "  ✅ Build complete!" -ForegroundColor Green
Write-Host "  ═══════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Host "  Package location:" -ForegroundColor White
Write-Host "    $($result.PackagePath)" -ForegroundColor Cyan
Write-Host ""
Write-Host "  ZIP archive:" -ForegroundColor White
Write-Host "    $($result.ZipPath)" -ForegroundColor Cyan
Write-Host ""
Write-Host "  To install:" -ForegroundColor Yellow
Write-Host "    1. Extract the ZIP or use the package folder" -ForegroundColor White
Write-Host "    2. Run: .\Install-LazyFrogDevTerm.ps1" -ForegroundColor White
Write-Host ""
Write-Host "  To run directly (no install):" -ForegroundColor Yellow
Write-Host "    pwsh -File src\main.ps1" -ForegroundColor White
Write-Host "    Or double-click: LazyFrog-DevTerm.bat" -ForegroundColor White
Write-Host ""

# Optionally create PS2EXE executable
if ($CreateExe) {
    Write-Host ""
    Write-Step "Attempting to create EXE with PS2EXE..."
    
    # Check if PS2EXE is available
    $ps2exeModule = Get-Module -ListAvailable -Name ps2exe
    
    if ($null -eq $ps2exeModule) {
        Write-Step "PS2EXE not installed. Installing..." -Status "WARNING"
        try {
            Install-Module -Name ps2exe -Scope CurrentUser -Force
            Import-Module ps2exe
            Write-Step "PS2EXE installed" -Status "SUCCESS"
        }
        catch {
            Write-Step "Failed to install PS2EXE: $_" -Status "ERROR"
            Write-Step "Skipping EXE creation" -Status "WARNING"
            exit 0
        }
    }
    
    try {
        $exePath = Join-Path $OutputPath "LazyFrog-DevTerm-Setup.exe"
        $iconFile = Resolve-IconPath
        
        $ps2exeParams = @{
            InputFile   = $result.InstallerPath
            OutputFile  = $exePath
            Title       = $script:Config.AppName
            Description = $script:Config.Description
            Company     = $script:Config.Publisher
            Version     = $script:Config.AppVersion
            NoConsole   = $false
            RequireAdmin = $false
            Sta         = $true
        }
        
        if ($null -ne $iconFile -and (Test-Path $iconFile)) {
            $ps2exeParams.IconFile = $iconFile
        }
        
        Invoke-ps2exe @ps2exeParams
        
        Write-Step "EXE created: $(Split-Path $exePath -Leaf)" -Status "SUCCESS"
    }
    catch {
        Write-Step "Failed to create EXE: $_" -Status "ERROR"
    }
}
