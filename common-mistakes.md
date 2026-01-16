# Common Mistakes Reference
**Quick-lookup guide to prevent repeating past errors**

---

## 🔥 Critical Mistakes (Repeated 3+ Times)

### 1. GRC Regex Pattern Hell

**❌ WRONG (Failed 4+ times in one session):**
```regex
Episode\s*(\d+)                    # Missing HTML entity
Episode\s*\|\s*(\d+)              # Wrong separator (pipe)
Episode.*?(\d+)                    # Too greedy
```

**✅ CORRECT (Tested on 1000+ episodes):**
```regex
Episode\s*&#160;(\d{1,4})&#160;(\d{1,2})
```

**Why it fails:**
- GRC uses `&#160;` (non-breaking space HTML entity), NOT regular spaces
- The `|` pipe character doesn't exist in the HTML
- Tested successfully: Episodes 1, 436, 1000, 1059, 20

**Where to use:**
- Parsing `https://www.grc.com/securitynow.htm`
- Parsing `https://www.grc.com/sn/past/YYYY.htm` pages

---

### 2. Whisper.cpp Path Confusion

**❌ WRONG:**
```powershell
$WhisperExe = "C:\Tools\whisper.cpp\whisper-cli.exe"  # DOT in folder name
$WhisperModel = "C:\Tools\whispercpp\ggml-base.en.bin" # Model in root
```

**✅ CORRECT:**
```powershell
$WhisperExe = "C:\Tools\whispercpp\whisper-cli.exe"
$WhisperModel = "C:\Tools\whispercpp\models\ggml-base.en.bin"
```

**Why it fails:**
- Folder is `whispercpp\` (NO dot between whisper and cpp)
- Model file is in `models\` subfolder, NOT in root
- Case-sensitive on some systems

**How to verify:**
```powershell
Test-Path "C:\Tools\whispercpp\whisper-cli.exe"
Test-Path "C:\Tools\whispercpp\models\ggml-base.en.bin"
```

---

### 3. Script Version Confusion

**❌ PROBLEM:**
- User asks about `sn-full-run.ps1`
- AI proposes changes to `SecurityNow-EndToEnd.ps1`
- Or AI updates `sn-full-run-v3.ps1` instead of production

**✅ SOLUTION:**
**ALWAYS confirm first:**
```markdown
Quick confirm: Which script file are you currently using?
- [ ] sn-full-run.ps1 (production)
- [ ] sn-full-run-v3.ps1 (testing)
- [ ] SecurityNow-EndToEnd.ps1 (deprecated?)
```

**Production script location:**
```
D:\Desktop\SecurityNow-Full-Private\scripts\sn-full-run.ps1
```

---

### 4. PowerShell `Test-Path -and` Syntax Error

**❌ WRONG:**
```powershell
if Test-Path $mp3File -and -not Test-Path $txtFile {
    # Code here
}
```

**Error:**
```
A parameter cannot be found that matches parameter name 'and'.
```

**✅ CORRECT:**
```powershell
if (Test-Path $mp3File) -and (-not (Test-Path $txtFile)) {
    # Code here
}
```

**Why:** PowerShell interprets `-and` as a parameter to `Test-Path` without parentheses.

---

### 5. Python vs PowerShell Confusion

**❌ USER TYPES:**
```bash
python sn-full-run.ps1
```

**Error:**
```
SyntaxError: unterminated string literal
```

**✅ IMMEDIATE CORRECTION:**
```markdown
⚠️ This is a PowerShell script, not Python.

Run it with:
```powershell
cd D:\Desktop\SecurityNow-Full-Private\scripts
.\sn-full-run.ps1 -DryRun
```
```

---

## ⚠️ Moderate Mistakes (Repeated 2+ Times)

### 6. wkhtmltopdf Missing Flag

**❌ WRONG (silent failure):**
```powershell
& $wkhtmlPath --headless --disable-gpu --print-to-pdf="$output" "$input"
```

**✅ CORRECT:**
```powershell
& $wkhtmlPath `
  --enable-local-file-access `  # MANDATORY!
  --headless --disable-gpu `
  --print-to-pdf="$output" "$input"
```

**Why:** Modern security restrictions require explicit `--enable-local-file-access` flag.

---

### 7. Git Sync Workflow Violation

**❌ WRONG ORDER:**
1. Delete file from Public repo
2. Run `Sync-Repos.ps1`
3. File gets restored (infinite loop!)

**✅ CORRECT ORDER:**
1. Delete from **Private repo FIRST**
2. Commit & push Private
3. **THEN** run `Sync-Repos.ps1`
4. Deletion propagates to Public

**Rule:** Private repo is SOURCE OF TRUTH for sync operations.

---

### 8. Episode Year Hardcoding

**❌ WRONG (fails at year boundaries):**
```powershell
function Get-EpisodeYear {
    param($Episode)
    if ($Episode -le 20) { return 2005 }
    elseif ($Episode -le 72) { return 2006 }
    # ...
}
```

**Problem:** Episode 436 (Dec 27, 2012) gets placed in 2013 folder!

**✅ CORRECT:** Use `episode-dates.csv` with actual recording dates
```powershell
$entry = $global:EpisodeDateIndex | Where-Object { [int]$_.Episode -eq $Episode }
if ($entry) { return [int]$entry.Year }
```

---

### 9. D:\ Root File Constraint Violation

**❌ WRONG:**
```powershell
$testFile = "D:\test-data.csv"  # File directly in D:\ root!
```

**✅ CORRECT:**
```powershell
$testFile = "D:\SecurityNow-Test\test-data.csv"  # Inside folder
```

**Rule:** NO FILES at `D:\` root - only folders allowed!

---

### 10. "Wheel Re-Invention" (Manual Work)

**❌ WRONG APPROACH:**
```markdown
Please manually visit each episode page and copy the PDF URLs.
```

**User Response:**
> "Stop re-inventing the same wheel. You have all the data!"

**✅ CORRECT:**
**ALWAYS check Space files first** - we likely already automated this!

```markdown
Let me search Space files for existing URL discovery code...
[Search results show we already have this in sn-full-run.ps1]
```

---

## 🛠️ How to Use This Guide

### Before Proposing Code:
1. 🔍 Search this file for relevant keywords
2. ✅ Verify your approach isn't listed as "❌ WRONG"
3. 📝 Use the "✅ CORRECT" pattern instead

### When User Reports Error:
1. 🔍 Search this file for the error message
2. 📚 Check if it matches a known mistake
3. 🎯 Reference the documented solution

### After Solving New Issue:
1. 📝 Document it here if it took >2 attempts
2. 💾 Commit update to GitHub
3. 🔄 Update `.ai-context.md` if it's a critical pattern

---

## 📊 Mistake Frequency Tracker

| Mistake | Times Repeated | Last Occurrence | Status |
|---------|---------------|-----------------|--------|
| GRC Regex Pattern | 4+ | 2026-01-13 | 🔴 Critical |
| Whisper Path | 3+ | 2026-01-13 | 🔴 Critical |
| Script Version | 3+ | 2026-01-13 | 🟡 Moderate |
| Test-Path -and | 2 | 2026-01-12 | 🟢 Resolved |
| Python/PowerShell | 1 | 2026-01-12 | 🟢 Resolved |

---

**Last Updated:** 2026-01-15  
**Add new mistakes here as they're discovered!**
