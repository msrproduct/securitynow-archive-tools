# Frequently Asked Questions (FAQ)

Quick answers to common questions about the Security Now Archive Tools.

## General Questions

### What is this project?

A set of PowerShell tools that help you build and maintain a **personal archive** of Steve Gibson's Security Now podcast show notes, transcripts, and audio files. The tools automate downloading from official sources (GRC.com and TWiT.tv) and organizing everything locally.

### Is this legal?

Yes, with important caveats:

- ✅ **Downloading for personal use** is legal (like recording TV shows)
- ✅ **Sharing the tools** (scripts) is legal (they're open source)
- ❌ **Publicly distributing copyrighted content** (PDFs, MP3s) is NOT legal

This is why we use two repositories: public for tools, private for your personal media.

### Does Steve Gibson or GRC endorse this?

No. This is an **independent, fan-created project**. Steve Gibson and GRC are not affiliated with this project. Always support the official sources:

- Official show notes: https://www.grc.com/securitynow.htm
- Official podcast: https://twit.tv/shows/security-now

### Why not just use one repository?

Copyright law. We cannot legally share Steve Gibson's show notes (PDFs) or TWiT's audio files (MP3s) publicly. The dual-repo design lets us:

- Share the **tools** openly (public repo)
- Keep **copyrighted media** private (private repo)
- Automate synchronization between them

See [Architecture.md](Architecture.md) for details.

---

## Setup Questions

### What do I need to get started?

**Required**:
- Windows 10/11
- PowerShell 5.1+ (built into Windows)
- Git for Windows
- Internet connection

**Optional** (for AI transcripts):
- Python 3.8+
- OpenAI Whisper CLI
- Microsoft Edge or Google Chrome (for web scraping)

### How much disk space do I need?

**Estimates** (as of 2026):
- PDFs only: ~2-3 GB
- MP3s only: ~15-20 GB
- AI transcripts: ~500 MB
- **Complete archive**: ~20-25 GB

Plan for more as new episodes are released.

### Do I need a GitHub account?

Yes, to create your own private repository for storing media files. GitHub offers free private repos with Git LFS (for large files).

### Can I use this on Mac or Linux?

The scripts are PowerShell-based (Windows), but PowerShell Core runs on Mac/Linux. You may need to modify file paths and some commands. Community contributions for cross-platform support are welcome!

---

## Usage Questions

### How do I download all episodes?

```powershell
cd D:\Desktop\SecurityNow-Full-Private
.\scripts\SecurityNow-EndToEnd.ps1
```

The script will:
1. Check which episodes you already have
2. Download missing PDFs from GRC.com
3. Download missing MP3s from TWiT.tv
4. Generate AI transcripts (if configured)
5. Update the CSV index

### How do I update my archive with new episodes?

Run the same command! The script is smart:

- Skips episodes you already have
- Only downloads new episodes
- Updates the CSV index

### Can I download just specific episodes?

```powershell
# Single episode
.\scripts\SecurityNow-EndToEnd.ps1 -EpisodeNumber 950

# Range of episodes
.\scripts\SecurityNow-EndToEnd.ps1 -StartEpisode 900 -EndEpisode 950
```

### Can I skip AI transcription?

Yes! AI transcription is optional. You can:

- Skip the Whisper installation
- Comment out transcription code in the script
- Just download PDFs and MP3s

### How long does it take to build a complete archive?

**Depends on**:
- Your internet speed
- Whether you generate AI transcripts
- Which episodes you download

**Rough estimates**:
- PDFs only: 1-2 hours
- PDFs + MP3s: 3-5 hours
- Everything + AI transcripts: 10-20+ hours (run overnight)

---

## Sync Questions

### When should I run Sync-Repos.ps1?

Run it whenever you:
- Update any script in `scripts/`
- Modify documentation in `docs/`
- Change `README.md` or other root files
- Update the CSV index

**Don't need to run** for:
- Downloading new PDFs or MP3s (media stays private)

### What if I edited files in the public repo?

Your changes will be **overwritten** on next sync. The sync direction is:

**Private → Public** (one-way)

Always edit in the private repo, then sync.

### How do I test sync before running it?

```powershell
.\scripts\Sync-Repos.ps1 -DryRun -Verbose
```

This shows what would be synced without making changes.

### Does syncing copy my media files?

No! The sync script is designed to **exclude** copyrighted content:

- ❌ `local/PDF/` (not synced)
- ❌ `local/mp3/` (not synced)
- ❌ `local/Notes/ai-transcripts/` (not synced)
- ✅ `scripts/` (synced)
- ✅ `docs/` (synced)
- ✅ CSV index (synced)

---

## AI Transcription Questions

### What is AI transcription?

Using OpenAI's Whisper model to automatically generate text transcripts from MP3 audio files. This gives you searchable text for episodes that never had official show notes.

### Why generate transcripts when official notes exist?

Some early episodes (especially 2005-2006) don't have official show notes. AI transcripts fill those gaps.

### How accurate are AI transcripts?

Pretty good! Whisper is state-of-the-art, but:

- ✅ Generally 90-95% accurate for clear audio
- ❌ Technical terms may be misspelled
- ❌ Speaker attribution not perfect
- ❌ Can miss context or nuance

**Important**: AI transcripts are labeled as such and are NOT official show notes.

### Can I edit AI transcripts?

Yes! They're plain text files in `local/Notes/ai-transcripts/`. Feel free to:

- Fix technical terms
- Add formatting
- Correct errors
- Add timestamps

### Do I need a GPU for transcription?

No, but it helps:

- **CPU**: Works fine, just slower (5-10x real-time)
- **GPU**: Much faster (1-2x real-time)

Use smaller models (`tiny`, `base`) on CPU for speed.

### Can I use a different AI model?

Yes! The scripts can be modified to use:

- Different Whisper models (`tiny`, `base`, `small`, `medium`, `large`)
- Other transcription services (Azure, AWS, Google Cloud)
- Local Whisper variants (faster-whisper, whisper.cpp)

Community contributions welcome!

---

## Copyright & Ethics Questions

### Why keep media in a private repo?

Copyright compliance. The PDFs and MP3s are copyrighted by Steve Gibson/GRC and TWiT. We cannot legally distribute them publicly, but you can download them for personal use.

### Can I share my private repo with friends?

No. Your private repo contains copyrighted content. Keep it private and respect the creators' rights.

### What if Steve Gibson asks me to take it down?

We'd comply immediately. This project exists to help fans organize their personal archives, not to undermine the creators. If you're concerned, **support Security Now** through official channels:

- Visit https://www.grc.com
- Listen at https://twit.tv/shows/security-now
- Consider sponsoring TWiT or donating to Steve's projects

### Are AI transcripts copyrighted?

Unclear legal area. AI transcripts are **derivative works** of copyrighted audio, so we treat them the same as the original media:

- Keep them private
- Don't distribute publicly
- Label as AI-generated

### Can I contribute to this project?

Yes! We welcome:

- ✅ Script improvements
- ✅ Documentation updates
- ✅ Bug fixes
- ✅ Feature suggestions

Contribute via pull requests to the **public repo** only (no copyrighted content).

---

## Technical Questions

### Why PowerShell and not Python/Bash/etc?

PowerShell is:

- Built into Windows (no installation needed)
- Excellent for file operations and web requests
- Good Git integration
- Familiar to Windows sysadmins

Python/cross-platform versions could be community contributions!

### Can I run this on a schedule (automation)?

Yes! Use Windows Task Scheduler:

```powershell
# Create a scheduled task
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-File D:\Desktop\SecurityNow-Full-Private\scripts\SecurityNow-EndToEnd.ps1"
$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At 2am
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "SecurityNow-Update"
```

### What's the CSV index for?

The `SecurityNowNotesIndex.csv` file tracks:

- Episode numbers and titles
- Publication dates
- File locations (PDF, MP3, transcript)
- Metadata (duration, size, etc.)

You can use it to:

- Search episodes
- Generate reports
- Build a web interface
- Create playlists

### Can I build a searchable database?

Yes! The CSV and text transcripts make this possible. You could:

- Import CSV into SQLite/MySQL
- Full-text index transcripts
- Build a web interface (Electron app, local web server)
- Use tools like Obsidian or Notion

Community projects for this are encouraged!

### Why Git LFS?

Git Large File Storage (LFS) prevents your repo from getting bloated:

- Regular Git stores full history of every file version
- With 20GB of media, this would be massive
- Git LFS stores large files separately
- Your repo stays fast and manageable

---

## Troubleshooting Questions

### Script gives "Execution Policy" error

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

See [Troubleshooting.md](Troubleshooting.md) for details.

### Git says "Authentication Failed"

GitHub no longer accepts passwords. Use a Personal Access Token (PAT):

1. Go to https://github.com/settings/tokens
2. Generate new token with `repo` access
3. Use token as password when prompted

See [Troubleshooting.md](Troubleshooting.md) for full instructions.

### Downloads are failing

Check:

1. Internet connection
2. GRC.com and TWiT.tv are accessible
3. Episode actually exists (not all episodes have PDFs)
4. Rate limiting (script should handle this)

See [Troubleshooting.md](Troubleshooting.md) for solutions.

### Sync says files are different but they look the same

Line ending differences (CRLF vs LF). Configure Git:

```powershell
git config core.autocrlf true
```

See [Troubleshooting.md](Troubleshooting.md) for details.

### Where do I find more help?

1. Check [Troubleshooting.md](Troubleshooting.md)
2. Review [Sync-Repos-Guide.md](Sync-Repos-Guide.md)
3. Read [Architecture.md](Architecture.md)
4. Open an issue on GitHub (public repo only)

---

## Future Plans

### Will there be a GUI?

Not currently planned, but community contributions welcome! Possibilities:

- PowerShell GUI (Windows Forms)
- Electron app
- Web interface (local server)

### Will you add video support?

Security Now is primarily audio, but if TWiT releases video versions, we could add support. Community contributions welcome!

### Can this work with other podcasts?

The architecture is Security Now-specific (GRC.com URLs, TWiT.tv structure), but the concepts apply to any podcast. Fork and adapt!

### Will you add cloud storage integration?

Potential features:

- OneDrive/Dropbox sync
- Cloud backup automation
- Multi-device sync

Community contributions welcome!

---

## Getting Involved

### How can I contribute?

1. Fork the **public repo**: https://github.com/msrproduct/securitynow-archive-tools
2. Make improvements (scripts, docs, bug fixes)
3. Submit pull request
4. No copyrighted content in PRs!

See [CONTRIBUTING.md](../CONTRIBUTING.md) for guidelines.

### Can I report bugs?

Yes! Open issues on the public repo:

- Describe the problem
- Include error messages
- Provide system info (OS, PowerShell version)
- No copyrighted content in issues!

### Can I request features?

Absolutely! Open an issue with:

- Feature description
- Use case / why it's useful
- Implementation ideas (if any)

### How can I support the project?

The best way to support this project is to **support the creators**:

- Visit https://www.grc.com and use Steve's tools
- Listen to Security Now at https://twit.tv
- Sponsor TWiT or support their advertisers
- Share Security Now with friends

---

## Quick Reference

### Key Commands

```powershell
# Build/update archive
.\scripts\SecurityNow-EndToEnd.ps1

# Sync repos (dry run)
.\scripts\Sync-Repos.ps1 -DryRun -Verbose

# Sync repos (for real)
.\scripts\Sync-Repos.ps1

# Fix AI PDFs
.\scripts\Fix-AI-PDFs.ps1

# Check Git status
git status

# Get help
Get-Help .\scripts\SecurityNow-EndToEnd.ps1 -Full
```

### Important Links

- Public repo: https://github.com/msrproduct/securitynow-archive-tools
- Official Security Now: https://www.grc.com/securitynow.htm
- Official podcast: https://twit.tv/shows/security-now
- Git for Windows: https://git-scm.com/download/win
- OpenAI Whisper: https://github.com/openai/whisper

### Documentation

- [Sync-Repos Guide](Sync-Repos-Guide.md) - How to sync repos
- [Architecture](Architecture.md) - Why two repos?
- [Troubleshooting](Troubleshooting.md) - Common problems
- [Main Workflow](../WORKFLOW.md) - Complete process
- [Contributing](../CONTRIBUTING.md) - How to help

---

**Still have questions?** Open an issue on the [public repo](https://github.com/msrproduct/securitynow-archive-tools) or contribute to this FAQ!
