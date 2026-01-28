<#
.SYNOPSIS
    System Monitor Tool for LazyFrog Developer Tools
.DESCRIPTION
    Provides real-time system resource monitoring including CPU,
    RAM, disk, and network information.
.AUTHOR
    Kindware.dev
.VERSION
    1.0.0
#>

$script:SystemState = @{
    CpuUsage        = 0
    RamUsage        = 0
    RamTotal        = 0
    RamUsed         = 0
    DiskInfo        = @()
    NetworkInfo     = @()
    Uptime          = ""
    LastUpdate      = $null
    TopProcesses    = @()
}

<#
.SYNOPSIS
    Updates all system information
#>
function Update-SystemInfo {
    [CmdletBinding()]
    param()
    
    try {
        $cpuCounter = Get-Counter '\Processor(_Total)\% Processor Time' -ErrorAction SilentlyContinue
        if ($cpuCounter) {
            $script:SystemState.CpuUsage = [Math]::Round($cpuCounter.CounterSamples[0].CookedValue, 1)
        }
    }
    catch {
        $script:SystemState.CpuUsage = 0
    }
    
    try {
        $os = Get-CimInstance Win32_OperatingSystem
        $totalRam = [Math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
        $freeRam = [Math]::Round($os.FreePhysicalMemory / 1MB, 2)
        $usedRam = $totalRam - $freeRam
        
        $script:SystemState.RamTotal = $totalRam
        $script:SystemState.RamUsed = $usedRam
        $script:SystemState.RamUsage = [Math]::Round(($usedRam / $totalRam) * 100, 1)
    }
    catch {
        $script:SystemState.RamUsage = 0
    }
    
    try {
        $disks = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3"
        $script:SystemState.DiskInfo = @()
        
        foreach ($disk in $disks) {
            $totalSpace = [Math]::Round($disk.Size / 1GB, 2)
            $freeSpace = [Math]::Round($disk.FreeSpace / 1GB, 2)
            $usedSpace = $totalSpace - $freeSpace
            $usagePercent = if ($totalSpace -gt 0) { [Math]::Round(($usedSpace / $totalSpace) * 100, 1) } else { 0 }
            
            $script:SystemState.DiskInfo += @{
                Drive       = $disk.DeviceID
                Label       = if ($disk.VolumeName) { $disk.VolumeName } else { "Local Disk" }
                TotalGB     = $totalSpace
                UsedGB      = $usedSpace
                FreeGB      = $freeSpace
                UsagePercent = $usagePercent
            }
        }
    }
    catch {
        $script:SystemState.DiskInfo = @()
    }
    
    try {
        $adapters = Get-NetAdapter -Physical -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq "Up" }
        $script:SystemState.NetworkInfo = @()
        
        foreach ($adapter in $adapters) {
            $ipConfig = Get-NetIPAddress -InterfaceIndex $adapter.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue | Select-Object -First 1
            
            $script:SystemState.NetworkInfo += @{
                Name      = $adapter.Name
                Status    = $adapter.Status
                Speed     = if ($adapter.LinkSpeed) { $adapter.LinkSpeed } else { "N/A" }
                IPAddress = if ($ipConfig) { $ipConfig.IPAddress } else { "N/A" }
            }
        }
    }
    catch {
        $script:SystemState.NetworkInfo = @()
    }
    
    try {
        $bootTime = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
        $uptime = (Get-Date) - $bootTime
        $script:SystemState.Uptime = "{0}d {1}h {2}m" -f $uptime.Days, $uptime.Hours, $uptime.Minutes
    }
    catch {
        $script:SystemState.Uptime = "Unknown"
    }
    
    try {
        $script:SystemState.TopProcesses = Get-Process | 
            Sort-Object CPU -Descending | 
            Select-Object -First 5 @{N='Name';E={$_.ProcessName}}, 
                                    @{N='CPU';E={[Math]::Round($_.CPU, 1)}}, 
                                    @{N='Memory';E={[Math]::Round($_.WorkingSet64 / 1MB, 1)}}
    }
    catch {
        $script:SystemState.TopProcesses = @()
    }
    
    $script:SystemState.LastUpdate = Get-Date
}

<#
.SYNOPSIS
    Gets the current system state
#>
function Get-SystemState {
    return $script:SystemState
}

<#
.SYNOPSIS
    Gets system data for UI rendering
#>
function Get-SystemData {
    Update-SystemInfo
    return $script:SystemState
}

<#
.SYNOPSIS
    Creates a progress bar string
#>
function Get-ProgressBar {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [double]$Percent,
        
        [Parameter(Mandatory = $false)]
        [int]$Width = 25
    )
    
    $filled = [Math]::Floor($Width * $Percent / 100)
    $empty = $Width - $filled
    
    $bar = "#" * $filled + "-" * $empty
    return "[$bar]"
}

<#
.SYNOPSIS
    Formats system information for TUI display
#>
function Format-SystemInfo {
    [CmdletBinding()]
    param()
    
    Update-SystemInfo
    
    $lines = @()
    $lines += ""
    $lines += "  [SYSTEM] System Monitor"
    $lines += "  ====================================================="
    $lines += ""
    
    $cpuBar = Get-ProgressBar -Percent $script:SystemState.CpuUsage
    $lines += "  [CPU] CPU Usage"
    $lines += "      $cpuBar $($script:SystemState.CpuUsage)%"
    $lines += ""
    
    $ramBar = Get-ProgressBar -Percent $script:SystemState.RamUsage
    $lines += "  [RAM] RAM Usage"
    $lines += "      $ramBar $($script:SystemState.RamUsage)%"
    $lines += "      Used: $($script:SystemState.RamUsed) GB / $($script:SystemState.RamTotal) GB"
    $lines += ""
    
    $lines += "  [DISK] Disk Usage"
    foreach ($disk in $script:SystemState.DiskInfo) {
        $diskBar = Get-ProgressBar -Percent $disk.UsagePercent -Width 20
        $lines += "      $($disk.Drive) $diskBar $($disk.UsagePercent)%"
        $lines += "         $($disk.UsedGB) GB / $($disk.TotalGB) GB ($($disk.FreeGB) GB free)"
    }
    $lines += ""
    
    if ($script:SystemState.NetworkInfo.Count -gt 0) {
        $lines += "  [NET] Network Adapters"
        foreach ($adapter in $script:SystemState.NetworkInfo) {
            $lines += "      $($adapter.Name): $($adapter.IPAddress)"
            $lines += "         Speed: $($adapter.Speed)"
        }
        $lines += ""
    }
    
    $lines += "  [TIME] System Uptime: $($script:SystemState.Uptime)"
    $lines += ""
    
    if ($script:SystemState.TopProcesses.Count -gt 0) {
        $lines += "  [PROC] Top Processes (by CPU)"
        $lines += "      -----------------------------------------"
        $lines += "      Name                   CPU     Memory"
        $lines += "      -----------------------------------------"
        
        foreach ($proc in $script:SystemState.TopProcesses) {
            $name = $proc.Name
            if ($name.Length -gt 20) { $name = $name.Substring(0, 17) + "..." }
            $name = $name.PadRight(20)
            $cpu = $proc.CPU.ToString().PadLeft(6)
            $mem = "$($proc.Memory) MB".PadLeft(10)
            $lines += "      $name $cpu $mem"
        }
    }
    
    $lines += ""
    $lines += "  -----------------------------------------------------"
    $lines += "  [R] Refresh  [S] Save Snapshot  [Esc] Back"
    $lines += "  Last updated: $(Get-Date -Format 'HH:mm:ss')"
    
    return $lines
}

<#
.SYNOPSIS
    Saves a system snapshot to JSON file
#>
function Save-SystemSnapshot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )
    
    Update-SystemInfo
    
    $timestamp = Get-Date -Format "yyyy-MM-dd-HHmmss"
    $filename = "system-snapshot-$timestamp.json"
    $filepath = Join-Path $OutputPath $filename
    
    $snapshot = @{
        timestamp    = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss")
        cpu          = @{
            usage = $script:SystemState.CpuUsage
        }
        memory       = @{
            totalGB    = $script:SystemState.RamTotal
            usedGB     = $script:SystemState.RamUsed
            usagePercent = $script:SystemState.RamUsage
        }
        disks        = $script:SystemState.DiskInfo
        network      = $script:SystemState.NetworkInfo
        uptime       = $script:SystemState.Uptime
        topProcesses = $script:SystemState.TopProcesses
    }
    
    try {
        if (-not (Test-Path $OutputPath)) {
            New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
        }
        
        $snapshot | ConvertTo-Json -Depth 10 | Set-Content $filepath -Encoding UTF8
        return $filepath
    }
    catch {
        throw "Failed to save snapshot: $_"
    }
}

<#
.SYNOPSIS
    Gets detailed CPU information
#>
function Get-CpuInfo {
    [CmdletBinding()]
    param()
    
    try {
        $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
        
        return @{
            Name         = $cpu.Name
            Cores        = $cpu.NumberOfCores
            LogicalCores = $cpu.NumberOfLogicalProcessors
            MaxSpeed     = "$([Math]::Round($cpu.MaxClockSpeed / 1000, 2)) GHz"
            CurrentLoad  = $script:SystemState.CpuUsage
        }
    }
    catch {
        return @{
            Name         = "Unknown"
            Cores        = 0
            LogicalCores = 0
            MaxSpeed     = "N/A"
            CurrentLoad  = 0
        }
    }
}

<#
.SYNOPSIS
    Gets detailed memory information
#>
function Get-MemoryInfo {
    [CmdletBinding()]
    param()
    
    try {
        $os = Get-CimInstance Win32_OperatingSystem
        $totalRam = [Math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
        $freeRam = [Math]::Round($os.FreePhysicalMemory / 1MB, 2)
        $usedRam = $totalRam - $freeRam
        
        return @{
            TotalGB      = $totalRam
            UsedGB       = $usedRam
            FreeGB       = $freeRam
            UsagePercent = [Math]::Round(($usedRam / $totalRam) * 100, 1)
        }
    }
    catch {
        return @{
            TotalGB      = 0
            UsedGB       = 0
            FreeGB       = 0
            UsagePercent = 0
        }
    }
}

<#
.SYNOPSIS
    Gets OS information
#>
function Get-OSInfo {
    [CmdletBinding()]
    param()
    
    try {
        $os = Get-CimInstance Win32_OperatingSystem
        $cs = Get-CimInstance Win32_ComputerSystem
        
        return @{
            Name         = $os.Caption
            Version      = $os.Version
            Build        = $os.BuildNumber
            Architecture = $os.OSArchitecture
            ComputerName = $cs.Name
            Domain       = $cs.Domain
            Manufacturer = $cs.Manufacturer
            Model        = $cs.Model
        }
    }
    catch {
        return @{
            Name         = "Unknown"
            Version      = "N/A"
            Build        = "N/A"
            Architecture = "N/A"
            ComputerName = "Unknown"
            Domain       = "N/A"
            Manufacturer = "N/A"
            Model        = "N/A"
        }
    }
}

<#
.SYNOPSIS
    Formats detailed system information
#>
function Format-DetailedSystemInfo {
    [CmdletBinding()]
    param()
    
    $cpuInfo = Get-CpuInfo
    $osInfo = Get-OSInfo
    
    $lines = @()
    $lines += ""
    $lines += "  [INFO] Detailed System Information"
    $lines += "  ====================================================="
    $lines += ""
    $lines += "  Computer: $($osInfo.ComputerName)"
    $lines += "  OS: $($osInfo.Name)"
    $lines += "  Version: $($osInfo.Version) (Build $($osInfo.Build))"
    $lines += "  Architecture: $($osInfo.Architecture)"
    $lines += ""
    $lines += "  CPU: $($cpuInfo.Name)"
    $lines += "  Cores: $($cpuInfo.Cores) Physical, $($cpuInfo.LogicalCores) Logical"
    $lines += "  Max Speed: $($cpuInfo.MaxSpeed)"
    $lines += ""
    $lines += "  Manufacturer: $($osInfo.Manufacturer)"
    $lines += "  Model: $($osInfo.Model)"
    $lines += ""
    
    return $lines
}

# Functions are available via dot-sourcing
