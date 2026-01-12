# Troubleshooting Guide

Detailed solutions for common issues with Security Now! Archive Tools.

---

## Table of Contents

- [PowerShell Issues](#powershell-issues)
- [Git Issues](#git-issues)
- [Download Problems](#download-problems)
- [File Organization Issues](#file-organization-issues)
- [Sync Script Problems](#sync-script-problems)
- [AI Transcription Issues](#ai-transcription-issues)
- [Performance Problems](#performance-problems)
- [GitHub Integration](#github-integration)

---

## PowerShell Issues

### "Cannot run scripts on this system"

**Error:**
```
File cannot be loaded because running scripts is disabled on this system.
```

**Cause:** PowerShell execution policy blocks script execution.

**Solution:**
```powershell
# Check current policy
Get-ExecutionPolicy

# Set to RemoteSigned (recommended)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Verify
Get-ExecutionPolicy -List
```

**Alternative (one-time bypass):**
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\SecurityNow-EndToEnd.ps1
```

---

### "Command not found" for PowerShell 7

**Error:**
```
powershell : The term 'powershell' is not recognized
```

**Cause:** PowerShell 7 not installed or not in PATH.

**Solution:**

1. **Install PowerShell 7:**
   - Windows: [Download MSI installer](https://github.com/PowerShell/PowerShell/releases)
   - macOS: `brew install powershell`
   - Linux: See [official docs](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell)

2. **Verify installation:**
   ```powershell
   pwsh --version
   # Should show 7.x.x
   ```

3. **Use `pwsh` instead of `powershell`:**
   ```powershell
   pwsh
   cd path\to\securitynow-archive-tools
   .\scripts\SecurityNow-EndToEnd.ps1
   ```

---

### Path with Spaces Causes Errors

**Error:**
```
Cannot find path 'C:\Program' because it does not exist.
```

**Cause:** Paths with spaces not properly quoted.

**Solution:**

```powershell
# WRONG
.\script.ps1 -Path C:\Program Files\Archive

# CORRECT
.\script.ps1 -Path "C:\Program Files\Archive"

# OR use literal path
.\script.ps1 -LiteralPath "C:\Program Files\Archive"
```

---

## Git Issues

### "Git not recognized as a command"

**Error:**
```
git : The term 'git' is not recognized
```

**Cause:** Git not installed or not in system PATH.

**Solution:**

1. **Install Git:**
   - Download from [git-scm.com](https://git-scm.com/)
   - Run installer (accept defaults)

2. **Restart PowerShell** (to reload PATH)

3. **Verify:**
   ```powershell
   git --version
   # Should show git version 2.x.x
   ```

---

### "Failed to push - Authentication required"

**Error:**
```
fatal: Authentication failed for 'https://github.com/...'
```

**Cause:** GitHub credentials not configured or token expired.

**Solution:**

1. **Use Personal Access Token (PAT):**
   - Go to GitHub → Settings → Developer settings → Personal access tokens
   - Generate new token (classic) with `repo` scope
   - Copy token

2. **Update remote URL:**
   ```powershell
   git remote set-url origin https://YOUR_TOKEN@github.com/USERNAME/REPO.git
   ```

3. **Or use SSH instead:**
   ```powershell
   git remote set-url origin git@github.com:USERNAME/REPO.git
   ```

---

### Merge Conflicts

**Error:**
```
CONFLICT (content): Merge conflict in README.md
Automatic merge failed; fix conflicts and then commit the result.
```

**Cause:** Same file edited in both repos.

**Solution:**

1. **Check status:**
   ```powershell
   git status
   ```

2. **Open conflicted file** (marked with `<<<<<<<`, `=======`, `>>>>>>>`)

3. **Edit to keep desired version:**
   ```
   <<<<<<< HEAD
   Your local changes
   =======
   Remote changes
   >>>>>>> origin/main
   ```
   
   Remove conflict markers and keep what you want.

4. **Mark as resolved:**
   ```powershell
   git add README.md
   git commit -m "Resolve merge conflict"
   git push origin main
   ```

---

## Download Problems

### PDFs Not Downloading

**Symptoms:** Script runs but no PDF files appear.

**Diagnosis:**

```powershell
# Test GRC connectivity
Test-Connection www.grc.com -Count 4

# Test specific PDF URL
$testUrl = "https://www.grc.com/sn/sn-001-notes.pdf"
Invoke-WebRequest -Uri $testUrl -Method Head
```

**Solutions:**

1. **Check internet connection**
2. **Verify firewall/antivirus** isn't blocking downloads
3. **Test manual download:**
   ```powershell
   Invoke-WebRequest -Uri $testUrl -OutFile "test.pdf"
   ```
4. **Check GRC website status** (may be temporarily down)

---

### "403 Forbidden" Errors

**Error:**
```
Invoke-WebRequest : The remote server returned an error: (403) Forbidden.
```

**Cause:** GRC server rate-limiting or blocking automated requests.

**Solution:**

1. **The script already includes retry logic with delays**
2. **Increase delay between requests:**
   ```powershell
   # Edit script, find:
   Start-Sleep -Seconds 1
   # Change to:
   Start-Sleep -Seconds 3
   ```

3. **Run during off-peak hours** (late evening/early morning)

---

### Incomplete Downloads

**Symptoms:** PDF files exist but are corrupted or 0 bytes.

**Solution:**

```powershell
# Find 0-byte files
Get-ChildItem -Path $HOME\SecurityNowArchive -Recurse -File | 
  Where-Object { $_.Length -eq 0 }

# Delete them
Get-ChildItem -Path $HOME\SecurityNowArchive -Recurse -File | 
  Where-Object { $_.Length -eq 0 } | Remove-Item

# Re-run script to download again
.\scripts\SecurityNow-EndToEnd.ps1
```

---

## File Organization Issues

### Files Not Organized by Year

**Cause:** Script couldn't determine episode date.

**Solution:**

```powershell
# Manually organize by year
$sourceFolder = "$HOME\SecurityNowArchive\local\PDF"
$files = Get-ChildItem -Path $sourceFolder -Filter "*.pdf" -Recurse

foreach ($file in $files) {
    # Extract episode number from filename (sn-XXX-notes.pdf)
    if ($file.Name -match 'sn-(\d+)-notes\.pdf') {
        $episodeNum = [int]$Matches[1]
        
        # Estimate year (rough calculation)
        $year = 2005 + [Math]::Floor($episodeNum / 52)
        
        # Create year folder
        $yearFolder = Join-Path $sourceFolder $year
        if (-not (Test-Path $yearFolder)) {
            New-Item -Path $yearFolder -ItemType Directory -Force
        }
        
        # Move file
        Move-Item -Path $file.FullName -Destination $yearFolder
    }
}
```

---

### Duplicate Files

**Cause:** Script re-downloaded files that already exist.

**Solution:**

```powershell
# Find duplicate files
Get-ChildItem -Path $HOME\SecurityNowArchive -Recurse -File | 
  Group-Object Name | 
  Where-Object { $_.Count -gt 1 } | 
  Select-Object Name, Count

# Remove duplicates (keeps first occurrence)
Get-ChildItem -Path $HOME\SecurityNowArchive -Recurse -File | 
  Group-Object Name | 
  Where-Object { $_.Count -gt 1 } | 
  ForEach-Object { $_.Group | Select-Object -Skip 1 | Remove-Item }
```

---

## Sync Script Problems

### "ERROR: Private repo not found"

**Error:**
```
ERROR: Private repo not found: D:\Desktop\SecurityNow-Full-Private
```

**Cause:** Script looking in wrong location.

**Solution:**

```powershell
# Specify correct path
.\scripts\Sync-Repos.ps1 -PrivateRepo "C:\Your\Actual\Path\Private"

# Or update script default path
notepad .\scripts\Sync-Repos.ps1
# Change line:
[string]$PrivateRepo = "D:\Desktop\SecurityNow-Full-Private",
```

---

### Files Syncing That Shouldn't

**Cause:** Copyrighted files not properly excluded.

**Solution:**

1. **Check exclusion rules in Sync-Repos.ps1:**
   ```powershell
   $ExcludeFolders = @(
       "local\PDF",
       "local\mp3",
       "local\Notes\ai-transcripts"
   )
   ```

2. **Verify .gitignore in public repo:**
   ```
   local/PDF/
   local/mp3/
   local/Notes/ai-transcripts/
   *.pdf
   *.mp3
   ```

3. **Remove accidentally committed files:**
   ```powershell
   cd public-repo
   git rm -r local/PDF/
   git commit -m "Remove copyrighted content"
   git push origin main
   ```

---

### Sync Shows Changes But Files Are Identical

**Cause:** Line ending differences (CRLF vs LF) or file permissions.

**Solution:**

```powershell
# Configure Git to normalize line endings
git config --global core.autocrlf true

# Re-sync
.\scripts\Sync-Repos.ps1
```

---

## AI Transcription Issues

### Whisper.cpp Not Found

**Error:**
```
whisper.exe : The term 'whisper.exe' is not recognized
```

**Cause:** whisper.cpp not installed or path incorrect.

**Solution:**

1. **Download whisper.cpp:**
   ```powershell
   # Clone repo
   git clone https://github.com/ggerganov/whisper.cpp.git
   cd whisper.cpp
   
   # Build (requires Visual Studio or MinGW)
   cmake -B build
   cmake --build build --config Release
   ```

2. **Update script path:**
   ```powershell
   $whisperPath = "C:\path\to\whisper.cpp\build\bin\Release\main.exe"
   ```

---

### Transcription Extremely Slow

**Cause:** Using large Whisper model or CPU-only processing.

**Solution:**

1. **Use smaller model:**
   ```powershell
   # Instead of medium.en (slow)
   $whisperModel = "ggml-tiny.en.bin"  # Fast
   # Or
   $whisperModel = "ggml-base.en.bin"  # Balanced
   ```

2. **Enable GPU acceleration** (if available):
   ```powershell
   # Rebuild whisper.cpp with CUDA support
   cmake -B build -DWHISPER_CUDA=ON
   cmake --build build --config Release
   ```

---

### Transcripts Have Poor Accuracy

**Cause:** Using `tiny` model or audio quality issues.

**Solution:**

1. **Upgrade to better model:**
   ```powershell
   # Download medium model
   cd C:\whisper\models
   Invoke-WebRequest -Uri "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-medium.en.bin" -OutFile "ggml-medium.en.bin"
   
   # Update script
   $whisperModel = "C:\whisper\models\ggml-medium.en.bin"
   ```

2. **Check audio quality:**
   - Ensure MP3 files are not corrupted
   - Re-download if necessary

---

## Performance Problems

### Script Running Very Slow

**Diagnosis:**

```powershell
# Check disk I/O
Get-PhysicalDisk | Get-StorageReliabilityCounter | Select-Object DeviceId, Temperature, Wear

# Check CPU usage
Get-Process | Sort-Object CPU -Descending | Select-Object -First 5

# Check available memory
Get-CimInstance Win32_OperatingSystem | Select-Object FreePhysicalMemory
```

**Solutions:**

1. **Run during idle time** (overnight)
2. **Close other applications**
3. **Increase delays** (reduces server load, increases total time)
4. **Use SSD instead of HDD** for archive location

---

### Out of Disk Space

**Error:**
```
There is not enough space on the disk.
```

**Solution:**

```powershell
# Check available space
Get-PSDrive C

# Find large files
Get-ChildItem -Path $HOME\SecurityNowArchive -Recurse -File | 
  Sort-Object Length -Descending | 
  Select-Object -First 20 FullName, @{Name="SizeMB";Expression={[math]::Round($_.Length/1MB,2)}}

# Delete logs and temp files
Remove-Item $HOME\SecurityNowArchive\logs\* -Recurse -Force
Remove-Item $HOME\SecurityNowArchive\temp\* -Recurse -Force

# Or move archive to larger drive
Move-Item -Path $HOME\SecurityNowArchive -Destination "E:\SecurityNowArchive"
```

---

## GitHub Integration

### Push Rejected (Non-Fast-Forward)

**Error:**
```
 ! [rejected]        main -> main (non-fast-forward)
```

**Cause:** Remote has changes you don't have locally.

**Solution:**

```powershell
# Pull and merge
git pull origin main --no-edit

# Resolve any conflicts (see Merge Conflicts section)

# Push again
git push origin main
```

---

### Large File Rejected

**Error:**
```
remote: error: File local/PDF/sn-001-notes.pdf is 105.25 MB; this exceeds GitHub's file size limit of 100.00 MB
```

**Cause:** Accidentally committing copyrighted media files.

**Solution:**

```powershell
# Remove from staging
git reset HEAD local/PDF/sn-001-notes.pdf

# Ensure in .gitignore
echo "local/PDF/" >> .gitignore
echo "*.pdf" >> .gitignore

# Remove from Git history (if already committed)
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch local/PDF/sn-001-notes.pdf" \
  --prune-empty --tag-name-filter cat -- --all

# Force push (WARNING: rewrites history)
git push origin main --force
```

---

## Still Having Issues?

### Gather Diagnostic Information

```powershell
# System info
$PSVersionTable
Get-ComputerInfo | Select-Object WindowsVersion, OsArchitecture

# Git info
git --version
git remote -v

# Path info
$env:PATH -split ';'

# Disk space
Get-PSDrive

# Recent errors (if any)
Get-EventLog -LogName Application -EntryType Error -Newest 10
```

### Get Help

1. **Search existing issues:** [GitHub Issues](https://github.com/msrproduct/securitynow-archive-tools/issues)
2. **Open new issue** with:
   - Full error message
   - PowerShell version
   - OS version
   - Steps to reproduce
   - Diagnostic information above

3. **Community help:**
   - [GitHub Discussions](https://github.com/msrproduct/securitynow-archive-tools/discussions)
   - [GRC Forums](https://forums.grc.com/)

---

**Related Documentation:**

- [FAQ.md](FAQ.md) - Frequently asked questions
- [QUICK-START.md](QUICK-START.md) - Getting started guide
- [SYNC-REPOS-GUIDE.md](SYNC-REPOS-GUIDE.md) - Sync script documentation
