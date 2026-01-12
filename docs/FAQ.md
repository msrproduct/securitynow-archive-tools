# Frequently Asked Questions (FAQ)

Common questions about the Security Now! Archive Tools project.

---

## General Questions

### What is this project?

This is a PowerShell-based automation toolkit that helps Security Now! fans build personal archives of show notes and transcripts from official sources (GRC and TWiT.tv).

**What it does:**
- Downloads official show notes PDFs from Steve Gibson's GRC website
- Generates AI transcripts for episodes that never had official notes
- Organizes everything by year in a clean folder structure
- Maintains a CSV index of all episodes

**What it does NOT do:**
- Redistribute copyrighted content (PDFs, audio, or transcripts)
- Stream or play podcast episodes
- Modify or edit Steve Gibson's original content

---

### Who is this for?

This project is designed for:
- **Security Now! fans** who want a searchable local archive for research
- **Researchers** studying security topics covered across 1000+ episodes
- **Students** learning from Steve Gibson's explanations
- **IT professionals** referencing specific episodes for work

**Technical skill level:** Beginner-friendly. If you can follow step-by-step instructions, you can use this.

---

### Is this official?

**No.** This is an unofficial, fan-created tool.

- It is NOT affiliated with Steve Gibson, GRC, or TWiT.tv
- It is NOT endorsed by the Security Now! podcast
- All Security Now! content remains © Steve Gibson / GRC and TWiT.tv

**Official resources:**
- [GRC Security Now! page](https://www.grc.com/securitynow.htm)
- [TWiT Security Now! page](https://twit.tv/shows/security-now)

---

## Legal & Copyright

### Is this legal?

**Yes**, with important caveats:

**What IS legal:**
- ✅ Downloading public content from GRC for personal use
- ✅ Automating your own personal archive
- ✅ Creating AI transcripts of publicly available audio for personal research
- ✅ Sharing the automation **tools** (scripts, not content)

**What is NOT legal:**
- ❌ Redistributing Steve Gibson's PDFs or TWiT audio files
- ❌ Selling or monetizing Security Now! content
- ❌ Claiming AI transcripts as official Steve Gibson notes
- ❌ Bypassing paywalls or DRM

**Bottom line:** This project helps you build a *personal archive* from *public sources*. It does not redistribute copyrighted material.

---

### Can I share my archive with others?

**No, you should not share the media files.**

**Do NOT share:**
- ❌ PDF files (official or AI-generated)
- ❌ MP3 audio files
- ❌ Transcript text files

**You CAN share:**
- ✅ This GitHub repository (tools only)
- ✅ Links to official GRC/TWiT pages
- ✅ Your CSV index (episode numbers and URLs)

**Why?** The PDFs, audio, and transcripts are copyrighted. Even though you downloaded them legally for personal use, redistributing them violates copyright law.

---

### What about AI-generated transcripts?

**AI transcripts are NOT Steve Gibson's work.**

This project generates them ONLY for episodes that:
1. Never had official show notes (early episodes, audio-only Q&A episodes)
2. Are publicly available as audio on GRC or TWiT.tv

**Legal basis:**
- You're transcribing publicly available audio for personal research (fair use)
- AI transcripts are clearly marked with disclaimers
- They supplement, not replace, Steve's official notes where available

**Important:** Do NOT:
- Share AI transcripts as if they're official
- Claim they represent Steve Gibson's views accurately
- Use them commercially

---

## Technical Questions

### What are the system requirements?

**Minimum:**
- **OS:** Windows 10/11, macOS 10.15+, or Linux (Ubuntu 20.04+, etc.)
- **PowerShell:** Version 7.0 or higher
- **Disk space:** 5-10 GB for full archive (1000+ PDFs + AI transcripts)
- **RAM:** 4 GB (8 GB recommended for AI transcription)
- **Internet:** Broadband connection

**Optional (for HTML → PDF conversion):**
- **wkhtmltopdf** ([Download](https://wkhtmltopdf.org/downloads.html))
  - Windows: MSI installer (adds to PATH automatically)
  - macOS: `brew install wkhtmltopdf`
  - Linux: `apt-get install wkhtmltopdf` or `yum install wkhtmltopdf`

**Optional (for AI transcripts):**
- **whisper.cpp** (speech-to-text engine)

---

### Does this work on macOS or Linux?

**Yes!** The scripts are fully cross-platform with PowerShell 7.

**Installation:**
- **macOS:** `brew install powershell wkhtmltopdf`
- **Linux:** Install PowerShell 7 ([instructions](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-linux))

**What works cross-platform:**
- ✅ Downloading PDFs from GRC
- ✅ HTML → PDF conversion (via wkhtmltopdf)
- ✅ Building the CSV index
- ✅ Organizing files by year
- ✅ AI transcription (whisper.cpp available on all platforms)

**Path differences:**
- Windows: `C:\whisper\main.exe`
- macOS/Linux: `/usr/local/bin/main` or `~/whisper.cpp/main`

---

### How long does the initial run take?

**Expect 3-8 hours** for a full archive:

| Phase | Time |
|-------|------|
| Downloading 500+ PDFs | 30-60 minutes |
| AI transcription (~100 episodes) | 2-7 hours |
| Organizing and indexing | 5-10 minutes |

**Variables:**
- Internet speed (downloads)
- CPU speed (AI transcription)
- Whisper model size (`tiny` = fast, `medium` = slow but accurate)

**Tip:** Run overnight or while you're away from your computer.

---

### Can I pause and resume?

**Yes!** The script is designed to be interruptible:

- Press `Ctrl+C` to stop at any time
- Re-run the script later
- It automatically **skips files that already exist**
- No need to start over from scratch

**Example:**
```powershell
# Start the archive
.\scripts\SecurityNow-EndToEnd.ps1

# (Runs for 2 hours, then you need to leave)
# Press Ctrl+C to stop

# Later, resume where you left off:
.\scripts\SecurityNow-EndToEnd.ps1
# Skips 200 already-downloaded PDFs, continues with remaining episodes
```

---

### What if a download fails?

**The script handles failures gracefully:**

1. **Network errors:** Logs a warning, moves to the next episode
2. **404 Not Found:** Marks the episode as missing, attempts AI transcript
3. **403 Forbidden:** Waits 5 seconds, retries once

**You can manually retry** specific episodes by deleting the local file and re-running the script.

**Example:**
```powershell
# Episode 432 failed to download
Remove-Item $HOME\SecurityNowArchive\local\PDF\2013\sn-432-notes.pdf

# Re-run script to retry just that episode
.\scripts\SecurityNow-EndToEnd.ps1
```

---

### Why are some transcripts missing?

**Possible reasons:**

1. **Whisper.cpp not installed** or path incorrect
2. **MP3 audio unavailable** from GRC/TWiT
3. **Model file missing** (e.g., `ggml-base.en.bin`)
4. **Insufficient disk space** or RAM during transcription
5. **Episode is a video-only special** (no audio-only MP3)

**Check the console output** for error messages during the AI transcription phase.

---

### How accurate are AI transcripts?

**Accuracy varies:**

| Whisper Model | Accuracy | Speed | Disk Space |
|---------------|----------|-------|------------|
| `tiny.en` | ~85% | Fastest | 75 MB |
| `base.en` | **~90%** (recommended) | Fast | 142 MB |
| `small.en` | ~93% | Moderate | 466 MB |
| `medium.en` | ~95% | Slow | 1.5 GB |

**Common errors:**
- Technical jargon ("Diffie-Hellman" → "difficult helmet")
- Acronyms ("AES" → "ace")
- Names ("Schneier" → "schneider")

**Recommendation:** Use `base.en` for a good balance of speed and accuracy. Review transcripts before relying on them for critical research.

---

### Can I search the archive?

**Yes, but not built-in.**

This project creates the files; you need a separate tool to search them:

**Options:**
- **Windows Search:** Index the `SecurityNowArchive` folder
- **Everything (software):** Lightning-fast filename search
- **DocFetcher:** Free desktop search for PDF content
- **PowerShell:** `Select-String` for text search across files

**Example PowerShell search:**
```powershell
# Find all PDFs mentioning "ransomware"
Get-ChildItem -Path $HOME\SecurityNowArchive -Recurse -Filter *.pdf |
  Select-String -Pattern "ransomware" | Select-Object Path
```

---

## Maintenance

### How do I update for new episodes?

**Simply re-run the script:**

```powershell
cd path\to\securitynow-archive-tools
.\scripts\SecurityNow-EndToEnd.ps1
```

**What happens:**
1. Checks GRC for new episodes since your last run
2. Downloads any new official notes PDFs
3. Skips all existing files (fast!)
4. Updates the CSV index

**Recommendation:** Run monthly or after each new episode release.

---

### What if GRC changes their website?

**This project may break** if GRC restructures their archive pages.

**How to check:**
1. Visit [GRC Security Now!](https://www.grc.com/securitynow.htm)
2. Verify the PDF links still follow the pattern: `https://www.grc.com/sn/sn-###-notes.pdf`

**If broken:**
- Check for [open issues](https://github.com/msrproduct/securitynow-archive-tools/issues)
- Report a new issue with details
- Community contributions welcome to fix!

---

### How do I back up my archive?

**Your archive is stored locally** in the folder you configured (e.g., `$HOME\SecurityNowArchive`).

**Backup options:**

1. **Cloud storage:**
   ```powershell
   # Copy to OneDrive, Dropbox, Google Drive, etc.
   Copy-Item -Path $HOME\SecurityNowArchive -Destination "$HOME\OneDrive\Backups\" -Recurse
   ```

2. **External drive:**
   ```powershell
   Copy-Item -Path $HOME\SecurityNowArchive -Destination "E:\Backups\" -Recurse
   ```

3. **ZIP archive:**
   ```powershell
   Compress-Archive -Path $HOME\SecurityNowArchive -DestinationPath "$HOME\Desktop\SecurityNow-Backup.zip"
   ```

**Reminder:** This is YOUR personal archive. Do NOT upload to public cloud shares or file-sharing sites.

---

## Repository Sync Questions

### What is the Sync-Repos.ps1 script?

**Purpose:** Automatically synchronizes non-copyrighted files between your private archive (which includes PDFs/MP3s) and the public GitHub repository (scripts and docs only).

**Why it exists:**
- Keeps your private complete archive
- Shares improvements with the community
- Prevents accidental copyright violations
- Automates what would otherwise be manual copying

**See:** [SYNC-REPOS-GUIDE.md](SYNC-REPOS-GUIDE.md) for full documentation.

---

### Do I need two repositories?

**No, but it's recommended** if you want to contribute back to the community.

**Single repo (simpler):**
- Clone the public repo
- Run scripts to build your archive
- Keep everything local
- Don't push to GitHub

**Two repos (advanced):**
- **Private repo:** Your complete archive with media files
- **Public repo:** Scripts and docs only
- Use `Sync-Repos.ps1` to keep them in sync
- Contribute improvements to public repo safely

---

### How do I set up the two-repo workflow?

**Step-by-step:**

1. **Clone public repo:**
   ```powershell
   git clone https://github.com/msrproduct/securitynow-archive-tools.git SecurityNow-Full
   ```

2. **Create private copy:**
   ```powershell
   Copy-Item -Path SecurityNow-Full -Destination SecurityNow-Full-Private -Recurse
   cd SecurityNow-Full-Private
   ```

3. **Initialize as separate repo:**
   ```powershell
   Remove-Item -Path .git -Recurse -Force
   git init
   git add .
   git commit -m "Initial private archive"
   ```

4. **Create private GitHub repo** (via website)

5. **Push to private:**
   ```powershell
   git remote add origin https://github.com/YOUR-USERNAME/securitynow-full-archive.git
   git branch -M main
   git push -u origin main
   ```

6. **Use sync script:**
   ```powershell
   .\scripts\Sync-Repos.ps1
   ```

**See:** [QUICK-START.md](QUICK-START.md#two-repo-setup-private--public) for detailed instructions.

---

### What files does Sync-Repos.ps1 sync?

**Synced (private → public):**
- ✅ `README.md`
- ✅ `LICENSE`
- ✅ `docs/` folder (all documentation)
- ✅ `scripts/` folder (all scripts)
- ✅ `data/SecurityNowNotesIndex.csv`

**Never synced (stays private):**
- ❌ `local/PDF/` (official and AI-generated PDFs)
- ❌ `local/mp3/` (audio files)
- ❌ `local/Notes/ai-transcripts/` (transcripts)
- ❌ `.gitignore` (each repo maintains its own)

---

### How do I test sync without making changes?

**Use dry-run mode:**

```powershell
.\scripts\Sync-Repos.ps1 -DryRun -Verbose
```

**Output shows:**
- What files would be synced
- What's already in sync
- What would be skipped
- **No changes are made**

**Perfect for:**
- Verifying sync before running
- Checking if repos are already in sync
- Testing after making changes

---

### Sync script says "Files synced: 0" - is that normal?

**Yes!** This is **good** - it means:

✅ Both repos are perfectly in sync  
✅ No changes need to be copied  
✅ Script is working correctly  

**You'll see non-zero counts when:**
- You've edited files in the private repo
- You've added new scripts
- You've updated documentation
- First time running after changes

---

### Can I edit files in the public repo directly?

**Not recommended.** The sync script copies from private → public (one-way).

**What happens if you edit public repo:**
- Next sync will **overwrite** your changes
- You'll lose your edits

**Correct workflow:**
1. Edit files in **private** repo
2. Commit to private repo
3. Run `Sync-Repos.ps1`
4. Changes automatically pushed to public

**Exception:** If you only have a public repo (no private), edit directly and push normally.

---

### Sync failed with "Git operations failed" - what now?

**Don't worry!** The files are already synced locally.

**Cause:** Network issue, authentication problem, or merge conflict.

**Solution:**

```powershell
# Navigate to public repo
cd D:\Desktop\SecurityNow-Full

# Check status
git status

# Try pushing manually
git push origin main

# If authentication fails, check your GitHub token
```

**See:** [TROUBLESHOOTING.md](TROUBLESHOOTING.md#git-issues) for detailed solutions.

---

## Contributing

### Can I contribute improvements?

**Yes!** Contributions are welcome.

**See:** [CONTRIBUTING.md](../CONTRIBUTING.md) for guidelines.

**Popular contribution ideas:**
- Improve error handling
- Add macOS/Linux support
- Better progress indicators
- Enhanced CSV export formats
- Integration with note-taking apps

---

### I found a bug. What should I do?

1. Check [existing issues](https://github.com/msrproduct/securitynow-archive-tools/issues)
2. If not already reported, [open a new issue](https://github.com/msrproduct/securitynow-archive-tools/issues/new)
3. Include:
   - PowerShell version
   - OS version
   - Error message (full text)
   - Steps to reproduce

---

## Support

### Where can I get help?

**Resources:**

1. **Documentation:**
   - [README.md](../README.md) - Quick start guide
   - [QUICK-START.md](QUICK-START.md) - Beginner-friendly setup
   - [WORKFLOW.md](WORKFLOW.md) - Detailed step-by-step instructions
   - [SYNC-REPOS-GUIDE.md](SYNC-REPOS-GUIDE.md) - Sync script documentation
   - [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Problem solving

2. **Community:**
   - [GitHub Issues](https://github.com/msrproduct/securitynow-archive-tools/issues) - Bug reports and questions
   - [GitHub Discussions](https://github.com/msrproduct/securitynow-archive-tools/discussions) - General discussion

3. **Security Now! Community:**
   - [GRC Forums](https://forums.grc.com/)
   - [/r/SecurityNow subreddit](https://www.reddit.com/r/SecurityNow/)

**Note:** This is a community project with no official support. Response times vary.

---

### Can I hire someone to set this up for me?

**This is a free, community project** with no commercial support.

**However:**
- The setup is designed to be beginner-friendly
- Follow the [QUICK-START.md](QUICK-START.md) step-by-step
- Ask for help in [GitHub Discussions](https://github.com/msrproduct/securitynow-archive-tools/discussions) if stuck

**If you're a business** needing professional assistance, consider hiring a freelance PowerShell developer on platforms like Upwork or Fiverr to help with setup.

---

## Still Have Questions?

**Didn't find your answer?**

1. Search [existing issues](https://github.com/msrproduct/securitynow-archive-tools/issues)
2. Check the [TROUBLESHOOTING.md](TROUBLESHOOTING.md) guide
3. Review the [QUICK-START.md](QUICK-START.md) setup instructions
4. Ask in [GitHub Discussions](https://github.com/msrproduct/securitynow-archive-tools/discussions)

---

**Happy archiving!** 🔐📚
