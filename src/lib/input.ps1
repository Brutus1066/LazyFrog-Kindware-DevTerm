<#
.SYNOPSIS
    Input Handling Library for LazyFrog Developer Tools
.DESCRIPTION
    Provides keyboard input handling, key mapping, and navigation
    support for the TUI application.
.AUTHOR
    Kindware.dev
.VERSION
    1.0.0
#>

# Key constants
$script:Keys = @{
    Escape    = 27
    Enter     = 13
    Backspace = 8
    Tab       = 9
    UpArrow   = 38
    DownArrow = 40
    LeftArrow = 37
    RightArrow = 39
    PageUp    = 33
    PageDown  = 34
    Home      = 36
    End       = 35
    Delete    = 46
    F1        = 112
    F2        = 113
    F3        = 114
    F4        = 115
    F5        = 116
}

# Input state
$script:InputState = @{
    LastKey       = $null
    LastChar      = $null
    InputBuffer   = ""
    IsInputMode   = $false
    SelectedIndex = 0
    MaxIndex      = 0
}

<#
.SYNOPSIS
    Waits for a key press and returns key information
.PARAMETER Timeout
    Maximum time to wait in milliseconds (0 = infinite)
#>
function Wait-KeyPress {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [int]$Timeout = 0
    )
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    while ($true) {
        if ([Console]::KeyAvailable) {
            $key = [Console]::ReadKey($true)
            
            $script:InputState.LastKey = $key
            $script:InputState.LastChar = $key.KeyChar
            
            return @{
                Key       = $key.Key
                KeyChar   = $key.KeyChar
                Modifiers = $key.Modifiers
                IsControl = ($key.Modifiers -band [ConsoleModifiers]::Control) -ne 0
                IsShift   = ($key.Modifiers -band [ConsoleModifiers]::Shift) -ne 0
                IsAlt     = ($key.Modifiers -band [ConsoleModifiers]::Alt) -ne 0
            }
        }
        
        if ($Timeout -gt 0 -and $stopwatch.ElapsedMilliseconds -ge $Timeout) {
            return $null
        }
        
        Start-Sleep -Milliseconds 50
    }
}

<#
.SYNOPSIS
    Checks if a specific key was pressed
.PARAMETER ExpectedKey
    The key to check for
.PARAMETER KeyInfo
    The key info object from Wait-KeyPress
#>
function Test-KeyPressed {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ExpectedKey,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$KeyInfo
    )
    
    if ($null -eq $KeyInfo) {
        return $false
    }
    
    # Check by key name
    if ($KeyInfo.Key -eq $ExpectedKey) {
        return $true
    }
    
    # Check by character (case insensitive for letters)
    $char = $KeyInfo.KeyChar
    if ($null -ne $char -and $char.ToString().ToUpper() -eq $ExpectedKey.ToUpper()) {
        return $true
    }
    
    return $false
}

<#
.SYNOPSIS
    Gets the character from key info
.PARAMETER KeyInfo
    The key info object from Wait-KeyPress
#>
function Get-KeyCharacter {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$KeyInfo
    )
    
    if ($null -eq $KeyInfo) {
        return $null
    }
    
    return $KeyInfo.KeyChar.ToString()
}

<#
.SYNOPSIS
    Reads a line of text with key-by-key input
.PARAMETER Prompt
    The prompt to display
.PARAMETER MaxLength
    Maximum input length
.PARAMETER DefaultValue
    Default value
#>
function Read-LineInput {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$Prompt = "",
        
        [Parameter(Mandatory = $false)]
        [int]$MaxLength = 100,
        
        [Parameter(Mandatory = $false)]
        [string]$DefaultValue = ""
    )
    
    $script:InputState.IsInputMode = $true
    $script:InputState.InputBuffer = $DefaultValue
    
    [Console]::CursorVisible = $true

    $width = [Math]::Max(40, $Host.UI.RawUI.WindowSize.Width)
    $height = [Math]::Max(10, $Host.UI.RawUI.WindowSize.Height)
    $promptLine = [Math]::Max(0, $height - 2)
    $separatorLine = [Math]::Max(0, $promptLine - 1)

    function Clear-Line {
        param([int]$LineIndex)
        try {
            [Console]::SetCursorPosition(0, $LineIndex)
            Write-Host (" " * ($width - 1)) -NoNewline
        }
        catch {}
    }

    # Draw a clean prompt bar at the bottom
    try {
        [Console]::SetCursorPosition(0, $separatorLine)
        Write-Host ("-" * ($width - 1)) -ForegroundColor DarkGray
        Clear-Line -LineIndex $promptLine
        [Console]::SetCursorPosition(0, $promptLine)
    }
    catch {}

    if (-not [string]::IsNullOrEmpty($Prompt)) {
        Write-Host "  " -NoNewline
        Write-Host $Prompt -NoNewline -ForegroundColor Yellow
        Write-Host " (Esc to cancel)" -NoNewline -ForegroundColor DarkGray
        Write-Host " " -NoNewline
    }
    
    Write-Host $script:InputState.InputBuffer -NoNewline
    
    while ($true) {
        $keyInfo = Wait-KeyPress
        
        if ($keyInfo.Key -eq [ConsoleKey]::Enter) {
            Write-Host ""
            break
        }
        elseif ($keyInfo.Key -eq [ConsoleKey]::Escape) {
            $script:InputState.InputBuffer = ""
            Write-Host ""
            [Console]::CursorVisible = $false
            $script:InputState.IsInputMode = $false
            Clear-Line -LineIndex $separatorLine
            Clear-Line -LineIndex $promptLine
            return $null
        }
        elseif ($keyInfo.Key -eq [ConsoleKey]::Backspace) {
            if ($script:InputState.InputBuffer.Length -gt 0) {
                $script:InputState.InputBuffer = $script:InputState.InputBuffer.Substring(0, $script:InputState.InputBuffer.Length - 1)
                Write-Host "`b `b" -NoNewline
            }
        }
        else {
            $char = $keyInfo.KeyChar
            if ($char -ge ' ' -and $script:InputState.InputBuffer.Length -lt $MaxLength) {
                $script:InputState.InputBuffer += $char
                Write-Host $char -NoNewline
            }
        }
    }
    
    [Console]::CursorVisible = $false
    $script:InputState.IsInputMode = $false
    Clear-Line -LineIndex $separatorLine
    Clear-Line -LineIndex $promptLine
    
    return $script:InputState.InputBuffer
}

<#
.SYNOPSIS
    Handles navigation in a list
.PARAMETER KeyInfo
    The key info object
.PARAMETER CurrentIndex
    Current selected index
.PARAMETER MaxIndex
    Maximum valid index
#>
function Update-ListNavigation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$KeyInfo,
        
        [Parameter(Mandatory = $true)]
        [int]$CurrentIndex,
        
        [Parameter(Mandatory = $true)]
        [int]$MaxIndex
    )
    
    $newIndex = $CurrentIndex
    
    switch ($KeyInfo.Key) {
        "UpArrow" {
            $newIndex = [Math]::Max(0, $CurrentIndex - 1)
        }
        "DownArrow" {
            $newIndex = [Math]::Min($MaxIndex, $CurrentIndex + 1)
        }
        "PageUp" {
            $newIndex = [Math]::Max(0, $CurrentIndex - 10)
        }
        "PageDown" {
            $newIndex = [Math]::Min($MaxIndex, $CurrentIndex + 10)
        }
        "Home" {
            $newIndex = 0
        }
        "End" {
            $newIndex = $MaxIndex
        }
    }
    
    $script:InputState.SelectedIndex = $newIndex
    return $newIndex
}

<#
.SYNOPSIS
    Maps a menu key to a tool number
.PARAMETER KeyInfo
    The key info object
#>
function Get-ToolFromKey {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$KeyInfo
    )
    
    $char = $KeyInfo.KeyChar.ToString()
    
    switch ($char) {
        "1" { return 1 }
        "2" { return 2 }
        "3" { return 3 }
        "4" { return 4 }
        default { return 0 }
    }
}

<#
.SYNOPSIS
    Gets the action from a key press
.PARAMETER KeyInfo
    The key info object
#>
function Get-ActionFromKey {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$KeyInfo
    )
    
    $char = $KeyInfo.KeyChar.ToString().ToUpper()
    $key = $KeyInfo.Key
    
    # Check for quit
    if ($char -eq "Q" -or $key -eq [ConsoleKey]::Escape) {
        return "Quit"
    }
    
    # Check for save
    if ($char -eq "S") {
        return "Save"
    }
    
    # Check for refresh
    if ($char -eq "R" -or $key -eq [ConsoleKey]::F5) {
        return "Refresh"
    }
    
    # Check for help
    if ($char -eq "?" -or $key -eq [ConsoleKey]::F1) {
        return "Help"
    }
    
    # Check for watchlist
    if ($char -eq "W") {
        return "Watchlist"
    }
    
    # Check for add
    if ($char -eq "A") {
        return "Add"
    }
    
    # Check for delete
    if ($char -eq "D" -or $key -eq [ConsoleKey]::Delete) {
        return "Delete"
    }
    
    # Check for execute
    if ($char -eq "X" -or $key -eq [ConsoleKey]::Enter) {
        return "Execute"
    }
    
    # Check for tool selection
    $tool = Get-ToolFromKey -KeyInfo $KeyInfo
    if ($tool -gt 0) {
        return "Tool$tool"
    }
    
    # Navigation
    if ($key -eq [ConsoleKey]::UpArrow) {
        return "Up"
    }
    if ($key -eq [ConsoleKey]::DownArrow) {
        return "Down"
    }
    if ($key -eq [ConsoleKey]::PageUp) {
        return "PageUp"
    }
    if ($key -eq [ConsoleKey]::PageDown) {
        return "PageDown"
    }
    
    return "Unknown"
}

<#
.SYNOPSIS
    Gets the current input state
#>
function Get-InputState {
    return $script:InputState
}

<#
.SYNOPSIS
    Sets the selected index
.PARAMETER Index
    The new selected index
#>
function Set-SelectedIndex {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [int]$Index
    )
    
    $script:InputState.SelectedIndex = $Index
}

<#
.SYNOPSIS
    Gets the selected index
#>
function Get-SelectedIndex {
    return $script:InputState.SelectedIndex
}

<#
.SYNOPSIS
    Clears the input buffer
#>
function Clear-InputBuffer {
    $script:InputState.InputBuffer = ""
}

# Functions are available via dot-sourcing
