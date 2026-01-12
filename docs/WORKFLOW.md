# Security Now! Archive - Detailed Workflow

This document provides step-by-step instructions for using the Security Now! Archive Tools, from initial setup through ongoing maintenance.

## Table of Contents

1. [First-Time Setup](#first-time-setup)
2. [Understanding the Process](#understanding-the-process)
3. [Running the Main Script](#running-the-main-script)
4. [What Happens During Execution](#what-happens-during-execution)
5. [Verifying Results](#verifying-results)
6. [Updating for New Episodes](#updating-for-new-episodes)
7. [Advanced Configuration](#advanced-configuration)
8. [Troubleshooting Common Issues](#troubleshooting-common-issues)

---

## First-Time Setup

### 1. Install Prerequisites

#### PowerShell 7+

**Check if you already have it:**
```powershell
pwsh --version
```

If you see `PowerShell 7.x.x` or higher, you're good to go.

**If not, install it:**
1. Visit [PowerShell Releases](https://github.com/PowerShell/PowerShell/releases)
2. Download the `.msi` installer for Windows
3. Run the installer (accept all defaults)
4. Restart your terminal

#### Whisper.cpp (Speech-to-Text)

**What this does:** Converts audio files to text transcripts for episodes that never had official show notes.

**Installation steps:**

1. **Download the pre-built binary:**
   - Visit [whisper.cpp releases](https://github.com/ggerganov/whisper.cpp/releases)
   - Download `whisper-bin-x64.zip` (or similar for Windows)
   - Extract to `C:\whisper` (or your preferred location)

2. **Download a model file:**
   - Visit [whisper.cpp models](https://huggingface.co/ggerganov/whisper.cpp/tree/main)
   - Download `ggml-base.en.bin` (recommended balance of speed/accuracy)
   - Place it in the same folder as `whisper-cli.exe` (e.g., `C:\whisper\ggml-base.en.bin`)

3. **Test it works:**
   ```powershell
   C:\whisper\whisper-cli.exe --help
   ```
   You should see usage instructions.

**Note:** If you place whisper somewhere other than `C:\whisper`, remember that path—you'll configure it in Step 3.

#### Git (Optional)

Only needed if cloning the repository. Otherwise, download as ZIP from GitHub.

**Install:**
- Visit [git-scm.com](https://git-scm.com/downloads)
- Download and run the installer
- Accept all defaults

---

### 2. Get the Repository

**Option A - Clone with Git (Recommended):**
```powershell
cd $HOME\Documents
git clone https://github.com/msrproduct/securitynow-archive-tools.git
cd securitynow-archive-tools
```

**Option B - Download ZIP:**
1. Go to [the repository](https://github.com/msrproduct/securitynow-archive-tools)
2. Click the green **Code** button
3. Select **Download ZIP**
4. Extract to `Documents\securitynow-archive-tools`

---

### 3. Configure the Script

Open `scripts/SecurityNow-EndToEnd.ps1` in your favorite text editor (Notepad, VS Code, etc.).

**Find these lines near the top:**
```powershell
# --------- CONFIG: PATHS ---------
$WhisperExe = "C:\whisper\whisper-cli.exe"
$WhisperModel = "C:\whisper\ggml-base.en.bin"
$Root = "$HOME\SecurityNowArchive"
```

**Customize them:**

| Variable | What It Is | Example Value |
|----------|------------|---------------|
| `$WhisperExe` | Path to whisper-cli.exe | `C:\whisper\whisper-cli.exe` |
| `$WhisperModel` | Path to the model file | `C:\whisper\ggml-base.en.bin` |
| `$Root` | Where to store your archive | `$HOME\SecurityNowArchive` |

**Important:**
- Use **double backslashes** (`\\`) in paths, or single forward slashes (`/`)
- `$HOME` automatically points to your user folder (e.g., `C:\Users\YourName`)
- Don't use hard-coded paths like `D:\` unless you're sure that drive exists on any machine you'll run this on

**Save the file** after making changes.

---

### 4. Allow PowerShell to Run Scripts

By default, Windows blocks PowerShell scripts for security.

**Open PowerShell 7 as Administrator:**
1. Press `Windows Key`
2. Type `pwsh`
3. Right-click **PowerShell 7** and select **Run as Administrator**

**Run this command:**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**When prompted, type `Y` and press Enter.**

This allows locally created scripts to run, while still requiring downloaded scripts to be signed.

---

## Understanding the Process

Before running the script, here's what it does:

### Phase 1: Discovery
- Scans GRC's archive pages for all Security Now! episodes (2005-2025+)
- Builds a list of episode numbers and their official show notes URLs
- Identifies episodes **without** official show notes PDFs

### Phase 2: Download Official Notes
- Downloads all available `sn-###-notes.pdf` files from GRC
- Organizes them by year into folders: `2005/`, `2006/`, ..., `2025/`
- Skips episodes that already exist locally (no re-downloads)

### Phase 3: AI Transcript Generation (Optional)
- For episodes **without** official notes:
  - Downloads the audio (MP3) from GRC or TWiT
  - Runs Whisper.cpp to transcribe audio → text
  - Wraps the transcript in an HTML template with a disclaimer
  - Converts HTML → PDF with a clear "AI-GENERATED" warning

### Phase 4: Index Update
- Updates `data/SecurityNowNotesIndex.csv` with:
  - Episode number
  - Source URL (GRC link or "AI-generated")
  - Filename

---

## Running the Main Script

### Initial Full Run

**This will take several hours** because it:
- Downloads 500+ PDFs from GRC
- Generates AI transcripts for ~100 episodes without official notes
- Each AI transcript takes 2-5 minutes depending on episode length

**Execute:**
```powershell
cd path\to\securitynow-archive-tools
.\scripts\SecurityNow-EndToEnd.ps1
```

**What you'll see:**
```
Security Now! Archive - Full Run
Root: C:\Users\YourName\SecurityNowArchive
Whisper: C:\whisper\whisper-cli.exe

[Phase 1] Discovering episodes from GRC...
Found 1045 episodes across 2005-2025

[Phase 2] Downloading official show notes PDFs...
Episode 432: Downloaded sn-432-notes.pdf → 2013/
Episode 433: Downloaded sn-433-notes.pdf → 2013/
...

[Phase 3] Generating AI transcripts for missing episodes...
Episode 1: No official notes found
  → Downloading MP3...
  → Running Whisper transcription...
  → Creating AI-derived PDF with disclaimer...
  → Filed as 2005/sn-1-notes-ai.pdf
...

[Phase 4] Updating index CSV...
Index updated: 1045 episodes

Complete! Archive location: C:\Users\YourName\SecurityNowArchive
```

**You can safely interrupt** with `Ctrl+C` and resume later—the script skips already-processed episodes.

---

## What Happens During Execution

### Folder Structure Created

```
SecurityNowArchive/
├── data/
│   └── SecurityNowNotesIndex.csv
├── local/
│   ├── PDF/
│   │   ├── 2005/
│   │   │   ├── sn-1-notes-ai.pdf      ← AI-generated (no official notes)
│   │   │   ├── sn-2-notes.pdf         ← Official GRC notes
│   │   │   └── ...
│   │   ├── 2006/
│   │   ├── .../
│   │   └── 2025/
│   ├── mp3/
│   │   ├── sn-1.mp3                   ← Audio for AI episodes
│   │   └── ...
│   └── Notes/
│       └── ai-transcripts/
│           ├── sn-1-notes-ai.txt      ← Raw transcript text
│           └── ...
```

### File Naming Conventions

| Type | Pattern | Example |
|------|---------|----------|
| Official GRC PDF | `sn-###-notes.pdf` | `sn-432-notes.pdf` |
| AI-generated PDF | `sn-###-notes-ai.pdf` | `sn-1-notes-ai.pdf` |
| Audio file | `sn-###.mp3` | `sn-1.mp3` |
| Transcript text | `sn-###-notes-ai.txt` | `sn-1-notes-ai.txt` |

### CSV Index Format

Open `data/SecurityNowNotesIndex.csv` in Excel:

| Episode | Url | File |
|---------|-----|------|
| 1 | (empty) | sn-1-notes-ai.pdf |
| 2 | https://www.grc.com/sn/sn-2-notes.pdf | sn-2-notes.pdf |
| 432 | https://www.grc.com/sn/sn-432-notes.pdf | sn-432-notes.pdf |

**Key:**
- **Empty Url**: AI-generated transcript (no official notes exist)
- **GRC Url**: Official show notes from Steve Gibson

---

## Verifying Results

### Check File Counts

```powershell
cd $HOME\SecurityNowArchive\local\PDF

# Count PDFs by year
Get-ChildItem -Recurse -Filter *.pdf | Group-Object DirectoryName | Select-Object Name, Count

# Count AI-generated vs. official
Get-ChildItem -Recurse -Filter *-ai.pdf | Measure-Object | Select-Object Count
Get-ChildItem -Recurse -Filter *-notes.pdf -Exclude *-ai.pdf | Measure-Object | Select-Object Count
```

### Spot-Check Episodes

**Open a few PDFs to verify:**

1. **Official notes** (e.g., `2024/sn-1000-notes.pdf`):
   - Should be Steve Gibson's original show notes
   - Clean, professional formatting

2. **AI-generated notes** (e.g., `2005/sn-1-notes-ai.pdf`):
   - Should have a red disclaimer at the top:
     > "THIS IS AN AUTOMATICALLY GENERATED TRANSCRIPT/NOTES FILE..."
   - Contains transcript text below

### Check the CSV Index

```powershell
Import-Csv $HOME\SecurityNowArchive\data\SecurityNowNotesIndex.csv | Measure-Object
```

Should show ~1000+ episodes (as of 2025).

---

## Updating for New Episodes

As Steve Gibson releases new Security Now! episodes:

### Weekly Update

**Simply re-run the script:**
```powershell
cd path\to\securitynow-archive-tools
.\scripts\SecurityNow-EndToEnd.ps1
```

**What happens:**
- Checks GRC for new episode PDFs
- Downloads any new official notes
- Skips existing episodes (very fast)
- Updates the CSV index

**Tip:** Run this weekly or monthly to stay current.

### Force Re-Process a Single Episode

If you need to regenerate a specific episode (e.g., improved AI model):

```powershell
# Delete the existing files
Remove-Item $HOME\SecurityNowArchive\local\PDF\2005\sn-1-notes-ai.pdf
Remove-Item $HOME\SecurityNowArchive\local\mp3\sn-1.mp3
Remove-Item $HOME\SecurityNowArchive\local\Notes\ai-transcripts\sn-1-notes-ai.txt

# Re-run the script (it will regenerate missing files)
.\scripts\SecurityNow-EndToEnd.ps1
```

---

## Advanced Configuration

### Episode Range Filtering

Edit `SecurityNow-EndToEnd.ps1` to process specific episodes:

```powershell
# Near the top, add:
$MinEpisode = 1
$MaxEpisode = 100  # Only process episodes 1-100
```

### Dry-Run Mode

Test without downloading:

```powershell
# Add this parameter in the script
$DryRun = $true

# Then wrap download commands:
if (-not $DryRun) {
    Invoke-WebRequest -Uri $url -OutFile $path
}
```

### Whisper Model Selection

| Model | Size | Speed | Accuracy |
|-------|------|-------|----------|
| `ggml-tiny.en.bin` | 75 MB | Fastest | Lower |
| `ggml-base.en.bin` | 142 MB | **Recommended** | Good |
| `ggml-small.en.bin` | 466 MB | Slower | Better |
| `ggml-medium.en.bin` | 1.5 GB | Slow | Best |

Change the model path in the script:
```powershell
$WhisperModel = "C:\whisper\ggml-medium.en.bin"
```

---

## Troubleshooting Common Issues

### Issue: "Whisper-cli.exe is not recognized"

**Cause:** Path to Whisper is incorrect.

**Fix:**
1. Verify the file exists:
   ```powershell
   Test-Path "C:\whisper\whisper-cli.exe"
   ```
2. If `False`, find where you extracted Whisper
3. Update the path in `SecurityNow-EndToEnd.ps1`

---

### Issue: "Cannot run script - execution policy"

**Cause:** PowerShell security is blocking scripts.

**Fix:**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

---

### Issue: AI transcripts are blank or garbled

**Cause:** Whisper model file is missing or corrupted.

**Fix:**
1. Verify the model exists:
   ```powershell
   Test-Path "C:\whisper\ggml-base.en.bin"
   ```
2. If missing, re-download from [Hugging Face](https://huggingface.co/ggerganov/whisper.cpp/tree/main)
3. Ensure it's in the same folder as `whisper-cli.exe`

---

### Issue: PDFs not organizing by year

**Cause:** Episode number not parsed correctly from filename.

**Fix:**
1. Check the filename pattern matches `sn-###-notes.pdf` or `sn-###-notes-ai.pdf`
2. Verify the year-mapping function in the script covers all episodes
3. Manually move misplaced files:
   ```powershell
   Move-Item local\PDF\sn-432-notes.pdf local\PDF\2013\
   ```

---

### Issue: Download fails with "403 Forbidden" or "404 Not Found"

**Cause:** GRC server is temporarily unavailable, or the episode doesn't exist.

**Fix:**
1. Wait a few minutes and retry
2. Check manually if the PDF exists on [GRC's site](https://www.grc.com/securitynow.htm)
3. If it's a missing episode, the script should skip it and attempt AI generation

---

### Issue: Script runs very slowly

**Cause:** AI transcription is CPU-intensive.

**Optimization tips:**
- Use a smaller Whisper model (`ggml-tiny.en.bin` or `ggml-base.en.bin`)
- Process only recent episodes by setting `$MinEpisode` higher
- Run overnight or during off-hours

**Expected times:**
- Download PDFs: ~30 minutes (first run)
- AI transcription: ~2-5 minutes per episode × ~100 episodes = 3-8 hours

---

### Issue: CSV index is missing episodes

**Cause:** Script interrupted before index was written.

**Fix:**
1. Delete the partial CSV:
   ```powershell
   Remove-Item $HOME\SecurityNowArchive\data\SecurityNowNotesIndex.csv
   ```
2. Re-run the script (it will rebuild the index from existing files)

---

## Getting Help

If you encounter issues not covered here:

1. **Check existing issues:** [GitHub Issues](https://github.com/msrproduct/securitynow-archive-tools/issues)
2. **Open a new issue:** Include:
   - Your PowerShell version (`pwsh --version`)
   - Whisper version/model used
   - Error messages (copy/paste from terminal)
   - Operating system version

---

## Next Steps

- **Customize the script** for your specific needs (see Advanced Configuration)
- **Set up automatic weekly runs** using Windows Task Scheduler
- **Explore the archive** using the CSV index to find episodes by topic
- **Contribute improvements** via pull requests on GitHub

---

**Happy archiving!** 📚🔒
