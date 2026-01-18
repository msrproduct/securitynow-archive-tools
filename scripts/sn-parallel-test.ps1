<#
.SYNOPSIS
  4x Parallel Whisper Transcription - v3.2.0 Baseline Test
.DESCRIPTION
  Tests parallel processing speedup using PowerShell jobs.
  Baseline: 300s/episode × 4 episodes = 1200s sequential
  Target: ~300s total (4x speedup) via 4 simultaneous jobs
.PARAMETER Episodes
  Array of episode numbers to transcribe (default: 436,487,540,592)
.PARAMETER MaxParallel
  Maximum concurrent jobs (default: 4 for i7-1270P)
.EXAMPLE
  .\sn-parallel-test.ps1 -Episodes 436,487,540,592
  .\sn-parallel-test.ps1 -Episodes 1,2,3,4,5 -MaxParallel 3
.NOTES
  Version: 1.0.6
  Author: Security Now Archive Tools Project
  Requires: whisper-cli.exe, test MP3 files in local\mp3\
  Handles both padded (sn-0436.mp3) and unpadded (sn-436.mp3) filenames
#>
[CmdletBinding()]
param(
    [int[]]$Episodes = @(436, 487, 540, 592),
    [int]$MaxParallel = 4
)

# === CONFIGURATION - PATHS FROM ai-context.md SOT ===
$whisperExe = "C:\Tools\whispercpp\whisper-cli.exe"
$baseModel = "C:\Tools\whispercpp\models\ggml-base.en.bin"
$mp3Folder = Join-Path $PSScriptRoot "..\local\mp3"
$outputFolder = Join-Path $PSScriptRoot "..\local\transcripts-test"

# Validate dependencies
if (-not (Test-Path $whisperExe)) {
    Write-Error "Whisper not found: $whisperExe"
    Write-Host "Install from: https://github.com/ggerganov/whisper.cpp/releases" -ForegroundColor Yellow
    exit 1
}

if (-not (Test-Path $baseModel)) {
    Write-Error "Model not found: $baseModel"
    exit 1
}

if (-not (Test-Path $outputFolder)) {
    New-Item -ItemType Directory -Path $outputFolder -Force | Out-Null
}

# === PARALLEL JOB LOGIC ===
$transcribeJob = {
    param($episode, $whisperPath, $modelPath, $mp3Path, $outputPath)
    
    # Try 4-digit padding first (sn-0436.mp3), fall back to no padding (sn-436.mp3)
    $mp3File = Join-Path $mp3Path "sn-$($episode.ToString('0000')).mp3"
    if (-not (Test-Path $mp3File)) {
        $mp3File = Join-Path $mp3Path "sn-$episode.mp3"
    }
    
    $txtFile = Join-Path $outputPath "sn-$($episode.ToString('0000')).txt"
    
    if (-not (Test-Path $mp3File)) {
        return @{ Episode = $episode; Success = $false; Error = "MP3 not found"; Time = 0 }
    }
    
    $start = Get-Date
    & $whisperPath -m $modelPath -f $mp3File -otxt -of ($txtFile -replace '\.txt$','') 2>&1 | Out-Null
    $elapsed = (Get-Date) - $start
    
    return @{
        Episode = $episode
        Success = (Test-Path $txtFile)
        Time = [math]::Round($elapsed.TotalSeconds, 1)
        Error = $null
    }
}

# === EXECUTE ===
Write-Host "`n==========================================" -ForegroundColor Cyan
Write-Host "  4x PARALLEL TRANSCRIPTION TEST v1.0" -ForegroundColor Cyan
Write-Host "=========================================="`n -ForegroundColor Cyan
Write-Host "Episodes:     $($Episodes -join ', ')" -ForegroundColor White
Write-Host "Max Parallel: $MaxParallel" -ForegroundColor White
Write-Host "Output:       $outputFolder`n" -ForegroundColor White

$jobs = @()
$totalStart = Get-Date

foreach ($ep in $Episodes) {
    Write-Host "Starting Episode $ep..." -ForegroundColor Yellow
    $job = Start-Job -ScriptBlock $transcribeJob -ArgumentList @($ep, $whisperExe, $baseModel, $mp3Folder, $outputFolder)
    $jobs += $job
    
    while ((Get-Job -State Running).Count -ge $MaxParallel) {
        Start-Sleep -Seconds 2
    }
}

Write-Host "`nWaiting for completion..." -ForegroundColor Yellow
$jobs | Wait-Job | Out-Null
$results = $jobs | Receive-Job
$jobs | Remove-Job
$totalTime = ((Get-Date) - $totalStart).TotalSeconds

# === RESULTS ===
Write-Host "`n==========================================" -ForegroundColor Cyan
Write-Host "  RESULTS" -ForegroundColor Cyan
Write-Host "=========================================="`n -ForegroundColor Cyan

$successCount = 0
$totalEpisodeTime = 0

$results | ForEach-Object {
    if ($_.Success) {
        Write-Host "Episode $($_.Episode): $($_.Time)s" -ForegroundColor Green
        $successCount++
        $totalEpisodeTime += $_.Time
    } else {
        Write-Host "Episode $($_.Episode): $($_.Error)" -ForegroundColor Red
    }
}

Write-Host "`n------------------------------------------" -ForegroundColor Cyan
Write-Host "Total Wall Time:  $([math]::Round($totalTime, 1))s" -ForegroundColor Cyan
Write-Host "Avg Episode Time: $([math]::Round($totalEpisodeTime / $Episodes.Count, 1))s" -ForegroundColor Cyan

if ($totalEpisodeTime -gt 0) {
    $speedup = [math]::Round($totalEpisodeTime / $totalTime, 2)
    Write-Host "Speedup:          ${speedup}x" -ForegroundColor Green
}

Write-Host "Success Rate:     $successCount / $($Episodes.Count)" -ForegroundColor White
Write-Host "=========================================="`n -ForegroundColor Cyan