$dir = $null
try {
    $dir = Split-Path $MyInvocation.MyCommand.Path
}
catch {}
if ([string]::IsNullOrEmpty($dir)) {
    try {
        $dir = Split-Path -Parent ([System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName)
    }
    catch {}
}
if ([string]::IsNullOrEmpty($dir)) {
    $dir = $PWD.Path
}
$script = Join-Path $dir "src\main.ps1"

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

    Write-Host "PowerShell 7 is not installed. Install now with winget? (Y/n)" -ForegroundColor Yellow
    $answer = Read-Host
    if ($answer -eq "n" -or $answer -eq "N") { return $null }

    $winget = Get-Command winget -ErrorAction SilentlyContinue
    if ($null -eq $winget) {
        Write-Host "winget not found. Please install PowerShell 7 manually." -ForegroundColor Red
        return $null
    }

    Write-Host "Installing PowerShell 7 via winget..." -ForegroundColor Cyan
    Start-Process -FilePath $winget.Source -ArgumentList "install","--id","Microsoft.PowerShell","--source","winget","--accept-source-agreements","--accept-package-agreements" -Wait
    return Get-PwshPath
}

$pwsh = Ensure-Pwsh
if ($null -eq $pwsh) {
    Write-Host "PowerShell 7 is required to run LazyFrog." -ForegroundColor Red
    Write-Host "Log file: $logFile" -ForegroundColor Yellow
    Write-Log "PowerShell 7 not available"
    Read-Host "Press Enter to exit" | Out-Null
    exit 1
}

try {
    Write-Log "Launching: $pwsh -File $script"
    $proc = Start-Process $pwsh -ArgumentList "-NoProfile","-ExecutionPolicy","Bypass","-File",$script -WorkingDirectory $dir -Wait -PassThru
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
