# Troubleshooting Guide

## Status Line Not Updating

If the "Modified:" or "Model" sections are not updating properly, follow these steps:

### Enable Debug Mode

Set the environment variable to enable detailed debugging output:

**Windows (PowerShell):**
```powershell
$env:STATUSLINE_DEBUG = 'true'
```

**Windows (CMD):**
```cmd
set STATUSLINE_DEBUG=true
```

**Linux/macOS:**
```bash
export STATUSLINE_DEBUG=true
```

Then run the status line script to see detailed diagnostic information.

### Common Issues and Solutions

#### 1. Model Not Updating

**Symptoms:**
- Always shows "Claude Sonnet 4" regardless of actual model
- Model name doesn't change when switching between Claude models

**Possible Causes:**
- JSON input from Claude Code not being received
- Input parsing failures
- Console.In reading issues in certain terminal environments

**Solutions:**
- Check debug output for "No input received from stdin" message
- Verify Claude Code is sending JSON data correctly
- Try running in different terminal (PowerShell vs CMD vs Windows Terminal)

#### 2. Modified Files Not Updating

**Symptoms:**
- Always shows same file or "no recent files"
- Doesn't reflect actual recent modifications
- Shows ".claude/settings.json" as fallback

**Possible Causes:**
- Permission denied errors in project directories
- Directory depth exceeds maxDepth setting
- Large project with many files causing timeouts
- Hidden or system files interfering

**Solutions:**
- Increase `maxDepth` in `statusline-config.json` (default is now 7)
- Check debug output for "Access denied" messages
- Ensure the script has read permissions for project directories
- Try running PowerShell as Administrator (Windows)

#### 3. Complex/Large Projects (like MultiCord)

For large projects with deep directory structures:

1. **Increase search depth:**
   Edit `statusline-config.json`:
   ```json
   "technical": {
     "maxDepth": 10,
     "pathShortening": 3
   }
   ```

2. **Create project-specific configuration:**
   Place a custom `statusline-config.json` in your project's `.claude/` directory

3. **Check for permission issues:**
   - Run with elevated permissions if needed
   - Check for directories with restricted access

### Testing the Script

Test with manual input to isolate issues:

```powershell
# Test with sample input
echo '{"model":{"display_name":"Opus 4.1"},"workspace":{"current_dir":"C:\\path\\to\\project"}}' | .\statusline.ps1
```

### Debug Output Interpretation

When debug mode is enabled, look for these key messages:

- `[DEBUG] No input received from stdin` - Claude Code isn't sending data
- `[DEBUG] Access denied error` - Permission issues with file search
- `[DEBUG] No files found in search` - Search depth or permission issues
- `[DEBUG] Model name resolved to: ...` - Shows what model was detected
- `[DEBUG] Found X files, most recent: ...` - Shows file discovery results

### Performance Issues

If the status line is slow:

1. Reduce `maxDepth` for faster searches
2. Exclude large directories from search
3. Check for network drives or slow file systems

### Reporting Issues

If problems persist after troubleshooting:

1. Run with `STATUSLINE_DEBUG=true`
2. Capture the full debug output
3. Note your:
   - PowerShell version: `$PSVersionTable.PSVersion`
   - Operating system
   - Project structure (approximate size/depth)
4. Report at: https://github.com/HollowTheSilver/ClaudeCode-StatusLine/issues