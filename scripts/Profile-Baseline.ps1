<#
.SYNOPSIS
Profile v3.1.2 baseline performance for Episode 7

.DESCRIPTION
Validates restored AI transcription pipeline and measures bottlenecks.
Generates metrics CSV for v3.2.0 optimization baseline comparison.

.EXAMPLE
.\Profile-Baseline.ps1
Runs Episode 7 profiling with detailed timing breakdown
#>

param(
    [int]$Episode = 7
)

$ErrorActionPreference = 'Stop'

# Resolve paths
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Root = Split-Path -Parent $ScriptDir

Write-Host ""
Write-Host "====================================" -ForegroundColor Cyan
Write-Host "v3.1.2 Baseline Profile - Episode $Episode" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""

# Clean slate - remove Episode 7 files if they exist
$localRoot = Join-Path $Root "local"
$pdfRoot = Join-Path $localRoot "pdf"
$mp3Root = Join-Path $localRoot "mp3"
$transcriptsRoot = Join-Path $localRoot "Notes\ai-transcripts"

$paddedEp = '{0:D4}' -f $Episode
$mp3File = Join-Path $mp3Root "sn-$paddedEp.mp3"
$txtFile = Join-Path $transcriptsRoot "sn-$paddedEp-notes-ai.txt"
$pdfFile = Join-Path $pdfRoot "2005\sn-$paddedEp-notes-ai.pdf"

Write-Host "Cleaning previous Episode $Episode files..." -ForegroundColor Yellow
foreach ($file in @($mp3File, $txtFile, $pdfFile)) {
    if (Test-Path $file) {
        Remove-Item -Path $file -Force
        Write-Host "  Removed: $file" -ForegroundColor DarkGray
    }
}

Write-Host ""
Write-Host "Starting profiling run..." -ForegroundColor Green
Write-Host ""

# Capture overall timing
$overallStart = Get-Date

# Run the main script
try {
    & (Join-Path $ScriptDir "sn-full-run.ps1") -MinEpisode $Episode -MaxEpisode $Episode
    $success = $true
} catch {
    Write-Host ""
    Write-Host "ERROR: Script failed" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    $success = $false
}

$overallEnd = Get-Date
$totalTime = ($overallEnd - $overallStart).TotalSeconds

Write-Host ""
Write-Host "====================================" -ForegroundColor Cyan
Write-Host "PROFILING RESULTS" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""

# Check file existence and sizes
$mp3Exists = Test-Path $mp3File
$txtExists = Test-Path $txtFile
$pdfExists = Test-Path $pdfFile

$mp3Size = if ($mp3Exists) { [math]::Round((Get-Item $mp3File).Length / 1MB, 2) } else { 0 }
$txtSize = if ($txtExists) { [math]::Round((Get-Item $txtFile).Length / 1KB, 2) } else { 0 }
$pdfSize = if ($pdfExists) { [math]::Round((Get-Item $pdfFile).Length / 1MB, 2) } else { 0 }

Write-Host "Execution Status:" -ForegroundColor White
Write-Host "  Success: $success"
Write-Host "  Total Runtime: $([math]::Round($totalTime, 1))s"
Write-Host ""

Write-Host "File Generation:" -ForegroundColor White
Write-Host "  MP3 Downloaded: $mp3Exists ($mp3Size MB)"
Write-Host "  Transcript Generated: $txtExists ($txtSize KB)"
Write-Host "  PDF Created: $pdfExists ($pdfSize MB)"
Write-Host ""

# Read error log
$errorLogPath = Join-Path $Root "error-log.csv"
if (Test-Path $errorLogPath) {
    $errors = Import-Csv $errorLogPath | Where-Object { [int]$_.Episode -eq $Episode }
    if ($errors) {
        Write-Host "Errors Logged:" -ForegroundColor Red
        $errors | Format-Table -AutoSize
    } else {
        Write-Host "Errors: None" -ForegroundColor Green
    }
} else {
    Write-Host "Error log not found" -ForegroundColor Yellow
}

Write-Host ""

# Generate metrics CSV
$metricsPath = Join-Path $Root "baseline-metrics.csv"
$metrics = [PSCustomObject]@{
    Episode = $Episode
    Success = $success
    TotalTime_Seconds = [math]::Round($totalTime, 1)
    MP3_Downloaded = $mp3Exists
    MP3_Size_MB = $mp3Size
    Transcript_Generated = $txtExists
    Transcript_Size_KB = $txtSize
    PDF_Created = $pdfExists
    PDF_Size_MB = $pdfSize
    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
}

$metrics | Export-Csv -Path $metricsPath -NoTypeInformation -Encoding UTF8

Write-Host "Metrics saved to: $metricsPath" -ForegroundColor Green
Write-Host ""

# Comparison to historical baseline
$historicalBaseline = 158.0
$delta = $totalTime - $historicalBaseline
$deltaPercent = [math]::Round(($delta / $historicalBaseline) * 100, 1)

Write-Host "====================================" -ForegroundColor Cyan
Write-Host "BASELINE COMPARISON" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Historical Baseline (Episode 7 test): $historicalBaseline s"
Write-Host "Current Run: $([math]::Round($totalTime, 1)) s"
Write-Host "Delta: $([math]::Round($delta, 1)) s ($deltaPercent%)"

if ([math]::Abs($deltaPercent) -le 10) {
    Write-Host "Status: WITHIN TOLERANCE (±10%)" -ForegroundColor Green
} else {
    Write-Host "Status: OUTSIDE TOLERANCE (>±10%)" -ForegroundColor Yellow
    Write-Host "Note: Variance may be due to network speed, CPU load, or system differences" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "====================================" -ForegroundColor Cyan
Write-Host "NEXT STEPS" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Review metrics CSV: $metricsPath"
Write-Host "2. Verify AI PDF has red disclaimer banner"
Write-Host "3. Start v3.2.0 optimization thread with this baseline data"
Write-Host ""
Write-Host "Target for v3.2.0: ~4-8 seconds (20-40x speedup)" -ForegroundColor Yellow
Write-Host ""

# Validate PDF content (red disclaimer check)
if ($pdfExists) {
    Write-Host "Opening AI PDF for manual verification..." -ForegroundColor Cyan
    Start-Process $pdfFile
    Write-Host "CHECK: Does the PDF have a red disclaimer banner at the top?" -ForegroundColor Yellow
    Write-Host ""
}