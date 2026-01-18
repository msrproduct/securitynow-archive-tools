<#
.SYNOPSIS
    Phase 2B: Test medium.en model performance vs base.en baseline.

.DESCRIPTION
    Compares medium.en transcription speed and quality against base.en baseline from Phase 1.
    Tests single-episode performance to project total speedup with 4x parallel processing.

.PARAMETER EpisodeNum
    Episode number to test (default 7, from Phase 1 baseline).

.PARAMETER CleanStart
    If specified, deletes existing transcript/MP3 to force fresh download/transcription.

.NOTES
    Version: 1.0.2
    Prerequisite: Run Test-BaselineProfile.ps1 first to establish 300s baseline.
    
    Expected Results:
    - medium.en model: ~150s (2x speedup vs base.en)
    - Projected with 4x parallel: 8x total speedup = 10.5 hours for full archive
#>

[CmdletBinding()]
param(
    [Parameter()][int]$EpisodeNum = 7,
    [Parameter()][switch]$CleanStart
)

#=================================
# CONFIGURATION
#=================================

# Repository paths (auto-detect)
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptDir
$Mp3Folder = Join-Path $RepoRoot "local\mp3"
$TranscriptsFolder = Join-Path $RepoRoot "local\transcripts"
$PdfFolder = Join-Path $RepoRoot "local\pdf"

# Whisper.cpp paths (verified from ai-context.md v3.12)
$WhisperExe    = "C:\tools\whispercpp\whisper-cli.exe"
$BaseModel     = "C:\tools\whispercpp\models\ggml-base.en.bin"
$MediumModel   = "C:\tools\whispercpp\models\ggml-medium.en.bin"

# Performance baseline from Phase 1
$BaselineSeconds = 300  # base.en model baseline (Episode 7, 2026-01-17)

#=================================
# HELPER FUNCTIONS
#=================================

function Write-Header($Text) {
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host $Text -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan
}

function Write-Section($Text) {
    Write-Host "`n## $Text" -ForegroundColor Yellow
}

#=================================
# MAIN SCRIPT
#=================================

Write-Header "Phase 2B: medium.en Model Performance Test"

# Display test configuration
Write-Host "Test Configuration:" -ForegroundColor White
Write-Host "  Episode:        $EpisodeNum"
Write-Host "  MP3:            $Mp3Folder"
Write-Host "  Baseline ref:   ${BaselineSeconds}s (base.en, from 2026-01-17 profiling)"
Write-Host "  Expected:       150s (2x speedup with medium.en)"
Write-Host ""

#=================================
# Step 1: Validate Environment
#=================================

Write-Section "Step 1: Validate Environment"

# Check Whisper.cpp
if (-not (Test-Path $WhisperExe)) {
    Write-Host "ERROR: Whisper.cpp not found at $WhisperExe" -ForegroundColor Red
    Write-Host "Install Whisper.cpp first: .\scripts\Install-Whisper.ps1" -ForegroundColor Yellow
    exit 1
}
Write-Host "✓ Whisper.cpp found: $WhisperExe" -ForegroundColor Green

# Check base model (for reference)
if (-not (Test-Path $BaseModel)) {
    Write-Host "ERROR: Base model not found at $BaseModel" -ForegroundColor Red
    exit 1
}
Write-Host "✓ Base model found: $BaseModel" -ForegroundColor Green

# Check/download medium.en model
if (-not (Test-Path $MediumModel)) {
    Write-Host "⚠ Medium model not found at $MediumModel" -ForegroundColor Yellow
    
    $modelDir = Split-Path -Parent $MediumModel
    $downloadUrl = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-medium.en.bin"
    
    Write-Host "  Download URL: $downloadUrl" -ForegroundColor Gray
    
    try {
        Invoke-WebRequest -Uri $downloadUrl -OutFile $MediumModel -UseBasicParsing
        
        if (Test-Path $MediumModel) {
            $sizeMB = [Math]::Round((Get-Item $MediumModel).Length / 1MB, 1)
            Write-Host "✓ Downloaded: $MediumModel ($sizeMB MB)" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "ERROR: Failed to download medium.en model: $_" -ForegroundColor Red
        exit 1
    }
}
else {
    $sizeMB = [Math]::Round((Get-Item $MediumModel).Length / 1MB, 1)
    Write-Host "✓ Medium model found: $MediumModel ($sizeMB MB)" -ForegroundColor Green
}

#=================================
# Step 2: Prepare Episode 7 Files
#=================================

Write-Section "Step 2: Prepare Episode 7 Files"

$mp3File = Join-Path $Mp3Folder "sn-$($EpisodeNum.ToString('0000')).mp3"
$txtFile = Join-Path $TranscriptsFolder "sn-$($EpisodeNum.ToString('0000'))-notes-ai.txt"

# Clean start if requested
if ($CleanStart) {
    Write-Host "Cleaning previous Episode $EpisodeNum files..." -ForegroundColor Gray
    
    if (Test-Path $mp3File) {
        Remove-Item $mp3File -Force
        Write-Host "  Deleted: $mp3File" -ForegroundColor Gray
    }
    if (Test-Path $txtFile) {
        Remove-Item $txtFile -Force
        Write-Host "  Deleted: $txtFile" -ForegroundColor Gray
    }
    
    $pdfPattern = Join-Path $PdfFolder "*\sn-$($EpisodeNum.ToString('0000'))-notes-ai.pdf"
    Get-ChildItem $pdfPattern -ErrorAction SilentlyContinue | Remove-Item -Force
    
    Write-Host "✓ Clean start ready" -ForegroundColor Green
}

# Download MP3 if needed
if (-not (Test-Path $mp3File)) {
    $mp3Url = "https://cdn.twit.tv/audio/sn/sn$($EpisodeNum.ToString('0000'))/sn$($EpisodeNum.ToString('0000')).mp3"
    
    Write-Host "Downloading MP3 from TWiT CDN..." -ForegroundColor Gray
    Write-Host "  $mp3Url" -ForegroundColor DarkGray
    
    try {
        Invoke-WebRequest -Uri $mp3Url -OutFile $mp3File -UseBasicParsing
        $mp3SizeMB = [Math]::Round((Get-Item $mp3File).Length / 1MB, 1)
        Write-Host "✓ MP3 File: $mp3SizeMB MB" -ForegroundColor Green
    }
    catch {
        Write-Host "ERROR: Failed to download MP3: $_" -ForegroundColor Red
        exit 1
    }
}
else {
    $mp3SizeMB = [Math]::Round((Get-Item $mp3File).Length / 1MB, 1)
    Write-Host "✓ MP3 File: $mp3SizeMB MB (already exists)" -ForegroundColor Gray
}

#=================================
# Step 3: Run medium.en Transcription (TIMED)
#=================================

Write-Section "Step 3: Transcription with medium.en Model"

Write-Host "Command: " -ForegroundColor Gray
Write-Host "  $WhisperExe -m $MediumModel -f `"$mp3File`" -otxt -of `"$($TranscriptsFolder)\sn-$($EpisodeNum.ToString('0000'))-notes-ai`"" -ForegroundColor DarkGray
Write-Host ""

$startTime = Get-Date

# Run Whisper.cpp with medium.en model
& $WhisperExe -m $MediumModel -f $mp3File -otxt -of "$TranscriptsFolder\sn-$($EpisodeNum.ToString('0000'))-notes-ai" 2>&1 | Out-Host

$endTime = Get-Date
$elapsedSeconds = [Math]::Round(($endTime - $startTime).TotalSeconds, 1)

if (-not (Test-Path $txtFile)) {
    Write-Host "ERROR: Transcription failed - output file not created" -ForegroundColor Red
    exit 1
}

$wordCount = (Get-Content $txtFile -Raw).Split(" `n`r`t".ToCharArray(), [StringSplitOptions]::RemoveEmptyEntries).Count

Write-Host ""
Write-Host "✓ Transcription Complete" -ForegroundColor Green
Write-Host "  Time:       ${elapsedSeconds}s" -ForegroundColor White
Write-Host "  Output:     $txtFile" -ForegroundColor Gray
Write-Host "  Word Count: $wordCount" -ForegroundColor Gray

#=================================
# Step 4: Performance Analysis
#=================================

Write-Section "Step 4: Performance Analysis"

$speedup = [Math]::Round($BaselineSeconds / $elapsedSeconds, 2)
$projectedParallelSpeedup = $speedup * 4  # 4x parallel processing
$fullArchiveHours = [Math]::Round(1060 * $BaselineSeconds / $projectedParallelSpeedup / 3600, 1)

Write-Host "Baseline (base.en):        ${BaselineSeconds}s" -ForegroundColor White
Write-Host "Medium.en (this run):      ${elapsedSeconds}s" -ForegroundColor White
Write-Host ""
Write-Host "Single Model Speedup:      ${speedup}x" -ForegroundColor $(if ($speedup -ge 1.8) { "Green" } else { "Yellow" })
Write-Host "Projected with 4x Parallel: ${projectedParallelSpeedup}x total" -ForegroundColor Cyan
Write-Host "Full Archive (1060 eps):   $fullArchiveHours hours" -ForegroundColor Cyan
Write-Host ""

#=================================
# Step 5: Quality Validation
#=================================

Write-Section "Step 5: Quality Validation"

Write-Host "Spot-checking transcript quality..." -ForegroundColor Gray
$transcriptText = Get-Content $txtFile -Raw

# Check for common Security Now technical terms
$technicalTerms = @("Steve", "Leo", "Security", "encryption", "firewall", "router", "TCP", "IP", "DNS", "SSL", "TLS", "VPN", "malware", "virus", "spyware", "CVE")
$foundTerms = $technicalTerms | Where-Object { $transcriptText -match $_ }

Write-Host "  Technical terms detected: $($foundTerms.Count)/$($technicalTerms.Count)" -ForegroundColor $(if ($foundTerms.Count -ge 10) { "Green" } else { "Yellow" })
Write-Host "  Sample: $($foundTerms[0..4] -join ', ')" -ForegroundColor Gray
Write-Host ""

#=================================
# SUMMARY
#=================================

Write-Header "Phase 2B Results Summary"

Write-Host "Episode $EpisodeNum Performance:" -ForegroundColor White
Write-Host "  Baseline (base.en):  ${BaselineSeconds}s" 
Write-Host "  Medium.en:           ${elapsedSeconds}s" -ForegroundColor $(if ($speedup -ge 1.8) { "Green" } else { "Yellow" })
Write-Host "  Speedup:             ${speedup}x" -ForegroundColor $(if ($speedup -ge 1.8) { "Green" } else { "Yellow" })
Write-Host ""

Write-Host "Projected Full Archive:" -ForegroundColor White
Write-Host "  With 4x Parallel:    ${projectedParallelSpeedup}x total speedup"
Write-Host "  Build Time:          $fullArchiveHours hours" -ForegroundColor Cyan
Write-Host ""

if ($speedup -ge 2.0) {
    Write-Host "✅ SUCCESS! medium.en achieves target 2x+ speedup" -ForegroundColor Green
    Write-Host "   Ready for Phase 3: Parallel processing implementation" -ForegroundColor Green
}
elseif ($speedup -ge 1.5) {
    Write-Host "⚠ PARTIAL SUCCESS: ${speedup}x speedup (target was 2x)" -ForegroundColor Yellow
    Write-Host "   Still acceptable - proceed to Phase 3 with adjusted expectations" -ForegroundColor Yellow
}
else {
    Write-Host "❌ ABORT: ${speedup}x speedup insufficient (target was 2x)" -ForegroundColor Red
    Write-Host "   Consider alternative optimization strategies" -ForegroundColor Red
}

Write-Host ""
