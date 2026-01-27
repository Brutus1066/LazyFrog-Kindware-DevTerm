<#
.SYNOPSIS
    Modern UI Rendering Library for LazyFrog Developer Tools
.DESCRIPTION
    Professional TUI rendering with colors, gradients, and modern styling
.AUTHOR
    Kindware.dev
.VERSION
    2.0.0
#>

# ============================================================================
# COLOR THEME - Cyberpunk Frog (Cyan/Magenta/Green gradient)
# ============================================================================
$script:Theme = @{
    # Primary colors
    Primary       = "Cyan"
    Secondary     = "Magenta"
    Accent        = "Green"
    
    # UI colors
    Border        = "DarkCyan"
    BorderLight   = "Cyan"
    Header        = "Cyan"
    HeaderAccent  = "Magenta"
    
    # Text colors
    Text          = "White"
    TextDim       = "Gray"
    TextHighlight = "Yellow"
    
    # Status colors
    Success       = "Green"
    Warning       = "Yellow"
    Error         = "Red"
    Info          = "Cyan"
    
    # Menu colors
    MenuSelected  = "Black"
    MenuSelectedBg = "Cyan"
    MenuItem      = "White"
    MenuKey       = "Yellow"
}

# ============================================================================
# ASCII ART LOGO - Geometric Frog
# ============================================================================
$script:Logo = @"

      [38;5;87m    ___[38;5;123m___[0m
      [38;5;87m   /[38;5;123m o [38;5;87m\[38;5;123m/[38;5;87m o[38;5;123m \[0m
      [38;5;87m  |[38;5;201m__[38;5;123m\_/[38;5;201m__[38;5;87m|[0m
      [38;5;123m   /[38;5;201m\   /[38;5;123m\[0m
      [38;5;201m  /[38;5;123m  \_/  [38;5;201m\[0m
      [38;5;201m /_[38;5;46m_[38;5;47m_[38;5;48m_[38;5;49m_[38;5;50m_[38;5;51m_[38;5;201m_\[0m

"@

# Simple ASCII logo fallback
$script:LogoSimple = @"
       _____
      / o  o \
     |___/\___|
       /\   /\
      /  \_/  \
     /_________\
"@

# ============================================================================
# UI STATE
# ============================================================================
$script:UIState = @{
    Width         = 100
    Height        = 30
    MenuWidth     = 22
    CurrentTool   = 1
    ContentBuffer = @()
    UseColors     = $true
}

# ============================================================================
# INITIALIZATION
# ============================================================================
function Initialize-UI {
    [CmdletBinding()]
    param()
    
    $script:UIState.Width = [Math]::Max($Host.UI.RawUI.WindowSize.Width, 100)
    $script:UIState.Height = [Math]::Max($Host.UI.RawUI.WindowSize.Height, 30)
    
    # Check if colors are supported
    $script:UIState.UseColors = $Host.UI.SupportsVirtualTerminal -or ($env:TERM -like "*color*")
    
    Clear-Host
    [Console]::CursorVisible = $false
    
    return $script:UIState
}

function Close-UI {
    [Console]::CursorVisible = $true
    Clear-Host
}

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================
function Write-Colored {
    param(
        [string]$Text,
        [string]$ForegroundColor = "White",
        [switch]$NoNewline
    )
    
    if ($NoNewline) {
        Write-Host $Text -ForegroundColor $ForegroundColor -NoNewline
    } else {
        Write-Host $Text -ForegroundColor $ForegroundColor
    }
}

function Write-ColoredLine {
    param(
        [array]$Segments  # Array of @{Text=""; Color=""}
    )
    
    foreach ($seg in $Segments) {
        Write-Host $seg.Text -ForegroundColor $seg.Color -NoNewline
    }
    Write-Host ""
}

function Get-CenteredText {
    param(
        [string]$Text,
        [int]$Width
    )
    
    $padding = [Math]::Max(0, ($Width - $Text.Length) / 2)
    return (" " * [Math]::Floor($padding)) + $Text
}

function Get-HorizontalLine {
    param(
        [int]$Width,
        [string]$Char = "-"
    )
    return $Char * $Width
}

# ============================================================================
# SCREEN BUFFER
# ============================================================================
function Clear-ScreenBuffer {
    Clear-Host
    [Console]::SetCursorPosition(0, 0)
}

# ============================================================================
# MODERN HEADER WITH BRANDING
# ============================================================================
function Show-Header {
    $width = $script:UIState.Width
    
    # Top border with gradient effect
    Write-Host ""
    Write-Colored -Text ("  " + ("=" * ($width - 4))) -ForegroundColor $script:Theme.Border
    
    # Brand line
    $brand = "  LAZYFROG Developer Tools"
    $powered = "powered by Kindware.dev  "
    $spacer = " " * ($width - $brand.Length - $powered.Length - 2)
    
    Write-Host "  " -NoNewline
    Write-Colored -Text "LAZYFROG" -ForegroundColor $script:Theme.Primary -NoNewline
    Write-Colored -Text " Developer Tools" -ForegroundColor $script:Theme.Text -NoNewline
    Write-Host $spacer -NoNewline
    Write-Colored -Text "powered by " -ForegroundColor $script:Theme.TextDim -NoNewline
    Write-Colored -Text "Kindware.dev" -ForegroundColor $script:Theme.Secondary -NoNewline
    Write-Host "  "
    
    Write-Colored -Text ("  " + ("=" * ($width - 4))) -ForegroundColor $script:Theme.Border
    Write-Host ""
}

# ============================================================================
# MAIN MENU - MODERN STYLE
# ============================================================================
function Show-MainMenu {
    param(
        [int]$SelectedIndex = 0,
        [string]$StatusMessage = "",
        [string]$StatusType = "info"
    )
    
    Clear-ScreenBuffer
    Show-Header
    
    $width = $script:UIState.Width
    
    # ASCII Art Frog with Write-Host colors (more compatible)
    Write-Host ""
    Write-Host "           " -NoNewline
    Write-Host "_____" -ForegroundColor Cyan
    Write-Host "          " -NoNewline
    Write-Host "/" -ForegroundColor Cyan -NoNewline
    Write-Host " o " -ForegroundColor White -NoNewline
    Write-Host " " -NoNewline
    Write-Host "o " -ForegroundColor White -NoNewline
    Write-Host "\" -ForegroundColor Cyan
    Write-Host "         " -NoNewline
    Write-Host "|" -ForegroundColor Cyan -NoNewline
    Write-Host "__" -ForegroundColor Magenta -NoNewline
    Write-Host "\_/" -ForegroundColor Cyan -NoNewline
    Write-Host "__" -ForegroundColor Magenta -NoNewline
    Write-Host "|" -ForegroundColor Cyan
    Write-Host "          " -NoNewline
    Write-Host "/\   /\" -ForegroundColor Cyan
    Write-Host "         " -NoNewline
    Write-Host "/  \_/  \" -ForegroundColor Magenta
    Write-Host "        " -NoNewline
    Write-Host "/_________\" -ForegroundColor Green
    Write-Host ""
    
    Write-Colored -Text "  Select a tool to begin:" -ForegroundColor $script:Theme.TextDim
    Write-Host ""
    
    # Menu items with modern styling
    $menuItems = @(
        @{ Key = "1"; Icon = "[GIT]"; Name = "GitHub Scanner"; Desc = "Search & explore repositories" }
        @{ Key = "2"; Icon = "[RUN]"; Name = "Task Runner"; Desc = "Execute custom commands" }
        @{ Key = "3"; Icon = "[SYS]"; Name = "System Monitor"; Desc = "Real-time performance metrics" }
        @{ Key = "4"; Icon = "[DOC]"; Name = "Help & Docs"; Desc = "Documentation & shortcuts" }
        @{ Key = "Q"; Icon = "[EXIT]"; Name = "Exit"; Desc = "Close application" }
    )
    
    for ($i = 0; $i -lt $menuItems.Count; $i++) {
        $item = $menuItems[$i]
        $isSelected = ($i -eq $SelectedIndex)
        
        if ($isSelected) {
            Write-Host "  " -NoNewline
            Write-Host " > " -ForegroundColor $script:Theme.Primary -NoNewline
            Write-Host "[" -ForegroundColor $script:Theme.Border -NoNewline
            Write-Host $item.Key -ForegroundColor $script:Theme.MenuKey -NoNewline
            Write-Host "] " -ForegroundColor $script:Theme.Border -NoNewline
            Write-Host $item.Icon -ForegroundColor $script:Theme.Secondary -NoNewline
            Write-Host " $($item.Name)" -ForegroundColor $script:Theme.Primary -NoNewline
            Write-Host " - " -ForegroundColor $script:Theme.TextDim -NoNewline
            Write-Host $item.Desc -ForegroundColor $script:Theme.Text
        }
        else {
            Write-Host "     " -NoNewline
            Write-Host "[" -ForegroundColor $script:Theme.Border -NoNewline
            Write-Host $item.Key -ForegroundColor $script:Theme.TextDim -NoNewline
            Write-Host "] " -ForegroundColor $script:Theme.Border -NoNewline
            Write-Host $item.Icon -ForegroundColor $script:Theme.TextDim -NoNewline
            Write-Host " $($item.Name)" -ForegroundColor $script:Theme.MenuItem
        }
    }
    
    Write-Host ""
    Write-Colored -Text ("  " + ("-" * ($width - 4))) -ForegroundColor $script:Theme.Border
    
    # Footer
    Write-Host "  " -NoNewline
    Write-Host "[" -ForegroundColor $script:Theme.Border -NoNewline
    Write-Host "Up/Down" -ForegroundColor $script:Theme.MenuKey -NoNewline
    Write-Host "] Navigate  " -ForegroundColor $script:Theme.TextDim -NoNewline
    Write-Host "[" -ForegroundColor $script:Theme.Border -NoNewline
    Write-Host "Enter" -ForegroundColor $script:Theme.MenuKey -NoNewline
    Write-Host "] Select  " -ForegroundColor $script:Theme.TextDim -NoNewline
    Write-Host "[" -ForegroundColor $script:Theme.Border -NoNewline
    Write-Host "1-4" -ForegroundColor $script:Theme.MenuKey -NoNewline
    Write-Host "] Quick Jump  " -ForegroundColor $script:Theme.TextDim -NoNewline
    Write-Host "[" -ForegroundColor $script:Theme.Border -NoNewline
    Write-Host "Q" -ForegroundColor $script:Theme.MenuKey -NoNewline
    Write-Host "] Quit" -ForegroundColor $script:Theme.TextDim
    
    # Status message
    if (-not [string]::IsNullOrEmpty($StatusMessage)) {
        Write-Host ""
        $statusColor = switch ($StatusType) {
            "success" { $script:Theme.Success }
            "warning" { $script:Theme.Warning }
            "error"   { $script:Theme.Error }
            default   { $script:Theme.Info }
        }
        $statusIcon = switch ($StatusType) {
            "success" { "[OK]" }
            "warning" { "[!]" }
            "error"   { "[X]" }
            default   { "[i]" }
        }
        Write-Host "  " -NoNewline
        Write-Host $statusIcon -ForegroundColor $statusColor -NoNewline
        Write-Host " $StatusMessage" -ForegroundColor $script:Theme.Text
    }
}

# ============================================================================
# TOOL VIEWS - GITHUB SCANNER
# ============================================================================
function Show-GitHubView {
    param(
        [array]$Results = @(),
        [int]$SelectedIndex = 0,
        [string]$LastSearch = "",
        [string]$StatusMessage = "",
        [string]$StatusType = "info"
    )
    
    Clear-ScreenBuffer
    
    $width = $script:UIState.Width
    
    # Header
    Write-Host ""
    Write-Colored -Text ("  " + ("=" * ($width - 4))) -ForegroundColor $script:Theme.Border
    Write-Host "  " -NoNewline
    Write-Host "[GIT]" -ForegroundColor $script:Theme.Secondary -NoNewline
    Write-Host " GitHub Repository Scanner" -ForegroundColor $script:Theme.Primary -NoNewline
    $spacer = " " * ($width - 40)
    Write-Host $spacer -NoNewline
    Write-Host "LAZYFROG" -ForegroundColor $script:Theme.HeaderAccent
    Write-Colored -Text ("  " + ("=" * ($width - 4))) -ForegroundColor $script:Theme.Border
    Write-Host ""
    
    if ($Results.Count -eq 0) {
        if ([string]::IsNullOrEmpty($LastSearch)) {
            Write-Host ""
            Write-Colored -Text "  Press [S] to search GitHub repositories..." -ForegroundColor $script:Theme.TextDim
            Write-Host ""
            Write-Host "  " -NoNewline
            Write-Host "TIP:" -ForegroundColor $script:Theme.Warning -NoNewline
            Write-Host " Try searching for: " -ForegroundColor $script:Theme.TextDim -NoNewline
            Write-Host "powershell tui" -ForegroundColor $script:Theme.Primary -NoNewline
            Write-Host ", " -ForegroundColor $script:Theme.TextDim -NoNewline
            Write-Host "terminal tools" -ForegroundColor $script:Theme.Primary -NoNewline
            Write-Host ", " -ForegroundColor $script:Theme.TextDim -NoNewline
            Write-Host "cli utility" -ForegroundColor $script:Theme.Primary
        }
        else {
            Write-Colored -Text "  No results found for: $LastSearch" -ForegroundColor $script:Theme.Warning
        }
    }
    else {
        Write-Host "  " -NoNewline
        Write-Host "Found " -ForegroundColor $script:Theme.TextDim -NoNewline
        Write-Host "$($Results.Count)" -ForegroundColor $script:Theme.Success -NoNewline
        Write-Host " repositories for: " -ForegroundColor $script:Theme.TextDim -NoNewline
        Write-Host $LastSearch -ForegroundColor $script:Theme.Primary
        Write-Host ""
        
        $index = 0
        foreach ($repo in $Results) {
            $isSelected = ($index -eq $SelectedIndex)
            
            if ($isSelected) {
                Write-Host "  " -NoNewline
                Write-Host ">" -ForegroundColor $script:Theme.Primary -NoNewline
                Write-Host " +-" -ForegroundColor $script:Theme.BorderLight -NoNewline
                Write-Host ("-" * 60) -ForegroundColor $script:Theme.BorderLight -NoNewline
                Write-Host "+" -ForegroundColor $script:Theme.BorderLight
                
                Write-Host "  " -NoNewline
                Write-Host "|" -ForegroundColor $script:Theme.BorderLight -NoNewline
                Write-Host " [*]" -ForegroundColor $script:Theme.Warning -NoNewline
                Write-Host " $($repo.Stars.ToString().PadRight(8))" -ForegroundColor $script:Theme.Warning -NoNewline
                Write-Host $repo.Name -ForegroundColor $script:Theme.Primary
                
                Write-Host "  " -NoNewline
                Write-Host "|" -ForegroundColor $script:Theme.BorderLight -NoNewline
                Write-Host " Updated: " -ForegroundColor $script:Theme.TextDim -NoNewline
                Write-Host $repo.UpdatedAt -ForegroundColor $script:Theme.Text -NoNewline
                Write-Host "  Lang: " -ForegroundColor $script:Theme.TextDim -NoNewline
                Write-Host $repo.Language -ForegroundColor $script:Theme.Secondary
                
                if (-not [string]::IsNullOrEmpty($repo.Description)) {
                    $desc = if ($repo.Description.Length -gt 55) { $repo.Description.Substring(0, 52) + "..." } else { $repo.Description }
                    Write-Host "  " -NoNewline
                    Write-Host "|" -ForegroundColor $script:Theme.BorderLight -NoNewline
                    Write-Host " $desc" -ForegroundColor $script:Theme.Text
                }
                
                Write-Host "  " -NoNewline
                Write-Host "+-" -ForegroundColor $script:Theme.BorderLight -NoNewline
                Write-Host ("-" * 60) -ForegroundColor $script:Theme.BorderLight -NoNewline
                Write-Host "+" -ForegroundColor $script:Theme.BorderLight
            }
            else {
                Write-Host "    " -NoNewline
                Write-Host "[*]" -ForegroundColor $script:Theme.TextDim -NoNewline
                Write-Host " $($repo.Stars.ToString().PadRight(8))" -ForegroundColor $script:Theme.TextDim -NoNewline
                Write-Host $repo.Name -ForegroundColor $script:Theme.MenuItem
            }
            
            $index++
            if ($index -ge 8) { break }  # Show max 8 results
        }
    }
    
    Write-Host ""
    Write-Colored -Text ("  " + ("-" * ($width - 4))) -ForegroundColor $script:Theme.Border
    
    # Footer with commands
    Write-Host "  " -NoNewline
    Write-Host "[S]" -ForegroundColor $script:Theme.MenuKey -NoNewline
    Write-Host " Search  " -ForegroundColor $script:Theme.TextDim -NoNewline
    Write-Host "[W]" -ForegroundColor $script:Theme.MenuKey -NoNewline
    Write-Host " Watchlist  " -ForegroundColor $script:Theme.TextDim -NoNewline
    Write-Host "[J]" -ForegroundColor $script:Theme.MenuKey -NoNewline
    Write-Host " Save JSON  " -ForegroundColor $script:Theme.TextDim -NoNewline
    Write-Host "[M]" -ForegroundColor $script:Theme.MenuKey -NoNewline
    Write-Host " Save MD  " -ForegroundColor $script:Theme.TextDim -NoNewline
    Write-Host "[Esc]" -ForegroundColor $script:Theme.MenuKey -NoNewline
    Write-Host " Back" -ForegroundColor $script:Theme.TextDim
    
    # Status
    if (-not [string]::IsNullOrEmpty($StatusMessage)) {
        Write-Host ""
        $statusColor = switch ($StatusType) { "success" { "Green" } "error" { "Red" } default { "Cyan" } }
        Write-Host "  " -NoNewline
        Write-Host $StatusMessage -ForegroundColor $statusColor
    }
}

# ============================================================================
# TOOL VIEWS - TASK RUNNER
# ============================================================================
function Show-TasksView {
    param(
        [array]$Tasks = @(),
        [int]$SelectedIndex = 0,
        [string]$StatusMessage = "",
        [string]$StatusType = "info"
    )
    
    Clear-ScreenBuffer
    
    $width = $script:UIState.Width
    
    # Header
    Write-Host ""
    Write-Colored -Text ("  " + ("=" * ($width - 4))) -ForegroundColor $script:Theme.Border
    Write-Host "  " -NoNewline
    Write-Host "[RUN]" -ForegroundColor $script:Theme.Secondary -NoNewline
    Write-Host " Task Runner" -ForegroundColor $script:Theme.Primary -NoNewline
    $spacer = " " * ($width - 28)
    Write-Host $spacer -NoNewline
    Write-Host "LAZYFROG" -ForegroundColor $script:Theme.HeaderAccent
    Write-Colored -Text ("  " + ("=" * ($width - 4))) -ForegroundColor $script:Theme.Border
    Write-Host ""
    
    if ($Tasks.Count -eq 0) {
        Write-Colored -Text "  No tasks configured." -ForegroundColor $script:Theme.TextDim
        Write-Host ""
        Write-Host "  " -NoNewline
        Write-Host "Press " -ForegroundColor $script:Theme.TextDim -NoNewline
        Write-Host "[A]" -ForegroundColor $script:Theme.MenuKey -NoNewline
        Write-Host " to add a new task, or edit " -ForegroundColor $script:Theme.TextDim -NoNewline
        Write-Host "tasks.json" -ForegroundColor $script:Theme.Primary
    }
    else {
        $categories = $Tasks | Group-Object -Property { if ($_.category) { $_.category } else { "General" } }
        
        $globalIndex = 0
        foreach ($category in $categories) {
            Write-Host "  " -NoNewline
            Write-Host "[$($category.Name)]" -ForegroundColor $script:Theme.Secondary
            
            foreach ($task in $category.Group) {
                $isSelected = ($globalIndex -eq $SelectedIndex)
                
                if ($isSelected) {
                    Write-Host "  " -NoNewline
                    Write-Host " > " -ForegroundColor $script:Theme.Primary -NoNewline
                    Write-Host "[$($task.id)]" -ForegroundColor $script:Theme.MenuKey -NoNewline
                    Write-Host " $($task.name)" -ForegroundColor $script:Theme.Primary
                    if (-not [string]::IsNullOrEmpty($task.description)) {
                        Write-Host "       " -NoNewline
                        Write-Host $task.description -ForegroundColor $script:Theme.TextDim
                    }
                    Write-Host "       " -NoNewline
                    Write-Host "CMD: " -ForegroundColor $script:Theme.TextDim -NoNewline
                    Write-Host $task.command -ForegroundColor $script:Theme.Accent
                }
                else {
                    Write-Host "     " -NoNewline
                    Write-Host "[$($task.id)]" -ForegroundColor $script:Theme.TextDim -NoNewline
                    Write-Host " $($task.name)" -ForegroundColor $script:Theme.MenuItem
                }
                
                $globalIndex++
            }
            Write-Host ""
        }
    }
    
    Write-Colored -Text ("  " + ("-" * ($width - 4))) -ForegroundColor $script:Theme.Border
    
    Write-Host "  " -NoNewline
    Write-Host "[Enter/X]" -ForegroundColor $script:Theme.MenuKey -NoNewline
    Write-Host " Run  " -ForegroundColor $script:Theme.TextDim -NoNewline
    Write-Host "[A]" -ForegroundColor $script:Theme.MenuKey -NoNewline
    Write-Host " Add  " -ForegroundColor $script:Theme.TextDim -NoNewline
    Write-Host "[D]" -ForegroundColor $script:Theme.MenuKey -NoNewline
    Write-Host " Delete  " -ForegroundColor $script:Theme.TextDim -NoNewline
    Write-Host "[H]" -ForegroundColor $script:Theme.MenuKey -NoNewline
    Write-Host " History  " -ForegroundColor $script:Theme.TextDim -NoNewline
    Write-Host "[Esc]" -ForegroundColor $script:Theme.MenuKey -NoNewline
    Write-Host " Back" -ForegroundColor $script:Theme.TextDim
    
    if (-not [string]::IsNullOrEmpty($StatusMessage)) {
        Write-Host ""
        $statusColor = switch ($StatusType) { "success" { "Green" } "error" { "Red" } default { "Cyan" } }
        Write-Host "  $StatusMessage" -ForegroundColor $statusColor
    }
}

# ============================================================================
# TOOL VIEWS - SYSTEM MONITOR
# ============================================================================
function Show-SystemView {
    param(
        [hashtable]$SystemInfo = @{},
        [string]$StatusMessage = "",
        [string]$StatusType = "info"
    )
    
    Clear-ScreenBuffer
    
    $width = $script:UIState.Width
    
    # Header
    Write-Host ""
    Write-Colored -Text ("  " + ("=" * ($width - 4))) -ForegroundColor $script:Theme.Border
    Write-Host "  " -NoNewline
    Write-Host "[SYS]" -ForegroundColor $script:Theme.Secondary -NoNewline
    Write-Host " System Monitor" -ForegroundColor $script:Theme.Primary -NoNewline
    $spacer = " " * ($width - 31)
    Write-Host $spacer -NoNewline
    Write-Host "LAZYFROG" -ForegroundColor $script:Theme.HeaderAccent
    Write-Colored -Text ("  " + ("=" * ($width - 4))) -ForegroundColor $script:Theme.Border
    Write-Host ""
    
    # CPU
    $cpuPct = if ($SystemInfo.CpuUsage) { $SystemInfo.CpuUsage } else { 0 }
    Write-Host "  " -NoNewline
    Write-Host "[CPU]" -ForegroundColor $script:Theme.Secondary -NoNewline
    Write-Host " Processor" -ForegroundColor $script:Theme.Text
    Write-Host "       " -NoNewline
    Show-ProgressBar -Percent $cpuPct -Width 40
    Write-Host " $($cpuPct)%" -ForegroundColor $(if ($cpuPct -gt 80) { "Red" } elseif ($cpuPct -gt 50) { "Yellow" } else { "Green" })
    Write-Host ""
    
    # RAM
    $ramPct = if ($SystemInfo.RamUsage) { $SystemInfo.RamUsage } else { 0 }
    $ramUsed = if ($SystemInfo.RamUsed) { $SystemInfo.RamUsed } else { 0 }
    $ramTotal = if ($SystemInfo.RamTotal) { $SystemInfo.RamTotal } else { 0 }
    Write-Host "  " -NoNewline
    Write-Host "[RAM]" -ForegroundColor $script:Theme.Secondary -NoNewline
    Write-Host " Memory" -ForegroundColor $script:Theme.Text
    Write-Host "       " -NoNewline
    Show-ProgressBar -Percent $ramPct -Width 40
    Write-Host " $ramPct% ($ramUsed / $ramTotal GB)" -ForegroundColor $(if ($ramPct -gt 80) { "Red" } elseif ($ramPct -gt 50) { "Yellow" } else { "Green" })
    Write-Host ""
    
    # Disks
    Write-Host "  " -NoNewline
    Write-Host "[DISK]" -ForegroundColor $script:Theme.Secondary -NoNewline
    Write-Host " Storage" -ForegroundColor $script:Theme.Text
    
    if ($SystemInfo.DiskInfo) {
        foreach ($disk in $SystemInfo.DiskInfo) {
            Write-Host "       " -NoNewline
            Write-Host "$($disk.Drive) " -ForegroundColor $script:Theme.Primary -NoNewline
            Show-ProgressBar -Percent $disk.UsagePercent -Width 30
            Write-Host " $($disk.UsagePercent)% ($($disk.FreeGB) GB free)" -ForegroundColor $script:Theme.TextDim
        }
    }
    Write-Host ""
    
    # Uptime
    Write-Host "  " -NoNewline
    Write-Host "[TIME]" -ForegroundColor $script:Theme.Secondary -NoNewline
    Write-Host " Uptime: " -ForegroundColor $script:Theme.Text -NoNewline
    Write-Host $(if ($SystemInfo.Uptime) { $SystemInfo.Uptime } else { "Unknown" }) -ForegroundColor $script:Theme.Primary
    Write-Host ""
    
    # Top Processes
    if ($SystemInfo.TopProcesses -and $SystemInfo.TopProcesses.Count -gt 0) {
        Write-Host "  " -NoNewline
        Write-Host "[PROC]" -ForegroundColor $script:Theme.Secondary -NoNewline
        Write-Host " Top Processes" -ForegroundColor $script:Theme.Text
        Write-Host "       " -NoNewline
        Write-Host "Name".PadRight(25) -ForegroundColor $script:Theme.TextDim -NoNewline
        Write-Host "CPU".PadRight(10) -ForegroundColor $script:Theme.TextDim -NoNewline
        Write-Host "Memory" -ForegroundColor $script:Theme.TextDim
        
        foreach ($proc in $SystemInfo.TopProcesses) {
            $name = if ($proc.Name.Length -gt 22) { $proc.Name.Substring(0, 19) + "..." } else { $proc.Name }
            Write-Host "       " -NoNewline
            Write-Host $name.PadRight(25) -ForegroundColor $script:Theme.MenuItem -NoNewline
            Write-Host "$($proc.CPU)".PadRight(10) -ForegroundColor $script:Theme.Warning -NoNewline
            Write-Host "$($proc.Memory) MB" -ForegroundColor $script:Theme.TextDim
        }
    }
    
    Write-Host ""
    Write-Colored -Text ("  " + ("-" * ($width - 4))) -ForegroundColor $script:Theme.Border
    
    Write-Host "  " -NoNewline
    Write-Host "[R]" -ForegroundColor $script:Theme.MenuKey -NoNewline
    Write-Host " Refresh  " -ForegroundColor $script:Theme.TextDim -NoNewline
    Write-Host "[S]" -ForegroundColor $script:Theme.MenuKey -NoNewline
    Write-Host " Save Snapshot  " -ForegroundColor $script:Theme.TextDim -NoNewline
    Write-Host "[I]" -ForegroundColor $script:Theme.MenuKey -NoNewline
    Write-Host " Details  " -ForegroundColor $script:Theme.TextDim -NoNewline
    Write-Host "[Esc]" -ForegroundColor $script:Theme.MenuKey -NoNewline
    Write-Host " Back" -ForegroundColor $script:Theme.TextDim
    
    Write-Host ""
    Write-Host "  " -NoNewline
    Write-Host "Last updated: " -ForegroundColor $script:Theme.TextDim -NoNewline
    Write-Host (Get-Date -Format "HH:mm:ss") -ForegroundColor $script:Theme.Info
}

function Show-ProgressBar {
    param(
        [double]$Percent,
        [int]$Width = 30
    )
    
    $filled = [Math]::Floor($Width * $Percent / 100)
    $empty = $Width - $filled
    
    $color = if ($Percent -gt 80) { "Red" } elseif ($Percent -gt 50) { "Yellow" } else { "Green" }
    
    Write-Host "[" -ForegroundColor $script:Theme.Border -NoNewline
    Write-Host ("#" * $filled) -ForegroundColor $color -NoNewline
    Write-Host ("-" * $empty) -ForegroundColor $script:Theme.TextDim -NoNewline
    Write-Host "]" -ForegroundColor $script:Theme.Border -NoNewline
}

# ============================================================================
# TOOL VIEWS - HELP
# ============================================================================
function Show-HelpView {
    param(
        [int]$SelectedIndex = 0
    )
    
    Clear-ScreenBuffer
    
    $width = $script:UIState.Width
    
    # Header
    Write-Host ""
    Write-Colored -Text ("  " + ("=" * ($width - 4))) -ForegroundColor $script:Theme.Border
    Write-Host "  " -NoNewline
    Write-Host "[DOC]" -ForegroundColor $script:Theme.Secondary -NoNewline
    Write-Host " Help & Documentation" -ForegroundColor $script:Theme.Primary -NoNewline
    $spacer = " " * ($width - 37)
    Write-Host $spacer -NoNewline
    Write-Host "LAZYFROG" -ForegroundColor $script:Theme.HeaderAccent
    Write-Colored -Text ("  " + ("=" * ($width - 4))) -ForegroundColor $script:Theme.Border
    Write-Host ""
    
    $helpItems = @(
        @{ Key = "1"; Name = "Getting Started"; Desc = "Overview and quick start guide" }
        @{ Key = "2"; Name = "GitHub Scanner"; Desc = "Repository search documentation" }
        @{ Key = "3"; Name = "Task Runner"; Desc = "Task configuration guide" }
        @{ Key = "4"; Name = "System Monitor"; Desc = "Performance monitoring help" }
        @{ Key = "5"; Name = "Keyboard Shortcuts"; Desc = "All available shortcuts" }
        @{ Key = "6"; Name = "About"; Desc = "Version and credits" }
    )
    
    for ($i = 0; $i -lt $helpItems.Count; $i++) {
        $item = $helpItems[$i]
        $isSelected = ($i -eq $SelectedIndex)
        
        if ($isSelected) {
            Write-Host "  " -NoNewline
            Write-Host " > " -ForegroundColor $script:Theme.Primary -NoNewline
            Write-Host "[$($item.Key)]" -ForegroundColor $script:Theme.MenuKey -NoNewline
            Write-Host " $($item.Name)" -ForegroundColor $script:Theme.Primary -NoNewline
            Write-Host " - $($item.Desc)" -ForegroundColor $script:Theme.Text
        }
        else {
            Write-Host "     " -NoNewline
            Write-Host "[$($item.Key)]" -ForegroundColor $script:Theme.TextDim -NoNewline
            Write-Host " $($item.Name)" -ForegroundColor $script:Theme.MenuItem
        }
    }
    
    Write-Host ""
    Write-Colored -Text ("  " + ("-" * ($width - 4))) -ForegroundColor $script:Theme.Border
    
    Write-Host "  " -NoNewline
    Write-Host "[Enter]" -ForegroundColor $script:Theme.MenuKey -NoNewline
    Write-Host " View  " -ForegroundColor $script:Theme.TextDim -NoNewline
    Write-Host "[1-6]" -ForegroundColor $script:Theme.MenuKey -NoNewline
    Write-Host " Quick Select  " -ForegroundColor $script:Theme.TextDim -NoNewline
    Write-Host "[Esc]" -ForegroundColor $script:Theme.MenuKey -NoNewline
    Write-Host " Back" -ForegroundColor $script:Theme.TextDim
}

# ============================================================================
# INPUT PROMPT
# ============================================================================
function Read-LineInput {
    param(
        [string]$Prompt = "Input"
    )
    
    Write-Host ""
    Write-Host "  " -NoNewline
    Write-Host $Prompt -ForegroundColor $script:Theme.Primary -NoNewline
    Write-Host " " -NoNewline
    
    [Console]::CursorVisible = $true
    $input = Read-Host
    [Console]::CursorVisible = $false
    
    return $input
}

# ============================================================================
# EXPORTS
# ============================================================================
function Get-UIState {
    return $script:UIState
}

function Set-ContentBuffer {
    param([array]$Content)
    $script:UIState.ContentBuffer = $Content
}

function Get-ContentBuffer {
    return $script:UIState.ContentBuffer
}

# Functions are available via dot-sourcing
