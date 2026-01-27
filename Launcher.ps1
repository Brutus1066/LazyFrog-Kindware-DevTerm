# LazyFrog Developer Tools Launcher
# This script launches the main application using PowerShell 7

$ErrorActionPreference = "Stop"

$logRoot = Join-Path $env:LOCALAPPDATA "LazyFrog-DevTerm\logs"
if (-not (Test-Path $logRoot)) {
    New-Item -ItemType Directory -Path $logRoot -Force | Out-Null
}
$logFile = Join-Path $logRoot "launcher-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

function Write-Log {
    param([string]$Message)
    $line = "[{0}] {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Message
    Add-Content -Path $logFile -Value $line
}

Write-Log "Launcher started"

function Test-IsInteractive {
    try {
        $null = $Host.UI.RawUI
        return $true
    }
    catch {
        return $false
    }
}

function Show-UserMessage {
    param(
        [Parameter(Mandatory = $true)][string]$Message,
        [Parameter(Mandatory = $false)][string]$Title = "LazyFrog",
        [Parameter(Mandatory = $false)][ValidateSet("OK","YesNo")][string]$Buttons = "OK",
        [Parameter(Mandatory = $false)][ValidateSet("Information","Warning","Error")][string]$Icon = "Information"
    )

    try {
        Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
        $buttonEnum = [System.Windows.Forms.MessageBoxButtons]::$Buttons
        $iconEnum = [System.Windows.Forms.MessageBoxIcon]::$Icon
        return [System.Windows.Forms.MessageBox]::Show($Message, $Title, $buttonEnum, $iconEnum)
    }
    catch {
        try {
            Write-Host $Message -ForegroundColor Yellow
        }
        catch {}
    }
    return $null
}

# Get the directory where this script is located
function Get-LauncherDir {
    $candidates = @(
        $PSScriptRoot,
        $(if (-not [string]::IsNullOrWhiteSpace($PSCommandPath)) { Split-Path -Parent $PSCommandPath } else { $null })
    )

    foreach ($candidate in $candidates) {
        if (-not [string]::IsNullOrWhiteSpace($candidate)) { return $candidate }
    }

    try {
        $path = $MyInvocation.MyCommand.Path
        if (-not [string]::IsNullOrWhiteSpace($path)) {
            return (Split-Path -Parent $path)
        }
    }
    catch {}

    try {
        $baseDir = [System.AppContext]::BaseDirectory
        if (-not [string]::IsNullOrWhiteSpace($baseDir)) {
            return $baseDir.TrimEnd('\')
        }
    }
    catch {}

    try {
        $exePath = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
        if (-not [string]::IsNullOrWhiteSpace($exePath)) {
            return (Split-Path -Parent $exePath)
        }
    }
    catch {}

    if ($null -ne $PWD -and -not [string]::IsNullOrWhiteSpace($PWD.Path)) {
        return $PWD.Path
    }

    return ""
}

$launcherDir = Get-LauncherDir
if ([string]::IsNullOrWhiteSpace($launcherDir)) {
    $msg = "Unable to resolve launcher path. Please run from the LazyFrog folder or reinstall."
    Write-Log $msg
    Show-UserMessage -Message $msg -Title "LazyFrog" -Buttons OK -Icon Error | Out-Null
    exit 1
}

function Get-PwshPath {
    $cmd = Get-Command pwsh -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }

    $pwshPaths = @(
        "C:\Program Files\PowerShell\7\pwsh.exe",
        "$env:ProgramFiles\PowerShell\7\pwsh.exe",
        "$env:LOCALAPPDATA\Microsoft\PowerShell\7\pwsh.exe"
    )

    foreach ($path in $pwshPaths) {
        if (Test-Path $path) { return $path }
    }

    return $null
}

function Ensure-Pwsh {
    $pwshExe = Get-PwshPath
    if ($null -ne $pwshExe) { return $pwshExe }

    $message = "PowerShell 7 is not installed. Install now with winget?"
    if (Test-IsInteractive) {
        Write-Host "$message (Y/n)" -ForegroundColor Yellow
        $answer = Read-Host
        if ($answer -eq "n" -or $answer -eq "N") { return $null }
    }
    else {
        $result = Show-UserMessage -Message $message -Title "LazyFrog" -Buttons YesNo -Icon Warning
        if ($null -ne $result -and $result.ToString() -eq "No") { return $null }
    }

    $winget = Get-Command winget -ErrorAction SilentlyContinue
    if ($null -eq $winget) {
        $msg = "winget not found. Please install PowerShell 7 manually from https://github.com/PowerShell/PowerShell/releases"
        Show-UserMessage -Message $msg -Title "LazyFrog" -Buttons OK -Icon Error | Out-Null
        return $null
    }

    Write-Host "Installing PowerShell 7 via winget..." -ForegroundColor Cyan
    Start-Process -FilePath $winget.Source -ArgumentList "install","--id","Microsoft.PowerShell","--source","winget","--accept-source-agreements","--accept-package-agreements" -Wait

    return Get-PwshPath
}

$pwshExe = Ensure-Pwsh
if ($null -eq $pwshExe) {
    $message = "PowerShell 7 is required to run LazyFrog."
    Write-Log $message
    Write-Host $message -ForegroundColor Red
    Write-Host "Log file: $logFile" -ForegroundColor Yellow
    Read-Host "Press Enter to close" | Out-Null
    exit 1
}

$mainScript = Join-Path $launcherDir "src\main.ps1"

if (-not (Test-Path $mainScript)) {
    $message = "Cannot find main.ps1`n`nExpected: $mainScript"
    try {
        Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
        [System.Windows.Forms.MessageBox]::Show(
            $message,
            "LazyFrog - Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        ) | Out-Null
    }
    catch {
        Write-Host $message -ForegroundColor Red
    }
    Write-Log $message
    Write-Host "Log file: $logFile" -ForegroundColor Yellow
    Read-Host "Press Enter to close" | Out-Null
    exit 1
}

# Launch PowerShell 7 with the main script
try {
    Write-Log "Launching: $pwshExe -File $mainScript"
    $proc = Start-Process -FilePath $pwshExe -ArgumentList "-NoProfile","-ExecutionPolicy","Bypass","-NoLogo","-File","`"$mainScript`"" -WorkingDirectory $launcherDir -Wait -PassThru
    Write-Log "Process exit code: $($proc.ExitCode)"

    if ($proc.ExitCode -ne 0) {
        Write-Host "" 

        try {
            Write-Log "LauncherDir: $launcherDir"

            $pwshExe = $null
            try {
                $pwshExe = Ensure-Pwsh
                Write-Log "PwshPath: $pwshExe"
            }
            catch {
                Write-Log "Ensure-Pwsh exception: $_"
                throw
            }

            if ($null -eq $pwshExe) {
                $message = "PowerShell 7 is required to run LazyFrog."
                Write-Log $message
                Write-Host $message -ForegroundColor Red
                Write-Host "Log file: $logFile" -ForegroundColor Yellow
                Read-Host "Press Enter to close" | Out-Null
                exit 1
            }

            $mainScript = Join-Path $launcherDir "src\main.ps1"
            Write-Log "MainScript: $mainScript"

            if (-not (Test-Path $mainScript)) {
                $message = "Cannot find main.ps1`n`nExpected: $mainScript"
                try {
                    Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
                    [System.Windows.Forms.MessageBox]::Show(
                        $message,
                        "LazyFrog - Error",
                        [System.Windows.Forms.MessageBoxButtons]::OK,
                        [System.Windows.Forms.MessageBoxIcon]::Error
                    ) | Out-Null
                }
                catch {
                    Write-Host $message -ForegroundColor Red
                }
                Write-Log $message
                Write-Host "Log file: $logFile" -ForegroundColor Yellow
                Read-Host "Press Enter to close" | Out-Null
                exit 1
            }

            Write-Log "Launching: $pwshExe -File $mainScript"
            $proc = Start-Process -FilePath $pwshExe -ArgumentList "-NoProfile","-ExecutionPolicy","Bypass","-NoLogo","-File","`"$mainScript`"" -WorkingDirectory $launcherDir -Wait -PassThru
            Write-Log "Process exit code: $($proc.ExitCode)"

            if ($proc.ExitCode -ne 0) {
                Write-Host "" 
                Write-Host "LazyFrog exited with code $($proc.ExitCode)." -ForegroundColor Red
                Write-Host "Log file: $logFile" -ForegroundColor Yellow
                Read-Host "Press Enter to close..." | Out-Null
            }
        }
        catch {
            Write-Log "Launcher exception: $_"
            Write-Host "Launcher error: $_" -ForegroundColor Red
            Write-Host "Log file: $logFile" -ForegroundColor Yellow
            Read-Host "Press Enter to close..." | Out-Null
        }

    }
}
catch {
    Write-Log "Launcher exception: $_"
    Write-Host "Launcher error: $_" -ForegroundColor Red
    Write-Host "Log file: $logFile" -ForegroundColor Yellow
    Read-Host "Press Enter to close..." | Out-Null
}
