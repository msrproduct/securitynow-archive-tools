# Performance Baseline - v3.1.2

**Purpose:** Establish reproducible baseline metrics before v3.2.0 performance optimizations  
**Date Created:** 2026-01-17  
**Engine Version:** v3.1.2  
**Phase:** 1 of 5 (v3.2.0 Performance Optimization Roadmap)

---

## Quick Start

```powershell
# Navigate to private repo
cd D:\Desktop\SecurityNow-Full-Private

# Pull latest changes (includes Profile-Baseline.ps1)
.\scripts\Special-Sync.ps1

# Run baseline profiling on Episode 7 (historical baseline)
.\scripts\Profile-Baseline.ps1 -TestEpisode 7 -CleanStart
```

**Expected Output:**
- Total runtime measurement
- File generation validation (MP3, transcript, PDF)
- Comparison to historical baseline (158s for Episode 7)
- Metrics saved to `baseline-metrics.csv`
- AI PDF opens automatically for visual verification

---

## Historical Baseline Reference

**Episode 7 Test (Historical):**
- **Total Runtime:** 158 seconds (2 min 38 sec)
- **Bottleneck:** Whisper.cpp transcription (81.3% of runtime)
- **Hardware:** [System specs from historical test]
- **Date:** [Date of historical test]

**Breakdown Estimate:**
- GRC metadata fetch: ~3s (2%)
- MP3 download: ~18s (11%)
- **Whisper transcription: ~129s (81%)** ← PRIMARY OPTIMIZATION TARGET
- HTML generation: ~1s (1%)
- wkhtmltopdf PDF conversion: ~7s (4%)

---

## What Profile-Baseline.ps1 Measures

### Execution Metrics
- Total runtime (seconds)
- Success/failure status
- Error count

### File Generation Validation
- MP3 downloaded (yes/no + size in MB)
- Transcript generated (yes/no + size in KB)
- PDF created (yes/no + size in MB)

### System Configuration (for reproducibility)
- Operating system
- PowerShell version
- CPU core count
- Total RAM (GB)
- Timestamp

### Output Files
- **baseline-metrics.csv:** Timestamped performance data
- **Console output:** Real-time profiling status
- **Auto-opened PDF:** Visual verification of AI disclaimer banner

---

## Baseline Comparison Logic

**Tolerance:** ±10% variance from historical baseline  
**Rationale:** Network speed, CPU load, and system differences cause natural variance

**Example:**
```
Historical Baseline (Episode 7): 158.0 s
Current Run: 156.3 s
Delta: -1.7 s (-1.1%)
Status: ✅ WITHIN TOLERANCE (±10%)
```

**If Outside Tolerance:**
- ⚠️ Check network speed (MP3 download from TWiT CDN)
- ⚠️ Check CPU usage (other processes running?)
- ⚠️ Verify Whisper.cpp model loaded correctly
- ⚠️ Review error log for failures

---

## Phase 1 Checklist

- [ ] Run `Profile-Baseline.ps1 -TestEpisode 7 -CleanStart`
- [ ] Verify total runtime within ±10% of 158s
- [ ] Confirm MP3, transcript, and PDF generated successfully
- [ ] Verify AI PDF has red disclaimer banner (auto-opened)
- [ ] Review `baseline-metrics.csv` for data completeness
- [ ] Document any errors in error-log.csv

**Success Criteria:**
- Script completes without errors
- All three files generated (MP3, TXT, PDF)
- Runtime within expected range
- Metrics CSV contains complete system info

---

## Identified Bottleneck (Expected)

**Whisper.cpp Transcription: 80-90% of total runtime**

This validates the v3.2.0 optimization priority:

1. **Distil-Whisper Integration** (Phase 2 - Tier 1)
   - Target: 10x speedup on transcription
   - Expected impact: 129s → 13s (116s saved)
   - New total runtime: ~42s (3.8x faster)

2. **Parallel CPU Processing** (Phase 2 - Tier 1)
   - Target: 4x speedup on multi-episode batches
   - Combined with Distil-Whisper: ~40x total speedup

3. **Intelligent Caching** (Phase 2 - Tier 1)
   - Skip re-processing unchanged episodes
   - Infinite speedup on re-runs

**Phase 2 Goal:** Reduce full archive processing from 500-1,000 hours to 5-15 hours

---

## Next Steps After Phase 1

**Phase 2: Tier 1 Optimizations (Free Performance Gains)**
1. Distil-Whisper integration (10x transcription speedup)
2. Parallel processing (4x multi-episode speedup)
3. Intelligent caching (skip unchanged episodes)
4. Parallel downloads (2x network I/O speedup)

**Expected Combined Result:** 40-80x speedup with zero hardware investment

**Phase 3: Validation Testing**
- Run 100-episode test suite
- Verify quality maintained across optimizations
- Update performance documentation

**Phase 4: Tag v3.2.0 Release**
- Update CHANGELOG.md with before/after benchmarks
- Document optimization techniques
- Freeze engine API for downstream features

**Phase 5: Optional Tier 2 (Hardware Acceleration)**
- GPU acceleration cost-benefit analysis
- CUDA/TensorRT for Whisper inference
- Only if Tier 1 doesn't hit 40x target

---

## Metrics CSV Schema

```csv
Timestamp,Episode,TotalRuntimeSeconds,MP3Downloaded,MP3SizeMB,TranscriptGenerated,TranscriptSizeKB,PDFCreated,PDFSizeMB,ErrorCount,OS,PowerShellVersion,CPUCores,TotalMemoryGB
2026-01-17 18:30:00,7,158.2,True,45.2,True,38.4,True,1.8,0,Windows 10,7.4.1,8,16.0
```

**Usage:**
- Track performance over time
- Compare different hardware configurations
- Validate optimization improvements
- Regression testing after code changes

---

## Troubleshooting

### Error: "Whisper.cpp not found"
```powershell
# Verify Whisper path
Test-Path "C:\whisper.cpp\whisper-cli.exe"

# If False, check ai-context.md for correct path
# Current expected path: C:\tools\whispercpp\whisper-cli.exe
```

### Error: "wkhtmltopdf not found"
```powershell
# Verify wkhtmltopdf path
Test-Path "C:\Program Files\wkhtmltopdf\bin\wkhtmltopdf.exe"

# Script will generate transcript TXT only (skip PDF) if missing
```

### Runtime significantly higher than baseline
- Check network speed: TWiT CDN download may be slow
- Check CPU usage: Close other applications
- Run again with `-CleanStart` to eliminate cached data effects

### MP3/Transcript/PDF not generated
- Check error-log.csv for specific failure stage
- Review console output for "ERROR" messages
- Verify disk space available (MP3 ~45MB per episode)

---

## END OF PERFORMANCE-BASELINE.md
✅ **Phase 1 Complete** - Ready to measure v3.1.2 baseline  
📈 **Target:** 40-80x speedup via Tier 1 optimizations  
🎯 **Next:** Distil-Whisper integration (10x transcription speedup)