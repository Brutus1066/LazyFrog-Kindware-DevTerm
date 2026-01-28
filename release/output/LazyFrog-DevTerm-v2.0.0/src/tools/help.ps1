<#
.SYNOPSIS
    Help Documentation Tool for LazyFrog Developer Tools
.DESCRIPTION
    Provides comprehensive help documentation, keyboard shortcuts,
    and usage instructions for all tool modules.
.AUTHOR
    Kindware.dev
.VERSION
    1.0.0
#>

$script:HelpState = @{
    CurrentSection   = "main"
    SelectedIndex    = 0
    Sections         = @("main", "github", "tasks", "system", "shortcuts", "about")
}

<#
.SYNOPSIS
    Gets the help menu items
#>
function Get-HelpMenu {
    return @(
        @{ id = "main"; name = "Welcome & Overview"; icon = "[HELP]" }
        @{ id = "github"; name = "GitHub Scanner Help"; icon = "[GIT]" }
        @{ id = "tasks"; name = "Task Runner Help"; icon = "[TASK]" }
        @{ id = "system"; name = "System Monitor Help"; icon = "[SYS]" }
        @{ id = "shortcuts"; name = "Keyboard Shortcuts"; icon = "[KEY]" }
        @{ id = "about"; name = "About LazyFrog"; icon = "[INFO]" }
    )
}

<#
.SYNOPSIS
    Sets the current help section
#>
function Set-HelpSection {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SectionId
    )
    
    if ($script:HelpState.Sections -contains $SectionId) {
        $script:HelpState.CurrentSection = $SectionId
    }
}

<#
.SYNOPSIS
    Gets the current help section
#>
function Get-HelpSection {
    return $script:HelpState.CurrentSection
}

<#
.SYNOPSIS
    Formats the main help content
#>
function Format-MainHelp {
    $lines = @()
    $lines += ""
    $lines += "  [HELP] LazyFrog DevTerm - Welcome"
    $lines += "  ================================================"
    $lines += ""
    $lines += "  CORE MODULES:"
    $lines += "  [1] GitHub Scanner  - Search repos and save results"
    $lines += "  [2] Task Runner     - Run tasks from tasks.json"
    $lines += "  [3] System Monitor  - Live CPU/RAM/Disk/Network"
    $lines += ""
    $lines += "  QUICK START:"
    $lines += "  • Use [Up/Down] and [Enter] to navigate"
    $lines += "  • Press [1-4] to jump to a module"
    $lines += "  • Press [H] for Help and [Esc] to go back"
    $lines += "  • Press [Q] to exit"
    $lines += ""
    $lines += "  TIP: Save GitHub results with [J] JSON or [M] Markdown"
    $lines += ""
    
    return $lines
}

<#
.SYNOPSIS
    Formats the GitHub Scanner help content
#>
function Format-GitHubHelp {
    $lines = @()
    $lines += ""
    $lines += "  [HELP] GitHub Scanner"
    $lines += "  ================================================"
    $lines += ""
    $lines += "  Search public repositories using the GitHub API."
    $lines += ""
    $lines += "  KEY ACTIONS:"
    $lines += "  [S] Search    [L] Language filter"
    $lines += "  [Enter] Open  [W] Watchlist  [V] View watchlist"
    $lines += ""
    $lines += "  SAVING RESULTS:"
    $lines += "  1) Run a search with [S]"
    $lines += "  2) Press [J] for JSON or [M] for Markdown"
    $lines += "  3) Files save to: results\\github-search-YYYY-MM-DD-HHMMSS.(json|md)"
    $lines += ""
    $lines += "  SEARCH TIPS:"
    $lines += "  • Use quotes for exact phrases"
    $lines += "  • Combine keywords + language for better results"
    $lines += "  • Results are sorted by relevance"
    $lines += ""
    
    return $lines
}

<#
.SYNOPSIS
    Formats the Task Runner help content
#>
function Format-TasksHelp {
    $lines = @()
    $lines += ""
    $lines += "  [HELP] Task Runner"
    $lines += "  ================================================"
    $lines += ""
    $lines += "  Run custom commands defined in tasks.json."
    $lines += ""
    $lines += "  CONFIGURATION:"
    $lines += "  • File: tasks.json (repo root)"
    $lines += "  • Fields: id, name, command, description, category"
    $lines += ""
    $lines += "  COMMANDS:"
    $lines += "  [Enter/X] Run  [A] Add  [E] Edit  [D] Delete"
    $lines += "  [H] History   [Up/Down] Navigate  [Esc] Back"
    $lines += ""
    $lines += "  NOTE: Git tasks must run inside a Git repo."
    $lines += "  If you see exit code 128, run from a repo folder."
    $lines += ""
    
    return $lines
}

<#
.SYNOPSIS
    Formats the System Monitor help content
#>
function Format-SystemHelp {
    $lines = @()
    $lines += ""
    $lines += "  [HELP] System Monitor"
    $lines += "  ================================================"
    $lines += ""
    $lines += "  Live system metrics and snapshot tools."
    $lines += ""
    $lines += "  METRICS:"
    $lines += "  [CPU] Usage percentage"
    $lines += "  [RAM] Used vs total memory"
    $lines += "  [DISK] Space per drive"
    $lines += "  [NET] Active adapters / IPs"
    $lines += "  [PROC] Top CPU processes"
    $lines += ""
    $lines += "  COMMANDS:"
    $lines += "  [R] Refresh  [S] Save snapshot  [I] Details  [Esc] Back"
    $lines += ""
    
    return $lines
}

<#
.SYNOPSIS
    Formats the keyboard shortcuts help content
#>
function Format-ShortcutsHelp {
    $lines = @()
    $lines += ""
    $lines += "  [HELP] Keyboard Shortcuts"
    $lines += "  ================================================"
    $lines += ""
    $lines += "  GLOBAL:"
    $lines += "  [1-4] Quick select  [Up/Down] Move  [Enter] Select"
    $lines += "  [Esc] Back/Cancel   [Q] Quit         [H] Help"
    $lines += ""
    $lines += "  GITHUB SCANNER:"
    $lines += "  [S] Search  [L] Language  [W] Watchlist  [V] View"
    $lines += "  [J] Save JSON  [M] Save Markdown"
    $lines += ""
    $lines += "  TASK RUNNER:"
    $lines += "  [Enter/X] Run  [A] Add  [E] Edit  [D] Delete  [H] History"
    $lines += ""
    $lines += "  SYSTEM MONITOR:"
    $lines += "  [R] Refresh  [S] Save  [I] Details"
    $lines += ""
    
    return $lines
}

<#
.SYNOPSIS
    Formats the About section
#>
function Format-AboutHelp {
    $lines = @()
    $lines += ""
    $lines += "  [INFO] About LazyFrog DevTerm"
    $lines += "  ================================================"
    $lines += ""
    $lines += "  LazyFrog DevTerm"
    $lines += ""
    $lines += "  Version: 1.1.1"
    $lines += "  Author: Kindware.dev"
    $lines += "  License: MIT"
    $lines += ""
    $lines += "  LazyFrog DevTerm is a modern, keyboard-first"
    $lines += "  utility suite for Windows Terminal."
    $lines += "  It keeps common developer tools in one place."
    $lines += ""
    $lines += "  Built with PowerShell 7+ for Windows Terminal."
    $lines += ""
    $lines += "  LINKS:"
    $lines += "  GitHub: https://github.com/Brutus1066"
    $lines += "  Website: https://kindware.dev"
    $lines += ""
    $lines += "  Thank you for using LazyFrog DevTerm!"
    $lines += ""
    
    return $lines
}

<#
.SYNOPSIS
    Formats the help menu for TUI display
#>
function Format-HelpMenu {
    [CmdletBinding()]
    param()
    
    $lines = @()
    $lines += ""
    $lines += "  [HELP] LazyFrog Developer Tools - Help"
    $lines += "  ====================================================="
    $lines += ""
    $lines += "  Select a topic to view help:"
    $lines += ""
    
    $menu = Get-HelpMenu
    for ($i = 0; $i -lt $menu.Count; $i++) {
        $prefix = if ($i -eq $script:HelpState.SelectedIndex) { " > " } else { "   " }
        $num = "[$($i + 1)]".PadRight(4)
        $lines += "$prefix$num $($menu[$i].icon) $($menu[$i].name)"
    }
    
    $lines += ""
    $lines += "  -----------------------------------------------------"
    $lines += "  [Up/Down] Navigate  [Enter] Select  [Esc] Back"
    
    return $lines
}

<#
.SYNOPSIS
    Formats help content based on current section
#>
function Format-HelpContent {
    [CmdletBinding()]
    param()
    
    switch ($script:HelpState.CurrentSection) {
        "main" { return Format-MainHelp }
        "github" { return Format-GitHubHelp }
        "tasks" { return Format-TasksHelp }
        "system" { return Format-SystemHelp }
        "shortcuts" { return Format-ShortcutsHelp }
        "about" { return Format-AboutHelp }
        default { return Format-MainHelp }
    }
}

<#
.SYNOPSIS
    Sets the selected menu index
#>
function Set-HelpSelectedIndex {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [int]$Index
    )
    
    $maxIndex = (Get-HelpMenu).Count - 1
    $script:HelpState.SelectedIndex = [Math]::Max(0, [Math]::Min($Index, $maxIndex))
}

<#
.SYNOPSIS
    Gets the selected help menu item
#>
function Get-SelectedHelpItem {
    $menu = Get-HelpMenu
    return $menu[$script:HelpState.SelectedIndex]
}

<#
.SYNOPSIS
    Gets the help state
#>
function Get-HelpState {
    return $script:HelpState
}

<#
.SYNOPSIS
    Displays quick help for a specific tool
#>
function Get-QuickHelp {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("github", "tasks", "system")]
        [string]$Tool
    )
    
    switch ($Tool) {
        "github" {
            return @(
                "[S] Search [L] Language [W] Watchlist [J] JSON [M] MD [Esc] Back"
            )
        }
        "tasks" {
            return @(
                "[Enter/X] Run [A] Add [E] Edit [D] Delete [H] History [Esc] Back"
            )
        }
        "system" {
            return @(
                "[R] Refresh [S] Save Snapshot [I] Info [Esc] Back"
            )
        }
    }
}

# Functions are available via dot-sourcing
