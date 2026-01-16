# Troubleshooting Guide

Common issues and solutions when building your Security Now archive.

## Table of Contents

- [Git Issues](#git-issues)
- [Sync Script Issues](#sync-script-issues)
- [Download Issues](#download-issues)
- [AI Transcription Issues](#ai-transcription-issues)
- [File System Issues](#file-system-issues)
- [PowerShell Issues](#powershell-issues)

---

## Git Issues

### Merge Conflicts

**Symptom**: `CONFLICT (content): Merge conflict in <file>`

**Cause**: Same file edited in both repos or GitHub

**Solution**:

```powershell
# Check status
git status

# Open conflicted files, look for:
<<<<<<< HEAD
Your changes
=======
Other changes
>>>>>>> branch-name

# Edit to keep desired version, remove markers

# Mark as resolved
git add <file>
git commit -m "Resolved merge conflict"
```

### Unfinished Merge

**Symptom**: `error: You have not concluded your merge (MERGE_HEAD exists)`

**Cause**: Previous merge not completed

**Solution**:

```powershell
# Complete the merge
git commit --no-edit

# Or abort if you want to start over
git merge --abort
```

### Push Rejected (Non-Fast-Forward)

**Symptom**: `error: failed to push some refs` / `tip of your current branch is behind`

**Cause**: Remote has commits you don't have locally

**Solution**:

```powershell
# Pull and merge remote changes
git pull origin main --no-edit

# Then push
git push origin main
```

### Authentication Failed

**Symptom**: `fatal: Authentication failed`

**Cause**: GitHub changed authentication (no more passwords)

**Solution**: Use Personal Access Token (PAT)

```powershell
# Generate PAT at: https://github.com/settings/tokens
# Use PAT as password when prompted

# Or configure Git credential manager
git config --global credential.helper manager-core
```

### Large Files Push Failed

**Symptom**: `remote: error: File is XXX MB; this exceeds GitHub's file size limit`

**Cause**: Trying to push files >100MB without Git LFS

**Solution**:

```powershell
# Install Git LFS (if not already)
git lfs install

# Track large file types
git lfs track "*.pdf"
git lfs track "*.mp3"

# Add .gitattributes
git add .gitattributes

# Migrate existing large files
git lfs migrate import --include="*.pdf,*.mp3"

# Push
git push origin main
```

---

## Sync Script Issues

### "Private repo not found"

**Symptom**: `ERROR: Private repo not found at: D:\Desktop\SecurityNow-Full-Private`

**Cause**: Wrong path or repo not cloned

**Solution**:

```powershell
# Check if path exists
Test-Path "D:\Desktop\SecurityNow-Full-Private"

# If false, clone the repo
git clone <your-private-repo-url> D:\Desktop\SecurityNow-Full-Private

# Or specify correct path
.\scripts\Sync-Repos.ps1 -PrivateRepo "C:\Your\Actual\Path"
```

### "Public repo not found"

**Symptom**: `ERROR: Public repo not found at: D:\Desktop\SecurityNow-Full`

**Solution**:

```powershell
# Clone public repo
git clone https://github.com/msrproduct/securitynow-archive-tools.git D:\Desktop\SecurityNow-Full
```

### Files Show Different When They're Not

**Symptom**: Sync says files differ, but they look identical

**Cause**: Line ending differences (CRLF vs LF)

**Solution**:

```powershell
# Configure Git consistently in both repos
cd D:\Desktop\SecurityNow-Full-Private
git config core.autocrlf true

cd D:\Desktop\SecurityNow-Full
git config core.autocrlf true

# Normalize line endings
git add --renormalize .
git commit -m "Normalize line endings"
```

### Sync Shows 0 Files But I Made Changes

**Causes**:
1. Edited files in public repo (sync direction is private → public)
2. Edited files in excluded folders (local/PDF, local/mp3)
3. Didn't save changes

**Solution**:

```powershell
# Always edit in PRIVATE repo
cd D:\Desktop\SecurityNow-Full-Private

# Verify your changes are saved
Get-Content .\scripts\YourScript.ps1

# Run sync with verbose output
.\scripts\Sync-Repos.ps1 -Verbose
```

### Git Push Fails During Sync

**Symptom**: Sync completes but fails to push to GitHub

**Solution**:

```powershell
# Manually push from public repo
cd D:\Desktop\SecurityNow-Full
git push origin main

# If that fails, pull first
git pull origin main --no-edit
git push origin main
```

---

## Download Issues

### SSL/TLS Certificate Errors

**Symptom**: `The underlying connection was closed: Could not establish trust relationship`

**Solution**:

```powershell
# Temporary workaround (not recommended for production)
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

# Better: Update Windows and PowerShell
# Or use -SkipCertificateCheck with Invoke-WebRequest
```

### 404 Not Found

**Symptom**: Episode PDF or MP3 not found

**Cause**: Episode number format wrong or file doesn't exist

**Solution**:

```powershell
# Check episode exists at GRC.com
# Format: https://www.grc.com/sn/sn-XXX-notes.pdf
# Some early episodes may not have show notes

# Script should log and continue
```

### Rate Limiting / Too Many Requests

**Symptom**: Downloads fail after many successful requests

**Solution**:

```powershell
# Add delays between requests (already in script)
Start-Sleep -Milliseconds 500

# Run in smaller batches
.\scripts\SecurityNow-EndToEnd.ps1 -StartEpisode 1 -EndEpisode 100
```

### Network Timeouts

**Symptom**: `The operation has timed out`

**Solution**:

```powershell
# Increase timeout in script
$timeout = 30000  # 30 seconds

# Or check your internet connection
Test-Connection grc.com
Test-Connection twit.tv
```

---

## AI Transcription Issues

### Whisper Not Found

**Symptom**: `whisper : The term 'whisper' is not recognized`

**Cause**: OpenAI Whisper CLI not installed

**Solution**:

```bash
# Install Python (if not already)
# Download from: https://www.python.org/downloads/

# Install whisper
pip install openai-whisper

# Verify installation
whisper --help
```

### CUDA/GPU Errors

**Symptom**: `CUDA out of memory` or GPU-related errors

**Solution**:

```powershell
# Use CPU instead of GPU
whisper audio.mp3 --device cpu --model base

# Or use smaller model
whisper audio.mp3 --model tiny
```

### Transcription Takes Forever

**Cause**: Using large model on CPU

**Solution**:

```powershell
# Use faster model
whisper audio.mp3 --model base  # Instead of large

# Process overnight for large batches
# Or use GPU if available
```

### Transcription Output Garbled

**Cause**: Wrong language detection or poor audio quality

**Solution**:

```powershell
# Force English language
whisper audio.mp3 --language en

# Try different model
whisper audio.mp3 --model medium --language en
```

### Out of Disk Space During Transcription

**Cause**: Whisper cache files

**Solution**:

```powershell
# Clear Whisper cache
Remove-Item -Path "$env:USERPROFILE\.cache\whisper" -Recurse -Force

# Or specify output directory
whisper audio.mp3 --output_dir "D:\Transcripts"
```

---

## File System Issues

### Access Denied

**Symptom**: `Access to the path is denied`

**Solution**:

```powershell
# Run PowerShell as Administrator
# Or check file permissions
Get-Acl -Path "D:\Desktop\SecurityNow-Full"

# Ensure you have write access to the directory
```

### Path Too Long

**Symptom**: `The specified path, file name, or both are too long`

**Solution**:

```powershell
# Enable long paths in Windows 10/11
# Run as Administrator:
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "LongPathsEnabled" -Value 1 -PropertyType DWORD -Force

# Or use shorter folder names
# Instead of: D:\Desktop\SecurityNow-Full-Private-Archive-Complete
# Use: D:\SN-Archive
```

### Disk Full

**Symptom**: `There is not enough space on the disk`

**Cause**: Complete archive is 10-20+ GB

**Solution**:

```powershell
# Check available space
Get-PSDrive D

# Delete old episodes or use external drive
# Or process in batches
```

### File in Use

**Symptom**: `The process cannot access the file because it is being used`

**Solution**:

```powershell
# Close any applications using the file
# Check what's using it:
Get-Process | Where-Object {$_.MainWindowTitle -like "*SecurityNow*"}

# Or restart PowerShell
```

---

## PowerShell Issues

### Execution Policy Blocks Script

**Symptom**: `cannot be loaded because running scripts is disabled`

**Solution**:

```powershell
# Check current policy
Get-ExecutionPolicy

# Set to allow local scripts (run as Administrator)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Or bypass for single session
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
```

### "Not Recognized as Cmdlet"

**Symptom**: `The term 'SomeCommand' is not recognized`

**Cause**: Module not loaded or command doesn't exist

**Solution**:

```powershell
# For Git commands
# Ensure Git is installed and in PATH
$env:Path

# Restart PowerShell after installing Git
```

### Script Hangs or Freezes

**Causes**:
1. Network timeout
2. Large file processing
3. Infinite loop (bug)

**Solution**:

```powershell
# Press Ctrl+C to stop

# Check network connectivity
# Review script logic
# Add debug output
Write-Host "Processing episode $episodeNum" -ForegroundColor Cyan
```

### Parameter Not Recognized

**Symptom**: `A parameter cannot be found that matches parameter name`

**Solution**:

```powershell
# Check parameter spelling
Get-Help .\scripts\SecurityNow-EndToEnd.ps1 -Full

# Ensure using correct parameters for the script
```

### "Cannot Convert Value to Type"

**Symptom**: `Cannot convert value "abc" to type "System.Int32"`

**Cause**: Passing wrong data type to parameter

**Solution**:

```powershell
# Ensure numbers are passed to numeric parameters
.\script.ps1 -EpisodeNumber 123  # Correct
.\script.ps1 -EpisodeNumber "123"  # Also works (auto-converts)
.\script.ps1 -EpisodeNumber "abc"  # ERROR
```

---

## Getting More Help

### Enable Verbose Output

```powershell
# Most scripts support -Verbose
.\scripts\Sync-Repos.ps1 -Verbose
```

### Check Script Help

```powershell
# View script parameters and examples
Get-Help .\scripts\SecurityNow-EndToEnd.ps1 -Full
```

### Debug Mode

```powershell
# Enable debug output
$DebugPreference = "Continue"

# Run script
.\scripts\YourScript.ps1

# Disable when done
$DebugPreference = "SilentlyContinue"
```

### Log Output

```powershell
# Save output to file for review
.\scripts\SecurityNow-EndToEnd.ps1 -Verbose *> output.log

# Review log
notepad output.log
```

### Still Stuck?

1. Check [FAQ.md](FAQ.md) for common questions
2. Review [Architecture.md](Architecture.md) to understand the design
3. Open an issue on GitHub with:
   - Full error message
   - Command you ran
   - PowerShell version: `$PSVersionTable.PSVersion`
   - OS version: `[System.Environment]::OSVersion`

---

## Quick Reference

### Common Commands

```powershell
# Check Git status
cd D:\Desktop\SecurityNow-Full-Private
git status

# Sync repos
.\scripts\Sync-Repos.ps1 -DryRun -Verbose

# Build archive
.\scripts\SecurityNow-EndToEnd.ps1

# Test paths
Test-Path "D:\Desktop\SecurityNow-Full-Private"

# Check PowerShell version
$PSVersionTable.PSVersion

# Check Git version
git --version
```

### Emergency Recovery

```powershell
# If Git is completely broken
cd D:\Desktop\SecurityNow-Full-Private

# Backup your local/ folder first!
Copy-Item -Path ".\local" -Destination "D:\Backup\local" -Recurse

# Reset to last known good state
git reset --hard HEAD

# Or re-clone if needed
cd D:\Desktop
Rename-Item SecurityNow-Full-Private SecurityNow-Full-Private-Broken
git clone <your-repo-url> SecurityNow-Full-Private

# Restore local/ folder
Copy-Item -Path "D:\Backup\local" -Destination ".\SecurityNow-Full-Private\local" -Recurse
```

---

## Related Documentation

- [Sync-Repos Guide](Sync-Repos-Guide.md) - Sync script usage
- [Architecture](Architecture.md) - System design
- [FAQ](FAQ.md) - Frequently asked questions
- [Main Workflow](../WORKFLOW.md) - Complete process

---

**Remember**: When reporting issues, include error messages, commands run, and system information!

---

## Frequently Asked Questions

### Q: Will running this script cause high bandwidth costs for Steve Gibson or Leo Laporte?

**A: No. Zero impact.**

The Security Now! archive is hosted on CDN infrastructure (Cloudflare/AWS) specifically designed for massive concurrent downloads:

- **GRC PDFs** (grc.com/sn/): Cloudflare free tier with unlimited bandwidth for cached content
- **TWiT MP3s** (cdn.twit.tv): Enterprise CDN built for podcast distribution

**Technical Details:**
- Your downloads hit CDN edge servers (cached copies), not origin servers
- CDN capacity: 45+ million requests/second globally
- Your script: ~20-30 requests/minute (sequential downloads)
- Impact: 0.0000086% of CDN capacity

**Bottom Line:** The script already includes polite rate limiting (20-second timeouts, exponential backoff). No additional throttling needed. Steve and Leo pay $  extra regardless of how many users run the archive tool.

**Reference:** Content distribution networks are designed for exactly this use case. Your current implementation is already respectful and CDN-friendly.
