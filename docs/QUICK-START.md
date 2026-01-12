# Quick Start Guide

Get your Security Now! archive up and running in under 30 minutes.

---

## Prerequisites

**Before you begin, ensure you have:**

- ✅ Windows 10/11, macOS 10.15+, or Linux (Ubuntu 20.04+)
- ✅ PowerShell 7.0 or higher ([Download here](https://github.com/PowerShell/PowerShell))
- ✅ Git installed ([Download here](https://git-scm.com/))
- ✅ 5-10 GB free disk space
- ✅ Internet connection

**Check PowerShell version:**
```powershell
$PSVersionTable.PSVersion
# Should show 7.0 or higher
```

**Optional tools:**
- **wkhtmltopdf** for HTML → PDF conversion ([Download](https://wkhtmltopdf.org/downloads.html))
  - Windows: `winget install wkhtmltopdf`
  - macOS: `brew install wkhtmltopdf`
  - Linux: `apt-get install wkhtmltopdf` or `yum install wkhtmltopdf`

---

## Setup (5 minutes)

### Step 1: Clone the Repository

```powershell
# Choose a location for your archive
cd D:\Desktop

# Clone the public repo
git clone https://github.com/msrproduct/securitynow-archive-tools.git SecurityNow-Full

# Navigate into it
cd SecurityNow-Full
```

### Step 2: Configure Paths

Edit the main script to set your archive location:

```powershell
# Open the script in your editor
notepad .\scripts\SecurityNow-EndToEnd.ps1

# Find and update this line:
$archiveRoot = "$HOME\SecurityNowArchive"  # Change to your preferred location
```

### Step 3: Create Archive Structure

```powershell
# Create the folder structure
$archiveRoot = "$HOME\SecurityNowArchive"
New-Item -Path $archiveRoot -ItemType Directory -Force
New-Item -Path "$archiveRoot\local\PDF" -ItemType Directory -Force
New-Item -Path "$archiveRoot\local\mp3" -ItemType Directory -Force
New-Item -Path "$archiveRoot\local\Notes\ai-transcripts" -ItemType Directory -Force
```

### Step 4: Install wkhtmltopdf (Optional)

For converting HTML show notes to PDF:

**Windows:**
```powershell
winget install wkhtmltopdf
# Restart PowerShell after installation
```

**macOS:**
```bash
brew install wkhtmltopdf
```

**Linux:**
```bash
# Debian/Ubuntu
sudo apt-get install wkhtmltopdf

# RHEL/CentOS
sudo yum install wkhtmltopdf
```

**Verify installation:**
```powershell
wkhtmltopdf --version
# Should show: wkhtmltopdf 0.12.6
```

---

## First Run (30-60 minutes)

### Basic Archive (Official PDFs Only)

If you only want official show notes PDFs:

```powershell
# Run the main script
.\scripts\SecurityNow-EndToEnd.ps1

# This will:
# - Download all official PDFs from GRC (~500 files)
# - Organize by year
# - Create CSV index
# - Convert HTML notes to PDF (if wkhtmltopdf installed)
# - Skip AI transcription (requires additional setup)
```

**Expected time:** 30-60 minutes depending on internet speed

### Monitor Progress

The script displays:
- Current episode being processed
- Download status
- HTML → PDF conversion (if applicable)
- File organization updates
- Final summary

```
Processing episode 1 of 1000...
[OK] Downloaded sn-001-notes.pdf
Processing episode 2 of 1000...
[SKIP] sn-002-notes.pdf not available
[OK] Converted HTML to PDF: sn-002-notes.pdf
...
```

---

## Verify Your Archive

### Check File Structure

```powershell
# View your archive structure
Get-ChildItem $HOME\SecurityNowArchive -Recurse -Directory

# Should show:
# local/
# local/PDF/
# local/PDF/2005/
# local/PDF/2006/
# ...
# local/PDF/2025/
```

### Check CSV Index

```powershell
# View the episode index
Import-Csv .\data\SecurityNowNotesIndex.csv | Select-Object -First 10

# Shows episode numbers, titles, URLs, local paths
```

---

## Daily Usage

### Update for New Episodes

Run monthly or after each new episode:

```powershell
cd D:\Desktop\SecurityNow-Full
.\scripts\SecurityNow-EndToEnd.ps1

# Only downloads NEW episodes (skips existing files)
# Takes 1-2 minutes
```

### Search Your Archive

**Find episodes by topic:**
```powershell
# Search filenames
Get-ChildItem -Path $HOME\SecurityNowArchive -Recurse -Filter *.pdf | 
  Where-Object { $_.Name -like "*ransomware*" }

# Search CSV index
Import-Csv .\data\SecurityNowNotesIndex.csv | 
  Where-Object { $_.Title -like "*encryption*" }
```

---

## Two-Repo Setup (Private + Public)

### Why Two Repos?

- **Private repo:** Your complete archive (PDFs, MP3s, scripts)
- **Public repo:** Only scripts and docs (safe to share on GitHub)

This setup lets you:
- Keep copyrighted content private
- Contribute improvements to the public community
- Stay synced with updates

### Setup Private Repo

```powershell
# Create private clone
cd D:\Desktop
cp -r SecurityNow-Full SecurityNow-Full-Private
cd SecurityNow-Full-Private

# Initialize as separate Git repo
rm -rf .git
git init
git add .
git commit -m "Initial private archive"

# Create private GitHub repo and push
# (Do this via GitHub website: New Repository > Private)
git remote add origin https://github.com/YOUR-USERNAME/securitynow-full-archive.git
git branch -M main
git push -u origin main
```

### Use Sync Script

```powershell
# Work in private repo
cd D:\Desktop\SecurityNow-Full-Private

# Make changes, add scripts, update docs
# ...

# Commit to private
git add .
git commit -m "My changes"
git push origin main

# Sync non-copyrighted files to public
.\scripts\Sync-Repos.ps1

# Done! Public repo updated automatically
```

---

## Optional: AI Transcripts

### Prerequisites

- **whisper.cpp** installed ([Instructions](https://github.com/ggerganov/whisper.cpp))
- **Whisper model** downloaded (e.g., `ggml-base.en.bin`)
- **8 GB RAM** recommended

### Enable Transcription

```powershell
# Edit script
notepad .\scripts\SecurityNow-EndToEnd.ps1

# Set these variables:
$enableAITranscripts = $true
$whisperPath = "C:\whisper\main.exe"  # Windows
# $whisperPath = "/usr/local/bin/main"  # macOS/Linux
$whisperModel = "C:\whisper\models\ggml-base.en.bin"
```

### First Transcription Run

```powershell
# Run the script
.\scripts\SecurityNow-EndToEnd.ps1

# Will transcribe ~100 episodes without official notes
# Expect 2-7 hours depending on CPU speed
```

---

## Troubleshooting Quick Fixes

### "Cannot run scripts" error

```powershell
# Set execution policy (once)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### "Git not found" error

```powershell
# Verify Git installation
git --version

# If not installed, download from https://git-scm.com/
```

### "wkhtmltopdf not found" error

```powershell
# Check if installed
wkhtmltopdf --version

# If not found:
# Windows: winget install wkhtmltopdf
# macOS: brew install wkhtmltopdf
# Linux: apt-get install wkhtmltopdf

# Restart PowerShell after installation
```

### Downloads failing

```powershell
# Check internet connection
Test-Connection www.grc.com -Count 2

# Try again (script auto-retries failed downloads)
.\scripts\SecurityNow-EndToEnd.ps1
```

### Disk space full

```powershell
# Check available space
Get-PSDrive C

# Delete old logs or temporary files
Remove-Item $HOME\SecurityNowArchive\logs\* -Recurse -Force
```

---

## Next Steps

### Learn More

- 📚 [FAQ.md](FAQ.md) - Common questions answered
- 🔧 [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Detailed problem solving
- 📦 [SYNC-REPOS-GUIDE.md](SYNC-REPOS-GUIDE.md) - Two-repo workflow
- 📋 [WORKFLOW.md](WORKFLOW.md) - Complete archiving workflow

### Get Help

- [GitHub Issues](https://github.com/msrproduct/securitynow-archive-tools/issues) - Report bugs
- [GitHub Discussions](https://github.com/msrproduct/securitynow-archive-tools/discussions) - Ask questions
- [GRC Forums](https://forums.grc.com/) - Security Now! community

### Contribute

- [CONTRIBUTING.md](../CONTRIBUTING.md) - How to contribute improvements

---

## Quick Reference

### Essential Commands

| Task | Command |
|------|----------|
| Initial setup | `git clone https://github.com/msrproduct/securitynow-archive-tools.git` |
| Install wkhtmltopdf (Windows) | `winget install wkhtmltopdf` |
| Install wkhtmltopdf (macOS) | `brew install wkhtmltopdf` |
| Install wkhtmltopdf (Linux) | `apt-get install wkhtmltopdf` |
| Build archive | `.\scripts\SecurityNow-EndToEnd.ps1` |
| Update archive | `.\scripts\SecurityNow-EndToEnd.ps1` |
| Sync repos | `.\scripts\Sync-Repos.ps1` |
| Test sync | `.\scripts\Sync-Repos.ps1 -DryRun -Verbose` |
| Check PowerShell version | `$PSVersionTable.PSVersion` |
| Check wkhtmltopdf | `wkhtmltopdf --version` |

### File Locations

| Item | Default Location |
|------|------------------|
| Archive root | `$HOME\SecurityNowArchive` |
| PDFs | `$HOME\SecurityNowArchive\local\PDF\YYYY\` |
| MP3s | `$HOME\SecurityNowArchive\local\mp3\` |
| Transcripts | `$HOME\SecurityNowArchive\local\Notes\ai-transcripts\` |
| CSV index | `.\data\SecurityNowNotesIndex.csv` |
| Scripts | `.\scripts\` |

### Cross-Platform Paths

| Tool | Windows | macOS/Linux |
|------|---------|-------------|
| wkhtmltopdf | `C:\Program Files\wkhtmltopdf\bin\wkhtmltopdf.exe` | `/usr/local/bin/wkhtmltopdf` |
| whisper.cpp | `C:\whisper\main.exe` | `/usr/local/bin/main` |

---

**You're all set!** 🎉 Your Security Now! archive is ready to use.
