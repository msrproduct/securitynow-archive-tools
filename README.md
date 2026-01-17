# Security Now! Archive Tools

**Version 3.1.2** - Complete AI transcription pipeline  
**Released:** January 17, 2026

PowerShell tools to build a complete archive of Steve Gibson's **Security Now!** podcast episodes with official PDFs and AI-generated transcripts for missing episodes.

---

## ✨ What's New in v3.1.2

- **Complete AI transcription pipeline** restored and tested
- Whisper.cpp integration for high-quality local speech-to-text
- Automatic fallback: official GRC PDFs → AI transcripts for missing episodes
- HTML wrapper with prominent disclaimer for AI-generated content
- Episode metadata caching for faster subsequent runs
- Air-gapped deployment support (no cloud dependencies)

**Tested Performance (Episode 7):** ~158 seconds total processing time (MP3 download + Whisper transcription + PDF generation)

---

## 📋 What This Repo Contains

### Scripts (`/scripts`)
- **`sn-full-run.ps1`** - Main archive builder
  - Downloads official show-notes PDFs from [GRC.com](https://www.grc.com/securitynow.htm)
  - Generates AI transcripts for episodes without official notes
  - Organizes files by year (2005-2026+)
  - Maintains searchable CSV index

### Data (`/data`)
- **`episode-dates.csv`** - Cached episode-to-year mappings
- **`SecurityNowNotesIndex.csv`** - Master index of all episodes
  - Episode number
  - Source URL (GRC or TWiT CDN)
  - Local filename
  - File type (official PDF vs AI transcript)

---

## 🚫 What This Repo Does NOT Contain

This public repository **does not include**:

- Original Security Now! show-notes PDFs (copyright Steve Gibson/GRC)
- TWiT.tv transcripts or MP3 audio files
- Any copyrighted content from GRC or TWiT.tv

Instead, it provides **tools and an index** so you can:
1. Download official content directly from authoritative sources
2. Generate clearly-marked AI transcripts for gaps in official coverage
3. Maintain a private archive in compliance with fair use principles

---

## ⚙️ Installation

### Prerequisites

1. **PowerShell 5.1+** (Windows) or **PowerShell Core 7+** (cross-platform)

2. **Whisper.cpp** (for AI transcription)
   - Download: [github.com/ggerganov/whisper.cpp/releases](https://github.com/ggerganov/whisper.cpp/releases)
   - Extract to `C:\whisper.cpp\` (or update path in script)
   - Download model: `ggml-base.en.bin` to `C:\whisper.cpp\models\`

3. **wkhtmltopdf** (for PDF generation)
   - Download: [wkhtmltopdf.org/downloads.html](https://wkhtmltopdf.org/downloads.html)
   - Install to default location: `C:\Program Files\wkhtmltopdf\`

### Quick Start

```powershell
# Clone the repository
git clone https://github.com/msrproduct/securitynow-archive-tools.git
cd securitynow-archive-tools

# Test run (no changes made)
.\scripts\sn-full-run.ps1 -DryRun -MinEpisode 1 -MaxEpisode 5

# Download episodes 1-100 with AI transcripts
.\scripts\sn-full-run.ps1 -MinEpisode 1 -MaxEpisode 100

# GRC PDFs only (skip AI generation)
.\scripts\sn-full-run.ps1 -MinEpisode 1 -MaxEpisode 1000 -SkipAI
```

---

## 📁 Directory Structure

After running the script, your repository will contain:

```
securitynow-archive-tools/
├── scripts/
│   └── sn-full-run.ps1          # Main archive builder
├── data/
│   └── episode-dates.csv        # Cached metadata
├── local/                       # Created on first run (gitignored)
│   ├── pdf/
│   │   ├── 2005/
│   │   │   ├── sn-0001-notes.pdf          # Official GRC PDF
│   │   │   └── sn-0007-notes-ai.pdf       # AI-generated (if no official)
│   │   ├── 2006/
│   │   └── .../
│   ├── mp3/                     # Downloaded episode audio
│   └── Notes/
│       └── ai-transcripts/      # Intermediate text files
├── SecurityNowNotesIndex.csv    # Master episode index
└── error-log.csv                # Processing errors
```

**Note:** The `local/` folder is **not synced** to the public repo (`.gitignore` exclusion). For backups, use a [private fork](https://github.com/msrproduct/securitynow-full-archive) or separate private repository.

---

## 🎯 Usage Examples

### Build Complete Archive (Episodes 1-1000)

```powershell
.\scripts\sn-full-run.ps1 -MinEpisode 1 -MaxEpisode 1000
```

**Output:**
- Downloads all available official PDFs from GRC
- Generates AI transcripts for missing episodes
- Creates year-organized folder structure
- Updates `SecurityNowNotesIndex.csv`

### Update Archive (New Episodes)

```powershell
# Re-run same command to pick up new episodes
.\scripts\sn-full-run.ps1 -MinEpisode 1 -MaxEpisode 1100
```

**Smart caching:**
- Skips already-downloaded files
- Uses cached episode metadata
- Only processes new/missing episodes

### Air-Gapped Deployment

1. **Online system:** Download Whisper.cpp, wkhtmltopdf, and this repo
2. **Transfer to air-gapped system** via approved media
3. **Run script** - all processing is local (no internet required after setup)

---

## 🚀 Roadmap: v3.2.0 Performance Optimization

**Current baseline (v3.1.2):** ~158 seconds per episode  
**Target (v3.2.0):** ~4-8 seconds per episode (20-40x speedup)

### Planned Optimizations

| Tier | Optimization | Expected Speedup | Complexity |
|------|--------------|------------------|------------|
| 1 | **Distil-Whisper** integration | 6-10x | Low |
| 1 | Parallel episode processing | 4-8x (8-core CPU) | Medium |
| 2 | Content-addressable caching | 2-5x (re-runs) | Medium |
| 2 | GPU acceleration (Whisper) | 2-4x | Medium-High |
| 3 | Incremental MP3 download | 1.2-1.5x | Low |

**Combined potential:** 40-80x speedup for batch processing

### Why This Matters

- **Enterprise air-gapped deployments:** Process 1000+ episodes in <2 hours instead of days
- **Research workflows:** Rapid iteration on transcription quality improvements
- **Cost savings:** Eliminate cloud API dependencies ($0.006/min → $0 via local Whisper)

---

## 🔒 Respecting Copyright

All Security Now! content is authored and owned by **Steve Gibson / Gibson Research Corporation** and published in cooperation with **TWiT.tv**.

### Fair Use Principles

✅ **Allowed:**
- Personal archival and research
- Generating AI transcripts **only for episodes without official show notes**
- Clearly labeling AI-generated content as "NOT OFFICIAL"
- Downloading from authoritative sources (GRC.com, TWiT CDN)

❌ **Prohibited:**
- Redistributing copyrighted PDFs or audio files
- Presenting AI transcripts as official Steve Gibson content
- Commercial use without explicit permission

### AI Transcript Disclaimer

All AI-generated transcripts include a prominent red banner:

> ⚠️ **AI-GENERATED TRANSCRIPT - NOT OFFICIAL SHOW NOTES**
>
> This transcript was automatically generated using Whisper.cpp speech recognition.  
> It may contain errors, omissions, or inaccuracies. This is NOT an official  
> Steve Gibson show notes document from GRC.com.
>
> For official episode notes (when available), visit [grc.com/securitynow.htm](https://www.grc.com/securitynow.htm)

---

## 🤝 Contributing

Contributions welcome! Please:

1. **Test thoroughly** before submitting PRs
2. **Document changes** in commit messages
3. **Respect copyright** - no copyrighted content in PRs
4. **Follow existing code style** (PowerShell best practices)

### Reporting Issues

- **Script bugs:** Open GitHub issue with error log (`error-log.csv`)
- **Performance ideas:** Suggest in Discussions (v3.2.0 roadmap)
- **Missing episodes:** Check [GRC.com](https://www.grc.com/securitynow.htm) first

---

## 📜 License

MIT License - see [LICENSE](LICENSE) file

**Important:** This license applies **only to the scripts and tools**, not to:
- Security Now! podcast content (copyright Steve Gibson/GRC)
- TWiT.tv media files
- Any generated transcripts (derivative works)

---

## 🙏 Credits

- **Steve Gibson** - Creator of Security Now! podcast
- **TWiT.tv** - Podcast hosting and distribution
- **Whisper.cpp** - [ggerganov/whisper.cpp](https://github.com/ggerganov/whisper.cpp)
- **OpenAI Whisper** - Original speech recognition model
- **wkhtmltopdf** - HTML to PDF conversion

---

## 📞 Support

- **Documentation:** This README
- **Issues:** [GitHub Issues](https://github.com/msrproduct/securitynow-archive-tools/issues)
- **Discussions:** [GitHub Discussions](https://github.com/msrproduct/securitynow-archive-tools/discussions)
- **Official podcast:** [grc.com/securitynow.htm](https://www.grc.com/securitynow.htm)

---

**Status:** v3.1.2 baseline complete ✅ | v3.2.0 optimization roadmap defined 🚀

**Last updated:** January 17, 2026