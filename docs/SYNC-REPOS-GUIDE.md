# Sync-Repos.ps1 User Guide

## Overview

`Sync-Repos.ps1` is a PowerShell script that keeps your public and private Security Now archive repositories synchronized. It ensures non-copyrighted files (scripts, documentation, index files) are identical across both repos while respecting copyright boundaries.

## Why This Script Exists

This project uses a **dual-repository architecture**:

- **Private repo** (`securitynow-full-archive`) - Contains everything: scripts, docs, PDFs, MP3s, transcripts
- **Public repo** (`securitynow-archive-tools`) - Contains only tools and documentation (no copyrighted media)

The sync script automates keeping shared files (scripts, docs) identical between both repos without accidentally copying copyrighted content to the public repo.

## What It Does

### Files That Get Synced

✅ **Always synced**:
- `README.md`
- `LICENSE`
- `FUNDING.yml`
- `docs/` folder (all documentation)
- `scripts/` folder (all PowerShell scripts)
- `data/SecurityNowNotesIndex.csv`

❌ **Never synced** (copyrighted content):
- `local/PDF/` (official GRC show notes)
- `local/mp3/` (podcast audio files)
- `local/Notes/ai-transcripts/` (AI-generated transcripts)
- `.gitignore` (intentionally different per repo)

### Smart Features

- **Hash-based comparison** - Only syncs files that actually changed (uses SHA256)
- **Dry-run mode** - Test before making changes
- **Verbose output** - See exactly what's happening
- **Automatic Git operations** - Commits and pushes to public repo for you
- **Idempotent** - Safe to run multiple times; won't make unnecessary changes

## How to Use

### Basic Usage

```powershell
# Navigate to private repo
cd D:\Desktop\SecurityNow-Full-Private

# Run the sync
.\scripts\Sync-Repos.ps1
```

### Test Before Syncing (Recommended)

```powershell
# Dry-run with detailed output
.\scripts\Sync-Repos.ps1 -DryRun -Verbose
```

This shows what **would** be synced without making any changes.

### Verbose Mode

```powershell
# See detailed file-by-file status
.\scripts\Sync-Repos.ps1 -Verbose
```

### Custom Paths

```powershell
# If your repos are in different locations
.\scripts\Sync-Repos.ps1 -PrivateRepo "C:\MyRepos\Private" -PublicRepo "C:\MyRepos\Public"
```

## Understanding the Output

### Status Indicators

- **[SAME]** - File is identical in both repos (no action needed)
- **[UPDATE]** - File exists but differs; will be updated
- **[NEW]** - File doesn't exist in public repo; will be created
- **[SKIP]** - File doesn't exist in private repo
- **[SYNC]** - Processing directory
- **[EXCLUDE]** - File is in excluded folder (copyrighted content)

### Example Output

```
========================================
Security Now Repo Sync
========================================
Private repo: D:\Desktop\SecurityNow-Full-Private
Public repo:  D:\Desktop\SecurityNow-Full

Comparing files...
NOTE: .gitignore is excluded (each repo maintains its own)

[SAME] README.md
[SYNC] Directory: scripts
  [UPDATE] SecurityNow-EndToEnd.ps1
  [SAME] Fix-AI-PDFs.ps1
  [NEW] New-Helper-Script.ps1

Committing changes to public repo...
  Pushed to public GitHub repo

========================================
SUMMARY
========================================
Files synced:  2
Files skipped: 1

Complete!
========================================
```

## When to Run This Script

Run the sync script whenever you:

1. **Update scripts** in the private repo
2. **Modify documentation** (README, WORKFLOW.md, etc.)
3. **Add new scripts** to the `scripts/` folder
4. **Update the CSV index** after running SecurityNow-EndToEnd.ps1

**Don't need to run** when you only:
- Download new PDFs or MP3s
- Generate new AI transcripts
- Make changes only to `local/` folder

## Typical Workflow

```powershell
# 1. Work in private repo (your primary workspace)
cd D:\Desktop\SecurityNow-Full-Private

# 2. Make your changes to scripts or docs
# ... edit files ...

# 3. Commit to private repo
git add .
git commit -m "Updated scripts and docs"
git push origin main

# 4. Test the sync (optional but recommended)
.\scripts\Sync-Repos.ps1 -DryRun -Verbose

# 5. Sync to public repo
.\scripts\Sync-Repos.ps1

# Done! Both repos are now in sync
```

## Troubleshooting

### Issue: "ERROR: Private repo not found"

**Solution**: Check the path to your private repo:

```powershell
# Verify path exists
Test-Path "D:\Desktop\SecurityNow-Full-Private"

# Use correct path
.\scripts\Sync-Repos.ps1 -PrivateRepo "D:\Your\Actual\Path"
```

### Issue: "Updates were rejected" (Git push failed)

**Solution**: The public repo has changes you don't have locally:

```powershell
# Go to public repo and pull changes
cd D:\Desktop\SecurityNow-Full
git pull origin main

# Then run sync again
cd D:\Desktop\SecurityNow-Full-Private
.\scripts\Sync-Repos.ps1
```

### Issue: Files showing as different when they shouldn't be

**Cause**: Line ending differences (CRLF vs LF)

**Solution**: Ensure Git is configured consistently:

```powershell
# In both repos, set line ending handling
git config core.autocrlf true
```

### Issue: "Files synced: 0" but I made changes

**Check**:
1. Are you editing files in the private repo?
2. Are the files in the sync list (see "What It Does" above)?
3. Did you save your changes?

```powershell
# Run verbose dry-run to see status
.\scripts\Sync-Repos.ps1 -DryRun -Verbose
```

### Issue: Script runs but doesn't push to GitHub

**Cause**: No files actually changed

**Behavior**: Script only commits/pushes when files are different. This is correct behavior.

## Parameters Reference

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-PrivateRepo` | String | `D:\Desktop\SecurityNow-Full-Private` | Path to private repo |
| `-PublicRepo` | String | `D:\Desktop\SecurityNow-Full` | Path to public repo |
| `-DryRun` | Switch | `$false` | Test mode; no changes made |
| `-Verbose` | Switch | `$false` | Detailed output |

## Best Practices

### ✅ DO:

- Run `-DryRun -Verbose` first to preview changes
- Keep private repo as your primary workspace
- Commit to private repo before syncing
- Run sync after updating scripts or docs

### ❌ DON'T:

- Edit files directly in public repo (they'll be overwritten)
- Manually copy files between repos (use the script)
- Skip the dry-run for major changes
- Commit copyrighted content to public repo

## FAQ

**Q: How often should I run this?**  
A: After any changes to scripts, docs, or the CSV index. For media-only changes (PDFs, MP3s), you don't need to sync.

**Q: Can I run this from the public repo?**  
A: Technically yes, but not recommended. Always work in the private repo and sync outward.

**Q: What if I accidentally edited the public repo?**  
A: Your changes will be overwritten on next sync. Edit in private repo instead, then sync.

**Q: Does this sync Git commit history?**  
A: No, only file contents. Each repo maintains its own Git history.

**Q: Is this idempotent?**  
A: Yes! Running multiple times won't cause problems. It only syncs when files differ.

## Related Documentation

- [Architecture Guide](Architecture.md) - Why two repos?
- [Main Workflow](../WORKFLOW.md) - Complete archive building process
- [Troubleshooting Guide](Troubleshooting.md) - Common issues and solutions
- [FAQ](FAQ.md) - Frequently asked questions

## Support

If you encounter issues:

1. Check [Troubleshooting.md](Troubleshooting.md)
2. Review [FAQ.md](FAQ.md)
3. Open an issue on GitHub with:
   - Full command you ran
   - Complete output (use `-Verbose`)
   - Your repo paths

---

**Remember**: This script is designed to keep your public repo safe from copyrighted content while maintaining identical tools and documentation across both repos.
