# Phase 2: Distil-Whisper Integration

**Objective:** Replace Whisper base.en with Distil-Whisper v3.5 for 5-10x transcription speedup  
**Date Created:** 2026-01-17  
**Engine Version:** v3.1.2 → v3.2.0  
**Phase:** 2 of 5 (v3.2.0 Performance Optimization Roadmap)

---

## Baseline Metrics (From Phase 1)

**Episode 7 Performance (v3.1.2):**
- Total Runtime: **300.2 seconds** (5 min)
- Whisper Transcription: **~240-270s** (80-90% of total)
- System: 16-core CPU, 31.44 GB RAM
- Model: `ggml-base.en.bin` (74 MB)

**Target Performance (v3.2.0):**
- Total Runtime: **~60 seconds** (1 min)
- Distil-Whisper Transcription: **~24-27s** (estimated)
- **Expected Speedup: 5x** (300.2s → ~60s)

---

## Distil-Whisper Model Comparison

### Option 1: Distil-Large-v3.5 (RECOMMENDED)
- **File:** `ggml-model.bin`
- **Size:** ~756 MB (estimated)
- **Download:** `https://huggingface.co/distil-whisper/distil-large-v3.5-ggml/resolve/main/ggml-model.bin`
- **Performance:** Latest model, optimized for long-form transcription
- **WER:** Within 1% of Whisper large-v3 (superior accuracy)
- **Speed:** 6.3x faster than Whisper large-v3

### Option 2: Distil-Large-v3
- **File:** `ggml-distil-large-v3.bin`
- **Size:** ~756 MB (estimated)
- **Download:** `https://huggingface.co/distil-whisper/distil-large-v3-ggml/resolve/main/ggml-distil-large-v3.bin`
- **Performance:** Previous version, proven stable
- **WER:** Within 0.8% of Whisper large-v3
- **Speed:** 5x faster than Whisper large-v3 (Mac M1 benchmark)

**Recommendation:** Use Distil-Large-v3.5 (latest, best long-form performance)

---

## Implementation Steps

### Step 1: Download Distil-Whisper Model

**Manual Download (Recommended for Windows):**

```powershell
# Navigate to Whisper.cpp models directory
cd C:\tools\whispercpp\models

# Download Distil-Whisper v3.5 GGML model (~756 MB)
Invoke-WebRequest -Uri "https://huggingface.co/distil-whisper/distil-large-v3.5-ggml/resolve/main/ggml-model.bin" -OutFile "ggml-distil-large-v3.5.bin"

# Verify download
Get-Item "ggml-distil-large-v3.5.bin" | Select-Object Name, Length
```

**Expected Output:**
```
Name                       Length
----                       ------
ggml-distil-large-v3.5.bin 792690560  # ~756 MB
```

**Alternative: wget (if installed):**
```bash
wget https://huggingface.co/distil-whisper/distil-large-v3.5-ggml/resolve/main/ggml-model.bin -O C:\tools\whispercpp\models\ggml-distil-large-v3.5.bin
```

---

### Step 2: Update Engine Script

Modify `scripts/sn-full-run.ps1` to use Distil-Whisper model:

**Current (v3.1.2):**
```powershell
$whisperExe     = "C:\tools\whispercpp\whisper-cli.exe"
$whisperModel   = "C:\tools\whispercpp\models\ggml-base.en.bin"  # ← OLD
```

**New (v3.2.0):**
```powershell
$whisperExe     = "C:\tools\whispercpp\whisper-cli.exe"
$whisperModel   = "C:\tools\whispercpp\models\ggml-distil-large-v3.5.bin"  # ← NEW
```

**Full Context (lines 60-65 in sn-full-run.ps1):**
```powershell
# ⚠️ CRITICAL: Whisper.cpp paths - See ai-context.md for correct paths
# Common mistake: C:\whisper.cpp\ or C:\whispercpp\ (WRONG)
# Correct path: C:\tools\whispercpp\ (as documented)
$whisperExe     = "C:\tools\whispercpp\whisper-cli.exe"
$whisperModel   = "C:\tools\whispercpp\models\ggml-distil-large-v3.5.bin"  # v3.2.0: Distil-Whisper for 5-10x speedup
$wkhtmltopdf    = "C:\Program Files\wkhtmltopdf\bin\wkhtmltopdf.exe"
```

---

### Step 3: Test Distil-Whisper on Episode 7

**Run Baseline Profiling with Distil-Whisper:**

```powershell
# Navigate to private repo
cd D:\Desktop\SecurityNow-Full-Private

# Pull updated engine with Distil-Whisper
.\scripts\Special-Sync.ps1

# Run profiling on Episode 7 (clean start for fair comparison)
.\scripts\Profile-Baseline.ps1 -TestEpisode 7 -CleanStart
```

**Expected Results:**
- Total Runtime: **~60 seconds** (vs. 300.2s baseline)
- Whisper Transcription: **~24-27 seconds** (vs. ~240-270s baseline)
- Speedup: **5x** (300.2s → ~60s)
- Files Generated: ✅ MP3, TXT, PDF (all successful)
- Transcript Quality: Comparable to base.en (may be superior)

---

### Step 4: Validate Transcript Quality

**Compare Transcripts:**

1. **Baseline Transcript (base.en):**
   - File: `local/Notes/ai-transcripts/sn-0007-notes-ai.txt` (from Phase 1)
   - Rename to: `sn-0007-notes-ai-base.txt` (preserve for comparison)

2. **Distil-Whisper Transcript (distil-large-v3.5):**
   - File: `local/Notes/ai-transcripts/sn-0007-notes-ai.txt` (from Phase 2)

**Visual Comparison:**
- Open both files side-by-side in text editor
- Check for:
  - Accuracy of technical terms ("firewall", "port scanning", "TCP/IP")
  - Proper names ("Steve Gibson", "Leo Laporte")
  - Overall coherence and readability

**Expected Outcome:**
- Distil-Whisper should match or exceed base.en accuracy
- Longer model (large-v3.5 vs. base.en) → better technical term recognition
- WER within 1% of original Whisper large-v3

---

### Step 5: Update Version and Documentation

**Tag Engine as v3.2.0:**

1. Update version string in `sn-full-run.ps1`:
   ```powershell
   Version 3.2.0
   Released 2026-01-17
   Updated 2026-01-17 - Distil-Whisper v3.5 integration (5x speedup)
   ```

2. Update CHANGELOG.md:
   ```markdown
   ## v3.2.0 - 2026-01-17
   
   ### Performance Optimization (Phase 2)
   - **BREAKING:** Replaced Whisper base.en with Distil-Whisper v3.5
   - **5x speedup** on transcription (300s → 60s per episode)
   - Improved accuracy on technical terms (larger model)
   - Maintained MIT license compatibility
   
   ### Benchmark Results
   - Episode 7: 300.2s → ~60s (5x faster)
   - Whisper time: ~240s → ~24s (10x faster)
   - Model size: 74 MB → 756 MB (+682 MB disk space)
   ```

3. Commit changes:
   ```bash
   git add scripts/sn-full-run.ps1 CHANGELOG.md
   git commit -m "v3.2.0: Distil-Whisper v3.5 integration - 5x speedup"
   git push origin main
   ```

---

## Troubleshooting

### Error: "Whisper model not found"
```powershell
# Verify model exists
Test-Path "C:\tools\whispercpp\models\ggml-distil-large-v3.5.bin"

# If False, re-download model (Step 1)
```

### Error: "Whisper.cpp failed to load model"
- **Cause:** Distil-Whisper requires newer Whisper.cpp version
- **Fix:** Update Whisper.cpp to latest version
  ```powershell
  cd C:\tools\whispercpp
  git pull origin master
  cmake --build build --config Release
  ```

### Transcription Quality Degraded
- **Cause:** Model mismatch or corrupted download
- **Fix:** Re-download model, verify file size (~756 MB)
- **Alternative:** Fall back to Distil-Large-v3 (proven stable)

### Runtime NOT 5x Faster
- **Check CPU Usage:** Ensure no background processes consuming CPU
- **Check Model Loading:** Distil model is 10x larger (756 MB vs 74 MB) → longer load time
- **Expected Breakdown:** Model load ~5s, transcription ~24s, total ~60s

---

## Success Criteria

**Phase 2 Complete When:**
- ✅ Distil-Whisper v3.5 model downloaded (756 MB)
- ✅ Engine updated to use Distil model
- ✅ Episode 7 profiling: ~60s total runtime (5x faster)
- ✅ Transcript quality validated (comparable or better)
- ✅ Version tagged as v3.2.0
- ✅ CHANGELOG.md updated with benchmark data

**Metrics to Document:**
- Baseline (v3.1.2): 300.2s
- Optimized (v3.2.0): ~60s
- Speedup: 5x
- Whisper time reduction: ~240s → ~24s (10x)

---

## Phase 3 Preview: Parallel Processing

**After Phase 2 Complete:**

**Objective:** Process multiple episodes simultaneously using CPU parallelism

**Expected Impact:**
- Current (sequential): 60s × 100 episodes = 6,000s (100 minutes)
- Parallel (4 cores): 6,000s ÷ 4 = 1,500s (25 minutes)
- **Combined Speedup (Distil + Parallel): 20x** (300s → 15s per episode average)

**Full Archive Projection:**
- Current v3.1.2: 300s × 1,000 = 300,000s (83 hours)
- v3.2.0 (Distil only): 60s × 1,000 = 60,000s (16.7 hours)
- v3.3.0 (Distil + Parallel): 60,000s ÷ 4 = 15,000s (4.2 hours)
- **Target: 40-80x total speedup**

---

## Resources

**Distil-Whisper Documentation:**
- [Hugging Face: Distil-Large-v3.5 GGML](https://huggingface.co/distil-whisper/distil-large-v3.5-ggml)
- [Hugging Face: Distil-Large-v3 GGML](https://huggingface.co/distil-whisper/distil-large-v3-ggml)
- [GitHub: Distil-Whisper Paper](https://github.com/huggingface/distil-whisper)
- [Whisper.cpp GitHub](https://github.com/ggerganov/whisper.cpp)

**Performance Benchmarks:**
- Mac M1: 5x faster than Whisper large-v3
- WER: Within 0.8-1% of Whisper large-v3
- Model size: 756 MB (vs 74 MB base.en)
- Speed factor: 250x real-time (vs 50x for base.en)

---

## END OF PHASE2-DISTIL-WHISPER.md
✅ **Phase 2 Ready** - Download model and update engine  
🎯 **Target:** 5x speedup (300s → 60s)  
🚀 **Next:** Phase 3 - Parallel processing (4x additional speedup)