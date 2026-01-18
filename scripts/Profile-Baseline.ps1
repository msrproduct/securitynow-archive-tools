<#
.SYNOPSIS
Baseline Performance Profiling for Security Now Archive Engine v3.1.2

.DESCRIPTION
Measures detailed performance metrics for the v3.1.2 engine before v3.2.0 optimizations.
Generates baseline-metrics.csv for comparison against Distil-Whisper, parallel processing,
and other Tier 1 optimizations.

.PARAMETER TestEpisode
Episode number to profile (default 7 - historical baseline)

.PARAMETER CleanStart
Delete existing episode files before test for fresh measurement

.EXAMPLE
.\Profile-Baseline.ps1 -TestEpisode 7 -CleanStart
Profile Episode 7 with fresh download/transcription

.NOTES
Version: 1.0
Created: 2026-01-17
Purpose: Phase 1 of v3.2.0 Performance Optimization Roadmap
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [int]$TestEpisode = 7,
    
    [switch]$CleanStart
)

$ErrorActionPreference = 'Stop'

# Resolve paths
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Root = Split-Path -Parent $ScriptDir
$engineScript = Join-Path $ScriptDir "sn-full-run.ps1"
$metricsFile = Join-Path $Root "baseline-metrics.csv"

Write-Host ""
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "  v3.1.2 Baseline Performance Profile" -ForegroundColor Cyan
Write-Host "  Episode $TestEpisode" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""

# Verify engine exists
if (-not (Test-Path $engineScript)) {
    Write-Host "ERROR: Engine script not found at $engineScript" -ForegroundColor Red
    exit 1
}

# Historical baseline data for comparison
$historicalBaseline = @{
    Episode = 7
    TotalTime = 158.0  # seconds
    Source = "Episode 7 historical test"
}

Write-Host "Historical Baseline Reference:" -ForegroundColor Yellow
Write-Host "  Episode $($historicalBaseline.Episode): $($historicalBaseline.TotalTime)s" -ForegroundColor Yellow
Write-Host "  Source: $($historicalBaseline.Source)" -ForegroundColor Yellow
Write-Host ""

# Clean existing files if requested
if ($CleanStart) {
    Write-Host "Cleaning previous Episode $TestEpisode files..." -ForegroundColor Yellow
    
    $localRoot = Join-Path $Root "local"
    $mp3Root = Join-Path $localRoot "mp3"
    $transcriptsRoot = Join-Path $localRoot "Notes\ai-transcripts"
    $pdfRoot = Join-Path $localRoot "pdf"
    
    $paddedEp = '{0:D4}' -f $TestEpisode
    
    # Remove MP3
    $mp3File = Join-Path $mp3Root "sn-$paddedEp.mp3"
    if (Test-Path $mp3File) {
        Remove-Item -LiteralPath $mp3File -Force
        Write-Host "  Deleted: $mp3File" -ForegroundColor DarkGray
    }
    
    # Remove transcript TXT
    $txtFile = Join-Path $transcriptsRoot "sn-$paddedEp-notes-ai.txt"
    if (Test-Path $txtFile) {
        Remove-Item -LiteralPath $txtFile -Force
        Write-Host "  Deleted: $txtFile" -ForegroundColor DarkGray
    }
    
    # Remove AI PDFs (check all year folders)
    Get-ChildItem -Path $pdfRoot -Directory | ForEach-Object {
        $aiPdf = Join-Path $_.FullName "sn-$paddedEp-notes-ai.pdf"
        if (Test-Path $aiPdf) {
            Remove-Item -LiteralPath $aiPdf -Force
            Write-Host "  Deleted: $aiPdf" -ForegroundColor DarkGray
        }
    }
    
    Write-Host "  Clean start ready" -ForegroundColor Green
    Write-Host ""
}

# Capture system info for reproducibility
$systemInfo = @{
    OS = [System.Environment]::OSVersion.VersionString
    PowerShell = $PSVersionTable.PSVersion.ToString()
    ProcessorCount = [System.Environment]::ProcessorCount
    TotalMemoryGB = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
}

Write-Host "System Configuration:" -ForegroundColor Cyan
Write-Host "  OS: $($systemInfo.OS)"
Write-Host "  PowerShell: $($systemInfo.PowerShell)"
Write-Host "  CPU Cores: $($systemInfo.ProcessorCount)"
Write-Host "  RAM: $($systemInfo.TotalMemoryGB) GB"
Write-Host ""

Write-Host "Starting profiling run..." -ForegroundColor Cyan
Write-Host ""

# Measure total execution time
$totalStopwatch = [System.Diagnostics.Stopwatch]::StartNew()

try {
    # Run the engine for single episode
    $output = & $engineScript -MinEpisode $TestEpisode -MaxEpisode $TestEpisode 2>&1 | Tee-Object -Variable engineOutput
    
    $totalStopwatch.Stop()
    
    Write-Host ""
    Write-Host "==============================================" -ForegroundColor Green
    Write-Host "  Profiling Complete" -ForegroundColor Green
    Write-Host "==============================================" -ForegroundColor Green
    Write-Host ""
    
    # Calculate metrics
    $totalSeconds = [math]::Round($totalStopwatch.Elapsed.TotalSeconds, 1)
    
    # Verify output files were created
    $localRoot = Join-Path $Root "local"
    $mp3Root = Join-Path $localRoot "mp3"
    $transcriptsRoot = Join-Path $localRoot "Notes\ai-transcripts"
    $pdfRoot = Join-Path $localRoot "pdf"
    
    $paddedEp = '{0:D4}' -f $TestEpisode
    $mp3File = Join-Path $mp3Root "sn-$paddedEp.mp3"
    $txtFile = Join-Path $transcriptsRoot "sn-$paddedEp-notes-ai.txt"
    
    # Find AI PDF (could be in any year folder)
    $aiPdfFile = $null
    Get-ChildItem -Path $pdfRoot -Directory | ForEach-Object {
        $testPdf = Join-Path $_.FullName "sn-$paddedEp-notes-ai.pdf"
        if (Test-Path $testPdf) {
            $aiPdfFile = $testPdf
        }
    }
    
    $mp3Exists = Test-Path $mp3File
    $txtExists = Test-Path $txtFile
    $pdfExists = $aiPdfFile -ne $null
    
    $mp3SizeMB = if ($mp3Exists) { [math]::Round((Get-Item $mp3File).Length / 1MB, 1) } else { 0 }
    $txtSizeKB = if ($txtExists) { [math]::Round((Get-Item $txtFile).Length / 1KB, 1) } else { 0 }
    $pdfSizeMB = if ($pdfExists) { [math]::Round((Get-Item $aiPdfFile).Length / 1MB, 1) } else { 0 }
    
    # Display results
    Write-Host "PROFILING RESULTS" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Execution Status" -ForegroundColor Yellow
    Write-Host "  Success: $($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq $null)"
    Write-Host "  Total Runtime: $totalSeconds seconds"
    Write-Host ""
    Write-Host "File Generation" -ForegroundColor Yellow
    Write-Host "  MP3 Downloaded: $mp3Exists ($mp3SizeMB MB)"
    Write-Host "  Transcript Generated: $txtExists ($txtSizeKB KB)"
    Write-Host "  PDF Created: $pdfExists ($pdfSizeMB MB)"
    Write-Host ""
    
    # Parse output for errors
    $errorCount = ($engineOutput | Select-String -Pattern "ERROR" -AllMatches).Matches.Count
    Write-Host "Errors: $errorCount" -ForegroundColor $(if ($errorCount -eq 0) { "Green" } else { "Red" })
    Write-Host ""
    
    # Save metrics to CSV
    $metrics = [PSCustomObject]@{
        Timestamp = $systemInfo.Timestamp
        Episode = $TestEpisode
        TotalRuntimeSeconds = $totalSeconds
        MP3Downloaded = $mp3Exists
        MP3SizeMB = $mp3SizeMB
        TranscriptGenerated = $txtExists
        TranscriptSizeKB = $txtSizeKB
        PDFCreated = $pdfExists
        PDFSizeMB = $pdfSizeMB
        ErrorCount = $errorCount
        OS = $systemInfo.OS
        PowerShellVersion = $systemInfo.PowerShell
        CPUCores = $systemInfo.ProcessorCount
        TotalMemoryGB = $systemInfo.TotalMemoryGB
    }
    
    # Append to metrics file
    $metrics | Export-Csv -Path $metricsFile -NoTypeInformation -Encoding UTF8 -Append
    
    Write-Host "Metrics saved to: $metricsFile" -ForegroundColor Green
    Write-Host ""
    
    # Compare to historical baseline
    if ($TestEpisode -eq $historicalBaseline.Episode) {
        Write-Host "BASELINE COMPARISON" -ForegroundColor Cyan
        Write-Host ""
        
        $delta = [math]::Round($totalSeconds - $historicalBaseline.TotalTime, 1)
        $percentChange = [math]::Round(($delta / $historicalBaseline.TotalTime) * 100, 1)
        
        Write-Host "  Historical Baseline (Episode $($historicalBaseline.Episode)): $($historicalBaseline.TotalTime) s"
        Write-Host "  Current Run: $totalSeconds s"
        Write-Host "  Delta: $delta s ($percentChange%)"
        
        $tolerance = 10  # ±10% tolerance
        if ([math]::Abs($percentChange) -le $tolerance) {
            Write-Host "  Status: ✅ WITHIN TOLERANCE (±$tolerance%)" -ForegroundColor Green
        } else {
            Write-Host "  Status: ⚠️ OUTSIDE TOLERANCE (±$tolerance%)" -ForegroundColor Yellow
            Write-Host "  Note: Variance may be due to network speed, CPU load, or system differences" -ForegroundColor Yellow
        }
        Write-Host ""
    }
    
    Write-Host "NEXT STEPS" -ForegroundColor Cyan
    Write-Host "  1. Review metrics CSV: $metricsFile"
    Write-Host "  2. Verify AI PDF has red disclaimer banner"
    Write-Host "  3. Start v3.2.0 optimization thread with this baseline data"
    Write-Host ""
    Write-Host "Target for v3.2.0: 4-8 seconds (20-40x speedup)" -ForegroundColor Yellow
    Write-Host ""
    
    # Open AI PDF for visual verification if it exists
    if ($pdfExists) {
        Write-Host "Opening AI PDF for visual verification..." -ForegroundColor Cyan
        Start-Process $aiPdfFile
    }
    
} catch {
    $totalStopwatch.Stop()
    
    Write-Host ""
    Write-Host "ERROR during profiling run:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
    Write-Host "Check engine error log for details" -ForegroundColor Yellow
    exit 1
}

Write-Host "CHECK: Does the PDF have a red disclaimer banner at the top?" -ForegroundColor Yellow
Write-Host "       (PDF will open automatically)" -ForegroundColor Yellow
Write-Host ""