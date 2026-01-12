# Security Now Archive Architecture

## Overview

This project uses a **dual-repository architecture** to balance open-source collaboration with copyright compliance. Understanding this design is essential for contributors and users.

## Why Two Repositories?

### The Copyright Challenge

Security Now podcast content has different copyright statuses:

- **Copyrighted Content** (© Steve Gibson / GRC / TWiT)
  - Official show notes PDFs from GRC.com
  - MP3 audio files from TWiT.tv
  - Even AI-generated transcripts derived from copyrighted audio

- **Open Source Tools** (MIT License)
  - PowerShell scripts we create
  - Documentation we write
  - Index/metadata files

**Problem**: You can't legally share copyrighted content publicly, but you can share the tools to build your own personal archive.

**Solution**: Split into two repositories with different purposes.

## Repository Architecture

### Public Repository: `securitynow-archive-tools`

**Purpose**: Open-source toolkit for building your own archive

**Location**: https://github.com/msrproduct/securitynow-archive-tools

**Contains**:
- ✅ PowerShell scripts
- ✅ Documentation
- ✅ Episode index CSV (metadata only)
- ✅ Setup instructions
- ❌ NO PDFs
- ❌ NO MP3s
- ❌ NO transcripts

**Who can access**: Everyone (public)

**Purpose**: 
- Share tools with the community
- Accept contributions
- Help others build their own archives
- Respect copyright by not distributing protected content

### Private Repository: `securitynow-full-archive`

**Purpose**: Complete personal archive with all media files

**Location**: https://github.com/msrproduct/securitynow-full-archive (private)

**Contains**:
- ✅ Everything from public repo (scripts, docs)
- ✅ Official PDFs from GRC.com
- ✅ MP3 files from TWiT.tv
- ✅ AI-generated transcripts
- ✅ All media organized by year

**Who can access**: Only you (private)

**Purpose**:
- Store your complete personal archive
- Use Git LFS for large files
- Maintain version control
- Personal backup and organization

## Folder Structure

### Shared Structure (Both Repos)

```
├── README.md                  # Main documentation
├── WORKFLOW.md               # How to use the tools
├── scripts/                  # PowerShell automation
│   ├── SecurityNow-EndToEnd.ps1
│   ├── Fix-AI-PDFs.ps1
│   └── Sync-Repos.ps1
├── docs/                     # User documentation
│   ├── Sync-Repos-Guide.md
│   ├── Architecture.md       # This file
│   ├── Troubleshooting.md
│   └── FAQ.md
└── data/                     # Metadata only
    └── SecurityNowNotesIndex.csv
```

### Private Repo Only

```
└── local/                    # All media files (gitignored in public)
    ├── PDF/                  # Organized by year
    │   ├── 2005/
    │   │   ├── sn-1-notes.pdf
    │   │   ├── sn-1-notes-ai.pdf
    │   │   └── ...
    │   ├── 2006/
    │   └── ...
    ├── mp3/                  # Organized by year
    │   ├── 2005/
    │   │   ├── sn0001.mp3
    │   │   └── ...
    │   └── ...
    └── Notes/
        └── ai-transcripts/   # AI-generated text files
            ├── sn-1-notes-ai.txt
            └── ...
```

## How Files Stay in Sync

### The Sync-Repos.ps1 Script

This script is the bridge between the two repositories:

```
┌─────────────────────────────────┐
│  Private Repo (Full Archive)   │
│                                 │
│  • Scripts                      │
│  • Docs                         │
│  • CSV Index                    │
│  • PDFs (not synced) ───────┐   │
│  • MP3s (not synced) ───────┤   │
│  • Transcripts (not synced) ┘   │
└────────────┬────────────────────┘
             │
             │ Sync-Repos.ps1
             │ (copies non-copyrighted files)
             ↓
┌─────────────────────────────────┐
│  Public Repo (Tools Only)       │
│                                 │
│  • Scripts (synced)             │
│  • Docs (synced)                │
│  • CSV Index (synced)           │
│                                 │
└─────────────────────────────────┘
```

### Sync Rules

**Always Synced** (Public ← Private):
- `README.md`
- `LICENSE`
- `FUNDING.yml`
- `scripts/**/*`
- `docs/**/*`
- `data/SecurityNowNotesIndex.csv`

**Never Synced** (Private only):
- `local/PDF/**/*`
- `local/mp3/**/*`
- `local/Notes/ai-transcripts/**/*`
- `.gitignore` (intentionally different)

### Sync Direction

Sync is **unidirectional**: Private → Public

- ✅ Changes in private repo sync TO public repo
- ❌ Changes in public repo are overwritten by next sync

**Best practice**: Always edit in the private repo, then sync.

## Git Configuration

### Public Repo `.gitignore`

```gitignore
# OS files
Thumbs.db
.DS_Store

# Temp files
*.tmp
*.log

# IDE
.vs/
.vscode/

# Note: No need to ignore media files (they don't exist here)
```

### Private Repo `.gitignore`

```gitignore
# OS files
Thumbs.db
.DS_Store

# Temp files
*.tmp
*.log
temp-*.html

# IDE
.vs/
.vscode/

# Git LFS tracks large files (don't ignore them)
# PDFs, MP3s, and transcripts are tracked by Git LFS
```

### Git LFS (Large File Storage)

The private repo uses Git LFS for large files:

```bash
# Configured in private repo
git lfs track "*.pdf"
git lfs track "*.mp3"
```

This prevents repo bloat by storing large files separately.

## Local Directory Setup

### Recommended Local Structure

```
D:\Desktop\
├── SecurityNow-Full/              # Public repo clone
│   ├── .git/
│   ├── scripts/
│   ├── docs/
│   └── README.md
│
└── SecurityNow-Full-Private/      # Private repo clone
    ├── .git/
    ├── scripts/
    ├── docs/
    ├── local/                     # Media files
    │   ├── PDF/
    │   ├── mp3/
    │   └── Notes/
    └── README.md
```

### Why This Structure?

1. **Clear separation** - Easy to see which is which
2. **Prevents accidents** - Hard to commit media to public repo
3. **Script compatibility** - Default paths work out of the box
4. **Sync efficiency** - Quick file comparisons

## Workflow Integration

### Daily Use

1. **Work in private repo** (primary workspace)
2. **Run SecurityNow-EndToEnd.ps1** (downloads/processes media)
3. **Commit to private repo** (save your work)
4. **Run Sync-Repos.ps1** (update public repo)
5. **Public repo auto-syncs to GitHub** (share tools)

### One-Time Setup

```powershell
# Clone public repo
git clone https://github.com/msrproduct/securitynow-archive-tools.git SecurityNow-Full

# Clone private repo
git clone https://github.com/YourUsername/securitynow-full-archive.git SecurityNow-Full-Private

# Configure private repo for Git LFS
cd SecurityNow-Full-Private
git lfs install
git lfs track "*.pdf"
git lfs track "*.mp3"
```

## Copyright Compliance

### What's Legal

✅ **You can**:
- Download PDFs from GRC.com for personal use
- Download MP3s from TWiT.tv for personal use
- Store them in your private repo
- Generate AI transcripts for personal use
- Share the **tools** that build an archive

❌ **You cannot**:
- Publicly distribute GRC PDFs
- Publicly distribute TWiT MP3s
- Publicly share AI transcripts (derivative works)
- Host media on public GitHub repos

### Why This Matters

Steve Gibson and Leo Laporte provide this content for free:
- **Respect their copyright** by not redistributing
- **Support their work** through proper channels
- **Use tools legally** by keeping media private

## Benefits of This Architecture

### For Users

- ✅ Legal access to tools
- ✅ Build your own personal archive
- ✅ Version control for scripts
- ✅ Contribute improvements
- ✅ Keep media private and legal

### For Contributors

- ✅ Fork public repo freely
- ✅ Submit pull requests for tools
- ✅ Improve documentation
- ✅ No copyright concerns
- ✅ Clear separation of concerns

### For the Project

- ✅ Copyright compliant
- ✅ Open source tools
- ✅ Community contributions
- ✅ Respects content creators
- ✅ Sustainable long-term

## Security Considerations

### Private Repo Security

- **Never make private repo public** - Contains copyrighted content
- **Use strong GitHub credentials** - Protect your private media
- **Regular backups** - Git LFS files are not in standard backups
- **Review commits** - Ensure no accidental copyright violations

### Public Repo Safety

- **Double-check before push** - No media files accidentally committed
- **Use Sync-Repos.ps1** - Automated copyright protection
- **Review pull requests** - Ensure no copyrighted content

## Future Scalability

### Adding New Features

When adding new scripts:

1. Develop in private repo
2. Test thoroughly
3. Sync to public repo
4. Tag release in both repos

### Supporting New Episode Types

If Security Now introduces new formats:

- Update scripts in private repo
- Test with new media locally
- Sync scripts to public repo
- Update documentation in both repos

## Related Documentation

- [Sync-Repos Guide](Sync-Repos-Guide.md) - How to use the sync script
- [Main Workflow](../WORKFLOW.md) - Complete archive process
- [Troubleshooting](Troubleshooting.md) - Common issues
- [FAQ](FAQ.md) - Frequently asked questions

## Summary

The dual-repository architecture enables:

1. **Legal tool sharing** via public repo
2. **Personal media archive** via private repo
3. **Automated synchronization** via Sync-Repos.ps1
4. **Copyright compliance** through clear boundaries
5. **Community contributions** without legal concerns

This design respects content creators while empowering users to build their own personal archives using open-source tools.
