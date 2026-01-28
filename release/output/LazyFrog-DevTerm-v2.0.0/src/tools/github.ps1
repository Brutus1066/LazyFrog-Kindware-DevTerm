<#
.SYNOPSIS
    GitHub Scanner Tool for LazyFrog Developer Tools
.DESCRIPTION
    Provides GitHub repository search, results display, saving to JSON/Markdown,
    and watchlist management functionality.
.AUTHOR
    Kindware.dev
.VERSION
    1.0.0
#>

$script:GitHubState = @{
    LastSearchTerm   = ""
    LastResults      = @()
    SelectedIndex    = 0
    IsSearching      = $false
    ErrorMessage     = ""
    WatchlistPath    = ""
}

<#
.SYNOPSIS
    Initializes the GitHub Scanner
#>
function Initialize-GitHubScanner {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$WatchlistPath
    )
    
    $script:GitHubState.WatchlistPath = $WatchlistPath
}

<#
.SYNOPSIS
    Searches GitHub repositories by keyword
#>
function Search-GitHubRepositories {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SearchTerm,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("stars", "forks", "updated")]
        [string]$Sort = "stars",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("desc", "asc")]
        [string]$Order = "desc",
        
        [Parameter(Mandatory = $false)]
        [int]$PerPage = 10
    )
    
    $script:GitHubState.IsSearching = $true
    $script:GitHubState.ErrorMessage = ""
    $script:GitHubState.LastSearchTerm = $SearchTerm
    
    try {
        $encodedTerm = [System.Web.HttpUtility]::UrlEncode($SearchTerm)
        $apiUrl = "https://api.github.com/search/repositories?q=$encodedTerm&sort=$Sort&order=$Order&per_page=$PerPage"
        
        $headers = @{
            "Accept"     = "application/vnd.github.v3+json"
            "User-Agent" = "LazyFrog-DevTerm/1.0"
        }
        
        $response = Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method Get -ErrorAction Stop
        
        $results = @()
        foreach ($repo in $response.items) {
            $results += [PSCustomObject]@{
                Name        = $repo.full_name
                Description = if ($repo.description) { 
                    if ($repo.description.Length -gt 60) { 
                        $repo.description.Substring(0, 57) + "..." 
                    } else { 
                        $repo.description 
                    }
                } else { "No description" }
                Stars       = $repo.stargazers_count
                Forks       = $repo.forks_count
                Language    = if ($repo.language) { $repo.language } else { "N/A" }
                UpdatedAt   = ([datetime]$repo.updated_at).ToString("yyyy-MM-dd")
                Url         = $repo.html_url
                Owner       = $repo.owner.login
                License     = if ($repo.license) { $repo.license.spdx_id } else { "N/A" }
                Topics      = if ($repo.topics) { $repo.topics -join ", " } else { "" }
                OpenIssues  = $repo.open_issues_count
            }
        }
        
        $script:GitHubState.LastResults = $results
        $script:GitHubState.IsSearching = $false
        
        return $results
    }
    catch {
        $script:GitHubState.ErrorMessage = "Search failed: $($_.Exception.Message)"
        $script:GitHubState.IsSearching = $false
        $script:GitHubState.LastResults = @()
        return @()
    }
}

<#
.SYNOPSIS
    Gets the last search results
#>
function Get-LastSearchResults {
    return $script:GitHubState.LastResults
}

<#
.SYNOPSIS
    Gets the current GitHub state
#>
function Get-GitHubState {
    return $script:GitHubState
}

<#
.SYNOPSIS
    Formats search results for TUI display
#>
function Format-GitHubResults {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [AllowEmptyCollection()]
        [array]$Results = $null
    )
    
    # Use state results if not provided
    if ($null -eq $Results) {
        $Results = @($script:GitHubState.LastResults)
    }
    
    $lines = @()
    $lines += ""
    $lines += "  GitHub Repository Search Results"
    $lines += "  ====================================================="
    $lines += ""
    
    if ($Results.Count -eq 0) {
        if (-not [string]::IsNullOrEmpty($script:GitHubState.ErrorMessage)) {
            $lines += "  [X] $($script:GitHubState.ErrorMessage)"
        }
        elseif ([string]::IsNullOrEmpty($script:GitHubState.LastSearchTerm)) {
            $lines += "  Press [S] to search GitHub repositories..."
        }
        else {
            $lines += "  No results found."
        }
        $lines += ""
        $lines += "  Press [S] to search..."
        return $lines
    }
    
    $index = 0
    foreach ($repo in $Results) {
        $prefix = if ($index -eq $script:GitHubState.SelectedIndex) { " > " } else { "   " }
        
        $lines += "$prefix+--------------------------------------------------"
        $lines += "$prefix| [*] $($repo.Stars.ToString().PadRight(8)) $($repo.Name)"
        $lines += "$prefix| Updated: $($repo.UpdatedAt)  Lang: $($repo.Language)"
        
        if (-not [string]::IsNullOrEmpty($repo.Description)) {
            $lines += "$prefix| $($repo.Description)"
        }
        
        $lines += "$prefix+--------------------------------------------------"
        $lines += ""
        $index++
    }
    
    $lines += "  -----------------------------------------------------"
    $lines += "  [Up/Down] Navigate  [W] Add to Watchlist  [S] Save Results"
    $lines += "  [Enter] Open in Browser  [Esc] Back"
    
    return $lines
}

<#
.SYNOPSIS
    Saves search results to JSON file
#>
function Save-ResultsToJson {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [array]$Results = $null,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )

    if ($null -eq $Results -or $Results.Count -eq 0) {
        $Results = @($script:GitHubState.LastResults)
    }
    
    $timestamp = Get-Date -Format "yyyy-MM-dd-HHmmss"
    $filename = "github-search-$timestamp.json"
    $filepath = Join-Path $OutputPath $filename
    
    $exportData = @{
        searchTerm = $script:GitHubState.LastSearchTerm
        timestamp  = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss")
        count      = $Results.Count
        results    = $Results
    }
    
    try {
        if (-not (Test-Path $OutputPath)) {
            New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
        }
        
        $exportData | ConvertTo-Json -Depth 10 | Set-Content $filepath -Encoding UTF8
        return $filepath
    }
    catch {
        throw "Failed to save JSON: $_"
    }
}

<#
.SYNOPSIS
    Saves search results to Markdown file
#>
function Save-ResultsToMarkdown {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [array]$Results = $null,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )

    if ($null -eq $Results -or $Results.Count -eq 0) {
        $Results = @($script:GitHubState.LastResults)
    }
    
    $timestamp = Get-Date -Format "yyyy-MM-dd-HHmmss"
    $filename = "github-search-$timestamp.md"
    $filepath = Join-Path $OutputPath $filename
    
    $markdown = @()
    $markdown += "# GitHub Search Results"
    $markdown += ""
    $markdown += "**Search Term:** $($script:GitHubState.LastSearchTerm)"
    $markdown += "**Date:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    $markdown += "**Results:** $($Results.Count)"
    $markdown += ""
    $markdown += "---"
    $markdown += ""
    $markdown += "| Repository | Stars | Language | Updated |"
    $markdown += "|------------|-------|----------|---------|"
    
    foreach ($repo in $Results) {
        $markdown += "| [$($repo.Name)]($($repo.Url)) | $($repo.Stars) | $($repo.Language) | $($repo.UpdatedAt) |"
    }
    
    $markdown += ""
    $markdown += "---"
    $markdown += ""
    $markdown += "## Details"
    $markdown += ""
    
    foreach ($repo in $Results) {
        $markdown += "### $($repo.Name)"
        $markdown += ""
        $markdown += "- **URL:** $($repo.Url)"
        $markdown += "- **Stars:** $($repo.Stars)"
        $markdown += "- **Forks:** $($repo.Forks)"
        $markdown += "- **Language:** $($repo.Language)"
        $markdown += "- **License:** $($repo.License)"
        $markdown += "- **Last Updated:** $($repo.UpdatedAt)"
        $markdown += "- **Open Issues:** $($repo.OpenIssues)"
        $markdown += ""
        $markdown += "> $($repo.Description)"
        $markdown += ""
    }
    
    $markdown += "---"
    $markdown += "*Generated by LazyFrog Developer Tools*"
    
    try {
        if (-not (Test-Path $OutputPath)) {
            New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
        }
        
        $markdown -join "`n" | Set-Content $filepath -Encoding UTF8
        return $filepath
    }
    catch {
        throw "Failed to save Markdown: $_"
    }
}

<#
.SYNOPSIS
    Adds a repository to the watchlist
#>
function Add-ToWatchlist {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Repository,
        
        [Parameter(Mandatory = $true)]
        [string]$WatchlistPath
    )
    
    try {
        $watchlist = @{ watchlist = @(); lastUpdated = $null }
        
        if (Test-Path $WatchlistPath) {
            $watchlist = Get-Content $WatchlistPath -Raw | ConvertFrom-Json
            if ($null -eq $watchlist.watchlist) {
                $watchlist = @{ watchlist = @(); lastUpdated = $null }
            }
        }
        
        $existing = $watchlist.watchlist | Where-Object { $_.Name -eq $Repository.Name }
        if ($existing) {
            return $false
        }
        
        $watchlistItem = @{
            Name        = $Repository.Name
            Url         = $Repository.Url
            Stars       = $Repository.Stars
            Language    = $Repository.Language
            AddedAt     = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss")
            Description = $Repository.Description
        }
        
        $newWatchlist = @($watchlist.watchlist) + $watchlistItem
        
        $watchlist = @{
            watchlist   = $newWatchlist
            lastUpdated = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss")
        }
        
        $watchlist | ConvertTo-Json -Depth 10 | Set-Content $WatchlistPath -Encoding UTF8
        return $true
    }
    catch {
        throw "Failed to add to watchlist: $_"
    }
}

<#
.SYNOPSIS
    Gets the watchlist
#>
function Get-Watchlist {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$WatchlistPath
    )
    
    if (Test-Path $WatchlistPath) {
        try {
            $watchlist = Get-Content $WatchlistPath -Raw | ConvertFrom-Json
            return $watchlist.watchlist
        }
        catch {
            return @()
        }
    }
    
    return @()
}

<#
.SYNOPSIS
    Removes a repository from the watchlist
#>
function Remove-FromWatchlist {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepositoryName,
        
        [Parameter(Mandatory = $true)]
        [string]$WatchlistPath
    )
    
    try {
        if (-not (Test-Path $WatchlistPath)) {
            return $false
        }
        
        $watchlist = Get-Content $WatchlistPath -Raw | ConvertFrom-Json
        $newWatchlist = $watchlist.watchlist | Where-Object { $_.Name -ne $RepositoryName }
        
        $watchlist = @{
            watchlist   = @($newWatchlist)
            lastUpdated = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss")
        }
        
        $watchlist | ConvertTo-Json -Depth 10 | Set-Content $WatchlistPath -Encoding UTF8
        return $true
    }
    catch {
        throw "Failed to remove from watchlist: $_"
    }
}

<#
.SYNOPSIS
    Formats watchlist for TUI display
#>
function Format-Watchlist {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [array]$Watchlist
    )
    
    $lines = @()
    $lines += ""
    $lines += "  [LIST] Repository Watchlist"
    $lines += "  ====================================================="
    $lines += ""
    
    if ($Watchlist.Count -eq 0) {
        $lines += "  No repositories in watchlist."
        $lines += ""
        $lines += "  Add repositories using [W] from search results."
        return $lines
    }
    
    $index = 0
    foreach ($repo in $Watchlist) {
        $prefix = if ($index -eq $script:GitHubState.SelectedIndex) { " > " } else { "   " }
        
        $lines += "$prefix+--------------------------------------------------"
        $lines += "$prefix| [*] $($repo.Stars.ToString().PadRight(8)) $($repo.Name)"
        $lines += "$prefix| Lang: $($repo.Language)  Added: $($repo.AddedAt.Substring(0,10))"
        $lines += "$prefix+--------------------------------------------------"
        $lines += ""
        $index++
    }
    
    $lines += "  -----------------------------------------------------"
    $lines += "  [Up/Down] Navigate  [D] Remove  [Enter] Open  [Esc] Back"
    
    return $lines
}

<#
.SYNOPSIS
    Sets the selected index for navigation
#>
function Set-GitHubSelectedIndex {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [int]$Index
    )
    
    $maxIndex = $script:GitHubState.LastResults.Count - 1
    if ($maxIndex -lt 0) { $maxIndex = 0 }
    
    $script:GitHubState.SelectedIndex = [Math]::Max(0, [Math]::Min($Index, $maxIndex))
}

<#
.SYNOPSIS
    Gets the currently selected repository
#>
function Get-SelectedRepository {
    if ($script:GitHubState.LastResults.Count -eq 0) {
        return $null
    }
    
    return $script:GitHubState.LastResults[$script:GitHubState.SelectedIndex]
}

<#
.SYNOPSIS
    Opens a repository URL in the default browser
#>
function Open-RepositoryInBrowser {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Url
    )
    
    Start-Process $Url
}

# Functions are available via dot-sourcing
