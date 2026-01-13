# Security Now! Archive Builder - Quick-Start Guide
**Version 2.1 - wkhtmltopdf Edition**

Last Updated: January 13, 2026

---

## 🎯 What This Script Does

Automatically builds a **complete archive** of Security Now! podcast episodes:

- ✅ **Downloads official GRC show-notes PDFs** (600+ episodes)
- ✅ **Generates AI transcripts** for missing episodes using Whisper
- ✅ **Creates professional PDFs** with wkhtmltopdf (no browser needed!)
- ✅ **Organizes by year** (2005-2026+)
- ✅ **Tracks everything** in a CSV index
- ✅ **Supports future episodes** - just re-run the script!

---

## ⚡ Installation (5 Minutes)

### Step 1: Install Required Tools

#### **Windows:**
```powershell
# Install wkhtmltopdf (required for PDF creation)
winget install wkhtmltopdf

# Install Whisper.cpp (required for AI transcription)
# Download from: https://github.com/ggerganov/whisper.cpp/releases
# Extract to: C:\Tools\whispercpp\
```

#### **macOS:**
```bash
# Install wkhtmltopdf
brew install wkhtmltopdf

# Install Whisper.cpp
brew install whisper-cpp
```

#### **Linux:**
```bash
# Install wkhtmltopdf
sudo apt install wkhtmltopdf

# Install Whisper.cpp from source
# See: https://github.com/ggerganov/whisper.cpp
```

### Step 2: Download Whisper Model

```powershell
# Windows example - adjust paths as needed
cd C:\Tools\whispercpp\models
# Download ggml-base.en.bin from:
# https://huggingface.co/ggerganov/whisper.cpp/tree/main
```

### Step 3: Save the Script

1. **Copy the production script** from `scripts/sn-full-run.ps1`
2. **Save locally** in your preferred location
   - Example: `D:\SecurityNow\scripts\sn-full-run.ps1`

### Step 4: Edit Configuration (Optional)

Open `sn-full-run.ps1` and adjust these lines if needed:

```powershell
# Lines 20-21: Whisper paths
$WhisperExe = "C:\Tools\whispercpp\whisper-cli.exe"
$WhisperModel = "C:\Tools\whispercpp\models\ggml-base.en.bin"

# Line 58: Default archive location
[string]$Root = "$HOME\SecurityNowArchive"
```

---

## 🚀 Usage

### Basic Usage

```powershell
# Full archive build (all episodes)
.\sn-full-run.ps1

# Preview what will happen (no downloads)
.\sn-full-run.ps1 -DryRun

# Only process recent episodes (900+)
.\sn-full-run.ps1 -MinEpisode 900

# Custom archive location
.\sn-full-run.ps1 -Root "D:\MyArchive"
```

### Advanced Usage

```powershell
# Process specific episode range
.\sn-full-run.ps1 -MinEpisode 500 -MaxEpisode 600

# Update archive with new episodes (safe to re-run)
.\sn-full-run.ps1

# Test mode before production run
.\sn-full-run.ps1 -DryRun -MinEpisode 1 -MaxEpisode 10
```

---

## 📁 Archive Structure

After running, your archive will look like this:

```
SecurityNowArchive/
├── SecurityNowNotesIndex.csv          # Master index of all episodes
└── local/
    ├── PDF/                            # Organized by year
    │   ├── 2005/
    │   │   ├── sn-1-notes-ai.pdf      # AI-generated (red disclaimer banner)
    │   │   ├── sn-2-notes-ai.pdf
    │   │   └── ...
    │   ├── 2024/
    │   │   ├── sn-1000-notes.pdf      # Official GRC notes
    │   │   ├── sn-1001-notes.pdf
    │   │   └── ...
    │   └── 2025/
    ├── mp3/                            # Downloaded audio files
    │   ├── sn-1.mp3
    │   └── ...
    └── Notes/
        └── ai-transcripts/             # Raw Whisper transcripts
            ├── sn-1-notes-ai.txt
            └── ...
```

---

## 🔧 Troubleshooting

### "wkhtmltopdf not found"
**Solution:** Install wkhtmltopdf:
- Windows: `winget install wkhtmltopdf`
- macOS: `brew install wkhtmltopdf`
- Linux: `sudo apt install wkhtmltopdf`

### "Whisper not found"
**Solution:** 
- Download Whisper.cpp from: https://github.com/ggerganov/whisper.cpp/releases
- Edit script lines 20-21 with correct paths

### "Cannot find path 'D:\SecurityNow...' does not exist"
**Solution:** Create the folder first or run without `-DryRun` to auto-create

### Script runs but no PDFs created
**Solution:** 
- Check your internet connection
- Verify wkhtmltopdf is in PATH: `wkhtmltopdf --version`
- Run with `-DryRun` first to see what would happen

### AI transcripts are empty or garbled
**Solution:**
- Verify Whisper model is downloaded correctly
- Test Whisper manually: `whisper-cli.exe -m model.bin -f test.mp3`
- Try a different model (e.g., `ggml-small.en.bin`)

---

## 📊 Performance Notes

- **Official PDFs download:** ~5-10 minutes for 600+ episodes
- **AI transcription:** ~3-5 minutes per episode (depends on CPU)
- **Total time for full archive:** ~10-20 hours (mostly Whisper processing)

**Tip:** Run overnight for first build, then quick updates take seconds!

---

## 🎓 Understanding the Output

### Index CSV Format
```csv
Episode,Url,File
1,https://cdn.twit.tv/audio/sn/sn0001/sn0001.mp3,sn-1-notes-ai.pdf
1000,https://www.grc.com/sn/sn-1000-notes.pdf,sn-1000-notes.pdf
```

### PDF Types

1. **Official GRC PDFs** (`sn-XXX-notes.pdf`)
   - Original Steve Gibson show notes
   - Highest quality, preferred when available

2. **AI-Generated PDFs** (`sn-XXX-notes-ai.pdf`)
   - Created from audio transcription
   - Has red disclaimer banner at top
   - Used for episodes without official notes

---

## 🔄 Updating Your Archive

The script is **safe to re-run** anytime:

```powershell
# Check for new episodes (runs weekly)
.\sn-full-run.ps1
```

- ✅ Skips existing files
- ✅ Only downloads new episodes
- ✅ Updates CSV index automatically
- ✅ No data loss or duplication

---

## 💡 Pro Tips

1. **Start small:** Test with `-MinEpisode 1000` first
2. **Use DryRun:** Always preview with `-DryRun` before production
3. **Check the CSV:** Open `SecurityNowNotesIndex.csv` to verify episodes
4. **Organize by year:** PDFs are auto-filed into year folders
5. **Keep MP3s:** Save disk space by deleting `local/mp3/` after transcription

---

## 📝 Example Workflow

```powershell
# 1. Preview what will happen
.\sn-full-run.ps1 -DryRun -MinEpisode 1 -MaxEpisode 5

# 2. Test with 5 episodes
.\sn-full-run.ps1 -MinEpisode 1 -MaxEpisode 5

# 3. Verify output
ls local\PDF\2005\

# 4. Run full archive (overnight)
.\sn-full-run.ps1

# 5. Weekly update (30 seconds)
.\sn-full-run.ps1
```

---

## 🆘 Support

- **Script issues:** Check this guide's Troubleshooting section
- **GRC website:** https://www.grc.com/securitynow.htm
- **Whisper.cpp:** https://github.com/ggerganov/whisper.cpp
- **wkhtmltopdf:** https://wkhtmltopdf.org/

---

## ⚖️ Legal & Copyright

- **Official PDFs:** © Steve Gibson / GRC
- **Audio files:** © Leo Laporte / TWiT
- **This script:** Open source, use responsibly
- **AI transcripts:** Clearly marked with disclaimer banner

**This is a personal archival tool. Respect copyright and terms of service.**

---

## ✅ Quick Checklist

Before your first run:

- [ ] wkhtmltopdf installed and in PATH
- [ ] Whisper.cpp installed
- [ ] Whisper model downloaded (ggml-base.en.bin)
- [ ] Script saved as `sn-full-run.ps1`
- [ ] Paths configured in script (lines 20-21)
- [ ] Internet connection stable
- [ ] 50+ GB free disk space (for full archive)

Ready? Run: `.\sn-full-run.ps1 -DryRun` to test!

---

**Last Updated:** January 13, 2026  
**Script Version:** 2.1 Production  
**Method:** wkhtmltopdf (browser-free)