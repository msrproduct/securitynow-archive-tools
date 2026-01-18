<#
.SYNOPSIS
Download Distil-Whisper v3.5 GGML model for 5x transcription speedup

.DESCRIPTION
Downloads the Distil-Whisper large-v3.5 model from Hugging Face and installs it
to the correct Whisper.cpp models directory for use with v3.2.0 engine.

Model size: ~756 MB
Performance: 5-10x faster than base.en, superior accuracy

.PARAMETER Force
Overwrite existing model file if present

.EXAMPLE
.\Download-DistilWhisper.ps1
Download model to C:\tools\whispercpp\models

.EXAMPLE
.\Download-DistilWhisper.ps1 -Force
Force re-download even if model exists

.NOTES
Version: 1.0
Created: 2026-01-17
Purpose: Phase 2 of v3.2.0 Performance Optimization
#>

[CmdletBinding()]
param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

Write-Host ""
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "  Distil-Whisper v3.5 Download" -ForegroundColor Cyan
Write-Host "  Model: distil-large-v3.5 (GGML format)" -ForegroundColor Cyan
Write-Host "  Size: ~756 MB" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""

# Target paths
$modelDir = "C:\tools\whispercpp\models"
$modelFile = Join-Path $modelDir "ggml-distil-large-v3.5.bin"
$downloadUrl = "https://huggingface.co/distil-whisper/distil-large-v3.5-ggml/resolve/main/ggml-model.bin"

# Verify model directory exists
if (-not (Test-Path $modelDir)) {
    Write-Host "ERROR: Whisper.cpp models directory not found: $modelDir" -ForegroundColor Red
    Write-Host "" -ForegroundColor Yellow
    Write-Host "Please install Whisper.cpp first:" -ForegroundColor Yellow
    Write-Host "  1. See ai-context.md for installation instructions" -ForegroundColor Yellow
    Write-Host "  2. Verify Whisper.cpp is installed at C:\tools\whispercpp" -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

# Check if model already exists
if ((Test-Path $modelFile) -and -not $Force) {
    Write-Host "Distil-Whisper model already exists at:" -ForegroundColor Yellow
    Write-Host "  $modelFile" -ForegroundColor Yellow
    Write-Host ""
    
    $fileInfo = Get-Item $modelFile
    $sizeMB = [math]::Round($fileInfo.Length / 1MB, 1)
    
    Write-Host "File size: $sizeMB MB" -ForegroundColor Green
    Write-Host ""
    Write-Host "Use -Force to re-download" -ForegroundColor Yellow
    Write-Host ""
    
    # Verify size is reasonable (~756 MB expected)
    if ($sizeMB -lt 700 -or $sizeMB -gt 900) {
        Write-Host "WARNING: File size seems unusual (expected ~756 MB)" -ForegroundColor Yellow
        Write-Host "Consider re-downloading with -Force flag" -ForegroundColor Yellow
        Write-Host ""
    } else {
        Write-Host "✅ Model ready for use with v3.2.0 engine" -ForegroundColor Green
        Write-Host ""
    }
    
    exit 0
}

if ($Force -and (Test-Path $modelFile)) {
    Write-Host "Removing existing model file (Force mode)..." -ForegroundColor Yellow
    Remove-Item -LiteralPath $modelFile -Force
    Write-Host "  Deleted" -ForegroundColor Green
    Write-Host ""
}

Write-Host "Downloading Distil-Whisper v3.5 model..." -ForegroundColor Cyan
Write-Host "  Source: $downloadUrl" -ForegroundColor DarkGray
Write-Host "  Target: $modelFile" -ForegroundColor DarkGray
Write-Host ""
Write-Host "This will take several minutes (~756 MB download)..." -ForegroundColor Yellow
Write-Host ""

try {
    # Download with progress
    $ProgressPreference = 'Continue'
    Invoke-WebRequest -Uri $downloadUrl -OutFile $modelFile -UseBasicParsing
    
    Write-Host ""
    Write-Host "✅ Download complete!" -ForegroundColor Green
    Write-Host ""
    
    # Verify download
    $fileInfo = Get-Item $modelFile
    $sizeMB = [math]::Round($fileInfo.Length / 1MB, 1)
    
    Write-Host "Model Information:" -ForegroundColor Cyan
    Write-Host "  File: $($fileInfo.Name)"
    Write-Host "  Size: $sizeMB MB"
    Write-Host "  Path: $($fileInfo.FullName)"
    Write-Host ""
    
    # Validate size
    if ($sizeMB -lt 700 -or $sizeMB -gt 900) {
        Write-Host "WARNING: File size seems unusual (expected ~756 MB)" -ForegroundColor Yellow
        Write-Host "Download may be incomplete or corrupted" -ForegroundColor Yellow
        Write-Host "Consider re-downloading with -Force flag" -ForegroundColor Yellow
        Write-Host ""
        exit 1
    }
    
    Write-Host "✅ Model validated and ready for use" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Cyan
    Write-Host "  1. Run Special-Sync.ps1 to pull updated v3.2.0 engine"
    Write-Host "  2. Test performance: .\Profile-Baseline.ps1 -TestEpisode 7 -CleanStart"
    Write-Host "  3. Expected speedup: 5x (300s → ~60s)"
    Write-Host ""
    Write-Host "See docs/PHASE2-DISTIL-WHISPER.md for detailed instructions" -ForegroundColor DarkGray
    Write-Host ""
    
} catch {
    Write-Host ""
    Write-Host "ERROR: Download failed" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
    Write-Host "Possible causes:" -ForegroundColor Yellow
    Write-Host "  - Network connectivity issue" -ForegroundColor Yellow
    Write-Host "  - Hugging Face CDN temporarily unavailable" -ForegroundColor Yellow
    Write-Host "  - Insufficient disk space (~756 MB required)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Alternative: Manual download" -ForegroundColor Yellow
    Write-Host "  1. Open browser: $downloadUrl" -ForegroundColor Yellow
    Write-Host "  2. Save as: $modelFile" -ForegroundColor Yellow
    Write-Host ""
    exit 1
}
