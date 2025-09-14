#Requires -Version 5.0

<#
.SYNOPSIS
    Claude Code Status Line - Displays intelligent project context for development
    
.DESCRIPTION
    Displays project context including Git branch, recently accessed files, and Claude model
    information. Fully customizable through JSON configuration with built-in presets.
    
.NOTES
    Version: 2.1
    Author: HollowTheSilver
    Requires: PowerShell 5.1+, Git (optional)
#>

using namespace System.IO
using namespace System.Collections.Generic

[CmdletBinding()]
param()

#region Configuration Functions

function Get-StatusLineConfiguration {
    <#
    .SYNOPSIS
        Loads and merges status line configuration from JSON files
        
    .DESCRIPTION
        Loads configuration from statusline-config.json and applies preset overrides.
        Falls back to hardcoded defaults if configuration loading fails.
        
    .PARAMETER ConfigPath
        Path to the main configuration file
        
    .PARAMETER ScriptDirectory
        Directory containing the script and preset files
        
    .OUTPUTS
        PSCustomObject - Complete configuration object
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({ Test-Path (Split-Path $_) -PathType Container })]
        [string]$ConfigPath,
        
        [Parameter(Mandatory)]
        [ValidateScript({ Test-Path $_ -PathType Container })]
        [string]$ScriptDirectory
    )
    
    Write-Verbose "Loading configuration from: $ConfigPath"
    
    # Load base configuration
    $config = Get-ConfigurationFromFile -Path $ConfigPath
    
    # Apply preset if specified
    if ($config -and $config.preset -and $config.preset -ne 'default') {
        Write-Verbose "Applying preset: $($config.preset)"
        $presetPath = Join-Path $ScriptDirectory "presets" "$($config.preset).json"
        $presetConfig = Get-ConfigurationFromFile -Path $presetPath
        
        if ($presetConfig) {
            $config = $presetConfig
        }
    }
    
    # Return default configuration if loading failed
    if (-not $config) {
        Write-Verbose "Using default configuration"
        $config = Get-DefaultConfiguration
    }
    
    return $config
}

function Get-ConfigurationFromFile {
    <#
    .SYNOPSIS
        Loads configuration from a JSON file with proper error handling
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )
    
    if (-not (Test-Path $Path)) {
        Write-Verbose "Configuration file not found: $Path"
        return $null
    }
    
    try {
        $content = Get-Content $Path -Raw -ErrorAction Stop
        $config = $content | ConvertFrom-Json -ErrorAction Stop
        Write-Verbose "Successfully loaded configuration from: $Path"
        return $config
    }
    catch [System.ArgumentException] {
        Write-Warning "Invalid JSON in configuration file: $Path"
        return $null
    }
    catch {
        Write-Warning "Failed to load configuration from ${Path}: $($_.Exception.Message)"
        return $null
    }
}

function Get-DefaultConfiguration {
    <#
    .SYNOPSIS
        Returns the default hardcoded configuration
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()
    
    return [PSCustomObject]@{
        format = [PSCustomObject]@{
            layout = 'two-line'
            separator = ' -> '
            showLabels = $true
            components = [PSCustomObject]@{
                project = [PSCustomObject]@{ show = $true; label = ''; position = 1 }
                branch = [PSCustomObject]@{ show = $true; label = 'Branch:'; position = 2 }
                modified = [PSCustomObject]@{ show = $true; label = 'Modified:'; position = 3 }
                model = [PSCustomObject]@{ show = $true; position = 'line2' }
            }
        }
        technical = [PSCustomObject]@{
            maxDepth = 5
            pathShortening = 3
            timeWindow = 30
        }
        colors = [PSCustomObject]@{ enabled = $false }
    }
}

#endregion

#region Input Processing Functions

function Read-ClaudeCodeInput {
    <#
    .SYNOPSIS
        Reads and parses JSON input from Claude Code via stdin

    .DESCRIPTION
        Uses multiple methods to reliably read JSON input from stdin, with proper
        error handling and validation.

    .OUTPUTS
        PSCustomObject - Parsed JSON input from Claude Code, or $null if no input
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()

    Write-Verbose "Reading JSON input from stdin"

    $inputText = ''
    $debugMode = $env:STATUSLINE_DEBUG -eq 'true'

    # Method 1: Try Console.In with timeout
    try {
        $available = $false
        $attempts = 0
        while ($attempts -lt 3) {
            if ([Console]::In.Peek() -ne -1) {
                $available = $true
                break
            }
            Start-Sleep -Milliseconds 50
            $attempts++
        }

        if ($available) {
            $inputText = [Console]::In.ReadToEnd()
            Write-Verbose "Read $($inputText.Length) characters via Console.In"
            if ($debugMode) {
                Write-Host "[DEBUG] Console.In read: $($inputText.Substring(0, [Math]::Min(100, $inputText.Length)))..." -ForegroundColor DarkGray
            }
        }
    }
    catch {
        Write-Verbose "Console.In method failed: $($_.Exception.Message)"
        if ($debugMode) {
            Write-Host "[DEBUG] Console.In failed: $($_.Exception.Message)" -ForegroundColor DarkGray
        }
    }

    # Method 2: Try reading from pipeline
    if (-not $inputText -or $inputText.Trim() -eq '') {
        try {
            $pipelineInput = @($input)
            if ($pipelineInput.Count -gt 0) {
                $inputText = $pipelineInput -join "`n"
                Write-Verbose "Read input via pipeline"
                if ($debugMode) {
                    Write-Host "[DEBUG] Pipeline read: $($inputText.Substring(0, [Math]::Min(100, $inputText.Length)))..." -ForegroundColor DarkGray
                }
            }
        }
        catch {
            Write-Verbose "Pipeline method failed: $($_.Exception.Message)"
        }
    }

    # Method 3: Try automatic variable as last resort (skip if it would interfere)
    if (-not $inputText -or $inputText.Trim() -eq '') {
        try {
            # Check if $input exists and has content
            if ($null -ne $input -and @($input).Count -gt 0) {
                $tempInput = $input | Out-String
                # Only use if it looks like JSON
                if ($tempInput -and $tempInput.Trim().StartsWith('{')) {
                    $inputText = $tempInput
                    Write-Verbose "Read input via automatic variable"
                    if ($debugMode) {
                        Write-Host "[DEBUG] Automatic input read: $($inputText.Substring(0, [Math]::Min(100, $inputText.Length)))..." -ForegroundColor DarkGray
                    }
                }
            }
        }
        catch {
            Write-Verbose "Automatic variable method failed: $($_.Exception.Message)"
        }
    }

    # Parse JSON if we have input
    if ($inputText -and $inputText.Trim()) {
        try {
            $parsedInput = $inputText | ConvertFrom-Json -ErrorAction Stop
            Write-Verbose "Successfully parsed JSON input"
            if ($debugMode) {
                Write-Host "[DEBUG] Parsed model: $($parsedInput.model.display_name)" -ForegroundColor DarkGray
                Write-Host "[DEBUG] Parsed workspace: $($parsedInput.workspace.current_dir)" -ForegroundColor DarkGray
            }
            return $parsedInput
        }
        catch [System.ArgumentException] {
            Write-Warning "Invalid JSON received from Claude Code"
            if ($debugMode) {
                Write-Host "[DEBUG] Invalid JSON: $inputText" -ForegroundColor Red
            }
            return $null
        }
        catch {
            Write-Warning "Failed to parse Claude Code input: $($_.Exception.Message)"
            if ($debugMode) {
                Write-Host "[DEBUG] Parse error: $($_.Exception.Message)" -ForegroundColor Red
            }
            return $null
        }
    }

    Write-Verbose "No input received from Claude Code"
    if ($debugMode) {
        Write-Host "[DEBUG] No input received from stdin" -ForegroundColor Yellow
    }
    return $null
}

function Get-ModelName {
    <#
    .SYNOPSIS
        Extracts the Claude model name from parsed input
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter()]
        [PSCustomObject]$InputData
    )

    $debugMode = $env:STATUSLINE_DEBUG -eq 'true'

    if (-not $InputData) {
        if ($debugMode) {
            Write-Host "[DEBUG] No input data for model detection, using default" -ForegroundColor Yellow
        }
        return 'Claude Sonnet 4'
    }

    # Try multiple possible locations for model information
    $modelName = if ($InputData.model -and $InputData.model.display_name) {
        "Claude $($InputData.model.display_name)"
    }
    elseif ($InputData.model -and $InputData.model.name) {
        "Claude $($InputData.model.name)"
    }
    elseif ($InputData.modelName) {
        $InputData.modelName
    }
    elseif ($InputData.model) {
        # Handle case where model is just a string
        if ($InputData.model -is [string]) {
            $InputData.model
        } else {
            'Claude Sonnet 4'
        }
    }
    else {
        'Claude Sonnet 4'
    }

    Write-Verbose "Detected model: $modelName"
    if ($debugMode) {
        Write-Host "[DEBUG] Model name resolved to: $modelName" -ForegroundColor DarkGray
    }
    return $modelName
}

function Get-WorkingDirectory {
    <#
    .SYNOPSIS
        Determines the current working directory from input or environment
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter()]
        [PSCustomObject]$InputData
    )
    
    $workingDir = if ($InputData -and $InputData.workspace -and $InputData.workspace.current_dir) {
        $InputData.workspace.current_dir
    }
    else {
        $PWD.Path
    }
    
    Write-Verbose "Working directory: $workingDir"
    return $workingDir
}

#endregion

#region Git Operations

function Get-GitRepositoryInfo {
    <#
    .SYNOPSIS
        Retrieves Git repository information including root path and branch
        Handles both single repos and multi-repo projects

    .PARAMETER Path
        Directory path to analyze for Git repository

    .OUTPUTS
        Hashtable with GitRoot and Branch properties, or $null if not a Git repository
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({ Test-Path $_ -PathType Container })]
        [string]$Path
    )

    Write-Verbose "Searching for Git repository from: $Path"

    # First check if current path or any parent is a Git repo
    $gitRoot = $Path
    while ($gitRoot) {
        $gitDir = Join-Path $gitRoot '.git'
        if (Test-Path $gitDir) {
            Write-Verbose "Found Git repository at: $gitRoot"
            $branch = Get-GitBranch -RepositoryPath $gitRoot
            return @{
                GitRoot = $gitRoot
                Branch = $branch
            }
        }

        $parent = Split-Path $gitRoot -Parent
        if ($parent -eq $gitRoot -or [string]::IsNullOrWhiteSpace($parent)) {
            break
        }
        $gitRoot = $parent
    }

    # If no parent repo found, check for multi-repo structure (subdirectories with .git)
    Write-Verbose "Checking for multi-repo structure in: $Path"
    $subRepos = @()

    try {
        $subdirs = Get-ChildItem $Path -Directory -ErrorAction SilentlyContinue
        foreach ($dir in $subdirs) {
            $subGitDir = Join-Path $dir.FullName '.git'
            if (Test-Path $subGitDir) {
                Write-Verbose "Found sub-repository: $($dir.Name)"
                $subRepos += $dir
            }
        }
    }
    catch {
        Write-Verbose "Error checking subdirectories: $($_.Exception.Message)"
    }

    if ($subRepos.Count -gt 0) {
        # Use the most recently modified sub-repo for branch info
        $mostRecentRepo = $subRepos | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        Write-Verbose "Using most recent sub-repo: $($mostRecentRepo.Name)"

        $branch = Get-GitBranch -RepositoryPath $mostRecentRepo.FullName

        # Return the parent directory as the "project" but with branch from sub-repo
        return @{
            GitRoot = $Path  # Use parent as project root
            Branch = $branch
            IsMultiRepo = $true
            ActiveRepo = $mostRecentRepo.Name
        }
    }

    Write-Verbose "No Git repository found"
    return $null
}

function Get-GitBranch {
    <#
    .SYNOPSIS
        Gets the current Git branch name using git command
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({
            if ([string]::IsNullOrWhiteSpace($_)) {
                throw "Repository path cannot be empty"
            }
            if (-not (Test-Path $_ -PathType Container)) {
                throw "Repository path does not exist: $_"
            }
            $true
        })]
        [string]$RepositoryPath
    )
    
    # Verify git command is available
    $gitCommand = Get-Command git -ErrorAction SilentlyContinue
    if (-not $gitCommand) {
        Write-Verbose "Git command not found"
        return 'no-git'
    }
    
    try {
        $branch = & git -C $RepositoryPath branch --show-current 2>$null
        if ($LASTEXITCODE -eq 0 -and $branch) {
            $branchName = $branch.Trim()
            Write-Verbose "Git branch: $branchName"
            return $branchName
        }
        else {
            Write-Verbose "Git command failed or returned empty result"
            return 'main'
        }
    }
    catch {
        Write-Warning "Git command execution failed: $($_.Exception.Message)"
        return 'main'
    }
}

#endregion

#region File System Operations

function Get-RecentFileInfo {
    <#
    .SYNOPSIS
        Finds the most recently modified file in the project with intelligent depth handling

    .PARAMETER Path
        Root directory to search

    .PARAMETER MaxDepth
        Maximum directory depth to search

    .PARAMETER PathShortening
        Number of path segments before applying shortening

    .OUTPUTS
        Hashtable with ModifiedFile and HasDeepFiles properties
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({ Test-Path $_ -PathType Container })]
        [string]$Path,

        [Parameter(Mandatory)]
        [ValidateRange(1, 10)]
        [int]$MaxDepth,

        [Parameter(Mandatory)]
        [ValidateRange(1, 10)]
        [int]$PathShortening
    )

    Write-Verbose "Searching for recent files (depth: $MaxDepth, shortening: $PathShortening)"
    $debugMode = $env:STATUSLINE_DEBUG -eq 'true'

    $result = @{
        ModifiedFile = $null
        HasDeepFiles = $false
    }

    try {
        # First, try with full depth search
        $searchParams = @{
            Path = $Path
            File = $true
            Recurse = $true
            ErrorAction = 'SilentlyContinue'
        }

        # Add Depth parameter only if PowerShell version supports it
        if ($PSVersionTable.PSVersion.Major -ge 5) {
            $searchParams['Depth'] = $MaxDepth
        }

        if ($debugMode) {
            Write-Host "[DEBUG] Searching for files in: $Path (MaxDepth: $MaxDepth)" -ForegroundColor DarkGray
        }

        # Collect files with error handling for access denied
        $files = @()
        $errorCount = 0

        try {
            $files = Get-ChildItem @searchParams | Where-Object {
                # Filter out system/hidden files that might cause issues
                -not ($_.Attributes -band [System.IO.FileAttributes]::Hidden) -and
                -not ($_.Attributes -band [System.IO.FileAttributes]::System)
            }
        }
        catch {
            $errorCount++
            if ($debugMode) {
                Write-Host "[DEBUG] Error during file search: $($_.Exception.Message)" -ForegroundColor Yellow
            }
        }

        if ($files.Count -gt 0) {
            # Sort by LastWriteTime and get the most recent
            $mostRecentFile = $files | Sort-Object LastWriteTime -Descending | Select-Object -First 1
            $result.ModifiedFile = Format-RelativePath -FilePath $mostRecentFile.FullName -BasePath $Path -MaxSegments $PathShortening

            Write-Verbose "Most recently modified file: $($result.ModifiedFile)"
            if ($debugMode) {
                Write-Host "[DEBUG] Found $($files.Count) files, most recent: $($result.ModifiedFile)" -ForegroundColor DarkGray
                Write-Host "[DEBUG] Last modified: $($mostRecentFile.LastWriteTime)" -ForegroundColor DarkGray
            }
        }
        else {
            if ($debugMode) {
                Write-Host "[DEBUG] No files found in search" -ForegroundColor Yellow
            }
        }

        # Check for files beyond our search depth
        $result.HasDeepFiles = Test-DeepDirectoryContent -Path $Path -MaxDepth $MaxDepth

    }
    catch [UnauthorizedAccessException] {
        Write-Verbose "Access denied to some directories in $Path"
        if ($debugMode) {
            Write-Host "[DEBUG] Access denied error, trying fallback search" -ForegroundColor Yellow
        }

        # Fallback: Try searching only in accessible top-level directories
        try {
            $accessibleDirs = @($Path)
            $subdirs = Get-ChildItem $Path -Directory -ErrorAction SilentlyContinue |
                       Where-Object { $_.Name -notmatch '^\.' } # Skip hidden directories

            foreach ($dir in $subdirs) {
                try {
                    $testAccess = Get-ChildItem $dir.FullName -File -ErrorAction Stop | Select-Object -First 1
                    $accessibleDirs += $dir.FullName
                }
                catch {
                    # Skip inaccessible directories
                }
            }

            $files = @()
            foreach ($dir in $accessibleDirs) {
                $dirFiles = Get-ChildItem $dir -File -ErrorAction SilentlyContinue
                if ($dirFiles) {
                    $files += $dirFiles
                }
            }

            if ($files.Count -gt 0) {
                $mostRecentFile = $files | Sort-Object LastWriteTime -Descending | Select-Object -First 1
                $result.ModifiedFile = Format-RelativePath -FilePath $mostRecentFile.FullName -BasePath $Path -MaxSegments $PathShortening
            }
        }
        catch {
            Write-Verbose "Fallback search also failed: $($_.Exception.Message)"
        }
    }
    catch {
        Write-Verbose "File search failed: $($_.Exception.Message)"
        if ($debugMode) {
            Write-Host "[DEBUG] Unexpected error in file search: $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    # Provide default if no file found
    if (-not $result.ModifiedFile) {
        $fallbackFile = if ($result.HasDeepFiles) { '.../' } else { 'no recent files' }
        $result.ModifiedFile = $fallbackFile
        if ($debugMode) {
            Write-Host "[DEBUG] Using fallback file indicator: $fallbackFile" -ForegroundColor Yellow
        }
    }

    return $result
}

function Format-RelativePath {
    <#
    .SYNOPSIS
        Formats a file path as relative to base path with intelligent shortening
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$FilePath,
        
        [Parameter(Mandatory)]
        [string]$BasePath,
        
        [Parameter(Mandatory)]
        [int]$MaxSegments
    )
    
    if (-not $FilePath.StartsWith($BasePath)) {
        return [Path]::GetFileName($FilePath)
    }
    
    # Convert to relative path with forward slashes
    $relativePath = $FilePath.Substring($BasePath.Length).TrimStart('\', '/') -replace '\\', '/'
    
    if (-not $relativePath) {
        return [Path]::GetFileName($FilePath)
    }
    
    # Apply intelligent shortening
    $pathSegments = $relativePath -split '/' | Where-Object { $_ -and $_.Length -gt 0 }
    
    if ($pathSegments.Count -gt $MaxSegments) {
        # Format: first/../second-to-last/last
        return "$($pathSegments[0])/../$($pathSegments[-2])/$($pathSegments[-1])"
    }
    
    return $relativePath
}

function Test-DeepDirectoryContent {
    <#
    .SYNOPSIS
        Tests if there are directories/files beyond the specified depth
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        
        [Parameter(Mandatory)]
        [int]$MaxDepth
    )
    
    try {
        $deepDirs = Get-ChildItem $Path -Directory -Recurse -Depth $MaxDepth -ErrorAction SilentlyContinue |
            Where-Object {
                $pathDepth = ($_.FullName.Replace($Path, '').TrimStart('\', '/') -split '[\\\/]').Length
                $pathDepth -eq $MaxDepth
            }
        
        foreach ($dir in $deepDirs) {
            $hasContent = Get-ChildItem $dir.FullName -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($hasContent) {
                return $true
            }
        }
    }
    catch {
        Write-Verbose "Deep directory test failed: $($_.Exception.Message)"
    }
    
    return $false
}

#endregion

#region Output Formatting

function Build-StatusLine {
    <#
    .SYNOPSIS
        Builds the formatted status line output based on configuration
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Configuration,
        
        [Parameter(Mandatory)]
        [hashtable]$Data
    )
    
    Write-Verbose "Building status line with layout: $($Configuration.format.layout)"
    
    $components = [List[string]]::new()
    
    # Build line 1 components
    $sortedComponents = $Configuration.format.components.PSObject.Properties |
        Where-Object { $_.Value.show -eq $true -and $_.Value.position -ne 'line2' } |
        Sort-Object { $_.Value.position }
    
    foreach ($component in $sortedComponents) {
        $componentName = $component.Name
        $settings = $component.Value
        
        $value = switch ($componentName) {
            'project' { $Data.ProjectName }
            'branch' { $Data.Branch }
            'modified' { $Data.ModifiedFile }
            default { $null }
        }
        
        if ($value) {
            $formattedComponent = Format-Component -Value $value -Settings $settings
            $components.Add($formattedComponent)
        }
    }
    
    # Build output lines
    $line1 = $components -join $Configuration.format.separator
    
    $line2 = if ($Configuration.format.components.model.show) {
        Format-Component -Value $Data.ModelName -Settings $Configuration.format.components.model
    } else { '' }
    
    # Handle layout
    if ($Configuration.format.layout -eq 'one-line') {
        if ($line2) {
            $line1 = $line1 + $Configuration.format.separator + $line2
        }
        return @($line1, '')
    }
    
    return @($line1, $line2)
}

function Format-Component {
    <#
    .SYNOPSIS
        Formats a single component with label and suffix
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$Value,
        
        [Parameter(Mandatory)]
        [PSCustomObject]$Settings
    )
    
    $result = ''
    
    if ($Settings.label) {
        $result += $Settings.label + ' '
    }
    
    $result += $Value
    
    if ($Settings.suffix) {
        $result += $Settings.suffix
    }
    
    return $result
}

#endregion

#region Main Execution

try {
    Write-Verbose "Claude Code Status Line v2.1 starting"
    $debugMode = $env:STATUSLINE_DEBUG -eq 'true'

    if ($debugMode) {
        Write-Host "[DEBUG] Starting status line generation" -ForegroundColor Cyan
        Write-Host "[DEBUG] Script directory: $PSScriptRoot" -ForegroundColor DarkGray
        Write-Host "[DEBUG] Current directory: $PWD" -ForegroundColor DarkGray
    }

    # Initialize configuration
    $scriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
    $configPath = Join-Path $scriptDirectory 'statusline-config.json'
    $configuration = Get-StatusLineConfiguration -ConfigPath $configPath -ScriptDirectory $scriptDirectory

    if ($debugMode) {
        Write-Host "[DEBUG] Configuration loaded: Layout=$($configuration.format.layout), MaxDepth=$($configuration.technical.maxDepth)" -ForegroundColor DarkGray
    }

    # Read and process input
    $inputData = Read-ClaudeCodeInput
    $modelName = Get-ModelName -InputData $inputData
    $workingDirectory = Get-WorkingDirectory -InputData $inputData

    if ($debugMode) {
        Write-Host "[DEBUG] Working directory: $workingDirectory" -ForegroundColor DarkGray
        Write-Host "[DEBUG] Model detected: $modelName" -ForegroundColor DarkGray
    }

    # Get project information
    $gitInfo = Get-GitRepositoryInfo -Path $workingDirectory
    $projectName = if ($gitInfo) {
        Split-Path $gitInfo.GitRoot -Leaf
    } else {
        Split-Path $workingDirectory -Leaf
    }

    $branch = if ($gitInfo) {
        if ($gitInfo.IsMultiRepo) {
            # For multi-repo projects, show which sub-repo's branch
            "$($gitInfo.ActiveRepo)/$($gitInfo.Branch)"
        } else {
            $gitInfo.Branch
        }
    } else {
        'no-git'
    }

    if ($debugMode) {
        Write-Host "[DEBUG] Project: $projectName, Branch: $branch" -ForegroundColor DarkGray
        if ($gitInfo -and $gitInfo.IsMultiRepo) {
            Write-Host "[DEBUG] Multi-repo project, active: $($gitInfo.ActiveRepo)" -ForegroundColor DarkGray
        }
    }

    # Get file information
    $fileInfo = Get-RecentFileInfo -Path $workingDirectory -MaxDepth $configuration.technical.maxDepth -PathShortening $configuration.technical.pathShortening

    if ($debugMode) {
        Write-Host "[DEBUG] Recent file: $($fileInfo.ModifiedFile), Has deep files: $($fileInfo.HasDeepFiles)" -ForegroundColor DarkGray
    }

    # Prepare data for formatting
    $statusData = @{
        ProjectName = $projectName
        Branch = $branch
        ModifiedFile = $fileInfo.ModifiedFile
        ModelName = $modelName
    }

    # Generate and output status line
    $outputLines = Build-StatusLine -Configuration $configuration -Data $statusData

    if ($debugMode) {
        Write-Host "[DEBUG] Output line 1: $($outputLines[0])" -ForegroundColor Green
        if ($outputLines[1]) {
            Write-Host "[DEBUG] Output line 2: $($outputLines[1])" -ForegroundColor Green
        }
    }

    [Console]::WriteLine($outputLines[0])
    if ($configuration.format.layout -eq 'two-line' -and $outputLines[1]) {
        [Console]::WriteLine($outputLines[1])
    }

    Write-Verbose "Status line generation completed successfully"
    [Environment]::Exit(0)
}
catch {
    Write-Verbose "Status line generation failed: $($_.Exception.Message)"

    if ($env:STATUSLINE_DEBUG -eq 'true') {
        Write-Host "[DEBUG] FATAL ERROR: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "[DEBUG] Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Red
    }

    # Fallback output
    [Console]::WriteLine('MultiCord -> Branch: dev -> Modified: .claude/settings.json')
    [Console]::WriteLine('Claude Sonnet 4')
    [Environment]::Exit(0)
}

#endregion