# Contributing to Claude Code Status Line

Thank you for your interest in contributing to this project! This document provides guidelines and information for contributors.

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Commit Message Guidelines](#commit-message-guidelines)
- [Pull Request Process](#pull-request-process)
- [Code Standards](#code-standards)
- [Testing](#testing)
- [Documentation](#documentation)
- [Issue Reporting](#issue-reporting)
- [Platform-Specific Guidelines](#platform-specific-guidelines)

## 🤝 Code of Conduct

This project follows a professional code of conduct. Please be respectful, inclusive, and constructive in all interactions.

## 🚀 Getting Started

### Prerequisites

- PowerShell 5.1+ or PowerShell Core
- Git
- Claude Code CLI
- Basic understanding of PowerShell scripting and JSON configuration
- Windows environment (for development; cross-platform support planned)

### Development Setup

1. **Fork and clone the repository**
   ```bash
   git clone https://github.com/your-username/claude-code-statusline.git
   cd claude-code-statusline
   ```

2. **Set up test environment**
   ```bash
   # Create test .claude directory
   mkdir ~/.claude/claude-code-statusline-test
   
   # Copy files for testing
   cp statusline.ps1 ~/.claude/claude-code-statusline-test/
   cp statusline-config.json ~/.claude/claude-code-statusline-test/
   cp -r presets ~/.claude/claude-code-statusline-test/
   ```

3. **Configure test statusline**
   ```powershell
   # Test the statusline directly
   powershell.exe -NoProfile -ExecutionPolicy Bypass -File "~/.claude/claude-code-statusline-test/statusline.ps1"
   ```

4. **Verify all presets work**
   ```bash
   # Test each built-in preset
   # Edit statusline-config.json to test: default, minimal, clean, compact
   ```

## 🔄 Development Workflow

### Branch Naming

Use descriptive branch names with prefixes:
- `feature/add-macos-shell-script`
- `fix/unicode-character-rendering`
- `docs/update-installation-guide`
- `refactor/simplify-path-shortening`
- `update/preset-configurations`

### Development Process

1. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes**
   - Follow code standards
   - Test across different terminal environments
   - Update documentation as needed

3. **Test thoroughly**
   ```powershell
   # Test basic functionality
   .\statusline.ps1
   
   # Test all presets
   # Edit config to test: default, minimal, clean, compact
   
   # Test error scenarios
   # Test with invalid JSON, missing files, etc.
   
   # Test different project types
   # Git repositories, non-git directories, deep structures
   ```

4. **Commit with clear format**
   ```bash
   git add .
   git commit -m "implement: add bash script version for linux/macos"
   ```

5. **Push and create pull request**
   ```bash
   git push origin feature/your-feature-name
   ```

## 📝 Commit Message Guidelines

We use a clear and descriptive commit message format:

### Format
```
<type>: <description>

[optional body]

[optional footer(s)]
```

### Types (lowercase)
- **fix**: Bug fixes, error corrections, patches
- **implement**: New features, functionality, or components
- **enhance**: Improvements to existing features or performance
- **refactor**: Code restructuring without changing functionality
- **remove**: Deletion of features, dependencies, or code
- **update**: Dependencies, documentation, or configuration changes
- **add**: New files, assets, or simple additions
- **change**: Modifications that don't fit other categories

### Examples

```bash
# Good commits
implement: add native bash script version for linux/macos
fix: resolve unicode character rendering in cmd terminals
update: add comprehensive installation documentation
refactor: simplify path shortening algorithm
enhance: improve git branch detection performance
add: new minimal preset with pipe separators
remove: deprecated enhanced-statusline references
change: update configuration schema for v2.1

# Bad commits (avoid these)
Fix bug in statusline
Added new feature
Update stuff
WIP
```

### Commit Message Details

- **Subject line**: 72 characters or less, lowercase, no period
- **Body**: Wrap at 72 characters, explain what and why vs. how
- **Footer**: Reference issues and breaking changes

Example with body:
```
implement: add intelligent depth detection for large projects

Implements configurable directory scanning depth with graceful
fallback indicators when deeper content exists beyond the limit.
Improves performance on large codebases while maintaining context.

Closes #45
```

## 🔍 Pull Request Process

### Before Submitting

- [ ] Branch is up to date with main
- [ ] All functionality tested across terminal environments
- [ ] Code follows PowerShell best practices
- [ ] Documentation is updated
- [ ] Commit messages follow project format

### Pull Request Template

```markdown
## Description
Brief description of changes and why they're needed.

## Type of Change
- [ ] Bug fix (non-breaking change that fixes an issue)
- [ ] New feature (non-breaking change that adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update

## Testing
- [ ] Tested in PowerShell
- [ ] Tested in CMD
- [ ] Tested in Windows Terminal
- [ ] Tested all built-in presets
- [ ] Tested with various project structures

## Checklist
- [ ] Code follows PowerShell style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] Breaking changes documented
```

## 🎨 Code Standards

### PowerShell Style
- Follow PowerShell best practices and conventions
- Use clear, descriptive variable names
- Maximum line length: 120 characters
- Use proper error handling with try-catch blocks
- Comment complex logic and algorithms

### Example Function
```powershell
function Get-ProjectContext {
    <#
    .SYNOPSIS
    Retrieves project context including name, git branch, and recent files.
    
    .PARAMETER ProjectPath
    Path to the project directory to analyze
    
    .PARAMETER MaxDepth
    Maximum directory depth to scan for files
    
    .RETURNS
    Hashtable containing project context information
    #>
    param(
        [string]$ProjectPath,
        [int]$MaxDepth = 5
    )
    
    try {
        # Implementation here with proper error handling
    }
    catch {
        Write-Error "Failed to get project context: $($_.Exception.Message)"
        return $null
    }
}
```

### Configuration Standards
- Use valid JSON with consistent formatting
- Provide sensible default values
- Document all configuration options
- Maintain backward compatibility
- Use clear, descriptive property names

### Error Handling
- Use specific error messages
- Provide helpful troubleshooting information
- Fail gracefully with informative fallbacks
- Log errors appropriately

## 🧪 Testing

### Test Requirements
- Test new features across different terminal environments
- Ensure existing functionality isn't broken
- Test with various project structures and Git scenarios
- Test error conditions and edge cases

### Manual Testing Checklist
```powershell
# Basic functionality
.\statusline.ps1

# All presets
# Test: default, minimal, clean, compact

# Terminal environments
# PowerShell, CMD, Windows Terminal, Git Bash

# Project scenarios
# Git repositories, non-git directories
# Shallow and deep directory structures
# Large projects with many files

# Error scenarios
# Invalid JSON configuration
# Missing configuration files
# Permission issues
# Non-existent directories
```

### Cross-Platform Testing
- Test PowerShell Core on different platforms
- Verify path handling across operating systems
- Test unicode and character encoding
- Validate color output in different terminals

## 📚 Documentation

### Documentation Standards
- Update README.md for significant changes
- Document new configuration options with examples
- Include troubleshooting information
- Keep installation instructions current

### Documentation Types
- **Code comments**: Explain complex PowerShell logic
- **Configuration examples**: Show practical usage
- **README**: Setup and usage instructions
- **Troubleshooting**: Common issues and solutions

## 🐛 Issue Reporting

### Bug Reports
Include:
- Operating system and version
- PowerShell version (Get-Host)
- Claude Code CLI version
- Terminal environment (CMD, PowerShell, Windows Terminal)
- Steps to reproduce
- Expected vs actual behavior
- Configuration files (sanitized)
- Screenshots of terminal output

### Feature Requests
Include:
- Clear description of the feature
- Use case and benefits
- Possible implementation approach
- Impact on existing functionality
- Platform considerations

### Issue Labels
- `bug`: Something isn't working
- `enhancement`: New feature or request
- `documentation`: Documentation improvements
- `good first issue`: Good for newcomers
- `help wanted`: Extra attention needed
- `windows`: Windows-specific issues
- `linux`: Linux-specific issues
- `macos`: macOS-specific issues
- `powershell`: PowerShell script issues
- `config`: Configuration related
- `terminal`: Terminal compatibility

## 🖥️ Platform-Specific Guidelines

### Cross-Platform Considerations

1. **PowerShell Compatibility**
   - Test Windows PowerShell 5.1 and PowerShell Core
   - Avoid Windows-specific cmdlets where possible
   - Use cross-platform path handling

2. **Terminal Environment Support**
   - Test different terminal applications
   - Handle unicode and character encoding properly
   - Verify color output capabilities

3. **Configuration Portability**
   - Use forward slashes in paths where possible
   - Avoid hardcoded system-specific paths
   - Test configuration sharing between platforms

4. **Future Shell Script Support**
   - Consider bash/zsh compatibility in design
   - Plan for shared configuration format
   - Document platform differences

### Testing Platform Features

```powershell
# Windows-specific testing
# PowerShell ISE, Windows Terminal, CMD

# Cross-platform testing (if PowerShell Core available)
# Test on Linux with PowerShell Core
# Test on macOS with PowerShell Core

# Configuration testing
# Share configs between platforms
# Test path handling differences
```

## 🤝 Getting Help

- **GitHub Issues**: Create an issue for bugs and feature requests
- **GitHub Discussions**: Use discussions for questions and ideas
- **Documentation**: Check README.md for comprehensive information
- **Community**: Share configurations and tips with other users

## 📄 License

By contributing, you agree that your contributions will be licensed under the same license as the project.

---

Thank you for contributing to making Claude Code development more productive! 🚀