# New Thread Checklist
**For AI: Read this FIRST when starting a new thread in this Space**

---

## 🚨 Mandatory Pre-Response Actions

Before responding to user's first question in a new thread:

### 1️⃣ Load Core Context
- [ ] Read `ai-context.md` completely
- [ ] Note current production script name/version
- [ ] Verify tool paths (Whisper, wkhtmltopdf)
- [ ] Review file sync rules (Private vs Public repo)

### 2️⃣ Search Space History
- [ ] Search Space files for keywords from user's question
- [ ] Check if similar issue was solved in past threads
- [ ] Review last 2-3 thread titles for project state
- [ ] Note any recent changes to script structure

### 3️⃣ Confirm Current State
- [ ] Which repo is user working in? (Private or Public)
- [ ] Which script version are they using?
- [ ] Have paths changed from `ai-context.md` defaults?

### 4️⃣ 🛡️ **CONTEXT PROOF OF LIFE (MANDATORY)**

**AI MUST provide this verification as FIRST response in thread:**

```markdown
✅ **CONTEXT VERIFIED v3.13:**
- Repo: D:\Desktop\SecurityNow-Full-Private\
- Whisper: C:\tools\whispercpp\whisper-cli.exe
- Script: sn-full-run.ps1 v3.1.3
- Sync: Special-Sync.ps1 (NOT Sync-Repos.ps1)
- 14 documented errors in COMMON-MISTAKES.md loaded

**Verification checkpoint passed** - See ai-context.md line 1 for details
```

**If AI cannot produce this = CONTEXT NOT LOADED = Stop thread immediately**

**Why This Matters:**
- 41+ threads documented wrong paths suggested despite ai-context.md documentation
- Root cause: AI not actually loading/reading context files at thread start
- This protocol FORCES verification before any response
- Space Instructions bug fixed: `.ai-context.md` → `ai-context.md`

---

## ✅ Opening Response Template

Use this structure for your first response:

```markdown
✅ **CONTEXT VERIFIED v3.13:**
- Repo: D:\Desktop\SecurityNow-Full-Private\
- Whisper: C:\tools\whispercpp\whisper-cli.exe  
- Script: sn-full-run.ps1 v3.1.3
- Sync: Special-Sync.ps1 (NOT Sync-Repos.ps1)
- 14 documented errors in COMMON-MISTAKES.md loaded

✅ **Key Facts Confirmed:**
- Working directory: D:\Desktop\SecurityNow-Full-Private
- Production script: sn-full-run.ps1
- Whisper path: C:\tools\whispercpp\ (no dot)
- GRC regex: Uses `&#160;` HTML entities

✅ **Recent Project State:** [1-sentence summary from Space search]

🎯 **Ready to assist with:** [restate user's question]

**Quick confirm:** [Ask 1 clarifying question if needed]
```

---

## 🛑 Before Every Code Suggestion

### Pre-Flight Checks
1. ✅ Does solution already exist in Space files?
2. ✅ Are paths verified against `ai-context.md`?
3. ✅ Is this the correct script version?
4. ✅ Could this repeat a past mistake? (Check COMMON-MISTAKES.md)

### If Proposing Regex for GRC
⚠️ **STOP!** Verify you're using:
```regex
Episode\s*&#160;(\d{1,4})&#160;(\d{1,2})
```
**NOT:** pipes, regular spaces, or `\s+` alone

### If Proposing Whisper Paths
⚠️ **STOP!** Verify you're using:
```powershell
$WhisperExe = "C:\Tools\whispercpp\whisper-cli.exe"
$WhisperModel = "C:\Tools\whispercpp\models\ggml-base.en.bin"
```
**NOT:** `whisper.cpp` (with dot) or model in root

---

## 🔄 During Thread: Continuous Validation

### When User Reports an Error
1. ❌ **Don't immediately propose a fix**
2. ✅ **First:** Search Space files for this exact error
3. ✅ **Then:** Check if we've solved this before
4. ✅ **Finally:** Reference the past solution OR explain why new approach is needed

### If Repeating a Mistake
**Acknowledge immediately:**
```markdown
⚠️ I apologize - I repeated [specific mistake from COMMON-MISTAKES.md].

Let me correct this by referencing the solution from [thread/file]:
[paste correct solution]
```

---

## 📣 MCP WORKFLOW DISCOVERY (2026-01-16 21:52 CST)

### 🎯 Critical Process Improvement - PERMANENT WORKFLOW

**Discovery:** Special-Sync.ps1 Step 1/5 **ALREADY auto-pulls from GitHub Private**

**This means MCP commits work with ZERO manual git commands:**

```powershell
# When AI commits via MCP to GitHub Private:
# 1. AI commits to msrproduct/securitynow-full-archive (bypasses local)
# 2. User runs ONE command:
cd D:\Desktop\SecurityNow-Full-Private
.\scripts\Special-Sync.ps1

# 3. Special-Sync automatically:
#    Step 1/5: git pull origin main  ← AUTO-PULLS MCP COMMIT
#    Step 2/5: Commits any uncommitted local changes
#    Step 3/5: git push to GitHub Private
#    Step 4/5: Syncs Local Private → Local Public (excludes /local-*)
#    Step 5/5: git push to GitHub Public

# 4. Done - all 4 repos synced, zero manual work
```

### ✅ Files Safe for MCP Commits
- `ai-context.md` (synced to public for Space Instructions)
- `NEW-THREAD-CHECKLIST.md` (this file)
- `COMMON-MISTAKES.md`
- `scripts/*.ps1` (all PowerShell scripts)
- `docs/*.md` (all documentation)
- `data/*.csv` (metadata files)

### ❌ Never MCP-Commit
- `/local/audio/` (copyrighted MP3s)
- `/local/pdf/` (copyrighted PDFs)
- `/local/transcripts/` (copyrighted AI transcripts)

### 📊 Efficiency Gains
| Metric | Before (Manual) | After (MCP) | Improvement |
|--------|----------------|-------------|-------------|
| Steps per commit | 6 steps | 1 step | 83% reduction |
| Time per commit | ~3 minutes | ~30 seconds | 83% faster |
| Error risk | High | Zero | 100% elimination |

**Project savings:** 2.5 min × 50 commits = **2+ hours per development cycle**

### 🔒 Safety Guarantees
✅ Impossible to sync outdated version (auto-pull runs first)  
✅ Private repo remains source of truth (can still edit locally)  
✅ Public repo auto-syncs (Space reads latest version)  
✅ Copyrighted content never reaches GitHub (excluded by Special-Sync)  

### 🧪 Live Proof-of-Concept
**Thread:** 2026-01-16 "MCP Workflow Validation"  
**Test:** ai-context.md v3.6 → v3.7 via MCP commit  
**Result:** ✅ Special-Sync auto-pulled, synced all 4 repos, zero warnings  
**Status:** **PRODUCTION-READY** - use this workflow for all future commits  

---

## 📋 End-of-Thread Summary

Before thread closes, offer:

```markdown
## 📊 Thread Summary

**Problem Solved:** [brief description]

**Key Learnings:**
- [Lesson 1]
- [Lesson 2]

**Files Modified:**
- [file1] - [what changed]
- [file2] - [what changed]

**Next Steps:** [if applicable]

**Should I update ai-context.md with any new information from this thread?**
```

---

## 🚦 Red Flags - When to STOP

If you catch yourself about to:

- 🛑 Propose a regex pattern for GRC **without** `&#160;`
- 🛑 Use `goto` in PowerShell
- 🛑 Ask user to manually browse websites when automation exists
- 🛑 Suggest Whisper path with `.cpp` in folder name
- 🛑 Recommend deleting from Public repo before Private
- 🛑 Provide code without confirming script version first
- 🛑 Tell user to run `git pull` before Special-Sync.ps1 (auto-pull is built-in!)
- 🛑 **Respond without Context Proof of Life verification**

**→ STOP, check `ai-context.md` and COMMON-MISTAKES.md FIRST!**

---

## 🎯 Success Criteria

A successful thread demonstrates:

✅ **Context Proof of Life** provided in first response  
✅ No repeated mistakes from Space history  
✅ All paths verified against `ai-context.md`  
✅ Solutions reference past work when applicable  
✅ User confirms approach before code generation  
✅ Clear acknowledgment if error was repeated  
✅ MCP workflow used when committing files (not manual download/commit)  

---

**Remember:** This checklist exists because we've wasted hours re-solving the same problems. Use it religiously!

**NEW (2026-01-16):** MCP workflow is now the STANDARD for all file commits. Special-Sync auto-pulls, so never tell user to run `git pull` manually!

**NEW (2026-01-18):** **Context Proof of Life protocol is MANDATORY** - AI must prove context loaded in first response or thread stops immediately.