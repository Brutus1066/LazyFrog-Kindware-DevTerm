<#
.SYNOPSIS
    LazyFrog Developer Tools - Main Application Entry Point
.DESCRIPTION
    KINDWARE Rainbow CLI TUI developer utility suite for Windows Terminal.
    Modern colorful interface with GitHub Scanner, Task Runner, System Monitor, and Help.
.AUTHOR
    Kindware.dev
.VERSION
    2.0.0
.NOTES
    Requires PowerShell 7+ for KINDWARE rainbow ANSI color support
    Designed for Windows Terminal with full color support
#>

#Requires -Version 7.0

$ErrorActionPreference = "Stop"

$script:AppRoot = $PSScriptRoot
$script:ConfigRoot = Split-Path $PSScriptRoot -Parent

# Load modern UI library
$script:Libs = @(
    (Join-Path $PSScriptRoot "lib\config.ps1"),
    (Join-Path $PSScriptRoot "lib\ui.ps1"),
    (Join-Path $PSScriptRoot "lib\input.ps1")
)

$script:Tools = @(
    (Join-Path $PSScriptRoot "tools\github.ps1"),
    (Join-Path $PSScriptRoot "tools\tasks.ps1"),
    (Join-Path $PSScriptRoot "tools\system.ps1"),
    (Join-Path $PSScriptRoot "tools\help.ps1")
)

foreach ($lib in $script:Libs) {
    if (Test-Path $lib) {
        . $lib
    }
    else {
        Write-Error "Required library not found: $lib"
        exit 1
    }
}

foreach ($tool in $script:Tools) {
    if (Test-Path $tool) {
        . $tool
    }
    else {
        Write-Error "Required tool not found: $tool"
        exit 1
    }
}

# ============================================================================
# APPLICATION STATE
# ============================================================================
$script:AppState = @{
    CurrentView      = "main"
    PreviousView     = ""
    IsRunning        = $true
    SelectedIndex    = 0
    StatusMessage    = ""
    StatusType       = "info"
    Config           = $null
}

$script:SystemViewState = @{
    LastRefresh = [datetime]::MinValue
    Cache       = $null
}

# ============================================================================
# INITIALIZATION
# ============================================================================
function Initialize-Application {
    [Console]::CursorVisible = $false
    Clear-Host
    
    # Initialize config
    Initialize-AppConfig -RootPath $script:ConfigRoot
    $script:AppState.Config = Get-AppConfig
    
    # Initialize tools
    $tasksPath = Join-Path $script:ConfigRoot "tasks.json"
    Initialize-TaskRunner -TasksPath $tasksPath
    
    $watchlistPath = Join-Path $script:ConfigRoot "watchlist.json"
    Initialize-GitHubScanner -WatchlistPath $watchlistPath
    
    # Set window title
    $Host.UI.RawUI.WindowTitle = "LazyFrog Developer Tools - powered by Kindware.dev"
    
    # Initialize UI
    Initialize-UI
}

function Exit-Application {
    $script:AppState.IsRunning = $false
    [Console]::CursorVisible = $true
    Clear-Host
    
    # KINDWARE styled exit message
    Write-Host ""
    Write-Host "    `e[91m██╗  ██╗`e[93m██╗`e[92m███╗   ██╗`e[96m██████╗ `e[94m██╗    ██╗`e[95m █████╗ `e[91m██████╗ `e[93m███████╗`e[0m"
    Write-Host "    `e[91m██║ ██╔╝`e[93m██║`e[92m████╗  ██║`e[96m██╔══██╗`e[94m██║    ██║`e[95m██╔══██╗`e[91m██╔══██╗`e[93m██╔════╝`e[0m"
    Write-Host "    `e[91m█████╔╝ `e[93m██║`e[92m██╔██╗ ██║`e[96m██║  ██║`e[94m██║ █╗ ██║`e[95m███████║`e[91m██████╔╝`e[93m█████╗  `e[0m"
    Write-Host "    `e[91m██╔═██╗ `e[93m██║`e[92m██║╚██╗██║`e[96m██║  ██║`e[94m██║███╗██║`e[95m██╔══██║`e[91m██╔══██╗`e[93m██╔══╝  `e[0m"
    Write-Host "    `e[91m██║  ██╗`e[93m██║`e[92m██║ ╚████║`e[96m██████╔╝`e[94m╚███╔███╔╝`e[95m██║  ██║`e[91m██║  ██║`e[93m███████╗`e[0m"
    Write-Host "    `e[91m╚═╝  ╚═╝`e[93m╚═╝`e[92m╚═╝  ╚═══╝`e[96m╚═════╝ `e[94m ╚══╝╚══╝ `e[95m╚═╝  ╚═╝`e[91m╚═╝  ╚═╝`e[93m╚══════╝`e[0m"
    Write-Host ""
    Write-Host "  `e[92m✔`e[0m Thanks for using `e[96mLazyFrog`e[0m Developer Tools!"
    Write-Host ""
    Write-Host "  `e[90mGoodbye! Powered by`e[0m `e[95mkindware.dev`e[0m"
    Write-Host ""
}

function Set-Status {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("info", "success", "warning", "error")]
        [string]$Type = "info"
    )
    
    $script:AppState.StatusMessage = $Message
    $script:AppState.StatusType = $Type
}

# ============================================================================
# VIEW SWITCHING
# ============================================================================
function Switch-View {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ViewId
    )
    
    $script:AppState.PreviousView = $script:AppState.CurrentView
    $script:AppState.CurrentView = $ViewId
    $script:AppState.StatusMessage = ""

    if (Get-Command Reset-UI -ErrorAction SilentlyContinue) {
        Reset-UI
    }
    
    if ($ViewId -eq "exit") {
        Exit-Application
    }
}

# ============================================================================
# MAIN MENU INPUT HANDLER
# ============================================================================
function Invoke-MainMenuInput {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.ConsoleKeyInfo]$Key
    )
    
    switch ($Key.Key) {
        "UpArrow" {
            $script:AppState.SelectedIndex--
            if ($script:AppState.SelectedIndex -lt 0) {
                $script:AppState.SelectedIndex = 4  # 5 menu items (0-4)
            }
        }
        "DownArrow" {
            $script:AppState.SelectedIndex++
            if ($script:AppState.SelectedIndex -gt 4) {
                $script:AppState.SelectedIndex = 0
            }
        }
        "Enter" {
            $viewIds = @("github", "tasks", "system", "help", "exit")
            Switch-View -ViewId $viewIds[$script:AppState.SelectedIndex]
        }
        "D1" {
            Switch-View -ViewId "github"
        }
        "D2" {
            Switch-View -ViewId "tasks"
        }
        "D3" {
            Switch-View -ViewId "system"
        }
        "D4" {
            Switch-View -ViewId "help"
        }
        "Q" {
            Switch-View -ViewId "exit"
        }
        "Escape" {
            Switch-View -ViewId "exit"
        }
    }
}

# ============================================================================
# GITHUB SCANNER INPUT HANDLER
# ============================================================================
function Invoke-GitHubInput {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.ConsoleKeyInfo]$Key
    )
    
    $state = Get-GitHubState
    
    switch ($Key.Key) {
        "UpArrow" {
            Set-GitHubSelectedIndex -Index ($state.SelectedIndex - 1)
        }
        "DownArrow" {
            Set-GitHubSelectedIndex -Index ($state.SelectedIndex + 1)
        }
        "S" {
            $query = Read-LineInput -Prompt "Search GitHub:"
                if ($null -eq $query) {
                    Set-Status -Message "Search cancelled" -Type "warning"
                }
                elseif (-not [string]::IsNullOrEmpty($query)) {
                Set-Status -Message "Searching..." -Type "info"
                try {
                    $results = Search-GitHubRepositories -SearchTerm $query
                    Set-Status -Message "Found $($results.Count) repositories" -Type "success"
                }
                catch {
                    Set-Status -Message "Search failed: $_" -Type "error"
                }
            }
        }
        "W" {
            $repo = Get-SelectedRepository
            if ($null -ne $repo) {
                try {
                    $watchlistPath = Join-Path $script:ConfigRoot "watchlist.json"
                    Add-ToWatchlist -Repository $repo -WatchlistPath $watchlistPath
                    Set-Status -Message "Added to watchlist: $($repo.name)" -Type "success"
                }
                catch {
                    Set-Status -Message "Failed to add to watchlist" -Type "error"
                }
            }
        }
        "J" {
            $state = Get-GitHubState
            if ($state.LastResults.Count -gt 0) {
                try {
                    $outputPath = Join-Path $script:ConfigRoot "results"
                    $filepath = Save-ResultsToJson -Results $state.LastResults -OutputPath $outputPath
                    Set-Status -Message "Saved to $filepath" -Type "success"
                }
                catch {
                    Set-Status -Message "Failed to save: $_" -Type "error"
                }
            }
        }
        "M" {
            $state = Get-GitHubState
            if ($state.LastResults.Count -gt 0) {
                try {
                    $outputPath = Join-Path $script:ConfigRoot "results"
                    $filepath = Save-ResultsToMarkdown -Results $state.LastResults -OutputPath $outputPath
                    Set-Status -Message "Saved to $filepath" -Type "success"
                }
                catch {
                    Set-Status -Message "Failed to save: $_" -Type "error"
                }
            }
        }
        "Escape" {
            Switch-View -ViewId "main"
        }
    }
}

# ============================================================================
# TASK RUNNER INPUT HANDLER
# ============================================================================
function Invoke-TasksInput {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.ConsoleKeyInfo]$Key
    )
    
    $state = Get-TaskState
    
    switch ($Key.Key) {
        "UpArrow" {
            Set-TaskSelectedIndex -Index ($state.SelectedIndex - 1)
        }
        "DownArrow" {
            Set-TaskSelectedIndex -Index ($state.SelectedIndex + 1)
        }
        "Enter" {
            $task = Get-SelectedTask
            if ($null -ne $task) {
                try {
                    Set-Status -Message "Executing: $($task.name)..." -Type "info"
                    $result = Invoke-Task -TaskId $task.id
                    
                    # Show output
                    Clear-ScreenBuffer
                    Write-Host ""
                    Write-Host "  " -NoNewline
                    Write-Host "[OUTPUT]" -ForegroundColor Cyan -NoNewline
                    Write-Host " Task: $($task.name)" -ForegroundColor White
                    Write-Host "  " -NoNewline
                    Write-Host ("-" * 60) -ForegroundColor DarkCyan
                    Write-Host ""
                    
                    if ($result.output) {
                        foreach ($line in $result.output -split "`n") {
                            Write-Host "  $line" -ForegroundColor Gray
                        }
                    }
                    
                    Write-Host ""
                    Write-Host "  " -NoNewline
                    Write-Host ("-" * 60) -ForegroundColor DarkCyan
                    
                    if ($result.success) {
                        Write-Host "  " -NoNewline
                        Write-Host "[OK]" -ForegroundColor Green -NoNewline
                        Write-Host " Completed successfully" -ForegroundColor White
                    }
                    else {
                        Write-Host "  " -NoNewline
                        Write-Host "[ERROR]" -ForegroundColor Red -NoNewline
                        Write-Host " Exit code: $($result.exitCode)" -ForegroundColor White
                    }
                    
                    Write-Host ""
                    Write-Host "  Press any key to continue..." -ForegroundColor DarkGray
                    $null = [Console]::ReadKey($true)
                    
                    $tasksPath = Join-Path $script:ConfigRoot "tasks.json"
                    Save-Tasks -TasksPath $tasksPath
                    
                    Set-Status -Message "Task completed" -Type $(if ($result.success) { "success" } else { "error" })
                }
                catch {
                    Set-Status -Message "Task execution failed: $_" -Type "error"
                }
            }
        }
        "X" {
            Invoke-TasksInput -Key ([System.ConsoleKeyInfo]::new([char]13, [System.ConsoleKey]::Enter, $false, $false, $false))
        }
        "A" {
            $name = Read-LineInput -Prompt "Task name:"
                if ($null -eq $name) {
                    Set-Status -Message "Add task cancelled" -Type "warning"
                }
                elseif (-not [string]::IsNullOrEmpty($name)) {
                $command = Read-LineInput -Prompt "Command:"
                    if ($null -eq $command) {
                        Set-Status -Message "Add task cancelled" -Type "warning"
                    }
                    elseif (-not [string]::IsNullOrEmpty($command)) {
                    $description = Read-LineInput -Prompt "Description (optional):"
                        if ($null -eq $description) { $description = "" }
                        $category = Read-LineInput -Prompt "Category (optional):"
                        if ($null -eq $category) { $category = "" }
                    if ([string]::IsNullOrEmpty($category)) { $category = "Custom" }
                    
                    try {
                        $tasksPath = Join-Path $script:ConfigRoot "tasks.json"
                        Add-Task -Name $name -Command $command -Description $description -Category $category -TasksPath $tasksPath
                        Set-Status -Message "Task added: $name" -Type "success"
                    }
                    catch {
                        Set-Status -Message "Failed to add task: $_" -Type "error"
                    }
                }
            }
        }
        "D" {
            $task = Get-SelectedTask
            if ($null -ne $task) {
                $confirm = Read-LineInput -Prompt "Delete '$($task.name)'? (y/n)"
                    if ($null -eq $confirm) {
                        Set-Status -Message "Delete cancelled" -Type "warning"
                    }
                    elseif ($confirm -eq "y" -or $confirm -eq "Y") {
                    try {
                        $tasksPath = Join-Path $script:ConfigRoot "tasks.json"
                        Remove-Task -TaskId $task.id -TasksPath $tasksPath
                        Set-Status -Message "Task deleted" -Type "success"
                    }
                    catch {
                        Set-Status -Message "Failed to delete task" -Type "error"
                    }
                }
            }
        }
        "H" {
            $script:AppState.CurrentView = "taskhistory"
        }
        "Escape" {
            Switch-View -ViewId "main"
        }
    }
}

# ============================================================================
# TASK HISTORY INPUT HANDLER
# ============================================================================
function Invoke-TaskHistoryInput {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.ConsoleKeyInfo]$Key
    )
    
    switch ($Key.Key) {
        "S" {
            try {
                $outputPath = Join-Path $script:ConfigRoot "history"
                $filepath = Save-TaskHistory -OutputPath $outputPath
                Set-Status -Message "History saved to $filepath" -Type "success"
            }
            catch {
                Set-Status -Message "Failed to save history" -Type "error"
            }
        }
        "C" {
            $confirm = Read-LineInput -Prompt "Clear all history? (y/n)"
                if ($null -eq $confirm) {
                    Set-Status -Message "Clear cancelled" -Type "warning"
                }
                elseif ($confirm -eq "y" -or $confirm -eq "Y") {
                try {
                    $tasksPath = Join-Path $script:ConfigRoot "tasks.json"
                    Clear-TaskHistory -TasksPath $tasksPath
                    Set-Status -Message "History cleared" -Type "success"
                }
                catch {
                    Set-Status -Message "Failed to clear history" -Type "error"
                }
            }
        }
        "Escape" {
            Switch-View -ViewId "tasks"
        }
    }
}

# ============================================================================
# SYSTEM MONITOR INPUT HANDLER
# ============================================================================
function Invoke-SystemInput {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.ConsoleKeyInfo]$Key
    )
    
    switch ($Key.Key) {
        "R" {
            Update-SystemInfo
            Set-Status -Message "Refreshed" -Type "success"
        }
        "S" {
            try {
                $outputPath = Join-Path $script:ConfigRoot "results"
                $filepath = Save-SystemSnapshot -OutputPath $outputPath
                Set-Status -Message "Snapshot saved to $filepath" -Type "success"
            }
            catch {
                Set-Status -Message "Failed to save snapshot" -Type "error"
            }
        }
        "I" {
            $lines = Format-DetailedSystemInfo
            Clear-ScreenBuffer
            
            Write-Host ""
            Write-Host "  " -NoNewline
            Write-Host "[DETAIL]" -ForegroundColor Magenta -NoNewline
            Write-Host " Detailed System Information" -ForegroundColor White
            Write-Host "  " -NoNewline
            Write-Host ("-" * 60) -ForegroundColor DarkCyan
            Write-Host ""
            
            foreach ($line in $lines) {
                Write-Host "  $line" -ForegroundColor Gray
            }
            
            Write-Host ""
            Write-Host "  Press any key to continue..." -ForegroundColor DarkGray
            $null = [Console]::ReadKey($true)
        }
        "Escape" {
            Switch-View -ViewId "main"
        }
    }
}

# ============================================================================
# HELP INPUT HANDLER
# ============================================================================
function Invoke-HelpInput {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.ConsoleKeyInfo]$Key
    )
    
    $state = Get-HelpState
    
    switch ($Key.Key) {
        "UpArrow" {
            Set-HelpSelectedIndex -Index ($state.SelectedIndex - 1)
        }
        "DownArrow" {
            Set-HelpSelectedIndex -Index ($state.SelectedIndex + 1)
        }
        "Enter" {
            $item = Get-SelectedHelpItem
            Set-HelpSection -SectionId $item.id
            $script:AppState.CurrentView = "helpcontent"
        }
        "D1" {
            Set-HelpSection -SectionId "main"
            $script:AppState.CurrentView = "helpcontent"
        }
        "D2" {
            Set-HelpSection -SectionId "github"
            $script:AppState.CurrentView = "helpcontent"
        }
        "D3" {
            Set-HelpSection -SectionId "tasks"
            $script:AppState.CurrentView = "helpcontent"
        }
        "D4" {
            Set-HelpSection -SectionId "system"
            $script:AppState.CurrentView = "helpcontent"
        }
        "D5" {
            Set-HelpSection -SectionId "shortcuts"
            $script:AppState.CurrentView = "helpcontent"
        }
        "D6" {
            Set-HelpSection -SectionId "about"
            $script:AppState.CurrentView = "helpcontent"
        }
        "Escape" {
            Switch-View -ViewId "main"
        }
    }
}

function Invoke-HelpContentInput {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.ConsoleKeyInfo]$Key
    )
    
    switch ($Key.Key) {
        "Escape" {
            $script:AppState.CurrentView = "help"
        }
    }
}

# ============================================================================
# VIEW RENDERERS
# ============================================================================
function Show-MainMenuPanel {
    Show-MainMenu -SelectedIndex $script:AppState.SelectedIndex `
                  -StatusMessage $script:AppState.StatusMessage `
                  -StatusType $script:AppState.StatusType
}

function Show-GitHubPanel {
    $state = Get-GitHubState
    Show-GitHubView -Results $state.LastResults `
                    -SelectedIndex $state.SelectedIndex `
                    -LastSearch $state.LastSearchTerm `
                    -StatusMessage $script:AppState.StatusMessage `
                    -StatusType $script:AppState.StatusType
}

function Show-TasksPanel {
    $state = Get-TaskState
    Show-TasksView -Tasks $state.Tasks `
                   -SelectedIndex $state.SelectedIndex `
                   -StatusMessage $script:AppState.StatusMessage `
                   -StatusType $script:AppState.StatusType
}

function Show-TaskHistoryPanel {
    $lines = Format-TaskHistory
    
    Clear-ScreenBuffer
    Write-Host ""
    Write-Host "  " -NoNewline
    Write-Host "=" -ForegroundColor DarkCyan -NoNewline
    Write-Host ("=" * 78) -ForegroundColor DarkCyan
    Write-Host "  " -NoNewline
    Write-Host "[HIST]" -ForegroundColor Magenta -NoNewline
    Write-Host " Task History" -ForegroundColor Cyan
    Write-Host "  " -NoNewline
    Write-Host ("=" * 78) -ForegroundColor DarkCyan
    Write-Host ""
    
    foreach ($line in $lines) {
        Write-Host "  $line" -ForegroundColor Gray
    }
    
    Write-Host ""
    Write-Host "  " -NoNewline
    Write-Host ("-" * 78) -ForegroundColor DarkCyan
    Write-Host "  " -NoNewline
    Write-Host "[S]" -ForegroundColor Yellow -NoNewline
    Write-Host " Save  " -ForegroundColor DarkGray -NoNewline
    Write-Host "[C]" -ForegroundColor Yellow -NoNewline
    Write-Host " Clear  " -ForegroundColor DarkGray -NoNewline
    Write-Host "[Esc]" -ForegroundColor Yellow -NoNewline
    Write-Host " Back" -ForegroundColor DarkGray
}

function Show-SystemPanel {
    $systemData = if ($null -ne $script:SystemViewState.Cache) {
        $script:SystemViewState.Cache
    }
    else {
        Get-SystemData
    }
    Show-SystemView -SystemInfo $systemData `
                    -StatusMessage $script:AppState.StatusMessage `
                    -StatusType $script:AppState.StatusType
}

function Show-HelpMenuPanel {
    $state = Get-HelpState
    if (Get-Command Reset-UI -ErrorAction SilentlyContinue) {
        Reset-UI
    }
    Show-HelpView -SelectedIndex $state.SelectedIndex
}

function Get-HelpTokenColor {
    param(
        [string]$Token
    )

    $t = $Token.Trim('[', ']')
    switch -Regex ($t) {
        '^(HELP|DOC|INFO)$' { return $script:Theme.Secondary }
        '^(TIP)$' { return $script:Theme.Accent }
        '^(NOTE)$' { return $script:Theme.TextHighlight }
        '^(WARN|ERROR|X)$' { return $script:Theme.Error }
        default { return $script:Theme.MenuKey }
    }
}

function Write-HelpBoxLine {
    param(
        [string]$Text,
        [int]$TableWidth
    )

    $display = Get-TrimmedText -Text $Text -MaxLength ($TableWidth - 2)
    $content = " " + $display
    $padCount = [Math]::Max(0, ($TableWidth + 1) - $content.Length)
    $trim = $display.Trim()

    Write-Host "  " -NoNewline
    Write-Host "|" -ForegroundColor $script:Theme.Border -NoNewline
    Write-Host " " -NoNewline

    if ($trim -match '^[=\-]{4,}$') {
        Write-Host $display -ForegroundColor $script:Theme.Border -NoNewline
    }
    elseif ($trim -match '^[A-Z][A-Z ]+:$') {
        Write-Host $display -ForegroundColor $script:Theme.HeaderAccent -NoNewline
    }
    else {
        $parts = [regex]::Split($display, '(\[[^\]]+\])')
        foreach ($part in $parts) {
            if ($part -match '^\[[^\]]+\]$') {
                $color = Get-HelpTokenColor -Token $part
                Write-Host $part -ForegroundColor $color -NoNewline
            }
            else {
                Write-Host $part -ForegroundColor $script:Theme.Text -NoNewline
            }
        }
    }

    if ($padCount -gt 0) {
        Write-Host (" " * $padCount) -NoNewline
    }
    Write-Host "|" -ForegroundColor $script:Theme.Border
}

function Show-HelpContentPanel {
    $lines = Format-HelpContent

    if (Get-Command Reset-UI -ErrorAction SilentlyContinue) {
        Reset-UI
    }
    Clear-ScreenBuffer

    $width = $script:UIState.Width
    $tableWidth = [Math]::Min(100, $width - 4)

    Write-SectionHeader -Icon "[DOC]" -Title "Help & Documentation"

    Write-Host "  " -NoNewline
    Write-Host "+" -ForegroundColor $script:Theme.Border -NoNewline
    Write-Host ("-" * $tableWidth) -ForegroundColor $script:Theme.Border -NoNewline
    Write-Host "+" -ForegroundColor $script:Theme.Border

    $maxLines = [Math]::Max(6, $script:UIState.Height - 12)
    $visibleLines = $lines | Select-Object -First $maxLines
    foreach ($line in $visibleLines) {
        Write-HelpBoxLine -Text $line -TableWidth $tableWidth
    }

    Write-Host "  " -NoNewline
    Write-Host "+" -ForegroundColor $script:Theme.Border -NoNewline
    Write-Host ("-" * $tableWidth) -ForegroundColor $script:Theme.Border -NoNewline
    Write-Host "+" -ForegroundColor $script:Theme.Border

    Write-Host ""
    Write-Rule -Width $width -Char "-" -Color $script:Theme.Border
    Write-Host "  " -NoNewline
    Write-Host "[Esc]" -ForegroundColor $script:Theme.MenuKey -NoNewline
    Write-Host " Back" -ForegroundColor $script:Theme.TextDim
}

function Show-WatchlistPanel {
    $lines = Format-Watchlist
    
    Clear-ScreenBuffer
    Write-Host ""
    Write-Host "  " -NoNewline
    Write-Host ("=" * 78) -ForegroundColor DarkCyan
    Write-Host "  " -NoNewline
    Write-Host "[WATCH]" -ForegroundColor Magenta -NoNewline
    Write-Host " Repository Watchlist" -ForegroundColor Cyan
    Write-Host "  " -NoNewline
    Write-Host ("=" * 78) -ForegroundColor DarkCyan
    Write-Host ""
    
    foreach ($line in $lines) {
        Write-Host "  $line" -ForegroundColor Gray
    }
    
    Write-Host ""
    Write-Host "  " -NoNewline
    Write-Host ("-" * 78) -ForegroundColor DarkCyan
    Write-Host "  " -NoNewline
    Write-Host "[R]" -ForegroundColor Yellow -NoNewline
    Write-Host " Remove  " -ForegroundColor DarkGray -NoNewline
    Write-Host "[Esc]" -ForegroundColor Yellow -NoNewline
    Write-Host " Back" -ForegroundColor DarkGray
}

function Invoke-WatchlistInput {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.ConsoleKeyInfo]$Key
    )
    
    switch ($Key.Key) {
        "Escape" {
            Switch-View -ViewId "github"
        }
        "R" {
            $repo = Get-SelectedRepository
            if ($null -ne $repo) {
                try {
                    $watchlistPath = Join-Path $script:ConfigRoot "watchlist.json"
                    Remove-FromWatchlist -RepositoryId $repo.id -WatchlistPath $watchlistPath
                    Set-Status -Message "Removed from watchlist" -Type "success"
                }
                catch {
                    Set-Status -Message "Failed to remove" -Type "error"
                }
            }
        }
    }
}

# ============================================================================
# MAIN RENDER LOOP
# ============================================================================
function Show-CurrentView {
    switch ($script:AppState.CurrentView) {
        "main"        { Show-MainMenuPanel }
        "github"      { Show-GitHubPanel }
        "watchlist"   { Show-WatchlistPanel }
        "tasks"       { Show-TasksPanel }
        "taskhistory" { Show-TaskHistoryPanel }
        "system"      { Show-SystemPanel }
        "help"        { Show-HelpMenuPanel }
        "helpcontent" { Show-HelpContentPanel }
    }
}

function Invoke-InputHandler {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.ConsoleKeyInfo]$Key
    )
    
    switch ($script:AppState.CurrentView) {
        "main"        { Invoke-MainMenuInput -Key $Key }
        "github"      { Invoke-GitHubInput -Key $Key }
        "watchlist"   { Invoke-WatchlistInput -Key $Key }
        "tasks"       { Invoke-TasksInput -Key $Key }
        "taskhistory" { Invoke-TaskHistoryInput -Key $Key }
        "system"      { Invoke-SystemInput -Key $Key }
        "help"        { Invoke-HelpInput -Key $Key }
        "helpcontent" { Invoke-HelpContentInput -Key $Key }
    }
}

# ============================================================================
# MAIN APPLICATION
# ============================================================================
function Start-Application {
    Initialize-Application
    
    $lastView = ""
    $needsRedraw = $true
    $systemRefreshMs = 1000
    $minFrameMs = 60
    $lastDraw = [datetime]::MinValue
    try {
        $cfgRefresh = Get-ConfigValue -Section "system" -Key "refreshInterval"
        if ($cfgRefresh -is [int] -and $cfgRefresh -gt 0) {
            $systemRefreshMs = $cfgRefresh
        }
    }
    catch {}
    
    while ($script:AppState.IsRunning) {
        if ($script:AppState.CurrentView -eq "system") {
            $elapsed = (Get-Date) - $script:SystemViewState.LastRefresh
            if ($null -eq $script:SystemViewState.Cache -or $elapsed.TotalMilliseconds -ge $systemRefreshMs) {
                $script:SystemViewState.Cache = Get-SystemData
                $script:SystemViewState.LastRefresh = Get-Date
                $needsRedraw = $true
            }
        }

        # Only redraw when needed
        if ($needsRedraw -or $lastView -ne $script:AppState.CurrentView) {
            $elapsed = (Get-Date) - $lastDraw
            if ($elapsed.TotalMilliseconds -lt $minFrameMs) {
                Start-Sleep -Milliseconds ([Math]::Max(0, $minFrameMs - [int]$elapsed.TotalMilliseconds))
            }
            Show-CurrentView
            $lastView = $script:AppState.CurrentView
            $needsRedraw = $false
            $lastDraw = Get-Date
        }
        
        if ([Console]::KeyAvailable) {
            $key = [Console]::ReadKey($true)
            Invoke-InputHandler -Key $key
            $needsRedraw = $true
        }
        
        # Small sleep to reduce CPU usage
        Start-Sleep -Milliseconds 50
    }
}

# ============================================================================
# ENTRY POINT
# ============================================================================
try {
    $logRoot = Join-Path $env:LOCALAPPDATA "LazyFrog-DevTerm\logs"
    if (-not (Test-Path $logRoot)) {
        New-Item -ItemType Directory -Path $logRoot -Force | Out-Null
    }
    $logFile = Join-Path $logRoot "app-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
    Add-Content -Path $logFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] App start"

    Start-Application
}
catch {
    [Console]::CursorVisible = $true
    if ($null -ne $logFile) {
        $err = $_
        $details = @()
        $details += "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] App error: $err"
        if ($err.InvocationInfo) {
            $details += "Script: $($err.InvocationInfo.ScriptName)"
            $details += "Line: $($err.InvocationInfo.ScriptLineNumber)"
            $details += "Position: $($err.InvocationInfo.PositionMessage)"
        }
        Add-Content -Path $logFile -Value ($details -join "`n")
    }
    Write-Host ""
    Write-Host "  " -NoNewline
    Write-Host "[ERROR]" -ForegroundColor Red -NoNewline
    Write-Host " Application error: $_" -ForegroundColor White
    Write-Host ""
    if ($null -ne $logFile) {
        Write-Host "  Log: $logFile" -ForegroundColor Yellow
        Write-Host "  Press Enter to close..." -ForegroundColor Yellow
        Read-Host | Out-Null
    }
    exit 1
}
finally {
    [Console]::CursorVisible = $true
}
