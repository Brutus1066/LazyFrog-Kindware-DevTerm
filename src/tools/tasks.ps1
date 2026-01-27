<#
.SYNOPSIS
    Task Runner Tool for LazyFrog Developer Tools
.DESCRIPTION
    Provides task execution, history tracking, and task management
    functionality for custom developer commands.
.AUTHOR
    Kindware.dev
.VERSION
    1.0.0
#>

$script:TaskState = @{
    Tasks         = @()
    History       = @()
    SelectedIndex = 0
    LastOutput    = ""
    IsRunning     = $false
}

<#
.SYNOPSIS
    Initializes the task runner with tasks from file
#>
function Initialize-TaskRunner {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TasksPath
    )
    
    if (Test-Path $TasksPath) {
        try {
            $config = Get-Content $TasksPath -Raw | ConvertFrom-Json
            $script:TaskState.Tasks = @($config.tasks)
            $script:TaskState.History = @($config.history)
        }
        catch {
            Write-Warning "Failed to load tasks: $_"
            $script:TaskState.Tasks = @()
            $script:TaskState.History = @()
        }
    }
    else {
        $script:TaskState.Tasks = @()
        $script:TaskState.History = @()
    }
}

<#
.SYNOPSIS
    Gets all configured tasks
#>
function Get-Tasks {
    return $script:TaskState.Tasks
}

<#
.SYNOPSIS
    Gets task execution history
#>
function Get-TaskHistory {
    return $script:TaskState.History
}

<#
.SYNOPSIS
    Executes a task by ID
#>
function Invoke-Task {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TaskId,
        
        [Parameter(Mandatory = $false)]
        [string]$WorkingDirectory = (Get-Location).Path
    )
    
    $task = $script:TaskState.Tasks | Where-Object { $_.id -eq $TaskId }
    
    if ($null -eq $task) {
        throw "Task with ID '$TaskId' not found"
    }
    
    $script:TaskState.IsRunning = $true
    $startTime = Get-Date
    
    try {
        $output = ""
        $exitCode = 0
        
        $previousLocation = Get-Location
        Set-Location $WorkingDirectory
        
        try {
            $output = Invoke-Expression $task.command 2>&1 | Out-String
            $exitCode = $LASTEXITCODE
            if ($null -eq $exitCode) { $exitCode = 0 }
        }
        catch {
            $output = $_.Exception.Message
            $exitCode = 1
        }
        finally {
            Set-Location $previousLocation
        }
        
        $endTime = Get-Date
        $duration = ($endTime - $startTime).TotalSeconds
        
        $historyEntry = @{
            taskId    = $TaskId
            taskName  = $task.name
            command   = $task.command
            output    = $output
            exitCode  = $exitCode
            startTime = $startTime.ToString("yyyy-MM-ddTHH:mm:ss")
            endTime   = $endTime.ToString("yyyy-MM-ddTHH:mm:ss")
            duration  = [Math]::Round($duration, 2)
            success   = ($exitCode -eq 0)
        }
        
        $script:TaskState.History = @($historyEntry) + @($script:TaskState.History) | Select-Object -First 100
        $script:TaskState.LastOutput = $output
        $script:TaskState.IsRunning = $false
        
        return $historyEntry
    }
    catch {
        $script:TaskState.IsRunning = $false
        throw "Task execution failed: $_"
    }
}

<#
.SYNOPSIS
    Formats tasks for TUI display
#>
function Format-Tasks {
    [CmdletBinding()]
    param()
    
    $lines = @()
    $lines += ""
    $lines += "  [TASKS] Task Runner"
    $lines += "  ====================================================="
    $lines += ""
    
    if ($script:TaskState.Tasks.Count -eq 0) {
        $lines += "  No tasks configured."
        $lines += ""
        $lines += "  Add tasks to tasks.json to get started."
        return $lines
    }
    
    $categories = $script:TaskState.Tasks | Group-Object -Property { if ($_.category) { $_.category } else { "General" } }
    
    $globalIndex = 0
    foreach ($category in $categories) {
        $lines += "  [FOLDER] $($category.Name)"
        $lines += "  ---------------------------------------------------"
        
        foreach ($task in $category.Group) {
            $prefix = if ($globalIndex -eq $script:TaskState.SelectedIndex) { " > " } else { "   " }
            $idPadded = "[$($task.id)]".PadRight(5)
            $lines += "$prefix$idPadded $($task.name)"
            
            if (-not [string]::IsNullOrEmpty($task.description)) {
                $lines += "         $($task.description)"
            }
            
            $globalIndex++
        }
        
        $lines += ""
    }
    
    $lines += "  -----------------------------------------------------"
    $lines += "  [Up/Down] Navigate  [Enter/X] Execute  [H] History  [A] Add"
    $lines += "  [E] Edit  [D] Delete  [Esc] Back"
    
    return $lines
}

<#
.SYNOPSIS
    Formats task history for TUI display
#>
function Format-TaskHistory {
    [CmdletBinding()]
    param()
    
    $lines = @()
    $lines += ""
    $lines += "  [HISTORY] Task History"
    $lines += "  ====================================================="
    $lines += ""
    
    if ($script:TaskState.History.Count -eq 0) {
        $lines += "  No task history available."
        $lines += ""
        $lines += "  Execute tasks to build history."
        return $lines
    }
    
    $recentHistory = $script:TaskState.History | Select-Object -First 10
    
    foreach ($entry in $recentHistory) {
        $status = if ($entry.success) { "[OK]" } else { "[X]" }
        $lines += "  $status $($entry.taskName)"
        $lines += "     Time: $($entry.duration)s | Date: $($entry.startTime.Substring(0,19))"
        $lines += ""
    }
    
    $lines += "  -----------------------------------------------------"
    $lines += "  [S] Save History  [C] Clear History  [Esc] Back"
    
    return $lines
}

<#
.SYNOPSIS
    Formats task output for TUI display
#>
function Format-TaskOutput {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$HistoryEntry
    )
    
    $lines = @()
    $lines += ""
    $lines += "  [OUTPUT] Task Output: $($HistoryEntry.taskName)"
    $lines += "  ====================================================="
    $lines += ""
    
    $status = if ($HistoryEntry.success) { "[OK] Success" } else { "[X] Failed (Exit: $($HistoryEntry.exitCode))" }
    $lines += "  Status: $status"
    $lines += "  Duration: $($HistoryEntry.duration) seconds"
    $lines += "  Command: $($HistoryEntry.command)"
    $lines += ""
    $lines += "  ---------------------------------------------------"
    $lines += "  Output:"
    $lines += ""
    
    $outputLines = $HistoryEntry.output -split "`n"
    foreach ($line in $outputLines) {
        $lines += "  $line"
    }
    
    $lines += ""
    $lines += "  -----------------------------------------------------"
    $lines += "  Press any key to continue..."
    
    return $lines
}

<#
.SYNOPSIS
    Adds a new task
#>
function Add-Task {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $true)]
        [string]$Command,
        
        [Parameter(Mandatory = $false)]
        [string]$Description = "",
        
        [Parameter(Mandatory = $false)]
        [string]$Category = "Custom",
        
        [Parameter(Mandatory = $true)]
        [string]$TasksPath
    )
    
    $maxId = 0
    foreach ($task in $script:TaskState.Tasks) {
        $taskId = [int]$task.id
        if ($taskId -gt $maxId) { $maxId = $taskId }
    }
    $newId = ($maxId + 1).ToString()
    
    $newTask = @{
        id          = $newId
        name        = $Name
        command     = $Command
        description = $Description
        category    = $Category
    }
    
    $script:TaskState.Tasks = @($script:TaskState.Tasks) + $newTask
    
    Save-Tasks -TasksPath $TasksPath
    
    return $newTask
}

<#
.SYNOPSIS
    Removes a task by ID
#>
function Remove-Task {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TaskId,
        
        [Parameter(Mandatory = $true)]
        [string]$TasksPath
    )
    
    $script:TaskState.Tasks = @($script:TaskState.Tasks | Where-Object { $_.id -ne $TaskId })
    
    Save-Tasks -TasksPath $TasksPath
}

<#
.SYNOPSIS
    Saves tasks to file
#>
function Save-Tasks {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TasksPath
    )
    
    $config = @{
        tasks   = $script:TaskState.Tasks
        history = $script:TaskState.History
    }
    
    try {
        $config | ConvertTo-Json -Depth 10 | Set-Content $TasksPath -Encoding UTF8
    }
    catch {
        throw "Failed to save tasks: $_"
    }
}

<#
.SYNOPSIS
    Saves task history to JSON file
#>
function Save-TaskHistory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd-HHmmss"
    $filename = "task-history-$timestamp.json"
    $filepath = Join-Path $OutputPath $filename
    
    try {
        if (-not (Test-Path $OutputPath)) {
            New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
        }
        
        $script:TaskState.History | ConvertTo-Json -Depth 10 | Set-Content $filepath -Encoding UTF8
        return $filepath
    }
    catch {
        throw "Failed to save history: $_"
    }
}

<#
.SYNOPSIS
    Clears task history
#>
function Clear-TaskHistory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TasksPath
    )
    
    $script:TaskState.History = @()
    Save-Tasks -TasksPath $TasksPath
}

<#
.SYNOPSIS
    Sets the selected task index
#>
function Set-TaskSelectedIndex {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [int]$Index
    )
    
    $maxIndex = $script:TaskState.Tasks.Count - 1
    if ($maxIndex -lt 0) { $maxIndex = 0 }
    
    $script:TaskState.SelectedIndex = [Math]::Max(0, [Math]::Min($Index, $maxIndex))
}

<#
.SYNOPSIS
    Gets the currently selected task
#>
function Get-SelectedTask {
    if ($script:TaskState.Tasks.Count -eq 0) {
        return $null
    }
    
    return $script:TaskState.Tasks[$script:TaskState.SelectedIndex]
}

<#
.SYNOPSIS
    Gets the task state
#>
function Get-TaskState {
    return $script:TaskState
}

# Functions are available via dot-sourcing
