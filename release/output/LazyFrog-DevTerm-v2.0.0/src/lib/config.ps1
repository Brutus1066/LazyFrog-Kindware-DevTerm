<#
.SYNOPSIS
    Configuration Manager for LazyFrog Developer Tools
.DESCRIPTION
    Handles loading, saving, and accessing configuration settings
    for the LazyFrog Developer Tools application.
.AUTHOR
    Kindware.dev
.VERSION
    1.0.0
#>

# Script-level configuration storage
$script:AppConfig = $null
$script:ConfigPath = $null
$script:TasksPath = $null
$script:WatchlistPath = $null

<#
.SYNOPSIS
    Initializes the configuration system
.DESCRIPTION
    Loads configuration from config.json and sets up paths
.PARAMETER RootPath
    The root path of the application
#>
function Initialize-AppConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RootPath
    )
    
    $script:ConfigPath = Join-Path $RootPath "config.json"
    $script:TasksPath = Join-Path $RootPath "tasks.json"
    $script:WatchlistPath = Join-Path $RootPath "watchlist.json"
    
    # Load or create default configuration
    if (Test-Path $script:ConfigPath) {
        try {
            $script:AppConfig = Get-Content $script:ConfigPath -Raw | ConvertFrom-Json
            Write-Verbose "Configuration loaded from $($script:ConfigPath)"
        }
        catch {
            Write-Warning "Failed to load config, using defaults: $_"
            $script:AppConfig = Get-DefaultConfig
            Save-AppConfig
        }
    }
    else {
        $script:AppConfig = Get-DefaultConfig
        Save-AppConfig
    }
    
    # Ensure required directories exist
    $resultsPath = Get-ConfigValue -Section "paths" -Key "results"
    $historyPath = Get-ConfigValue -Section "paths" -Key "history"
    
    $absoluteResultsPath = Join-Path $RootPath $resultsPath.TrimStart("./")
    $absoluteHistoryPath = Join-Path $RootPath $historyPath.TrimStart("./")
    
    if (-not (Test-Path $absoluteResultsPath)) {
        New-Item -ItemType Directory -Path $absoluteResultsPath -Force | Out-Null
    }
    if (-not (Test-Path $absoluteHistoryPath)) {
        New-Item -ItemType Directory -Path $absoluteHistoryPath -Force | Out-Null
    }
    
    return $script:AppConfig
}

<#
.SYNOPSIS
    Returns default configuration object
#>
function Get-DefaultConfig {
    return [PSCustomObject]@{
        application = [PSCustomObject]@{
            name    = "LazyFrog Developer Tools"
            version = "1.0.0"
            author  = "Kindware.dev"
            github  = "https://github.com/Brutus1066/LazyFrog-Kindware-DevTerm"
        }
        github      = [PSCustomObject]@{
            apiBaseUrl     = "https://api.github.com"
            resultsPerPage = 10
            defaultSort    = "stars"
            defaultOrder   = "desc"
            rateLimitDelay = 1000
        }
        ui          = [PSCustomObject]@{
            theme       = "default"
            refreshRate = 1000
            menuWidth   = 18
            showBorder  = $true
            colors      = [PSCustomObject]@{
                header       = "Cyan"
                menu         = "Yellow"
                menuSelected = "Green"
                content      = "White"
                footer       = "DarkGray"
                error        = "Red"
                success      = "Green"
                warning      = "Yellow"
            }
        }
        paths       = [PSCustomObject]@{
            results   = "./results"
            history   = "./history"
            watchlist = "./watchlist.json"
        }
        system      = [PSCustomObject]@{
            refreshInterval = 2000
            showNetworkInfo = $true
            showDiskInfo    = $true
        }
    }
}

<#
.SYNOPSIS
    Gets a configuration value
.PARAMETER Section
    The configuration section (e.g., "github", "ui")
.PARAMETER Key
    The key within the section
#>
function Get-ConfigValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Section,
        
        [Parameter(Mandatory = $false)]
        [string]$Key
    )
    
    if ($null -eq $script:AppConfig) {
        throw "Configuration not initialized. Call Initialize-AppConfig first."
    }
    
    $sectionData = $script:AppConfig.$Section
    
    if ($null -eq $sectionData) {
        return $null
    }
    
    if ([string]::IsNullOrEmpty($Key)) {
        return $sectionData
    }
    
    return $sectionData.$Key
}

<#
.SYNOPSIS
    Sets a configuration value
.PARAMETER Section
    The configuration section
.PARAMETER Key
    The key within the section
.PARAMETER Value
    The value to set
#>
function Set-ConfigValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Section,
        
        [Parameter(Mandatory = $true)]
        [string]$Key,
        
        [Parameter(Mandatory = $true)]
        $Value
    )
    
    if ($null -eq $script:AppConfig) {
        throw "Configuration not initialized. Call Initialize-AppConfig first."
    }
    
    if ($null -eq $script:AppConfig.$Section) {
        $script:AppConfig | Add-Member -NotePropertyName $Section -NotePropertyValue ([PSCustomObject]@{})
    }
    
    if ($null -eq $script:AppConfig.$Section.$Key) {
        $script:AppConfig.$Section | Add-Member -NotePropertyName $Key -NotePropertyValue $Value
    }
    else {
        $script:AppConfig.$Section.$Key = $Value
    }
    
    Save-AppConfig
}

<#
.SYNOPSIS
    Saves the current configuration to file
#>
function Save-AppConfig {
    [CmdletBinding()]
    param()
    
    if ($null -eq $script:AppConfig -or $null -eq $script:ConfigPath) {
        return
    }
    
    try {
        $script:AppConfig | ConvertTo-Json -Depth 10 | Set-Content $script:ConfigPath -Encoding UTF8
        Write-Verbose "Configuration saved to $($script:ConfigPath)"
    }
    catch {
        Write-Warning "Failed to save configuration: $_"
    }
}

<#
.SYNOPSIS
    Gets the full application configuration
#>
function Get-AppConfig {
    return $script:AppConfig
}

<#
.SYNOPSIS
    Gets the tasks configuration
#>
function Get-TasksConfig {
    [CmdletBinding()]
    param()
    
    if (Test-Path $script:TasksPath) {
        try {
            return Get-Content $script:TasksPath -Raw | ConvertFrom-Json
        }
        catch {
            Write-Warning "Failed to load tasks: $_"
            return [PSCustomObject]@{ tasks = @(); history = @() }
        }
    }
    
    return [PSCustomObject]@{ tasks = @(); history = @() }
}

<#
.SYNOPSIS
    Saves the tasks configuration
.PARAMETER TasksConfig
    The tasks configuration object to save
#>
function Save-TasksConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$TasksConfig
    )
    
    try {
        $TasksConfig | ConvertTo-Json -Depth 10 | Set-Content $script:TasksPath -Encoding UTF8
    }
    catch {
        Write-Warning "Failed to save tasks: $_"
    }
}

<#
.SYNOPSIS
    Gets the watchlist configuration
#>
function Get-WatchlistConfig {
    [CmdletBinding()]
    param()
    
    if (Test-Path $script:WatchlistPath) {
        try {
            return Get-Content $script:WatchlistPath -Raw | ConvertFrom-Json
        }
        catch {
            Write-Warning "Failed to load watchlist: $_"
            return [PSCustomObject]@{ watchlist = @(); lastUpdated = $null }
        }
    }
    
    return [PSCustomObject]@{ watchlist = @(); lastUpdated = $null }
}

<#
.SYNOPSIS
    Saves the watchlist configuration
.PARAMETER WatchlistConfig
    The watchlist configuration object to save
#>
function Save-WatchlistConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$WatchlistConfig
    )
    
    $WatchlistConfig.lastUpdated = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss")
    
    try {
        $WatchlistConfig | ConvertTo-Json -Depth 10 | Set-Content $script:WatchlistPath -Encoding UTF8
    }
    catch {
        Write-Warning "Failed to save watchlist: $_"
    }
}

<#
.SYNOPSIS
    Gets the root path of the application
#>
function Get-AppRootPath {
    return Split-Path (Split-Path $script:ConfigPath -Parent) -Parent
}

<#
.SYNOPSIS
    Gets the absolute path for a relative path from config
.PARAMETER RelativePath
    The relative path from configuration
#>
function Get-AbsolutePath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RelativePath
    )
    
    $rootPath = Get-AppRootPath
    return Join-Path $rootPath $RelativePath.TrimStart("./")
}

# Functions are available via dot-sourcing
