<#
.SYNOPSIS
    UI Rendering Library for LazyFrog Developer Tools
.DESCRIPTION
    Provides TUI rendering functions including borders, panels,
    menus, and styled text output.
.AUTHOR
    Kindware.dev
.VERSION
    1.0.0
#>

# Box drawing characters for TUI borders
$script:BoxChars = @{
    TopLeft     = "+"
    TopRight    = "+"
    BottomLeft  = "+"
    BottomRight = "+"
    Horizontal  = "-"
    Vertical    = "|"
    TeeRight    = "+"
    TeeLeft     = "+"
    TeeDown     = "+"
    TeeUp       = "+"
    Cross       = "+"
}

# Current UI state
$script:UIState = @{
    Width         = 0
    Height        = 0
    MenuWidth     = 18
    CurrentTool   = 1
    ContentBuffer = @()
}

<#
.SYNOPSIS
    Initializes the UI system
#>
function Initialize-UI {
    [CmdletBinding()]
    param()
    
    $Host.UI.RawUI.WindowTitle = "LazyFrog Developer Tools - powered by Kindware.dev"
    
    $script:UIState.Width = $Host.UI.RawUI.WindowSize.Width
    $script:UIState.Height = $Host.UI.RawUI.WindowSize.Height
    
    if ($script:UIState.Width -lt 80) { $script:UIState.Width = 80 }
    if ($script:UIState.Height -lt 24) { $script:UIState.Height = 24 }
    
    Clear-Host
    [Console]::CursorVisible = $false
    
    return $script:UIState
}

<#
.SYNOPSIS
    Clears the screen buffer
#>
function Clear-ScreenBuffer {
    [CmdletBinding()]
    param()
    
    Clear-Host
    [Console]::SetCursorPosition(0, 0)
}

<#
.SYNOPSIS
    Cleans up the UI system
#>
function Close-UI {
    [CmdletBinding()]
    param()
    
    [Console]::CursorVisible = $true
    Clear-Host
}

<#
.SYNOPSIS
    Draws the main application frame
#>
function Draw-MainFrame {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [int]$CurrentTool = 1
    )
    
    $script:UIState.CurrentTool = $CurrentTool
    $script:UIState.Width = [Math]::Max($Host.UI.RawUI.WindowSize.Width, 80)
    $script:UIState.Height = [Math]::Max($Host.UI.RawUI.WindowSize.Height, 24)
    
    Clear-Host
    Draw-Header
    Draw-MenuPanel -SelectedItem $CurrentTool
    Draw-Footer
}

<#
.SYNOPSIS
    Draws the application header
#>
function Draw-Header {
    [CmdletBinding()]
    param()
    
    $width = $script:UIState.Width - 1
    
    $topBorder = $script:BoxChars.TopLeft + ($script:BoxChars.Horizontal * ($width - 2)) + $script:BoxChars.TopRight
    Write-Host $topBorder -ForegroundColor Cyan
    
    $headerText = "  [FROG] LazyFrog Developer Tools -- powered by Kindware.dev"
    $padding = $width - 2 - $headerText.Length
    if ($padding -lt 0) { $padding = 0 }
    $headerLine = $script:BoxChars.Vertical + $headerText + (" " * $padding) + $script:BoxChars.Vertical
    Write-Host $headerLine -ForegroundColor Cyan
    
    $menuWidth = $script:UIState.MenuWidth
    $separator = $script:BoxChars.TeeRight + ($script:BoxChars.Horizontal * $menuWidth) + $script:BoxChars.TeeDown
    $separator += ($script:BoxChars.Horizontal * ($width - $menuWidth - 4)) + $script:BoxChars.TeeLeft
    Write-Host $separator -ForegroundColor Cyan
}

<#
.SYNOPSIS
    Draws the left menu panel
#>
function Draw-MenuPanel {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [int]$SelectedItem = 1
    )
    
    $menuItems = @(
        @{ Key = "1"; Name = "GitHub" },
        @{ Key = "2"; Name = "Tasks" },
        @{ Key = "3"; Name = "System" },
        @{ Key = "4"; Name = "Help" }
    )
    
    $menuWidth = $script:UIState.MenuWidth
    $contentWidth = $script:UIState.Width - $menuWidth - 4
    $contentHeight = $script:UIState.Height - 7
    
    for ($i = 0; $i -lt $contentHeight; $i++) {
        $menuText = ""
        $menuColor = "White"
        
        if ($i -lt $menuItems.Count) {
            $item = $menuItems[$i]
            $isSelected = ($i + 1) -eq $SelectedItem
            
            if ($isSelected) {
                $menuText = " > [$($item.Key)] $($item.Name)"
                $menuColor = "Green"
            }
            else {
                $menuText = "   [$($item.Key)] $($item.Name)"
                $menuColor = "Yellow"
            }
        }
        
        $menuText = $menuText.PadRight($menuWidth)
        if ($menuText.Length -gt $menuWidth) {
            $menuText = $menuText.Substring(0, $menuWidth)
        }
        
        $contentText = ""
        if ($i -lt $script:UIState.ContentBuffer.Count) {
            $contentText = $script:UIState.ContentBuffer[$i]
        }
        $contentText = $contentText.PadRight($contentWidth)
        if ($contentText.Length -gt $contentWidth) {
            $contentText = $contentText.Substring(0, $contentWidth)
        }
        
        Write-Host $script:BoxChars.Vertical -ForegroundColor Cyan -NoNewline
        Write-Host $menuText -ForegroundColor $menuColor -NoNewline
        Write-Host $script:BoxChars.Vertical -ForegroundColor Cyan -NoNewline
        Write-Host $contentText -ForegroundColor White -NoNewline
        Write-Host $script:BoxChars.Vertical -ForegroundColor Cyan
    }
}

<#
.SYNOPSIS
    Draws the application footer
#>
function Draw-Footer {
    [CmdletBinding()]
    param()
    
    $width = $script:UIState.Width - 1
    $menuWidth = $script:UIState.MenuWidth
    
    $separator = $script:BoxChars.TeeRight + ($script:BoxChars.Horizontal * $menuWidth) + $script:BoxChars.TeeUp
    $separator += ($script:BoxChars.Horizontal * ($width - $menuWidth - 4)) + $script:BoxChars.TeeLeft
    Write-Host $separator -ForegroundColor Cyan
    
    $footerText = "  [1-4] Select Tool  [S] Save  [W] Watchlist  [R] Refresh  [Q] Quit  [?] Help"
    $padding = $width - 2 - $footerText.Length
    if ($padding -lt 0) { $padding = 0 }
    $footerLine = $script:BoxChars.Vertical + $footerText + (" " * $padding) + $script:BoxChars.Vertical
    Write-Host $footerLine -ForegroundColor DarkGray
    
    $bottomBorder = $script:BoxChars.BottomLeft + ($script:BoxChars.Horizontal * ($width - 2)) + $script:BoxChars.BottomRight
    Write-Host $bottomBorder -ForegroundColor Cyan
}

<#
.SYNOPSIS
    Sets the content to display in the main panel
#>
function Set-ContentBuffer {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [string[]]$Content
    )
    
    $script:UIState.ContentBuffer = $Content
}

<#
.SYNOPSIS
    Gets the current content buffer
#>
function Get-ContentBuffer {
    return $script:UIState.ContentBuffer
}

<#
.SYNOPSIS
    Writes styled text to a specific position
#>
function Write-At {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [int]$X,
        
        [Parameter(Mandatory = $true)]
        [int]$Y,
        
        [Parameter(Mandatory = $true)]
        [string]$Text,
        
        [Parameter(Mandatory = $false)]
        [ConsoleColor]$ForegroundColor = [ConsoleColor]::White
    )
    
    $pos = $Host.UI.RawUI.CursorPosition
    $Host.UI.RawUI.CursorPosition = New-Object System.Management.Automation.Host.Coordinates($X, $Y)
    Write-Host $Text -ForegroundColor $ForegroundColor -NoNewline
    $Host.UI.RawUI.CursorPosition = $pos
}

<#
.SYNOPSIS
    Shows a message in the content area
#>
function Show-Message {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Info", "Success", "Warning", "Error")]
        [string]$Type = "Info"
    )
    
    $prefix = switch ($Type) {
        "Info" { "[i] " }
        "Success" { "[OK] " }
        "Warning" { "[!] " }
        "Error" { "[X] " }
    }
    
    $content = @("", "$prefix$Message", "")
    Set-ContentBuffer -Content $content
}

<#
.SYNOPSIS
    Shows a progress indicator
#>
function Show-Progress {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Activity,
        
        [Parameter(Mandatory = $false)]
        [int]$PercentComplete = -1
    )
    
    $width = 30
    $content = @("")
    $content += "  $Activity"
    $content += ""
    
    if ($PercentComplete -ge 0) {
        $filled = [Math]::Floor($width * $PercentComplete / 100)
        $empty = $width - $filled
        $bar = "[" + ("#" * $filled) + ("-" * $empty) + "] $PercentComplete%"
        $content += "  $bar"
    }
    else {
        $content += "  [...] Please wait..."
    }
    
    Set-ContentBuffer -Content $content
}

<#
.SYNOPSIS
    Creates a styled table from data
#>
function Format-Table-TUI {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [array]$Data,
        
        [Parameter(Mandatory = $true)]
        [array]$Columns
    )
    
    $lines = @()
    
    $headerLine = "  "
    foreach ($col in $Columns) {
        $headerLine += $col.Name.PadRight($col.Width)
    }
    $lines += $headerLine
    $lines += "  " + ("-" * ($headerLine.Length - 2))
    
    foreach ($item in $Data) {
        $dataLine = "  "
        foreach ($col in $Columns) {
            $value = $item.($col.Property)
            if ($null -eq $value) { $value = "" }
            $valueStr = $value.ToString()
            if ($valueStr.Length -gt ($col.Width - 1)) {
                $valueStr = $valueStr.Substring(0, $col.Width - 4) + "..."
            }
            $dataLine += $valueStr.PadRight($col.Width)
        }
        $lines += $dataLine
    }
    
    return $lines
}

<#
.SYNOPSIS
    Gets the current UI state
#>
function Get-UIState {
    return $script:UIState
}

<#
.SYNOPSIS
    Prompts user for input within the TUI
#>
function Read-TUIInput {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Prompt,
        
        [Parameter(Mandatory = $false)]
        [string]$DefaultValue = ""
    )
    
    [Console]::CursorVisible = $true
    
    $y = 3
    $x = $script:UIState.MenuWidth + 3
    
    $Host.UI.RawUI.CursorPosition = New-Object System.Management.Automation.Host.Coordinates($x, $y)
    Write-Host $Prompt -ForegroundColor Yellow -NoNewline
    
    if (-not [string]::IsNullOrEmpty($DefaultValue)) {
        Write-Host " [$DefaultValue]: " -ForegroundColor DarkGray -NoNewline
    }
    else {
        Write-Host ": " -NoNewline
    }
    
    $inputVal = Read-Host
    
    [Console]::CursorVisible = $false
    
    if ([string]::IsNullOrEmpty($inputVal) -and -not [string]::IsNullOrEmpty($DefaultValue)) {
        return $DefaultValue
    }
    
    return $inputVal
}

<#
.SYNOPSIS
    Shows a confirmation dialog
#>
function Show-Confirmation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [bool]$DefaultYes = $false
    )
    
    $defaultStr = if ($DefaultYes) { "Y/n" } else { "y/N" }
    $response = Read-TUIInput -Prompt "$Message [$defaultStr]"
    
    if ([string]::IsNullOrEmpty($response)) {
        return $DefaultYes
    }
    
    return $response.ToLower() -eq "y"
}

# Functions are available via dot-sourcing
