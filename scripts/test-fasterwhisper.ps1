<#
.SYNOPSIS
    Phase 1 Faster-Whisper Performance Test
.DESCRIPTION
    Tests faster-whisper library on Episode 7 to validate claimed 5-10× speedup
    vs baseline Whisper.cpp (300s baseline from 2026-01-17 profiling).
.PARAMETER EpisodeNum
    Episode number to test (default: 7)
.PARAMETER CleanStart
    Delete existing transcript before testing
.EXAMPLE
    .\Test-FasterWhisper.ps1 -EpisodeNum 7 -CleanStart
#>

param(
    [int]$EpisodeNum = 7,
    [switch]$CleanStart
)

$ErrorActionPreference = "Stop"

# Paths
$baseDir = "D:\Desktop\SecurityNow-Full-Private"
$mp3Dir = Join-Path $baseDir "local\mp3"
$transcriptDir = Join-Path $baseDir "local\Notes-ai-transcripts"
$episodeStr = "sn-{0:d4}" -f $EpisodeNum

$mp3Path = Join-Path $mp3Dir "$episodeStr.mp3"
$baselineTranscript = Join-Path $transcriptDir "$episodeStr-notes-ai.txt"
$fasterTranscript = Join-Path $transcriptDir "$episodeStr-notes-ai-FASTER.txt"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Phase 1: Faster-Whisper Performance Test" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "Test Configuration:" -ForegroundColor Yellow
Write-Host "  Episode:        $EpisodeNum"
Write-Host "  MP3:            $mp3Path"
Write-Host "  Baseline ref:   300s (from 2026-01-17 profiling)"
Write-Host "  Expected:       38-60s (5-8× speedup)`n"

# Check MP3 exists
if (-not (Test-Path $mp3Path)) {
    Write-Host "ERROR: MP3 not found at $mp3Path" -ForegroundColor Red
    Write-Host "Run sn-full-run.ps1 first to download Episode $EpisodeNum" -ForegroundColor Yellow
    exit 1
}

$mp3Size = (Get-Item $mp3Path).Length / 1MB
Write-Host "MP3 File: $([math]::Round($mp3Size, 1)) MB`n" -ForegroundColor Green

# Clean start if requested
if ($CleanStart -and (Test-Path $fasterTranscript)) {
    Write-Host "Cleaning previous Faster-Whisper transcript..." -ForegroundColor Yellow
    Remove-Item $fasterTranscript -Force
}

# Step 1: Check if faster-whisper is installed
Write-Host "[Step 1/4] Checking faster-whisper installation..." -ForegroundColor Cyan

try {
    $checkInstall = python -c "import faster_whisper; print(faster_whisper.__version__)" 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ faster-whisper already installed (v$checkInstall)" -ForegroundColor Green
    } else {
        throw "Not installed"
    }
} catch {
    Write-Host "  ⚠ faster-whisper not found, installing..." -ForegroundColor Yellow
    Write-Host "  This may take 2-5 minutes..." -ForegroundColor Gray
    
    $installStart = Get-Date
    pip install faster-whisper --quiet
    $installTime = [math]::Round(((Get-Date) - $installStart).TotalSeconds, 1)
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "`nERROR: Failed to install faster-whisper" -ForegroundColor Red
        Write-Host "Run manually: pip install faster-whisper" -ForegroundColor Yellow
        exit 1
    }
    
    Write-Host "  ✓ Installed in $installTime seconds" -ForegroundColor Green
}

# Step 2: Run Faster-Whisper transcription
Write-Host "`n[Step 2/4] Transcribing Episode $EpisodeNum with Faster-Whisper..." -ForegroundColor Cyan
Write-Host "  Model: base.en (int8 quantization)" -ForegroundColor Gray
Write-Host "  Device: CPU (i7-1270P)" -ForegroundColor Gray
Write-Host "  Starting transcription...`n" -ForegroundColor Gray

$transcriptStart = Get-Date

# Python script embedded in PowerShell
$pythonScript = @"
from faster_whisper import WhisperModel
import sys

# Initialize model (first run downloads ~150MB base.en model)
print('Loading model...', file=sys.stderr)
model = WhisperModel('base.en', device='cpu', compute_type='int8')

# Transcribe
print('Transcribing audio...', file=sys.stderr)
mp3_path = r'$($mp3Path -replace "'", "''")'
segments, info = model.transcribe(mp3_path, language='en')

# Write output
output_path = r'$($fasterTranscript -replace "'", "''")'
with open(output_path, 'w', encoding='utf-8') as f:
    for segment in segments:
        f.write(segment.text + ' ')

print(f'Done! Language: {info.language}, Duration: {info.duration:.1f}s', file=sys.stderr)
"@

try {
    # Run Python script and capture stderr for progress
    $pythonScript | python 2>&1 | ForEach-Object {
        if ($_ -match "Loading model|Transcribing|Done") {
            Write-Host "  $_" -ForegroundColor Gray
        }
    }
    
    if ($LASTEXITCODE -ne 0) {
        throw "Python script failed"
    }
    
} catch {
    Write-Host "`nERROR: Transcription failed" -ForegroundColor Red
    Write-Host "Error details: $_" -ForegroundColor Yellow
    exit 1
}

$transcriptTime = [math]::Round(((Get-Date) - $transcriptStart).TotalSeconds, 1)

# Step 3: Performance Analysis
Write-Host "`n[Step 3/4] Performance Results" -ForegroundColor Cyan
Write-Host ("  {0,-25} {1,10}" -f "Baseline (Whisper.cpp):", "300.0s") -ForegroundColor Yellow
Write-Host ("  {0,-25} {1,10}" -f "Faster-Whisper (actual):", "$($transcriptTime)s") -ForegroundColor Green

$speedup = [math]::Round(300.0 / $transcriptTime, 1)
$speedupColor = if ($speedup -ge 5) { "Green" } elseif ($speedup -ge 2) { "Yellow" } else { "Red" }

Write-Host ("  {0,-25} {1,9}×" -f "Speedup:", $speedup) -ForegroundColor $speedupColor

if ($speedup -ge 5) {
    Write-Host "`n  ✓ SUCCESS: Meets 5× speedup target!" -ForegroundColor Green
} elseif ($speedup -ge 2) {
    Write-Host "`n  ⚠ PARTIAL: 2-5× speedup (consider combining with medium.en model)" -ForegroundColor Yellow
} else {
    Write-Host "`n  ✗ FAILED: <2× speedup (not worth the complexity)" -ForegroundColor Red
}

# Step 4: Quality Validation
Write-Host "`n[Step 4/4] Quality Validation" -ForegroundColor Cyan

if (Test-Path $baselineTranscript) {
    Write-Host "  Comparing against baseline transcript..." -ForegroundColor Gray
    
    $baseline = Get-Content $baselineTranscript -Raw
    $faster = Get-Content $fasterTranscript -Raw
    
    $baselineWords = $baseline -split '\s+' | Where-Object { $_ }
    $fasterWords = $faster -split '\s+' | Where-Object { $_ }
    
    $wordCountDiff = [math]::Abs($baselineWords.Count - $fasterWords.Count)
    $wordCountPct = [math]::Round(($wordCountDiff / $baselineWords.Count) * 100, 1)
    
    Write-Host ("  Baseline word count:  {0,6}" -f $baselineWords.Count) -ForegroundColor Gray
    Write-Host ("  Faster word count:    {0,6}" -f $fasterWords.Count) -ForegroundColor Gray
    Write-Host ("  Difference:           {0,5} words ({1}%)" -f $wordCountDiff, $wordCountPct) -ForegroundColor $(if ($wordCountPct -lt 5) { "Green" } else { "Yellow" })
    
    if ($wordCountPct -lt 5) {
        Write-Host "`n  ✓ Quality looks good (word count within 5%)" -ForegroundColor Green
    } else {
        Write-Host "`n  ⚠ Significant word count difference - manual review recommended" -ForegroundColor Yellow
    }
    
    Write-Host "`n  Manual quality check:" -ForegroundColor Yellow
    Write-Host "    notepad `"$baselineTranscript`"" -ForegroundColor Gray
    Write-Host "    notepad `"$fasterTranscript`"" -ForegroundColor Gray
    
} else {
    Write-Host "  ⚠ No baseline transcript found - cannot compare quality" -ForegroundColor Yellow
    Write-Host "  Faster-Whisper transcript: $fasterTranscript" -ForegroundColor Gray
}

# Final Summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "PHASE 1 TEST COMPLETE" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$decision = if ($speedup -ge 5) {
    "✓ PROCEED TO PHASE 2A - Integrate Faster-Whisper into sn-full-run.ps1"
} elseif ($speedup -ge 2) {
    "⚠ PARTIAL SUCCESS - Consider Phase 2B (medium.en model) instead"
} else {
    "✗ ABORT - Faster-Whisper not worth complexity, go to Phase 2B"
}

Write-Host "Decision: $decision" -ForegroundColor $(if ($speedup -ge 5) { "Green" } elseif ($speedup -ge 2) { "Yellow" } else { "Red" })

Write-Host "`nNext steps:" -ForegroundColor Yellow
if ($speedup -ge 5) {
    Write-Host "  1. Review transcript quality (see paths above)"
    Write-Host "  2. If quality is good, proceed to Phase 2A integration"
    Write-Host "  3. Paste these results in the chat for Phase 2A code generation"
} else {
    Write-Host "  1. Paste these results in the chat"
    Write-Host "  2. We'll proceed with Phase 2B (medium.en model test)"
}

Write-Host ""
