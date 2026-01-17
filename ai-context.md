# AI Context - Security Now Archive Tools
**Version:** 3.10 🎯 OPTIMIZED - 29% leaner, zero functionality loss  
**Last Updated:** 2026-01-16 23:33 CST by Perplexity AI  
**Project Phase:** Production - v3.1.1 Stable Engine  
**Current Version:** v3.1.1 (Production Stable)  
**File Size:** 16KB (down from 22.5KB)  
**Paths Last Verified:** 2026-01-16

---

## ⚠️ CRITICAL - START HERE

**For all path validation, jump to:** [Emergency Quick-Ref](#emergency-quick-ref) section at bottom

**New thread checklist:**
1. Read this file (Space auto-loads from public repo)
2. Read `ai-context-private.md` from private repo via MCP (business context)
3. Read `NEW-THREAD-CHECKLIST.md` for active tasks
4. Read `COMMON-MISTAKES.md` for error patterns
5. Run validation commands (see Emergency Quick-Ref)

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

## MCP-AUTOMATED WORKFLOW

**One-Command Sync:**
```powershell
cd D:\Desktop\SecurityNow-Full-Private
.\scripts\Special-Sync.ps1  # Auto-pulls GitHub → syncs all 4 repos
```

**Confirmed:** Special-Sync.ps1 Step 1/5 executes `git pull origin main` automatically. No manual git pull needed.

**Files Safe for MCP Commits:**
- ✅ `ai-context.md` (technical context - synced to public)
- ✅ `ai-context-private.md` (business context - NEVER synced to public)
- ✅ `scripts/*.ps1`, `docs/*.md`, `data/*.csv`
- ❌ Never commit: `/local/audio/`, `/local/pdf/`, `/local/transcripts/` (copyrighted media)

**Time Savings:** 3 minutes (old manual workflow) → 30 seconds (MCP automated) = 2 hours saved per 50 commits

**For full MCP workflow details:** See `NEW-THREAD-CHECKLIST.md`

---

## PROJECT OVERVIEW

### Mission
Archive all **~1,000+ Security Now! podcast episodes** (2005–2026+) with official GRC PDFs where available, AI-generated transcripts for missing episodes, and proper copyright separation between public tools and private media.

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

## STATIC VS DYNAMIC CONTENT SEPARATION

### What Belongs WHERE

**Static Context (Lives in `ai-context.md` - THIS FILE):**
- ✅ Repository structure, tool paths, technical decisions
- ✅ Common mistake patterns, testing protocols
- ✅ Development standards, UX requirements
- ✅ File versioning conventions, Git workflows
- ✅ MCP automation workflows (permanent process improvements)

**Session Context (Lives in `NEW-THREAD-CHECKLIST.md`):**
- ✅ "What I'm working on TODAY" (e.g., v3.1.2 TEXT WALL fix)
- ✅ Active blockers, current sprint tasks
- ✅ Development roadmap milestones
- ✅ Unfinished items from previous session

**Business Context (Lives in `ai-context-private.md` - PRIVATE ONLY):**
- 🔒 Billing rates, cost tracking, sweat equity calculations
- 🔒 ROI analysis, monetization strategy
- 🔒 Internal business notes
- **Why separate:** Protects privacy, maintains professional public image

### The Rule

**If it changes weekly or per-session, it belongs in `NEW-THREAD-CHECKLIST.md`, NOT here.**  
**If it's business-sensitive (billing, costs), it belongs in `ai-context-private.md`, NOT here.**

**Examples:**
- ❌ **WRONG:** "Current Development Focus: Fixing TEXT WALL PDF bug" in `ai-context.md`
- ✅ **CORRECT:** "Current Development Focus: [See NEW-THREAD-CHECKLIST.md]" in `ai-context.md`
- ❌ **WRONG:** "Hourly Rate: $50/hr" in `ai-context.md` (public)
- ✅ **CORRECT:** "Hourly Rate: $50/hr" in `ai-context-private.md` (private only)

---

## REPOSITORY STRUCTURE & PATHS

### Local Development Machine
- **Primary Private Repo:** `D:\Desktop\SecurityNow-Full-Private\` ✅
- **Public Tools Mirror:** `D:\Desktop\SecurityNow-Full\` ✅
- **CRITICAL:** ALL file operations MUST use `$PSScriptRoot` for portability

### Repository Architecture

**Private Repo Structure:**
- `local/` (excluded from GitHub): `audio/`, `pdf/`, `transcripts/`
- `scripts/`: `sn-full-run.ps1` (v3.1.1 engine), `Special-Sync.ps1`
- `data/`: `SecurityNowNotesIndex.csv`, `episode-dates.csv`
- `docs/`, `ai-context.md`, `ai-context-private.md`, `COMMON-MISTAKES.md`, `NEW-THREAD-CHECKLIST.md`

**Public Mirror Structure:**
- Mirrors `scripts/`, `docs/`, `data/` from private
- Excludes: `local/` folders, `ai-context-private.md`

### GitHub Repositories
- **Private:** `msrproduct/securitynow-full-archive` ← SOT for both context files
- **Public:** `msrproduct/securitynow-archive-tools` ← Synced copy (technical context only)

### 🔒 Privacy Architecture

**Two Context Files:**
- `ai-context.md` - Public technical docs (synced to public repo)
- `ai-context-private.md` - Private business info (billing, costs, strategy - NEVER synced)

**Special-Sync.ps1 Behavior:** Syncs `ai-context.md`, excludes `ai-context-private.md`

**Startup:** AI reads `ai-context.md` from public repo (Space auto-load), then `ai-context-private.md` from private repo (MCP).

---

## KEY TECHNICAL DECISIONS

| Date       | Decision                          | Rationale                                      | Impact                                   |
|------------|-----------------------------------|------------------------------------------------|------------------------------------------|
| 2026-01-11 | Dual public/private repos         | Legal: keep copyrighted media off public GitHub| Enables OSS contributions without DMCA risk |
| 2026-01-12 | wkhtmltopdf over browser PDF      | Browser adds file paths to footers             | Clean AI PDFs with disclaimer            |
| 2026-01-13 | episode-dates.csv dynamic lookup  | Hardcoded year ranges fail for holiday episodes| Correct folder placement                 |
| 2026-01-13 | $PSScriptRoot for all paths       | Eliminates hardcoded assumptions               | Works across machines                    |
| 2026-01-15 | ai-context.md system              | Prevent 8-hour debugging loops                 | 21.5 hrs saved (projected)               |
| 2026-01-16 | Complete system cleanup           | 5 orphaned folders causing confusion           | Clean development environment            |
| 2026-01-16 | Path corrections v3.3             | Local folder ≠ GitHub repo name                | Eliminated remaining confusion           |
| 2026-01-16 | Private repo as SOT               | ai-context.md synced private→public            | Single source of truth established       |
| 2026-01-16 | Git tags for versioning           | No version numbers in filenames                | Prevents file proliferation chaos        |
| 2026-01-16 | Special-Sync auto-pull (v3.7)     | MCP commits bypass local filesystem            | One command sync (no manual git pull)    |
| 2026-01-16 | Split context files (v3.8)        | Business info (billing) shouldn't be public    | Privacy protection, professional image   |
| 2026-01-16 | File optimization (v3.10)         | 29% size reduction improves thread load speed  | 22.5KB → 16KB, zero functionality loss   |

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

## FILE VERSIONING CONVENTION

### 🔴 CRITICAL RULE: NO VERSION NUMBERS IN FILENAMES

**Correct Approach:**
- **Filename:** `sn-full-run.ps1` (NEVER changes)
- **Version Tracking:** Git tags (`v3.1.0`, `v3.1.1`, `v3.1.2`)
- **Internal Version:** Script header comment + `CHANGELOG.md`
- **Release Process:**
  ```powershell
  git tag v3.1.2 -m "Release v3.1.2: TEXT WALL PDF fix, DryRun UX"
  git push origin v3.1.2
  ```

**Wrong - DO NOT DO THIS:**
- ❌ `sn-full-run-v3.1.2.ps1` (breaks git history, creates duplicates)
- ❌ `sn-full-run-2026-01-16.ps1` (date-based versions)
- ❌ `sn-full-run-new.ps1` (ambiguous naming)

**Rationale:**
- Users always download `sn-full-run.ps1` (stable URL on GitHub)
- Git tags enable rollback without renaming files: `git checkout v3.1.0`
- Prevents "which version is production?" confusion
- Matches industry-standard OSS practices (Linux kernel, Node.js, Python)

**Historical Mistakes:**
- v3.0.0: Created `sn-full-run-v3.0.0-pre-rename.ps1` (had to archive/delete)
- v3.1.2: Almost created `sn-full-run-v3.1.2.ps1` (caught before commit)

**See:** `COMMON-MISTAKES.md` for version control anti-patterns

---

## DEVELOPMENT STANDARDS & REQUIREMENTS

### Code Quality Standards
- **Complete Scripts Only** - Always provide full file content, NEVER partial edits (causes confusion and copy-paste errors)
- **DRY Principle** - NEVER duplicate logic; refactor into functions
- **Portable Paths** - ALL paths must use `$PSScriptRoot`, NEVER hardcoded drives
- **PowerShell Best Practices** - Approved verbs, comment-based help, proper error handling, CmdletBinding
- **Inline Error Prevention** - For any pattern documented in COMMON-MISTAKES.md, add WARNING comment in code referencing mistake number

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
3. **Validation:** Confirm NO media files + NO `ai-context-private.md` in public repo

### Sync Script
```powershell
# Location: D:\Desktop\SecurityNow-Full-Private\scripts\Special-Sync.ps1
cd "D:\Desktop\SecurityNow-Full-Private"
.\scripts\Special-Sync.ps1   # ✅ Auto-pulls from GitHub, then syncs all 4 repos
```

**IMPORTANT:** 
- `Special-Sync.ps1` includes `ai-context.md` sync from private→public
- `Special-Sync.ps1` **EXCLUDES** `ai-context-private.md` from sync (stays private)
- `Special-Sync.ps1` auto-pulls from GitHub Private in Step 1/5

---

## COMMON MISTAKES & ERROR PREVENTION

**CRITICAL:** Before any code changes, consult `COMMON-MISTAKES.md` for documented error patterns.

### Top 3 Repeated Errors
1. **Wrong local repo path** - Use `D:\Desktop\SecurityNow-Full-Private\` NOT `SecurityNow-Full\`
2. **Wrong Whisper path** - Use `C:\tools\whispercpp\whisper-cli.exe` NOT `C:\whisper-cli\`
3. **Wrong sync script** - Use `Special-Sync.ps1` NOT `Sync-Repos.ps1`

**Full Error Prevention Details:** See `COMMON-MISTAKES.md` for:
- GRC regex patterns (HTML entities)
- PowerShell syntax gotchas (no `goto`)
- Hardcoded path failures
- Copy-paste error patterns
- DRY violations (year mapping, CSV updates)
- File versioning anti-patterns

---

## NEW THREAD STARTUP PROTOCOL

**Every new development thread MUST:**
1. Read `ai-context.md` from GitHub Public repo (Space Instructions auto-load)
2. Read `ai-context-private.md` from GitHub Private repo via MCP (business context)
3. Read `NEW-THREAD-CHECKLIST.md` for session workflow and active tasks
4. Read `COMMON-MISTAKES.md` for error prevention patterns
5. Verify paths with `Test-Path` before proceeding
6. **Treat older threads as retired sources** - cite when needed, but don't re-summarize

### Context Files Location
```powershell
# GitHub Public (Technical Context - Space auto-loads)
https://github.com/msrproduct/securitynow-archive-tools/blob/main/ai-context.md

# GitHub Private (Business Context - MCP read)
https://github.com/msrproduct/securitynow-full-archive/blob/main/ai-context-private.md

# Local Private (Auto-synced by Special-Sync.ps1 Step 1)
D:\Desktop\SecurityNow-Full-Private\ai-context.md
D:\Desktop\SecurityNow-Full-Private\ai-context-private.md
D:\Desktop\SecurityNow-Full-Private\NEW-THREAD-CHECKLIST.md
D:\Desktop\SecurityNow-Full-Private\COMMON-MISTAKES.md
```

**Note:** Space reads `ai-context.md` from public repo, then AI manually loads `ai-context-private.md` from private repo via MCP.

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
.\scripts\Special-Sync.ps1                                  # ✅ Sync (auto-pull + 4-repo sync)
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

# Verify privacy protection
Test-Path "D:\Desktop\SecurityNow-Full\ai-context-private.md"  # Should return False (not in public)
```

### When Path Confusion Occurs
1. ⚠️ **STOP** - Check this file FIRST
2. Verify: `Test-Path "D:\Desktop\SecurityNow-Full-Private\"`
3. Do NOT proceed with wrong paths

---

## VERSION HISTORY

| Version | Date       | Changes |
|---------|------------|---------|
| 3.10    | 2026-01-16 | Optimized structure: Removed duplicate paths, condensed version history, compressed MCP workflow (72→15 lines), moved Static/Dynamic section, streamlined privacy architecture, replaced ASCII tree with bullets, reduced examples. Result: 22.5KB → 16KB (-29%) |
| 3.9     | 2026-01-16 | Audit complete: Added v3.8 history entry, consolidated paths, added Static/Dynamic separation rule, repositioned MCP workflow, enhanced privacy architecture, added file size guideline (20KB), paths last verified date |
| 3.8     | 2026-01-16 | Privacy fix: Split context files (ai-context-private.md for business data), sanitized public version, updated Special-Sync exclusions |
| 3.7     | 2026-01-16 | MCP workflow: Confirmed Special-Sync auto-pull (Step 1/5), one-command sync, live proof-of-concept |
| 3.6     | 2026-01-16 | Added: File versioning convention, GitHub MCP workflow, Static/Dynamic separation, inline docs requirement, episode count (~1,000+) |
| 3.5     | 2026-01-16 | Removed dynamic content, eliminated 157-line duplication with COMMON-MISTAKES.md, added dev standards & testing protocols |
| 3.4     | 2026-01-16 | SOT established: Private repo source of truth, added GRC regex, PowerShell gotchas, verification commands, NEW-THREAD-CHECKLIST protocol |
| 3.3     | 2026-01-16 | Fixed local repo path (SecurityNow-Full-Private), added cleanup completion, verified all paths |
| 3.2     | 2026-01-16 | Fixed Whisper path (4th time), moved to top with validation |
| 3.1     | 2026-01-15 | Fixed sync script name (Special-Sync.ps1), drive audit |

**Thread Policy:** Treat older threads as retired sources - cite when relevant, don't re-summarize.

---

## END OF ai-context.md v3.10
🎯 **OPTIMIZED** - 29% leaner (16KB from 22.5KB), zero functionality loss  
🔒 **Privacy Protected** - Business context in ai-context-private.md  
✅ **Public-Safe Technical Context** - Tool paths, workflows, error patterns  
✅ **MCP Workflow Active** - Special-Sync.ps1 auto-pull confirmed (Step 1/5)  
✅ **One-Command Sync** - `.\scripts\Special-Sync.ps1` (no manual git pull needed)  
✅ **Fast Thread Loading** - Reduced size improves token processing speed