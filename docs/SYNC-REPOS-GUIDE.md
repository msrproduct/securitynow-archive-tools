# Sync-Repos.ps1 User Guide

## Overview

The `Sync-Repos.ps1` script synchronizes non-copyrighted files between your private Security Now archive and the public GitHub repository. This allows you to maintain a complete private archive with media files while contributing scripts, documentation, and index data to the public community repository.

## Why This Script Exists

When maintaining both a private and public Security Now archive repository:

- **Private repo** contains everything (scripts, docs, PDFs, MP3s, transcripts)
- **Public repo** contains only non-copyrighted content (scripts, docs, CSV index)

Manually keeping these in sync is error-prone. This script automates the synchronization while respecting copyright boundaries.

## What It Does

The script:

1. **Compares files** between private and public repos using SHA-256 hashes
2. **Syncs changed files** from private → public (one-way sync)
3. **Excludes copyrighted content** (PDFs, MP3s, AI transcripts)
4. **Maintains separate .gitignore files** (each repo has different needs)
5. **Commits and pushes** changes to the public GitHub repo
6. **Provides detailed reporting** of all operations

### Files That Are Synced

- `README.md` - Repository overview
- `LICENSE` - License information
- `FUNDING.yml` - Donation/sponsorship links
- `docs/` - All documentation files
- `scripts/` - All PowerShell scripts
- `data/SecurityNowNotesIndex.csv` - Episode index

### Files That Are NEVER Synced

- `local/PDF/` - Official and AI-generated PDF show notes
- `local/mp3/` - Audio files
- `local/Notes/ai-transcripts/` - AI-generated transcripts
- `.gitignore` - Each repo maintains its own version

## Usage

### Basic Usage

```powershell
# Sync from private to public repo
cd D:\Desktop\SecurityNow-Full-Private
.\scripts\Sync-Repos.ps1
```

### Dry Run (Test Mode)

```powershell
# See what would be synced without making changes
.\scripts\Sync-Repos.ps1 -DryRun -Verbose
```

### Custom Paths

```powershell
# Specify custom repo locations
.\scripts\Sync-Repos.ps1 `
    -PrivateRepo "C:\MyArchive\Private" `
    -PublicRepo "C:\MyArchive\Public"
```

## Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-PrivateRepo` | String | `D:\Desktop\SecurityNow-Full-Private` | Path to private repo |
| `-PublicRepo` | String | `D:\Desktop\SecurityNow-Full` | Path to public repo |
| `-DryRun` | Switch | Off | Test mode - shows changes without applying them |
| `-Verbose` | Switch | Off | Display detailed file-by-file comparison |

## Output Explained

### Status Indicators

- **[SAME]** - File is identical in both repos
- **[NEW]** - File exists in private but not public (will be created)
- **[UPDATE]** - File differs between repos (will be updated)
- **[SKIP]** - File not found in source repo
- **[EXCLUDE]** - File in copyrighted folder (not synced)

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
[UPDATE] docs/WORKFLOW.md
[NEW] scripts/New-Feature.ps1
[SKIP] Source not found: LICENSE

========================================
SUMMARY
========================================
Files synced:  2
Files skipped: 1

Complete!
========================================
```

## Workflow Integration

### Recommended Workflow

1. **Work in private repo** (your primary workspace)
   ```powershell
   cd D:\Desktop\SecurityNow-Full-Private
   # Make your changes, test scripts, etc.
   ```

2. **Commit to private repo**
   ```powershell
   git add .
   git commit -m "Add new feature"
   git push origin main
   ```

3. **Test sync with dry run**
   ```powershell
   .\scripts\Sync-Repos.ps1 -DryRun -Verbose
   # Review what would be synced
   ```

4. **Sync to public repo**
   ```powershell
   .\scripts\Sync-Repos.ps1
   # Automatically commits and pushes to public GitHub
   ```

### Verification

After syncing, verify both repos are in sync:

```powershell
# Should show "Files synced: 0"
.\scripts\Sync-Repos.ps1 -DryRun -Verbose
```

## Troubleshooting

### "ERROR: Private repo not found"

**Cause:** Script cannot locate the private repository path.

**Solution:** Verify the path exists or use `-PrivateRepo` parameter:
```powershell
.\scripts\Sync-Repos.ps1 -PrivateRepo "C:\Correct\Path\To\Private"
```

### "Warning: Git operations failed"

**Cause:** Git commit or push failed (network issue, authentication, conflicts).

**Solution:**
1. Files are already synced locally (safe to continue)
2. Manually push from public repo:
   ```powershell
   cd D:\Desktop\SecurityNow-Full
   git status
   git push origin main
   ```

### Files Not Syncing

**Cause:** File might be in excluded folder or .gitignore is blocking it.

**Solution:**
1. Run with `-Verbose` to see detailed status
2. Check if file is in `local/PDF`, `local/mp3`, or `local/Notes/ai-transcripts`
3. These folders are intentionally excluded

### Merge Conflicts

**Cause:** Public repo was edited directly instead of syncing from private.

**Solution:**
```powershell
cd D:\Desktop\SecurityNow-Full
git pull origin main
# Resolve conflicts, then sync again
cd ..\SecurityNow-Full-Private
.\scripts\Sync-Repos.ps1
```

## Best Practices

### ✅ DO

- Always work in the private repo first
- Use `-DryRun` before actual sync to preview changes
- Run sync after committing to private repo
- Keep both repos on the same branch (usually `main`)

### ❌ DON'T

- Don't edit files directly in the public repo (sync will overwrite)
- Don't manually copy files between repos (use the script)
- Don't commit copyrighted content to private repo's synced folders
- Don't modify the script's exclusion rules without understanding copyright implications

## Related Documentation

- [WORKFLOW.md](WORKFLOW.md) - Overall Security Now archiving workflow
- [FAQ.md](FAQ.md) - Frequently asked questions
- [README.md](../README.md) - Repository overview
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Detailed troubleshooting guide
