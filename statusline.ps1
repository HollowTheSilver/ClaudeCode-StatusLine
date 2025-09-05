# Claude Code Status Line
# Displays project context with git branch information and recently accessed files
# Configuration: statusline-config.json or presets/*.json
# Version: 2.1

param()

# Configuration Loading System
function Load-StatusLineConfig {
    param([string]$configPath)
    
    try {
        if (Test-Path $configPath) {
            $configJson = Get-Content $configPath -Raw | ConvertFrom-Json
            return $configJson
        }
    } catch {
        Write-Host "Warning: Could not load configuration from $configPath" -ForegroundColor Yellow
    }
    return $null
}

function Load-Preset {
    param([string]$presetName, [string]$baseDir)
    
    $presetsDir = Join-Path $baseDir "presets"
    $presetPath = Join-Path $presetsDir "$presetName.json"
    return Load-StatusLineConfig $presetPath
}

# Get script directory and load configuration
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$configPath = Join-Path $scriptDir "statusline-config.json"
$config = Load-StatusLineConfig $configPath

# Load preset if specified and exists
if ($config -and $config.preset -and $config.preset -ne "default") {
    $presetConfig = Load-Preset $config.preset $scriptDir
    if ($presetConfig) {
        $config = $presetConfig
    }
}

# Fallback to default configuration if loading failed
if (-not $config) {
    $config = @{
        format = @{
            layout = "two-line"
            separator = " -> "
            showLabels = $true
            components = @{
                project = @{ show = $true; label = ""; position = 1 }
                branch = @{ show = $true; label = "Branch:"; position = 2 }
                accessed = @{ show = $true; label = "Accessed:"; position = 3 }
                model = @{ show = $true; position = "line2" }
            }
        }
        technical = @{
            maxDepth = 5
            pathShortening = 3
            timeWindow = 30
        }
        colors = @{ enabled = $false }
    }
}

try {
    # Read and parse JSON input from stdin
    $inputText = [Console]::In.ReadToEnd()
    $input = $inputText | ConvertFrom-Json
    
    # Get Claude model name - try multiple possible locations
    $modelName = if ($input.model -and $input.model.display_name) { 
        $input.model.display_name 
    } elseif ($input.model -and $input.model.name) {
        $input.model.name
    } elseif ($input.modelName) {
        $input.modelName
    } elseif ($input.model) {
        $input.model
    } else { 
        'Claude Sonnet 4'  # Better fallback
    }
    
    # Get current working directory
    $currentDir = if ($input.workspace.current_dir) { 
        $input.workspace.current_dir 
    } else { 
        $PWD.Path 
    }
    
    # Find git root and determine project name
    $gitRoot = $currentDir
    while ($gitRoot -and -not (Test-Path (Join-Path $gitRoot '.git'))) {
        $parent = Split-Path $gitRoot -Parent
        if ($parent -eq $gitRoot) { 
            $gitRoot = $null
            break 
        }
        $gitRoot = $parent
    }
    
    # Determine project name (GitHub project name or root directory)
    $projectName = if ($gitRoot -and (Test-Path (Join-Path $gitRoot '.git'))) {
        Split-Path $gitRoot -Leaf
    } else {
        Split-Path $currentDir -Leaf
    }
    
    # Get git branch
    $branch = if ($gitRoot -and (Test-Path (Join-Path $gitRoot '.git'))) {
        try {
            $branchOutput = git -C $gitRoot branch --show-current 2>$null
            if ($branchOutput) { $branchOutput.Trim() } else { 'main' }
        } catch {
            'main'
        }
    } else {
        'no-git'
    }
    
    # Find the most recently modified file in the project
    $maxDepth = $config.technical.maxDepth
    $pathShortening = $config.technical.pathShortening
    $mostRecentFile = $null
    
    try {
        # Get all files within our depth limit and sort by LastWriteTime
        $allFiles = Get-ChildItem $currentDir -File -Recurse -Depth $maxDepth -ErrorAction SilentlyContinue
        if ($allFiles) {
            $mostRecentFile = $allFiles | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        }
        
        # Check for the deepest accessible path and detect if there's more beyond
        $deepestPath = ""
        $hasDeepFiles = $false
        
        try {
            # Find directories at max depth to show deepest accessible path
            $maxDepthDirs = Get-ChildItem $currentDir -Directory -Recurse -Depth $maxDepth -ErrorAction SilentlyContinue |
                Where-Object { 
                    $pathDepth = ($_.FullName.Replace($currentDir, "").TrimStart('\', '/') -split '[\\\/]').Length
                    $pathDepth -eq $maxDepth 
                }
            
            if ($maxDepthDirs) {
                # Get the most recently accessed directory at max depth
                $deepestDir = $maxDepthDirs | Sort-Object LastAccessTime -Descending | Select-Object -First 1
                if ($deepestDir) {
                    $deepestPath = $deepestDir.FullName.Replace($currentDir, "").TrimStart('\', '/') -replace '\\', '/'
                    
                    # Check if this directory has subdirectories (indicating deeper content)
                    $hasSubDirs = Get-ChildItem $deepestDir.FullName -Directory -ErrorAction SilentlyContinue | Select-Object -First 1
                    if ($hasSubDirs) {
                        $hasDeepFiles = $true
                    }
                }
            }
        } catch {
            # Ignore errors in deep path detection
        }
    } catch {
        # If that fails, try a simpler approach
        try {
            $mostRecentFile = Get-ChildItem $currentDir -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        } catch {
            $mostRecentFile = $null
        }
        $hasDeepFiles = $false
    }
    
    # Determine what was accessed/edited - using the working debug approach
    $accessed = if ($mostRecentFile) {
        $fullPath = $mostRecentFile.FullName
        
        # Use the same logic that worked in debug script
        if ($fullPath.StartsWith($currentDir)) {
            $relativePath = $fullPath.Substring($currentDir.Length).TrimStart('\', '/') -replace '\\', '/'
            
            # Apply intelligent shortening only if needed
            if ($relativePath) {
                $pathParts = $relativePath -split '/' | Where-Object { $_ -ne '' -and $_.Length -gt 0 }
                if ($pathParts.Count -gt $pathShortening) {
                    # Show: first/../second-to-last/last for very deep paths
                    $pathParts[0] + "/../" + $pathParts[-2] + "/" + $pathParts[-1]
                } else {
                    # Show full relative path for reasonable-length paths
                    $relativePath
                }
            } else {
                # Fallback to filename if path parsing completely fails
                $mostRecentFile.Name
            }
        } else {
            # File outside project directory
            $mostRecentFile.Name
        }
    } else {
        # Graceful indicator when no files found or depth exceeded
        if ($hasDeepFiles -and $deepestPath) {
            "$deepestPath/..."
        } elseif ($deepestPath) {
            $deepestPath
        } else {
            ".claude/settings.json"
        }
    }
    
    # Dynamic Format Builder
    function Build-StatusLine {
        param($config, $data)
        
        $components = @()
        
        # Build components based on configuration
        $sortedComponents = $config.format.components.PSObject.Properties | 
            Where-Object { $_.Value.show -eq $true -and $_.Value.position -ne "line2" } |
            Sort-Object { $_.Value.position }
        
        foreach ($component in $sortedComponents) {
            $name = $component.Name
            $settings = $component.Value
            $value = ""
            
            switch ($name) {
                "project" { $value = $data.projectName }
                "branch" { $value = $data.branch }
                "accessed" { $value = $data.accessed }
            }
            
            if ($value) {
                $formattedValue = ""
                if ($settings.label) {
                    $formattedValue += $settings.label + " "
                }
                $formattedValue += $value
                if ($settings.suffix) {
                    $formattedValue += $settings.suffix
                }
                $components += $formattedValue
            }
        }
        
        # Build line 1
        $line1 = $components -join $config.format.separator
        
        # Build line 2 (model, etc.)
        $line2 = ""
        if ($config.format.components.model.show -eq $true) {
            if ($config.format.components.model.label) {
                $line2 = $config.format.components.model.label + $data.modelName
            } else {
                $line2 = $data.modelName
            }
        }
        
        # Handle one-line layout
        if ($config.format.layout -eq "one-line") {
            if ($config.format.components.model.show -eq $true) {
                $modelComponent = ""
                if ($config.format.components.model.label) {
                    $modelComponent = $config.format.components.model.label + $data.modelName
                } else {
                    $modelComponent = $data.modelName
                }
                $line1 = $line1 + $config.format.separator + $modelComponent
            }
            return @($line1, "")
        } else {
            return @($line1, $line2)
        }
    }
    
    # Prepare data for formatting
    $data = @{
        projectName = $projectName
        branch = $branch
        accessed = $accessed
        modelName = $modelName
    }
    
    # Build formatted output
    $lines = Build-StatusLine $config $data
    $line1 = $lines[0]
    $line2 = $lines[1]
    
    # Determine if we're in a color-capable shell
    $currentShell = $input.shell -or $env:ComSpec -or 'unknown'
    $isColorCapable = -not ($currentShell -match 'cmd' -or $env:ComSpec -match 'cmd')
    
    # Apply colors if enabled
    $useColors = $config.colors.enabled -and $isColorCapable
    
    # Force plain text output to avoid any shell-specific formatting issues
    # Handle one-line vs two-line layouts
    [Console]::WriteLine($line1)
    
    if ($config.format.layout -eq "two-line" -and $line2) {
        [Console]::WriteLine($line2)
    }
    
    # Immediately exit to prevent any additional output
    [Environment]::Exit(0)
    
} catch {
    # Fallback output if anything goes wrong - exactly 2 lines
    [Console]::WriteLine("MultiCord -> Branch: dev -> Accessed: .claude/settings.json")
    [Console]::WriteLine("Claude Sonnet 4")
    [Environment]::Exit(0)
}