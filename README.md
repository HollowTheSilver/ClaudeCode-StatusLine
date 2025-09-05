# Claude Code Status Line

A professional, customizable status line for Claude Code with intelligent project context and complete customization through JSON configuration files and built-in presets.

## Overview

The Claude Code Status Line displays essential development context including project name, git branch, recently accessed files, and Claude model information. Fully customizable through JSON configuration with multiple built-in presets for different terminal environments and user preferences.

## Platform Support

### ✅ **Fully Supported**
- **Windows**: Native PowerShell support
  - Windows PowerShell 5.1+
  - PowerShell Core
  - CMD with PowerShell execution
  - Windows Terminal
  - Git Bash (with PowerShell available)

### ⚡ **Works with PowerShell Core**
- **Linux/macOS**: Compatible if PowerShell Core is installed
  - Requires PowerShell Core 6.0+ installation
  - Same functionality as Windows
  - Most users won't have PowerShell installed by default

### 🚧 **Native Shell Script Coming Soon**
- **Linux/macOS**: Native bash/zsh version in development
  - No PowerShell installation required
  - Uses same JSON configuration files
  - Optimized for native terminal environments

**Note**: While this PowerShell version works on Linux/macOS with PowerShell Core, a native shell script (.sh) version is planned for users who prefer not to install PowerShell.

## Features

### 🎛️ **Complete Configuration System**
- **JSON-based Configuration**: Easy-to-edit configuration files with no PowerShell knowledge required
- **Built-in Presets**: 4 ready-to-use formats (default, minimal, clean, compact)
- **Component Toggle**: Show/hide any component (project, branch, accessed file, model)
- **Custom Layouts**: One-line or two-line formats
- **Label Customization**: Custom or no labels for each component
- **Separator Options**: Choose from ->, |, /, •, or custom separators
- **Color Support**: Optional colorized output with customizable color schemes
- **Technical Settings**: Configurable search depth, path shortening, and time windows

### 🎯 **Intelligent Project Context**
- **Project Name Detection**: Automatically uses GitHub repository name or directory name
- **Git Branch Integration**: Real-time branch information with fallback to 'main' or 'no-git'
- **Smart File Tracking**: Shows recently accessed/modified files with intelligent path context

### 🗂️ **Advanced Path Intelligence**
- **Full Relative Paths**: Shows `.claude/settings.json` instead of just `settings.json`
- **Intelligent Shortening**: Paths like `very/deep/folder/structure/file.txt` become `very/../structure/file.txt`
- **Depth Awareness**: Displays `deepest/accessible/path/...` when files exist beyond search depth
- **Configurable Depth**: Default 5-level search depth (customizable)

### 🎨 **Professional Display**
- **Clean Two-Line Format**: Project context on line 1, Claude model on line 2
- **Cross-Terminal Compatibility**: Works in PowerShell, CMD, and compatible terminals
- **Performance Optimized**: Efficient file scanning with reasonable depth limits
- **Graceful Fallbacks**: Robust error handling with informative fallback messages

## Installation

### Global Setup (Recommended)
The status line is designed for global use across all your Claude Code projects.

#### Step 1: Global File Placement
Place these files in your global Claude directory:
```
C:\Users\{YourUsername}\.claude\
├── claude-code-statusline\
│   ├── statusline.ps1
│   ├── statusline-config.json
│   └── presets\
│       ├── minimal.json
│       ├── clean.json
│       └── compact.json
└── settings.json
```

#### Step 2: Global Configuration
Create or update `C:\Users\{YourUsername}\.claude\settings.json`:
```json
{
  "statusLine": {
    "type": "command",
    "command": "powershell.exe -NoProfile -ExecutionPolicy Bypass -File \"C:\\Users\\{YourUsername}\\.claude\\claude-code-statusline\\statusline.ps1\""
  }
}
```

#### Step 3: Restart Claude Code
Restart Claude Code to see your status line across all projects.

### Project-Specific Override (Optional)
You can override the global status line for specific projects by creating a local `.claude/settings.json` in your project directory with different configuration.

**Important**: To inherit the global statusLine configuration, simply omit the `statusLine` key from project-specific settings files. Do not use `"statusLine": null` as this will cause validation errors.

## Output Examples

### Standard Projects
```
MyProject -> Branch: main -> Accessed: src/components/Header.tsx
Claude Sonnet 4
```

### Deep Directory Structures
```
LargeProject -> Branch: feature/new-ui -> Accessed: frontend/../components/Button.jsx
Claude Sonnet 4
```

### Beyond Search Depth
```
ComplexProject -> Branch: dev -> Accessed: deep/nested/project/structure/modules/...
Claude Sonnet 4
```

### Git Repository Detection
```
MultiCord -> Branch: dev -> Accessed: .claude/settings.json
Claude Sonnet 4
```

## Configuration System

### 📋 **Complete Configuration Reference**

The status line uses JSON-based configuration for maximum flexibility and ease of use. The main configuration file is `statusline-config.json` located in your `.claude` directory.

#### Configuration Schema
```json
{
  "preset": "default",
  "format": {
    "layout": "two-line",           // "one-line" or "two-line"
    "separator": " -> ",            // Any string separator
    "showLabels": true,             // Global label toggle
    "components": {
      "project": {
        "show": true,               // Show/hide component
        "label": "",                // Custom label (empty for no label)
        "suffix": "",               // Optional suffix text
        "position": 1               // Order in line 1 (1, 2, 3...)
      },
      "branch": {
        "show": true,
        "label": "Branch:",
        "position": 2
      },
      "accessed": {
        "show": true,
        "label": "Accessed:",
        "position": 3
      },
      "model": {
        "show": true,
        "position": "line2"         // "line2" or number for line 1
      }
    }
  },
  "technical": {
    "maxDepth": 5,                 // Directory search depth
    "pathShortening": 3,           // When to shorten paths
    "timeWindow": 30               // File access time window
  },
  "colors": {
    "enabled": true,               // Enable color output
    "project": "Magenta",          // PowerShell color names
    "branch": "Yellow",
    "accessed": "Green",
    "model": "Cyan",
    "separator": "White"
  }
}
```

### 🎨 **Built-in Presets**

#### Default Preset
```
MultiCord -> Branch: dev -> Accessed: platform_core/entities/ProcessInfo.py
Claude Sonnet 4
```

#### Minimal Preset
```
MultiCord | dev | platform_core/entities/ProcessInfo.py
Claude Sonnet 4
```

#### Clean Preset  
```
MultiCord / platform_core/entities/ProcessInfo.py
Claude Sonnet 4
```

#### Compact Preset (One-Line)
```
MultiCord • dev • platform_core/entities/ProcessInfo.py • Claude Sonnet 4
```


### 🛠️ **Customization Options**

#### Using Built-in Presets
Simply change the `preset` value in your `statusline-config.json`:
```json
{
  "preset": "minimal"
}
```

Available presets: `default`, `minimal`, `clean`, `compact`

#### Creating Custom Configurations
You can override any setting in your `statusline-config.json`:
```json
{
  "preset": "default",
  "format": {
    "separator": " | ",
    "components": {
      "project": { "show": false },
      "model": { "label": "Model: " }
    }
  }
}
```

#### Advanced Customization Examples

**Hide Branch Information:**
```json
{
  "format": {
    "components": {
      "branch": { "show": false }
    }
  }
}
```

**One-Line Compact Format:**
```json
{
  "format": {
    "layout": "one-line",
    "separator": " • "
  }
}
```

**Custom Project Branding:**
```json
{
  "format": {
    "components": {
      "project": {
        "label": "🚀 ",
        "suffix": " Project"
      }
    }
  }
}
```

**Deep Project Configuration:**
```json
{
  "technical": {
    "maxDepth": 10,
    "pathShortening": 5
  }
}
```

## Customization

### Global vs Project-Level Customization

#### Global Customization
Edit `C:\Users\{YourUsername}\.claude\statusline-config.json` to affect all projects with your preferred format, or use presets by editing the configuration file.

**Global Settings Override**
Edit `C:\Users\{YourUsername}\.claude\settings.json`:
```json
{
  "statusLine": {
    "type": "command", 
    "command": "powershell.exe -NoProfile -ExecutionPolicy Bypass -File \"C:\\Users\\{YourUsername}\\.claude\\claude-code-statusline\\statusline.ps1\""
  },
  "outputStyle": "Explanatory"
}
```

#### Project-Level Customization
You can override the global configuration for specific projects:

**Project-Specific Configuration File:**
Create `{ProjectRoot}/.claude/statusline-config.json`:
```json
{
  "preset": "compact",
  "technical": {
    "maxDepth": 3
  }
}
```

**Use Different Script:**
Create `{ProjectRoot}/.claude/settings.json`:
```json
{
  "statusLine": {
    "type": "command",
    "command": "powershell.exe -NoProfile -ExecutionPolicy Bypass -File \"custom-statusline.ps1\""
  }
}
```

**Disable Status Line for Specific Project:**
```json
{
  "disableAllHooks": true
}
```

### Configuration Hierarchy
Claude Code uses this priority order:
1. **Project `.claude/settings.json`** (highest priority)
   - If a project has its own `.claude/settings.json`, it takes precedence over global settings
   - **Inheritance behavior**: When the `statusLine` key is completely absent from project settings, Claude Code automatically inherits the global statusLine configuration
   - **Critical**: Never use `"statusLine": null` - this is invalid and will cause Claude Code validation errors
2. **Global `.claude/settings.json`** (fallback)
   - Used when no project-specific settings exist, or when project settings don't contain a statusLine key
3. **Built-in defaults** (if no configuration found)

**Best Practice**: Configure statusLine once in your global settings. For projects with their own `.claude/settings.json` files, simply exclude the statusLine key entirely - the project will automatically inherit your global statusLine configuration.

## Technical Details

### File Search Algorithm
1. **Recursive Search**: Scans up to 5 directory levels deep (configurable)
2. **Time-Based Ranking**: Prioritizes recently modified files using `LastWriteTime`
3. **Intelligent Fallback**: Falls back to most recent file if no recent activity
4. **Performance Optimized**: Limits search depth to prevent performance issues

### Path Processing
1. **Relative Path Calculation**: Converts absolute paths to project-relative paths
2. **Cross-Platform Separators**: Normalizes Windows `\` to Unix-style `/` for consistency
3. **Intelligent Shortening**: Uses `first/../second-to-last/last` format for long paths
4. **Depth Indication**: Appends `...` when deeper files exist beyond search limit

### Git Integration
- **Repository Detection**: Automatically finds `.git` directory in parent directories
- **Branch Detection**: Uses `git branch --show-current` for accurate branch information
- **Fallback Handling**: Graceful handling of non-git projects and git errors

## Troubleshooting

### Status Line Not Appearing
1. Verify `statusline.ps1` is in your global `.claude` directory
2. Check that your global `.claude/settings.json` has the correct statusLine configuration
3. Ensure `statusline-config.json` exists and has valid JSON syntax
4. **Check for project-specific overrides**: If you see the default PowerShell banner instead of your custom statusline, check if the current project has a `.claude/settings.json` file that includes a conflicting statusLine configuration
5. **Inheritance troubleshooting**: Project-specific settings files should either completely omit the statusLine key (to inherit from global) or include a complete, valid statusLine configuration. Never use `"statusLine": null` as this causes validation errors
6. Restart Claude Code after making changes
7. Verify PowerShell execution policy allows script execution

### Configuration Issues
- **Invalid JSON**: Use a JSON validator to check your `statusline-config.json` syntax
- **Missing Preset**: If using a custom preset name, ensure the preset file exists in `presets/` directory
- **Component Errors**: Verify component names match: `project`, `branch`, `accessed`, `model`
- **Position Conflicts**: Ensure position numbers are unique (1, 2, 3...) or use "line2"

### Script Execution Errors
- **Execution Policy**: Script uses `-ExecutionPolicy Bypass` to avoid policy issues
- **Path Issues**: Ensure the script path in settings.json uses double backslashes: `\\`
- **PowerShell Version**: Works with Windows PowerShell 5.1+ and PowerShell Core
- **Configuration Loading**: Check for syntax errors in JSON files that prevent loading

### Performance Issues
- **Large Projects**: Reduce `maxDepth` in technical settings for very large projects
- **Network Drives**: May be slower on network-mounted directories
- **Deep Structures**: Script automatically limits depth to maintain performance
- **Configuration Caching**: Restart Claude Code if configuration changes don't take effect

## Requirements

- **PowerShell**: Windows PowerShell 5.1+ or PowerShell Core (cross-platform)
- **Git** (optional): For branch detection and repository name identification
- **Claude Code CLI**: The official Claude Code command-line interface

## Community & Support

This status line is designed to be:
- **Zero Configuration**: Works out of the box with sensible defaults
- **Community Friendly**: Easy to share and customize for team use
- **Professional Ready**: Suitable for professional development environments
- **Windows-Focused**: Optimized for Windows terminals with planned Linux/macOS support

## Version Information

- **Version**: 2.1
- **Author**: HollowTheSilver
- **Compatibility**: Claude Code CLI
- **Last Updated**: January 2025

### Release History
- **2.1**: Complete configuration system with JSON-based presets and advanced customization
- **2.0**: Intelligent path management and health monitoring
- **1.0**: Initial PowerShell status line with basic project context

### What's New in 2.1
- 🎛️ **JSON-Based Configuration**: Easy configuration without PowerShell knowledge
- 🎨 **Built-in Presets**: 4 professional format presets ready to use
- 🔧 **Component Toggle System**: Show/hide any status line component
- 🎯 **Advanced Customization**: Colors, separators, labels, and layout options
- 📐 **Flexible Layouts**: One-line or two-line display modes
- ⚙️ **Technical Settings**: Configurable depth, path shortening, and timing

## License

This status line is provided as-is for community use. Feel free to modify and share with your development teams.

---

**Enjoy your Claude Code development experience! 🚀**