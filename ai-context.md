# AI Context - Security Now Archive Tools
**Version:** 3.5 🎯 AUDIT COMPLETE - OPTIMIZED  
**Last Updated:** 2026-01-16 21:01 CST by Perplexity AI  
**Project Phase:** Production - v3.1.1 Stable Engine  
**Current Version:** v3.1.1 (Production Stable)

---

## ✅ SYSTEM CLEANUP COMPLETE (2026-01-16)

**Summary:** Clean development environment achieved
- 5 orphaned directories deleted (~750MB reclaimed)
- 11 duplicate/obsolete files removed from repos
- Git repos synced: Private (74f27bc), Public (3240e6b)
- Verification passed: Clean working trees, correct paths confirmed

**Current Clean State:**
- **C:\ Drive:** Tools only (`C:\tools\whispercpp\`, `C:\Program Files\wkhtmltopdf\`)
- **D:\Desktop:** Two repos only (`SecurityNow-Full-Private\`, `SecurityNow-Full\`)
- **Backup:** `D:\Backup\SecurityNow-Cleanup-20260116-152439\`

---

## ⚠️ CRITICAL PATHS - QUICK REFERENCE

**Validation Commands (Run these first in any new thread):**
```powershell
# Verify correct paths
Test-Path "D:\Desktop\SecurityNow-Full-Private\scripts\sn-full-run.ps1"  # Must return True
Test-Path "D:\Desktop\SecurityNow-Full\.git"                                # Must return True
Test-Path "C:\tools\whispercpp\whisper-cli.exe"                            # Must return True
Test-Path "C:\Program Files\wkhtmltopdf\bin\wkhtmltopdf.exe"              # Must return True
```

**Local Repositories:**
```powershell
D:\Desktop\SecurityNow-Full-Private\  # ✅ Primary private repo (SOT)
D:\Desktop\SecurityNow-Full\          # ✅ Public tools mirror
```

**GitHub Repositories:**
- Private: `msrproduct/securitynow-full-archive` (SOT for .ai-context.md)
- Public: `msrproduct/securitynow-archive-tools` (Synced copy)

**Tool Paths:**
```powershell
C:\tools\whispercpp\whisper-cli.exe                    # ✅ Whisper executable
C:\tools\whispercpp\models\base.en.bin               # ✅ Whisper model
C:\Program Files\wkhtmltopdf\bin\wkhtmltopdf.exe     # ✅ PDF converter
```

**Scripts:**
```powershell
.\scripts\Special-Sync.ps1   # ✅ Sync private→public (NOT Sync-Repos.ps1)
.\scripts\sn-full-run.ps1    # ✅ Production engine v3.1.1
```

**⚠️ Common Path Errors:** See `COMMON-MISTAKES.md` for detailed error prevention patterns.

---

## PROJECT OVERVIEW

### Mission
Archive all Security Now! podcast episodes (2005–2026+) with official GRC PDFs where available, AI-generated transcripts for missing episodes, and proper copyright separation between public tools and private media.

### Core Principles (NEVER VIOLATE)
1. **Steve Gibson Alignment** - Honor Steve's "trust no one's cloud" philosophy; local-first architecture; free tools for the greater good
2. **User Experience Priority** - User-friendly and easy to use is our goal always; MUST work for non-technical Security Now fans, not just PowerShell experts
3. **Legal/Ethical Boundaries** - NEVER redistribute copyrighted PDFs/MP3s publicly; only share tools/indexes; always cite GRC.com and TWiT.tv
4. **Local-First Security** - Target classified/regulated environments (defense, finance, healthcare) as competitive moat; air-gap compatible, zero cloud dependencies

### Tech Stack
- **Languages:** PowerShell 7.x (required)
- **PDF Generation:** wkhtmltopdf 0.12.6
- **Transcription:** Whisper.cpp (base.en model)
- **Version Control:** Git with dual remotes (public + private)
- **File Storage:** Git LFS for MP3/PDF in private repo

### Critical Constraints
- **Legal:** Never commit copyrighted media (PDFs, MP3s) to public repo
- **Performance:** ~1,000+ episodes × 3–5 min/episode = 50–85 hours full run
- **Compatibility:** Windows 10/11, PowerShell 7+, UTF-8 encoding
- **UX Priority:** Must work for non-technical fans, not just PowerShell experts

---

## REPOSITORY STRUCTURE & PATHS

### Local Development Machine
- **Primary Private Repo:** `D:\Desktop\SecurityNow-Full-Private\` ✅
- **Public Tools Mirror:** `D:\Desktop\SecurityNow-Full\` ✅
- **CRITICAL:** ALL file operations MUST use `$PSScriptRoot` for portability

### Repository Architecture

```
D:\Desktop\SecurityNow-Full-Private/         (Private - LOCAL + GitHub)
├── local/
│   ├── audio/         # MP3 files from TWiT CDN
│   ├── pdf/           # Official GRC PDFs + AI-generated PDFs (by year)
│   └── transcripts/   # Whisper AI transcripts (text files)
├── scripts/
│   ├── sn-full-run.ps1       # v3.1.1 PRODUCTION ENGINE
│   └── Special-Sync.ps1      # Sync script
├── data/
│   ├── SecurityNowNotesIndex.csv  # Episode metadata index
│   └── episode-dates.csv          # Episode → Year mapping
├── docs/                     # Documentation
├── .ai-context.md            # This file (SOT - synced to public)
├── COMMON-MISTAKES.md        # Error prevention
└── NEW-THREAD-CHECKLIST.md   # Development workflow

D:\Desktop\SecurityNow-Full/                 (Public Mirror - LOCAL + GitHub)
├── scripts/           # Sanitized scripts ONLY (no credentials)
├── docs/              # README, FAQ, WORKFLOW, TROUBLESHOOTING
├── data/              # Public data files
├── .ai-context.md     # Synced FROM private repo
└── .github/FUNDING.yml
```

### GitHub Repositories
- **Private:** `msrproduct/securitynow-full-archive` ← SOT for .ai-context.md
- **Public:** `msrproduct/securitynow-archive-tools` ← Synced copy

---

## TOOL INSTALLATION & CONFIGURATION

### Whisper Speech-to-Text ⚠️ CRITICAL
```powershell
# Executable
C:\tools\whispercpp\whisper-cli.exe       # ✅ CORRECT
# ❌ NOT C:\whisper-cli\whisper-cli.exe
# ❌ NOT C:\whispercpp\whisper-cli.exe

# Model
C:\tools\whispercpp\models\base.en.bin   # ✅ CORRECT
```

### wkhtmltopdf HTML → PDF
```powershell
# Executable
C:\Program Files\wkhtmltopdf\bin\wkhtmltopdf.exe

# Required Flags
& $wkhtmlPath --enable-local-file-access `
              --no-pdf-header-footer `
              --quiet `
              "$inputHtml" "$outputPdf"
```

### PowerShell
- **Version Required:** 7.4+ (NOT Windows PowerShell 5.1)
- **Check:** `$PSVersionTable.PSVersion`

---

## KEY TECHNICAL DECISIONS

| Date       | Decision                          | Rationale                                      | Impact                                   |
|------------|-----------------------------------|------------------------------------------------|------------------------------------------|
| 2026-01-11 | Dual public/private repos         | Legal: keep copyrighted media off public GitHub| Enables OSS contributions without DMCA risk |
| 2026-01-12 | wkhtmltopdf over browser PDF      | Browser adds file paths to footers             | Clean AI PDFs with disclaimer            |
| 2026-01-13 | episode-dates.csv dynamic lookup  | Hardcoded year ranges fail for holiday episodes| Correct folder placement                 |
| 2026-01-13 | $PSScriptRoot for all paths       | Eliminates hardcoded assumptions               | Works across machines                    |
| 2026-01-15 | .ai-context.md system             | Prevent 8-hour debugging loops                 | 21.5 hrs saved (projected)               |
| 2026-01-16 | Complete system cleanup           | 5 orphaned folders causing confusion           | Clean development environment            |
| 2026-01-16 | Path corrections v3.3             | Local folder ≠ GitHub repo name                | Eliminated remaining confusion           |
| 2026-01-16 | Private repo as SOT               | .ai-context.md synced private→public           | Single source of truth established       |

---

## CRITICAL PATHS & COORDINATES

### GRC Archive URLs
- **Current Year:** `https://www.grc.com/securitynow.htm`
- **Past Years:** `https://www.grc.com/sn/past-{YYYY}.htm` (2005–2025)
- **PDF Pattern:** `https://www.grc.com/sn/sn-{NNNN}-notes.pdf`
- **HTML Fallback:** `https://www.grc.com/sn/sn-{NNNN}.htm`

### TWiT Audio CDN
- **MP3 Pattern:** `https://cdn.twit.tv/audio/sn/sn{NNNN}/sn{NNNN}.mp3`
- **Example:** Episode 7 → `https://cdn.twit.tv/audio/sn/sn0007/sn0007.mp3`

---

## DEVELOPMENT STANDARDS & REQUIREMENTS

### Code Quality Standards
- **Complete Scripts Only** - Always provide full file content, NEVER partial edits (causes confusion and copy-paste errors)
- **DRY Principle** - NEVER duplicate logic; refactor into functions
- **Portable Paths** - ALL paths must use `$PSScriptRoot`, NEVER hardcoded drives
- **PowerShell Best Practices** - Approved verbs, comment-based help, proper error handling, CmdletBinding

### User Experience Requirements
- **Friendly Error Messages** - NO developer jargon (e.g., "regex failed"); explain WHY and WHAT TO DO
- **Progress Indicators** - Long operations (Whisper transcription, batch downloads) MUST show progress/timers
- **Dry-Run Clarity** - `-DryRun` mode MUST clearly show "SIMULATED" or "WOULD" actions, not confusing "FAILED" messages
- **Context-Aware Help** - Examples must explain WHEN/WHY to use a feature, not just syntax

### Pre-Commit Testing Checklist
```powershell
# 1. Syntax Validation
# PowerShell script must parse without errors

# 2. Dry-Run Test
.\scripts\sn-full-run.ps1 -DryRun -MinEpisode 1 -MaxEpisode 5 -Verbose

# 3. Three-Range Test (before release)
# - Episodes 1-5 (early/AI-only)
# - Episodes 500-505 (mid-range)
# - Episodes 1000-1005 (recent)

# 4. Path Verification
# Confirm NO hardcoded D:\ paths remain

# 5. Encoding Check
# CSV files MUST use -Encoding UTF8
```

---

## TESTING & VALIDATION PROTOCOLS

### Known Regression Risks (CHECK THESE)
- ⚠️ **Whisper Path** - `C:\tools\whispercpp\whisper-cli.exe` and model `base.en.bin`
- ⚠️ **wkhtmltopdf Flags** - Must include `--no-pdf-header-footer` to avoid file paths in PDFs
- ⚠️ **GRC Archive URLs** - `securitynow.htm` (current year) vs `sn/past-{YYYY}.htm` (historical)
- ⚠️ **GRC HTML Regex** - Must use `Episode&#160;(\d{1,4})&#160;-` (handles HTML entities)
- ⚠️ **CSV Encoding** - MUST use `-Encoding UTF8` for `episode-dates.csv` and `SecurityNowNotesIndex.csv`

### Three-Range Test Pattern (Required Before Release)
1. **Episodes 1-5** - Early archive, AI-only (no official PDFs)
2. **Episodes 500-505** - Mid-range, mixed content
3. **Episodes 1000-1005** - Recent, official PDFs available

---

## FILE SYNC WORKFLOW

### Sync Order (NEVER REVERSE)
1. **Private Repo First:** Commit to `D:\Desktop\SecurityNow-Full-Private\`
2. **Then Public:** Run `Special-Sync.ps1` to copy tools/docs → public repo
3. **Validation:** Confirm NO media files in public repo

### Sync Script
```powershell
# Location: D:\Desktop\SecurityNow-Full-Private\scripts\Special-Sync.ps1
cd "D:\Desktop\SecurityNow-Full-Private"
.\scripts\Special-Sync.ps1
```

**IMPORTANT:** `Special-Sync.ps1` now includes `.ai-context.md` sync from private→public

---

## COMMON MISTAKES & ERROR PREVENTION

**CRITICAL:** Before any code changes, consult `COMMON-MISTAKES.md` for documented error patterns.

### Top 3 Repeated Errors
1. **Wrong local repo path** - Use `D:\Desktop\SecurityNow-Full-Private\` NOT `SecurityNow-Full\`
2. **Wrong Whisper path** - Use `C:\tools\whispercpp\whisper-cli.exe` NOT `C:\whisper-cli\`
3. **Wrong sync script** - Use `Special-Sync.ps1` NOT `Sync-Repos.ps1`

### Quick Validation
```powershell
# Verify paths before proceeding
Test-Path "D:\Desktop\SecurityNow-Full-Private\scripts\sn-full-run.ps1"  # True
Test-Path "C:\tools\whispercpp\whisper-cli.exe"                          # True
Test-Path "C:\Program Files\wkhtmltopdf\bin\wkhtmltopdf.exe"            # True
```

**Full Error Prevention Details:** See `COMMON-MISTAKES.md` for:
- GRC regex patterns (HTML entities)
- PowerShell syntax gotchas (no `goto`)
- Hardcoded path failures
- Copy-paste error patterns
- DRY violations (year mapping, CSV updates)

---

## NEW THREAD STARTUP PROTOCOL

**Every new development thread MUST:**
1. Read this file (`.ai-context.md`) from private repo
2. Read `NEW-THREAD-CHECKLIST.md` for session workflow
3. Read `COMMON-MISTAKES.md` for error prevention patterns
4. Verify paths with `Test-Path` before proceeding
5. **Treat older threads as retired sources** - cite when needed, but don't re-summarize

### Context Files Location
```powershell
D:\Desktop\SecurityNow-Full-Private\.ai-context.md              # This file (SOT)
D:\Desktop\SecurityNow-Full-Private\NEW-THREAD-CHECKLIST.md     # Workflow
D:\Desktop\SecurityNow-Full-Private\COMMON-MISTAKES.md          # Errors
```

**Note:** Space Instructions point to public repo copy, but private repo is the source of truth.

---

## EMERGENCY QUICK-REF

### Correct Paths
```powershell
# Local Repos
D:\Desktop\SecurityNow-Full-Private\          # ✅ Primary private repo (SOT)
D:\Desktop\SecurityNow-Full\                  # ✅ Public mirror

# GitHub Repos  
https://github.com/msrproduct/securitynow-full-archive      # ✅ Private (SOT)
https://github.com/msrproduct/securitynow-archive-tools     # ✅ Public

# Tools
C:\tools\whispercpp\whisper-cli.exe                         # ✅ Whisper
C:\Program Files\wkhtmltopdf\bin\wkhtmltopdf.exe          # ✅ PDF

# Scripts
.\scripts\Special-Sync.ps1                                  # ✅ Sync
.\scripts\sn-full-run.ps1                                   # ✅ Engine v3.1.1
```

### Verification Commands
```powershell
# Test paths exist
Test-Path "D:\Desktop\SecurityNow-Full-Private\scripts\sn-full-run.ps1"  # Should return True
Test-Path "C:\tools\whispercpp\whisper-cli.exe"                          # Should return True
Test-Path "C:\Program Files\wkhtmltopdf\bin\wkhtmltopdf.exe"            # Should return True

# Verify correct repo
cd "D:\Desktop\SecurityNow-Full-Private"
git remote -v  # Should show msrproduct/securitynow-full-archive

# Check engine version
.\scripts\sn-full-run.ps1 -MaxEpisode 1 -DryRun  # Should show v3.1.1
```

### When Path Confusion Occurs
1. ⚠️ **STOP** - Check this file FIRST
2. Verify: `Test-Path "D:\Desktop\SecurityNow-Full-Private\"`
3. Do NOT proceed with wrong paths

---

## VERSION HISTORY

| Version | Date       | Changes                                                                 |
|---------|------------|-------------------------------------------------------------------------|
| 3.5     | 2026-01-16 | **AUDIT COMPLETE:** Removed "Current Development Focus" (dynamic content), eliminated 157-line duplication with COMMON-MISTAKES.md, added Development Standards & Testing Protocols, compressed cleanup summary, streamlined path corrections. File reduced from 485→315 lines (-35%). |
| 3.4     | 2026-01-16 | SOT ESTABLISHED: Private repo now source of truth, synced to public. Added GRC regex pattern, PowerShell goto gotcha, verification commands, NEW-THREAD-CHECKLIST protocol, development roadmap |
| 3.3     | 2026-01-16 | CRITICAL: Fixed local repo path (SecurityNow-Full-Private), added cleanup completion status, verified all paths |
| 3.2     | 2026-01-16 | Fixed Whisper path (4th time), moved to top with validation |
| 3.1     | 2026-01-15 | Fixed sync script name (Special-Sync.ps1), drive audit |
| 3.0     | 2026-01-15 | Complete context system with mistake log |
| 2.0     | 2026-01-13 | Added script versioning, episode-dates.csv |
| 1.0     | 2026-01-11 | Initial draft |

**Thread Policy:** Treat older threads as retired sources - cite when relevant, don't re-summarize.

---

## END OF .ai-context.md v3.5
✅ **AUDIT COMPLETE** - OPTIMIZED FOR ERROR-FREE DEVELOPMENT  
✅ **DUPLICATIONS ELIMINATED** - Single source per concept  
✅ **MISSING STANDARDS ADDED** - UX priority, testing protocols  
✅ **DYNAMIC CONTENT REMOVED** - Active work belongs in session context  
✅ **READY FOR PRODUCTION** - Trust built through clarity and precision
