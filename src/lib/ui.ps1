<#
.SYNOPSIS
    Modern UI Rendering Library for LazyFrog Developer Tools
.DESCRIPTION
    Modern TUI rendering with colors, gradients, and modern styling
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
    AccentSoft    = "DarkGray"
    
    # UI colors
    Border        = "DarkCyan"
    BorderLight   = "Cyan"
    BorderDark    = "DarkCyan"
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
    MenuHot       = "Cyan"
}

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
    FirstRender   = $true
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
    $script:UIState.FirstRender = $true
    
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

function Get-TrimmedText {
    param(
        [string]$Text,
        [int]$MaxLength
    )
    if ([string]::IsNullOrEmpty($Text)) { return "" }
    if ($Text.Length -le $MaxLength) { return $Text }
    if ($MaxLength -lt 4) { return $Text.Substring(0, $MaxLength) }
    return $Text.Substring(0, $MaxLength - 3) + "..."
}

function Write-Rule {
    param(
        [int]$Width,
        [string]$Char = "-",
        [string]$Color = $script:Theme.Border
    )
    Write-Colored -Text ("  " + ($Char * ($Width - 4))) -ForegroundColor $Color
}

function Write-SectionHeader {
    param(
        [string]$Icon,
        [string]$Title,
        [string]$RightTag = "LAZYFROG"
    )
    $width = $script:UIState.Width
    Write-Host ""
    Write-Rule -Width $width -Char "=" -Color $script:Theme.Border
    Write-Host "  " -NoNewline
    Write-Host $Icon -ForegroundColor $script:Theme.Secondary -NoNewline
    Write-Host " $Title" -ForegroundColor $script:Theme.Primary -NoNewline
    $spacer = " " * [Math]::Max(1, $width - ($Title.Length + $Icon.Length + $RightTag.Length + 6))
    Write-Host $spacer -NoNewline
    Write-Host $RightTag -ForegroundColor $script:Theme.HeaderAccent
    Write-Rule -Width $width -Char "=" -Color $script:Theme.Border
    Write-Host ""
}

function Write-StatusBar {
    param(
        [string]$Left = "",
        [string]$Right = ""
    )
    $width = $script:UIState.Width
    $leftText = $Left
    $rightText = $Right
    $spacer = " " * [Math]::Max(1, $width - ($leftText.Length + $rightText.Length + 4))
    Write-Host "  " -NoNewline
    Write-Host $leftText -ForegroundColor $script:Theme.TextDim -NoNewline
    Write-Host $spacer -NoNewline
    Write-Host $rightText -ForegroundColor $script:Theme.TextDim
}

function Write-BoxLine {
    param(
        [string]$Left,
        [string]$Right,
        [int]$Width,
        [string]$BorderColor = $script:Theme.Border
    )
    $leftText = $Left
    $rightText = $Right
    $space = [Math]::Max(1, $Width - ($leftText.Length + $rightText.Length + 6))
    Write-Host "  " -NoNewline
    Write-Host "|" -ForegroundColor $BorderColor -NoNewline
    Write-Host " $leftText" -ForegroundColor $script:Theme.Text -NoNewline
    Write-Host (" " * $space) -NoNewline
    Write-Host $rightText -ForegroundColor $script:Theme.TextDim -NoNewline
    Write-Host " |" -ForegroundColor $BorderColor
}

function Write-MenuRow {
    param(
        [int]$Index,
        [string]$Key,
        [string]$Label,
        [string]$Desc,
        [int]$SelectedIndex,
        [int]$Width
    )
    $isSelected = ($Index -eq $SelectedIndex)
    $left = "[$Key] $Label"
    $right = Get-TrimmedText -Text $Desc -MaxLength ($Width - $left.Length - 8)

    Write-Host "  " -NoNewline
    Write-Host "|" -ForegroundColor $script:Theme.Border -NoNewline
    Write-Host " " -NoNewline
    if ($isSelected) {
        Write-Host ">" -ForegroundColor $script:Theme.Primary -NoNewline
        Write-Host " $left" -ForegroundColor $script:Theme.Primary -NoNewline
    }
    else {
        Write-Host " " -NoNewline
        Write-Host " $left" -ForegroundColor $script:Theme.MenuItem -NoNewline
    }
    $pad = [Math]::Max(1, $Width - ($left.Length + 6))
    Write-Host (" " * $pad) -NoNewline
    Write-Host $right -ForegroundColor $script:Theme.TextDim -NoNewline
    Write-Host " |" -ForegroundColor $script:Theme.Border
}

function Write-FrogLogo {
    Write-Host "" 
    Write-Host "  " -NoNewline
    Write-Host "LAZYFROG" -ForegroundColor $script:Theme.Primary -NoNewline
    Write-Host " DEVTERM" -ForegroundColor $script:Theme.Text -NoNewline
    Write-Host "" 
    Write-Host "  " -NoNewline
    Write-Host "Kindware.dev" -ForegroundColor $script:Theme.AccentSoft
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
    if ($script:UIState.FirstRender) {
        [Console]::Clear()
        $script:UIState.FirstRender = $false
    }
    [Console]::SetCursorPosition(0, 0)
}

function Reset-UI {
    $script:UIState.FirstRender = $true
}

# ============================================================================
# MODERN HEADER WITH BRANDING
# ============================================================================
function Show-Header {
    $width = $script:UIState.Width

    Write-Host ""
    Write-Rule -Width $width -Char "═" -Color $script:Theme.Border
    Write-Host "  " -NoNewline
    Write-Colored -Text "LAZYFROG" -ForegroundColor $script:Theme.Primary -NoNewline
    Write-Colored -Text " DEVTERM" -ForegroundColor $script:Theme.Text -NoNewline
    $right = "kindware.dev"
    $spacer = " " * [Math]::Max(1, $width - ($right.Length + "LAZYFROG DEVTERM".Length + 4))
    Write-Host $spacer -NoNewline
    Write-Colored -Text $right -ForegroundColor $script:Theme.Secondary -NoNewline
    Write-Host ""
    Write-Rule -Width $width -Char "─" -Color $script:Theme.BorderDark
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
    $boxWidth = [Math]::Min(78, $width - 4)

    Write-FrogLogo
    Write-Host "  " -NoNewline
    Write-Host "LAZYFROG DEVTERM" -ForegroundColor $script:Theme.Primary -NoNewline
    Write-Host "  " -ForegroundColor $script:Theme.TextDim -NoNewline
    Write-Host "Modern terminal tooling for Windows" -ForegroundColor $script:Theme.TextDim
    Write-Host ""

    $menuItems = @(
        @{ Key = "1"; Name = "GitHub Scanner"; Desc = "Search & explore repositories" }
        @{ Key = "2"; Name = "Task Runner"; Desc = "Execute custom commands" }
        @{ Key = "3"; Name = "System Monitor"; Desc = "Real-time performance metrics" }
        @{ Key = "4"; Name = "Help & Docs"; Desc = "Documentation & shortcuts" }
        @{ Key = "Q"; Name = "Exit"; Desc = "Close application" }
    )

    Write-Host "  " -NoNewline
    Write-Host "+" -ForegroundColor $script:Theme.Border -NoNewline
    Write-Host ("-" * $boxWidth) -ForegroundColor $script:Theme.Border -NoNewline
    Write-Host "+" -ForegroundColor $script:Theme.Border
    Write-BoxLine -Left "Select a module" -Right "LazyFrog DevTerm" -Width $boxWidth -BorderColor $script:Theme.Border
    Write-Host "  " -NoNewline
    Write-Host "+" -ForegroundColor $script:Theme.Border -NoNewline
    Write-Host ("-" * $boxWidth) -ForegroundColor $script:Theme.Border -NoNewline
    Write-Host "+" -ForegroundColor $script:Theme.Border

    for ($i = 0; $i -lt $menuItems.Count; $i++) {
        $item = $menuItems[$i]
        Write-MenuRow -Index $i -Key $item.Key -Label $item.Name -Desc $item.Desc -SelectedIndex $SelectedIndex -Width $boxWidth
    }

    Write-Host "  " -NoNewline
    Write-Host "+" -ForegroundColor $script:Theme.Border -NoNewline
    Write-Host ("-" * $boxWidth) -ForegroundColor $script:Theme.Border -NoNewline
    Write-Host "+" -ForegroundColor $script:Theme.Border

    Write-Host ""
    Write-Rule -Width $width -Char "-" -Color $script:Theme.Border

    Write-Host "  " -NoNewline
    Write-Host "[Up/Down]" -ForegroundColor $script:Theme.MenuKey -NoNewline
    Write-Host " Navigate  " -ForegroundColor $script:Theme.TextDim -NoNewline
    Write-Host "[Enter]" -ForegroundColor $script:Theme.MenuKey -NoNewline
    Write-Host " Select  " -ForegroundColor $script:Theme.TextDim -NoNewline
    Write-Host "[1-4]" -ForegroundColor $script:Theme.MenuKey -NoNewline
    Write-Host " Quick Jump  " -ForegroundColor $script:Theme.TextDim -NoNewline
    Write-Host "[Q]" -ForegroundColor $script:Theme.MenuKey -NoNewline
    Write-Host " Quit" -ForegroundColor $script:Theme.TextDim

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

    Write-StatusBar -Left "Press Q to exit" -Right (Get-Date -Format "HH:mm")
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
    
    Write-SectionHeader -Icon "[GIT]" -Title "GitHub Repository Scanner"
    
    if ($Results.Count -eq 0) {
        if ([string]::IsNullOrEmpty($LastSearch)) {
            Write-Host ""
            Write-Colored -Text "  Press [S] to search GitHub repositories." -ForegroundColor $script:Theme.TextDim
            Write-Host "  " -NoNewline
            Write-Host "Example:" -ForegroundColor $script:Theme.TextDim -NoNewline
            Write-Host " powershell tui, terminal tools, cli utility" -ForegroundColor $script:Theme.Primary
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
        Write-Host "  " -NoNewline
        Write-Host "Use " -ForegroundColor $script:Theme.TextDim -NoNewline
        Write-Host "[Up/Down]" -ForegroundColor $script:Theme.MenuKey -NoNewline
        Write-Host " to select. " -ForegroundColor $script:Theme.TextDim -NoNewline
        Write-Host "[J]" -ForegroundColor $script:Theme.MenuKey -NoNewline
        Write-Host " JSON, " -ForegroundColor $script:Theme.TextDim -NoNewline
        Write-Host "[M]" -ForegroundColor $script:Theme.MenuKey -NoNewline
        Write-Host " Markdown." -ForegroundColor $script:Theme.TextDim
        Write-Host ""

        $tableWidth = [Math]::Min(90, $width - 4)
        $nameWidth = [Math]::Max(24, $tableWidth - 40)

        Write-Host "  " -NoNewline
        Write-Host "+" -ForegroundColor $script:Theme.Border -NoNewline
        Write-Host ("-" * $tableWidth) -ForegroundColor $script:Theme.Border -NoNewline
        Write-Host "+" -ForegroundColor $script:Theme.Border

        Write-BoxLine -Left ("Stars".PadRight(8) + "Name") -Right ("Lang".PadRight(9) + "Updated") -Width $tableWidth -BorderColor $script:Theme.Border

        Write-Host "  " -NoNewline
        Write-Host "+" -ForegroundColor $script:Theme.Border -NoNewline
        Write-Host ("-" * $tableWidth) -ForegroundColor $script:Theme.Border -NoNewline
        Write-Host "+" -ForegroundColor $script:Theme.Border

        $maxRows = 10
        $displayCount = [Math]::Min($maxRows, $Results.Count)
        $startIndex = [Math]::Min([Math]::Max(0, $SelectedIndex - ($maxRows - 1)), [Math]::Max(0, $Results.Count - $maxRows))
        $endIndex = $startIndex + $displayCount - 1

        Write-Host "  " -NoNewline
        Write-Host "Showing " -ForegroundColor $script:Theme.TextDim -NoNewline
        Write-Host "$(($startIndex + 1))-$(( $endIndex + 1))" -ForegroundColor $script:Theme.Primary -NoNewline
        Write-Host " of $($Results.Count)" -ForegroundColor $script:Theme.TextDim
        Write-Host ""

        for ($index = $startIndex; $index -le $endIndex; $index++) {
            $repo = $Results[$index]
            $isSelected = ($index -eq $SelectedIndex)
            $stars = $repo.Stars.ToString().PadRight(8)
            $name = Get-TrimmedText -Text $repo.Name -MaxLength $nameWidth
            $lang = Get-TrimmedText -Text $repo.Language -MaxLength 9
            $updated = Get-TrimmedText -Text $repo.UpdatedAt -MaxLength 10
            $left = "$stars$name"
            $right = $lang.PadRight(9) + $updated

            Write-Host "  " -NoNewline
            Write-Host "|" -ForegroundColor $script:Theme.Border -NoNewline
            Write-Host " " -NoNewline
            if ($isSelected) {
                Write-Host ">" -ForegroundColor $script:Theme.Primary -NoNewline
                Write-Host " $left" -ForegroundColor $script:Theme.Primary -NoNewline
            }
            else {
                Write-Host " " -NoNewline
                Write-Host " $left" -ForegroundColor $script:Theme.MenuItem -NoNewline
            }
            $pad = [Math]::Max(1, $tableWidth - ($left.Length + 6))
            Write-Host (" " * $pad) -NoNewline
            Write-Host $right -ForegroundColor $script:Theme.TextDim -NoNewline
            Write-Host " |" -ForegroundColor $script:Theme.Border

        }

        Write-Host "  " -NoNewline
        Write-Host "+" -ForegroundColor $script:Theme.Border -NoNewline
        Write-Host ("-" * $tableWidth) -ForegroundColor $script:Theme.Border -NoNewline
        Write-Host "+" -ForegroundColor $script:Theme.Border

        $selectedRepo = if ($Results.Count -gt 0 -and $SelectedIndex -lt $Results.Count) { $Results[$SelectedIndex] } else { $null }
        if ($null -ne $selectedRepo) {
            Write-Host ""
            $name = Get-TrimmedText -Text $selectedRepo.Name -MaxLength ($tableWidth - 2)
            $desc = Get-TrimmedText -Text $selectedRepo.Description -MaxLength ($tableWidth - 6)
            $detailLine = Get-TrimmedText -Text ("$name — $desc") -MaxLength ($tableWidth - 2)
            $url = Get-TrimmedText -Text $selectedRepo.Url -MaxLength 48
            $topics = Get-TrimmedText -Text $selectedRepo.Topics -MaxLength 32
            $license = Get-TrimmedText -Text $selectedRepo.License -MaxLength 16
            $metaLine = Get-TrimmedText -Text ("URL: $url | Topics: $topics | License: $license") -MaxLength ($tableWidth - 2)

            Write-Host "  $detailLine" -ForegroundColor $script:Theme.Text
            Write-Host "  $metaLine" -ForegroundColor $script:Theme.TextDim
        }
    }
    
    Write-Host ""
    Write-Rule -Width $width -Char "-" -Color $script:Theme.Border
    
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
    
    Write-SectionHeader -Icon "[RUN]" -Title "Task Runner"
    
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
        $tableWidth = [Math]::Min(90, $width - 4)
        $nameWidth = [Math]::Max(28, $tableWidth - 34)

        Write-Host "  " -NoNewline
        Write-Host "+" -ForegroundColor $script:Theme.Border -NoNewline
        Write-Host ("-" * $tableWidth) -ForegroundColor $script:Theme.Border -NoNewline
        Write-Host "+" -ForegroundColor $script:Theme.Border
        Write-BoxLine -Left "Tasks" -Right "Category" -Width $tableWidth -BorderColor $script:Theme.Border
        Write-Host "  " -NoNewline
        Write-Host "+" -ForegroundColor $script:Theme.Border -NoNewline
        Write-Host ("-" * $tableWidth) -ForegroundColor $script:Theme.Border -NoNewline
        Write-Host "+" -ForegroundColor $script:Theme.Border

        $globalIndex = 0
        foreach ($task in $Tasks) {
            $isSelected = ($globalIndex -eq $SelectedIndex)
            $cat = if ($task.category) { $task.category } else { "General" }
            $left = "[$($task.id)] " + (Get-TrimmedText -Text $task.name -MaxLength $nameWidth)
            $right = Get-TrimmedText -Text $cat -MaxLength 20

            Write-Host "  " -NoNewline
            Write-Host "|" -ForegroundColor $script:Theme.Border -NoNewline
            Write-Host " " -NoNewline
            if ($isSelected) {
                Write-Host ">" -ForegroundColor $script:Theme.Primary -NoNewline
                Write-Host " $left" -ForegroundColor $script:Theme.Primary -NoNewline
            }
            else {
                Write-Host " " -NoNewline
                Write-Host " $left" -ForegroundColor $script:Theme.MenuItem -NoNewline
            }
            $pad = [Math]::Max(1, $tableWidth - ($left.Length + 6))
            Write-Host (" " * $pad) -NoNewline
            Write-Host $right -ForegroundColor $script:Theme.TextDim -NoNewline
            Write-Host " |" -ForegroundColor $script:Theme.Border

            $globalIndex++
            if ($globalIndex -ge 12) { break }
        }

        Write-Host "  " -NoNewline
        Write-Host "+" -ForegroundColor $script:Theme.Border -NoNewline
        Write-Host ("-" * $tableWidth) -ForegroundColor $script:Theme.Border -NoNewline
        Write-Host "+" -ForegroundColor $script:Theme.Border

        $selectedTask = if ($Tasks.Count -gt 0 -and $SelectedIndex -lt $Tasks.Count) { $Tasks[$SelectedIndex] } else { $null }
        if ($null -ne $selectedTask) {
            Write-Host ""
            Write-Host "  " -NoNewline
            Write-Host "+" -ForegroundColor $script:Theme.Border -NoNewline
            Write-Host ("-" * $tableWidth) -ForegroundColor $script:Theme.Border -NoNewline
            Write-Host "+" -ForegroundColor $script:Theme.Border
            Write-BoxLine -Left "Command" -Right "" -Width $tableWidth -BorderColor $script:Theme.Border
            Write-BoxLine -Left (Get-TrimmedText -Text $selectedTask.command -MaxLength ($tableWidth - 4)) -Right "" -Width $tableWidth -BorderColor $script:Theme.Border
            if ($selectedTask.description) {
                Write-BoxLine -Left "Description" -Right "" -Width $tableWidth -BorderColor $script:Theme.Border
                Write-BoxLine -Left (Get-TrimmedText -Text $selectedTask.description -MaxLength ($tableWidth - 4)) -Right "" -Width $tableWidth -BorderColor $script:Theme.Border
            }
            Write-Host "  " -NoNewline
            Write-Host "+" -ForegroundColor $script:Theme.Border -NoNewline
            Write-Host ("-" * $tableWidth) -ForegroundColor $script:Theme.Border -NoNewline
            Write-Host "+" -ForegroundColor $script:Theme.Border
        }
    }

    Write-Host ""
    Write-Host "  " -NoNewline
    Write-Host "[NOTE]" -ForegroundColor $script:Theme.TextHighlight -NoNewline
    Write-Host " Git tasks must run inside a Git repo folder." -ForegroundColor $script:Theme.TextDim
    
    Write-Rule -Width $width -Char "-" -Color $script:Theme.Border
    
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
    
    Write-SectionHeader -Icon "[SYS]" -Title "System Monitor"
    
    $tableWidth = [Math]::Min(90, $width - 4)

    Write-Host "  " -NoNewline
    Write-Host "+" -ForegroundColor $script:Theme.Border -NoNewline
    Write-Host ("-" * $tableWidth) -ForegroundColor $script:Theme.Border -NoNewline
    Write-Host "+" -ForegroundColor $script:Theme.Border

    $cpuPct = if ($SystemInfo.CpuUsage) { $SystemInfo.CpuUsage } else { 0 }
    $ramPct = if ($SystemInfo.RamUsage) { $SystemInfo.RamUsage } else { 0 }
    $ramUsed = if ($SystemInfo.RamUsed) { $SystemInfo.RamUsed } else { 0 }
    $ramTotal = if ($SystemInfo.RamTotal) { $SystemInfo.RamTotal } else { 0 }

    Write-BoxLine -Left "CPU" -Right ("$cpuPct%") -Width $tableWidth -BorderColor $script:Theme.Border
    Write-Host "  " -NoNewline
    Write-Host "|" -ForegroundColor $script:Theme.Border -NoNewline
    Write-Host " " -NoNewline
    Show-ProgressBar -Percent $cpuPct -Width ([Math]::Max(10, $tableWidth - 6))
    Write-Host " |" -ForegroundColor $script:Theme.Border

    Write-BoxLine -Left "Memory" -Right ("$ramPct% ($ramUsed / $ramTotal GB)") -Width $tableWidth -BorderColor $script:Theme.Border
    Write-Host "  " -NoNewline
    Write-Host "|" -ForegroundColor $script:Theme.Border -NoNewline
    Write-Host " " -NoNewline
    Show-ProgressBar -Percent $ramPct -Width ([Math]::Max(10, $tableWidth - 6))
    Write-Host " |" -ForegroundColor $script:Theme.Border

    $uptimeText = if ($SystemInfo.Uptime) { $SystemInfo.Uptime } else { "Unknown" }
    Write-BoxLine -Left "Uptime" -Right $uptimeText -Width $tableWidth -BorderColor $script:Theme.Border

    $availableRows = [Math]::Max(1, $script:UIState.Height - 18)
    $diskRows = 0
    if ($SystemInfo.DiskInfo) {
        $maxDisks = [Math]::Min($SystemInfo.DiskInfo.Count, [Math]::Max(0, $availableRows - 4))
        for ($i = 0; $i -lt $maxDisks; $i++) {
            $disk = $SystemInfo.DiskInfo[$i]
            $diskLabel = "Disk $($disk.Drive)"
            $diskInfo = "$($disk.UsagePercent)% ($($disk.FreeGB) GB free)"
            Write-BoxLine -Left $diskLabel -Right $diskInfo -Width $tableWidth -BorderColor $script:Theme.Border
            $diskRows++
        }
    }

    $remaining = [Math]::Max(0, $availableRows - $diskRows)
    if ($SystemInfo.TopProcesses -and $SystemInfo.TopProcesses.Count -gt 0 -and $remaining -gt 1) {
        Write-BoxLine -Left "Top Processes" -Right "" -Width $tableWidth -BorderColor $script:Theme.Border
        $maxProc = [Math]::Min($SystemInfo.TopProcesses.Count, [Math]::Max(1, $remaining - 1))
        for ($i = 0; $i -lt $maxProc; $i++) {
            $proc = $SystemInfo.TopProcesses[$i]
            $name = if ($proc.Name.Length -gt 18) { $proc.Name.Substring(0, 15) + "..." } else { $proc.Name }
            $right = "CPU $($proc.CPU) | $($proc.Memory) MB"
            Write-BoxLine -Left $name -Right $right -Width $tableWidth -BorderColor $script:Theme.Border
        }
    }

    Write-Host "  " -NoNewline
    Write-Host "+" -ForegroundColor $script:Theme.Border -NoNewline
    Write-Host ("-" * $tableWidth) -ForegroundColor $script:Theme.Border -NoNewline
    Write-Host "+" -ForegroundColor $script:Theme.Border
    
    Write-Host ""
    Write-Rule -Width $width -Char "-" -Color $script:Theme.Border
    
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
    Write-Host (Get-Date -Format "HH:mm:ss") -ForegroundColor $script:Theme.Text
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
    Write-Host ("=" * $filled) -ForegroundColor $color -NoNewline
    Write-Host ("." * $empty) -ForegroundColor $script:Theme.TextDim -NoNewline
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
    Write-SectionHeader -Icon "[DOC]" -Title "Help & Documentation"
    
    Write-Host "  " -NoNewline
    Write-Host "Use " -ForegroundColor $script:Theme.TextDim -NoNewline
    Write-Host "[Up/Down]" -ForegroundColor $script:Theme.MenuKey -NoNewline
    Write-Host " to select a topic." -ForegroundColor $script:Theme.TextDim
    Write-Host ""

    $helpItems = @(
        @{ Key = "1"; Name = "Getting Started"; Desc = "Overview and quick start guide" }
        @{ Key = "2"; Name = "GitHub Scanner"; Desc = "Repository search documentation" }
        @{ Key = "3"; Name = "Task Runner"; Desc = "Task configuration guide" }
        @{ Key = "4"; Name = "System Monitor"; Desc = "Performance monitoring help" }
        @{ Key = "5"; Name = "Keyboard Shortcuts"; Desc = "All available shortcuts" }
        @{ Key = "6"; Name = "About"; Desc = "Version and credits" }
    )
    
    $tableWidth = [Math]::Min(78, $width - 4)
    Write-Host "  " -NoNewline
    Write-Host "+" -ForegroundColor $script:Theme.Border -NoNewline
    Write-Host ("-" * $tableWidth) -ForegroundColor $script:Theme.Border -NoNewline
    Write-Host "+" -ForegroundColor $script:Theme.Border
    Write-BoxLine -Left "Help topics" -Right "LazyFrog DevTerm" -Width $tableWidth -BorderColor $script:Theme.Border
    Write-Host "  " -NoNewline
    Write-Host "+" -ForegroundColor $script:Theme.Border -NoNewline
    Write-Host ("-" * $tableWidth) -ForegroundColor $script:Theme.Border -NoNewline
    Write-Host "+" -ForegroundColor $script:Theme.Border

    for ($i = 0; $i -lt $helpItems.Count; $i++) {
        $item = $helpItems[$i]
        Write-MenuRow -Index $i -Key $item.Key -Label $item.Name -Desc $item.Desc -SelectedIndex $SelectedIndex -Width $tableWidth
    }

    Write-Host "  " -NoNewline
    Write-Host "+" -ForegroundColor $script:Theme.Border -NoNewline
    Write-Host ("-" * $tableWidth) -ForegroundColor $script:Theme.Border -NoNewline
    Write-Host "+" -ForegroundColor $script:Theme.Border
    
    Write-Host ""
    Write-Rule -Width $width -Char "-" -Color $script:Theme.Border
    
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
