# Security Now! Archive Tools

A PowerShell-based toolkit for building and maintaining a personal archive of Steve Gibson's Security Now! podcast show notes and transcripts.

## 📋 What This Project Does

This toolkit helps you:
- Download official show notes PDFs from [Gibson Research Corporation (GRC)](https://www.grc.com/securitynow.htm)
- Generate AI-derived transcripts for episodes without official notes
- Organize everything by year in a clean folder structure
- Maintain a CSV index of all episodes

**Important**: This project respects copyright. It downloads content from official sources and generates AI transcripts only for missing episodes. All Security Now! content is © Steve Gibson/GRC and TWiT.tv.

## 💖 Support This Project

If this toolkit saves you time organizing your Security Now! archive, consider supporting its development:

[![GitHub Sponsor](https://img.shields.io/badge/Sponsor-💖-pink?logo=githubsponsors)](https://github.com/sponsors/msrproduct)
[![Buy Me A Coffee](https://img.shields.io/badge/Buy%20Me%20A%20Coffee-☕-yellow?logo=buymeacoffee)](https://www.buymeacoffee.com/msrproduct)

**Your support helps cover:**
- Compute costs for AI transcription (Whisper processing)
- Development time maintaining episode mappings
- Testing with new Security Now! episodes
- Server costs for hosting documentation

**Note**: All donations are voluntary. This project is and will always remain **free and open-source**. Every feature is available to everyone, regardless of contribution.

---

## ⭐ What Makes This Project Different

### Single Script, Complete Automation

**One PowerShell script does everything:**
- ✅ **Past episodes** (2005-2025+): Downloads all 1000+ official show notes from GRC
- ✅ **Missing episodes**: Automatically generates AI transcripts for ~100 episodes that never had official notes
- ✅ **Future episodes**: Simply re-run the script after new episodes air—it automatically detects and downloads them
- ✅ **Consistent format**: Every episode gets a PDF (official or AI-generated), organized by year

### Complete Coverage, Zero Manual Work

Unlike other archival solutions:
- **No manual downloads** - Script handles GRC.com and TWiT.tv automatically
- **No gaps** - AI fills in missing episodes with clearly marked transcripts
- **Future-proof** - Same script works for episodes 1-1000+ and beyond
- **Smart detection** - Checks both GRC and TWiT for official notes before generating AI versions

### Intelligent Fallback System

**For each episode, the script:**

1. **First**: Checks GRC.com for official show notes PDF → Downloads if available
2. **Second**: If no official notes, checks TWiT.tv for embedded PDFs → Downloads if found
3. **Third**: If still missing, downloads audio (MP3) and generates AI transcript → Converts to PDF with disclaimer
4. **Result**: Every episode has consistent PDF documentation, clearly marked as official or AI-generated

**You get a complete archive** with one command—no manual intervention, no gaps, ready for research.

## ⚙️ Prerequisites

Before you begin, ensure you have:

### 1. PowerShell 7+
**What it is**: The scripting environment that runs the automation.

**Installation**:
- Windows: Download from [Microsoft's PowerShell GitHub](https://github.com/PowerShell/PowerShell/releases)
- Already have it? Check version: `pwsh --version`

### 2. Whisper.cpp (Speech-to-Text Engine)
**What it is**: Converts audio files to text transcripts.

**Why needed**: Creates transcripts for episodes that never had official show notes.

**Installation** (Windows):
1. Download from [whisper.cpp releases](https://github.com/ggerganov/whisper.cpp/releases)
2. Extract to a folder (e.g., `C:\whisper`)
3. Download a model file (recommend `ggml-base.en.bin`) into the same folder
4. Note the path—you'll configure this in the script

### 3. Git (Optional)
Only needed if you want to clone the repository instead of downloading as ZIP.

**Installation**: [git-scm.com](https://git-scm.com/downloads)

### 4. Chrome or Edge Browser
Required for converting HTML transcripts to PDF format. Most Windows systems already have Edge.

## 🚀 Quick Start

### Step 1: Get the Code

**Option A - Clone with Git**:
```powershell
git clone https://github.com/msrproduct/securitynow-archive-tools.git
cd securitynow-archive-tools
```

**Option B - Download ZIP**:
1. Click the green "Code" button above
2. Select "Download ZIP"
3. Extract to a folder of your choice

### Step 2: Configure Paths

Open `scripts/SecurityNow-EndToEnd.ps1` in a text editor and update these lines (near the top):

```powershell
# Your whisper.cpp installation
$WhisperExe = "C:\whisper\whisper-cli.exe"
$WhisperModel = "C:\whisper\ggml-base.en.bin"

# Your preferred root folder (change as needed)
$Root = "$HOME\SecurityNowArchive"
```

**Note**: Replace `C:\whisper\` with wherever you installed Whisper. The `$HOME` variable automatically uses your user folder, so you don't need to hard-code paths.

### Step 3: Allow Script Execution

PowerShell's default security prevents running scripts. Open PowerShell 7 **as Administrator** and run:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Step 4: Run the Script

Navigate to your repository folder and run:

```powershell
cd path\to\securitynow-archive-tools
.\scripts\SecurityNow-EndToEnd.ps1
```

**First run will take time** (hours) as it downloads hundreds of PDFs and generates AI transcripts for missing episodes.

## 📁 Output Structure

After running, you'll have:

```
SecurityNowArchive/
├── data/
│   └── SecurityNowNotesIndex.csv    # Master index
├── local/
│   ├── PDF/
│   │   ├── 2005/
│   │   │   ├── sn-1-notes-ai.pdf    ← AI-generated (no official notes)
│   │   │   ├── sn-2-notes.pdf       ← Official GRC notes
│   │   │   └── ...
│   │   ├── 2024/
│   │   │   ├── sn-1000-notes.pdf    ← Official GRC notes
│   │   │   └── ...
│   ├── mp3/
│   │   └── sn-1.mp3 (audio for AI episodes)
│   └── Notes/
│       └── ai-transcripts/
│           └── sn-1-notes-ai.txt
```

## 📊 Understanding the CSV Index

Open `data/SecurityNowNotesIndex.csv` in Excel or any spreadsheet app:

| Episode | Url | File |
|---------|-----|------|
| 1 | (empty - AI generated) | sn-1-notes-ai.pdf |
| 2 | https://www.grc.com/sn/sn-2-notes.pdf | sn-2-notes.pdf |
| 432 | https://www.grc.com/sn/sn-432-notes.pdf | sn-432-notes.pdf |
| 1000 | https://www.grc.com/sn/sn-1000-notes.pdf | sn-1000-notes.pdf |

- **Empty URL**: AI-derived transcript (no official notes existed)
- **GRC URL**: Official show notes from Steve Gibson

**Every episode is documented** with a consistent PDF format, making your entire archive searchable and complete.

## 🔄 Updating for New Episodes

When new Security Now! episodes are released:

```powershell
.\scripts\SecurityNow-EndToEnd.ps1
```

The script automatically:
- Checks for new episodes on GRC and TWiT
- Downloads new official notes (if available)
- Generates AI transcripts (if official notes don't exist)
- Skips existing files (no re-downloads)
- Updates the CSV index

**Same script, works forever** - Run it weekly, monthly, or after each new episode to stay current.

## 🔐 Public vs. Private Usage

This repository contains **only scripts and the index**—no copyrighted content.

To maintain a full private archive:
1. Clone this public repo to a private location
2. Run the script there to build your local archive
3. Keep the `local/` folder private (backup to OneDrive, etc.)
4. Never commit PDFs/MP3s to a public repo

## 🛠️ Troubleshooting

### "Script not digitally signed"
Run: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`

### "Whisper-cli.exe not found"
- Verify the path in `SecurityNow-EndToEnd.ps1` matches your installation
- Ensure `whisper-cli.exe` and the model file are in the same folder

### AI transcripts not generating
- Check that the MP3 downloaded successfully
- Verify Whisper model file exists (e.g., `ggml-base.en.bin`)
- Look for error messages in the PowerShell output

### PDFs not organizing by year
- Ensure the script completed without errors
- Check that episode numbers in filenames are correct

## 🙏 Credits

- **Security Now!** podcast: © Steve Gibson, [Gibson Research Corporation](https://www.grc.com)
- **Podcast host**: [TWiT.tv](https://twit.tv/shows/security-now)
- **Speech-to-text**: [whisper.cpp](https://github.com/ggerganov/whisper.cpp)

This project is an unofficial archival tool for personal research and does not redistribute copyrighted content.

## 📝 License

This tooling is released under the MIT License. Security Now! content remains © Steve Gibson/GRC and TWiT.

---

**Questions?** Open an issue on GitHub or consult the detailed `WORKFLOW.md` in the `docs/` folder.