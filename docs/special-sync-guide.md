# Special-Sync.ps1 - Complete Repository Sync Tool

## Overview

`Special-Sync.ps1` is your **single-command solution** to keep all 4 repositories in perfect sync:
- **Local Private Repo** (`D:\Desktop\SecurityNow-Full-Private`) → Source of Truth
- **GitHub Private Repo** → Backup with copyrighted material
- **Local Public Repo** (`D:\Desktop\SecurityNow-Full`) → Tools-only mirror
- **GitHub Public Repo** → Community-accessible tools/docs

## Why This Script Exists

You needed ONE script that handles the entire sync workflow automatically, eliminating manual Git commands and ensuring consistency across all four repositories.

**The Problem:** Manually syncing 4 repos is error-prone and time-consuming.

**The Solution:** One script, one command, complete sync.

## What It Does (5 Steps)

### Step 1: Sync Local Private → GitHub Private
- Pulls latest changes from GitHub private repo
- Commits any local changes in `D:\Desktop\SecurityNow-Full-Private`
- Pushes to GitHub private repo
- **Result:** Private backup is current

### Step 2: Detect Changes
- Compares files between local private and local public repos
- Uses SHA-256 hashing to detect even 1-byte differences
- Lists NEW, UPDATE, SAME status for each file

### Step 3: Exclude Copyrighted Content
Automatically skips:
- `/local-pdf/` - Official GRC PDFs
- `/local-mp3/` - Audio files
- `/local-notes-ai-transcripts/` - AI transcripts
- `.gitignore` - Each repo maintains its own

### Step 4: Sync Local Private → Local Public
- Copies only tools, docs, and scripts
- Excludes ALL copyrighted material
- Maintains separate `.gitignore` files

### Step 5: Push to GitHub Public
- Commits changes to local public repo
- Pushes to GitHub public repo
- **Result:** Community has latest tools/docs

## Usage

### Basic Sync (One Command)
```powershell
cd D:\Desktop\SecurityNow-Full-Private
.\scripts\Special-Sync.ps1
```

**That's it!** All 4 repos are now synced.

### Dry Run (Preview Changes)
```powershell
.\scripts\Special-Sync.ps1 -DryRun -Verbose
```
Shows what would be synced without making changes.

### Custom Commit Messages
```powershell
.\scripts\Special-Sync.ps1 -PrivateCommitMessage "Fixed bug in AI PDF script" -PublicCommitMessage "Updated tools for episode 1061"
```

## Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-PrivateRepo` | String | `D:\Desktop\SecurityNow-Full-Private` | Path to local private repo (source of truth) |
| `-PublicRepo` | String | `D:\Desktop\SecurityNow-Full` | Path to local public repo |
| `-DryRun` | Switch | Off | Test mode - no changes made |
| `-Verbose` | Switch | Off | Detailed output for each file |
| `-PrivateCommitMessage` | String | Auto-generated | Custom commit for private repo |
| `-PublicCommitMessage` | String | "Sync from private repo" | Custom commit for public repo |

## Output Explained

### Sample Output
```
========================================
Security Now - Special Sync Tool #2
========================================
Private repo (SOURCE OF TRUTH): D:\Desktop\SecurityNow-Full-Private
Public repo (tools only)      : D:\Desktop\SecurityNow-Full

[1/5] Pull latest from GitHub Private → Local Private
✓ Already up to date

[2/5] Check for uncommitted changes in Local Private
✓ Local Private is clean

[3/5] Push Local Private → GitHub Private
✓ Everything up-to-date

[4/5] Sync Local Private → Local Public (tools/docs only)
Summary:
  New files    : 0
  Updated files: 0
  Unchanged    : 138

✓ Synced 0 files from Private → Public

[5/5] Commit and Push Local Public → GitHub Public
No changes to commit

========================================
SUMMARY
========================================
Files synced (Private → Public): 0
Files in Public-Only (warnings): 0

✅ ALL 4 REPOS SYNCED SUCCESSFULLY!
========================================
```

### Status Indicators
- **SAME** - File identical in both repos
- **NEW** - File exists in private but not public (will be created)
- **UPDATE** - File differs (will be updated)
- **SKIP** - File not found in private repo (source of truth)
- **EXCLUDE** - File in copyrighted folder (not synced)

## Workflow Integration

### Daily Development Workflow
```powershell
# 1. Work in private repo (your workspace)
cd D:\Desktop\SecurityNow-Full-Private

# 2. Make changes, test scripts
notepad scripts\Convert-HTML-to-PDF.ps1

# 3. Run Special Sync (one command!)
.\scripts\Special-Sync.ps1

# Done! All 4 repos synced automatically.
```

### Handle Extra Files (Public-Only)

If the script detects files in the public repo that **don't exist** in the private repo:

```
⚠️  PUBLIC-ONLY FILES DETECTED
Public-Only Files:
  • docs\test-file.txt

✓ Cleanup list saved to: PUBLIC-ONLY-CLEANUP-LIST.txt
```

**What to do:**
1. Review the `PUBLIC-ONLY-CLEANUP-LIST.txt` file
2. Copy useful files from public → private, OR
3. Delete orphaned files from public repo
4. Re-run Special-Sync.ps1

## Troubleshooting

### ERROR: "Private repo not found"
**Cause:** Script cannot locate `D:\Desktop\SecurityNow-Full-Private`

**Solution:**
```powershell
.\scripts\Special-Sync.ps1 -PrivateRepo "C:\MyRepos\SecurityNow-Private"
```

### WARNING: "Git push failed"
**Cause:** Network issue or authentication problem

**Solution:**
```powershell
cd D:\Desktop\SecurityNow-Full
git status
git push origin main
```

### Files Not Syncing
**Cause:** File in excluded folder

**Solution:** Check if file is in `/local-pdf/`, `/local-mp3/`, or `/local-notes-ai-transcripts/` - these are intentionally excluded.

### Public-Only Files Warning
**Solution:**
```powershell
# Review the cleanup list
notepad PUBLIC-ONLY-CLEANUP-LIST.txt

# Option 1: Copy to private if needed
Copy-Item D:\Desktop\SecurityNow-Full\docs\file.md D:\Desktop\SecurityNow-Full-Private\docs\

# Option 2: Delete from public if orphaned
cd D:\Desktop\SecurityNow-Full
git rm docs\orphaned-file.txt
git commit -m "Remove orphaned file"
git push origin main
```

## Source of Truth Clarification

⚠️ **Important:** The **local private repo** is your source of truth, NOT GitHub.

### Correct Flow
1. **Edit** → Local Private (`D:\Desktop\SecurityNow-Full-Private`)
2. **Backup** → GitHub Private
3. **Mirror** → Local Public (`D:\Desktop\SecurityNow-Full`)
4. **Share** → GitHub Public

## Best Practices

### DO ✅
- Always work in `D:\Desktop\SecurityNow-Full-Private` first
- Use `-DryRun` before actual sync to preview changes
- Run sync after committing to private repo
- Review `PUBLIC-ONLY-CLEANUP-LIST.txt` when warnings appear

### DON'T ❌
- Don't edit files directly in public repo (sync will overwrite)
- Don't manually copy files between repos (use script)
- Don't commit copyrighted content to synced folders
- Don't ignore public-only file warnings

## Advanced Usage

### Batch Multiple Changes
```powershell
# Make multiple changes
cd D:\Desktop\SecurityNow-Full-Private
notepad scripts\Fix-AI-PDFs.ps1
notepad docs\FAQ.md

# Commit all changes
git add .
git commit -m "Update scripts and documentation"

# Sync once (all changes propagated)
.\scripts\Special-Sync.ps1
```

## Related Documentation

- [WORKFLOW.md](WORKFLOW.md) - Overall Security Now archiving workflow
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Detailed troubleshooting
- [FAQ.md](FAQ.md) - Repository sync questions
- [QUICK-START.md](QUICK-START.md) - 30-minute beginner guide

## Credits

Created for the **Security Now! Archive Tools** project to simplify multi-repository management while respecting copyrighted content.

---

**One Script. One Command. Complete Sync.**
