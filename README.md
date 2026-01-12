# Security Now! Archive Tools

A PowerShell-based toolkit for building and maintaining a personal archive of Steve Gibson's Security Now! podcast show notes and transcripts.

## 📋 What This Project Does

This toolkit helps you:
- Download official show notes PDFs from [Gibson Research Corporation (GRC)](https://www.grc.com/securitynow.htm)
- Generate AI-derived transcripts for episodes without official notes
- Organize everything by year in a clean folder structure
- Maintain a CSV index of all episodes

**Important**: This project respects copyright. It downloads content from official sources and generates AI transcripts only for missing episodes. All Security Now! content is © Steve Gibson/GRC and TWiT.tv.

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
│   │   │   ├── sn-1-notes-ai.pdf
│   │   │   └── ...
│   │   ├── 2024/
│   │   │   ├── sn-1000-notes.pdf
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
| 432 | https://www.grc.com/sn/sn-432-notes.pdf | sn-432-notes.pdf |
| 1000 | https://www.grc.com/sn/sn-1000-notes.pdf | sn-1000-notes.pdf |

- **Empty URL**: AI-derived transcript (no official notes existed)
- **GRC URL**: Official show notes from Steve Gibson

## 🔄 Updating for New Episodes

When new Security Now! episodes are released:

```powershell
.\scripts\SecurityNow-EndToEnd.ps1
```

The script automatically:
- Checks for new episodes on GRC
- Downloads new official notes
- Skips existing files (no re-downloads)
- Updates the CSV index

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
