<#
.SYNOPSIS
    Regenerate all AI-created PDFs with proper formatting using wkhtmltopdf

.DESCRIPTION
    Finds all AI transcript text files and regenerates them as properly formatted PDFs
    with white backgrounds, readable black text, red disclaimer banners, and no browser artifacts.

.PARAMETER Root
    Root directory of the repository (defaults to parent of script location)

.EXAMPLE
    .\Fix-AI-PDFs.ps1
    .\Fix-AI-PDFs.ps1 -Root "D:\Desktop\SecurityNow-Full-Private"
#>

param(
    [string]$Root = (Split-Path -Parent $PSScriptRoot)
)

#
# CONFIGURATION
#

$LocalRoot = Join-Path $Root "local"
$NotesFolder = Join-Path $LocalRoot "Notes"
$PdfRoot = Join-Path $LocalRoot "PDF"
$TranscriptsFolder = Join-Path $NotesFolder "ai-transcripts"
$ConvertScript = Join-Path $Root "scripts\Convert-HTMLtoPDF.ps1"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Fix AI-Generated PDFs using wkhtmltopdf" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Root: $Root"
Write-Host ""

#
# VALIDATE TOOLS
#

Write-Host "Validating tools..." -ForegroundColor Yellow

# Check for Convert-HTMLtoPDF.ps1 script
if (-not (Test-Path $ConvertScript)) {
    Write-Host "ERROR: Convert-HTMLtoPDF.ps1 not found at $ConvertScript" -ForegroundColor Red
    Write-Host "This script is required for PDF generation" -ForegroundColor Red
    exit 1
}

Write-Host "  PDF Converter: wkhtmltopdf via Convert-HTMLtoPDF.ps1" -ForegroundColor Green

#
# EPISODE TO YEAR MAPPING
#

# Load episode date index (cached globally)
if (-not $global:EpisodeDateIndex) {
    $indexPath = Join-Path (Split-Path $PSScriptRoot -Parent) "episode-dates.csv"
    if (Test-Path $indexPath) {
        $global:EpisodeDateIndex = Import-Csv $indexPath
        Write-Host "  Loaded episode date index: $($global:EpisodeDateIndex.Count) episodes" -ForegroundColor Gray
    } else {
        Write-Host "  WARNING: episode-dates.csv not found, using fallback year logic" -ForegroundColor Yellow
        $global:EpisodeDateIndex = @()
    }
}

function Get-EpisodeYear {
    param([int]$Episode)

    # Try date index first
    $entry = $global:EpisodeDateIndex | Where-Object { [int]$_.Episode -eq $Episode }
    if ($entry) {
        return [int]$entry.Year
    }

    # Fallback: Calculate year based on episode ranges (52 episodes/year avg)
    switch ($Episode) {
        {$_ -ge 1 -and $_ -le 20} { return 2005 }
        {$_ -ge 21 -and $_ -le 72} { return 2006 }
        {$_ -ge 73 -and $_ -le 124} { return 2007 }
        {$_ -ge 125 -and $_ -le 176} { return 2008 }
        {$_ -ge 177 -and $_ -le 228} { return 2009 }
        {$_ -ge 229 -and $_ -le 280} { return 2010 }
        {$_ -ge 281 -and $_ -le 332} { return 2011 }
        {$_ -ge 333 -and $_ -le 384} { return 2012 }
        {$_ -ge 385 -and $_ -le 436} { return 2013 }
        {$_ -ge 437 -and $_ -le 488} { return 2014 }
        {$_ -ge 489 -and $_ -le 540} { return 2015 }
        {$_ -ge 541 -and $_ -le 592} { return 2016 }
        {$_ -ge 593 -and $_ -le 644} { return 2017 }
        {$_ -ge 645 -and $_ -le 696} { return 2018 }
        {$_ -ge 697 -and $_ -le 748} { return 2019 }
        {$_ -ge 749 -and $_ -le 800} { return 2020 }
        {$_ -ge 801 -and $_ -le 852} { return 2021 }
        {$_ -ge 853 -and $_ -le 904} { return 2022 }
        {$_ -ge 905 -and $_ -le 956} { return 2023 }
        {$_ -ge 957 -and $_ -le 1008} { return 2024 }
        {$_ -ge 1009 -and $_ -le 1060} { return 2025 }
        {$_ -ge 1061} { return 2026 }
        default { return 2026 }
    }
}

#
# FIND ALL AI TRANSCRIPT FILES
#

Write-Host "`nFinding AI transcript files..." -ForegroundColor Yellow

if (-not (Test-Path -LiteralPath $TranscriptsFolder)) {
    Write-Host "ERROR: Transcripts folder not found: $TranscriptsFolder" -ForegroundColor Red
    exit 1
}

$transcriptFiles = Get-ChildItem -LiteralPath $TranscriptsFolder -Filter "sn-*-notes-ai.txt"

if ($transcriptFiles.Count -eq 0) {
    Write-Host "No AI transcript files found" -ForegroundColor Yellow
    exit 0
}

Write-Host "  Found $($transcriptFiles.Count) AI transcript files" -ForegroundColor Green
Write-Host ""

#
# PROCESS EACH TRANSCRIPT
#

$processed = 0
$failed = 0

foreach ($txtFile in $transcriptFiles) {

    # Extract episode number
    if ($txtFile.Name -match 'sn-(\d+)-notes-ai\.txt') {
        $ep = [int]$matches[1]
    } else {
        Write-Host "SKIP: Could not parse episode number from $($txtFile.Name)" -ForegroundColor Yellow
        continue
    }

    # Get year for this episode
    $year = Get-EpisodeYear -Episode $ep
    if ($year -eq 0) {
        $episodeNum = $ep
        Write-Host "Episode $episodeNum - WARNING: No year mapping, skipping" -ForegroundColor Yellow
        continue
    }

    # Create year folder if needed
    $yearFolder = Join-Path $PdfRoot $year
    if (-not (Test-Path -LiteralPath $yearFolder)) {
        New-Item -ItemType Directory -Path $yearFolder -Force | Out-Null
    }

    Write-Host "Episode $ep ($year): Processing..." -NoNewline

    # Read transcript content
    $txtPath = $txtFile.FullName
    $transcriptText = Get-Content -LiteralPath $txtPath -Raw

    # Escape HTML special characters in the transcript
    $transcriptText = $transcriptText -replace '&', '&amp;'
    $transcriptText = $transcriptText -replace '<', '&lt;'
    $transcriptText = $transcriptText -replace '>', '&gt;'

    $episodeTitle = "Security Now! Episode $ep - AI-Generated Transcript"

    # Create HTML with proper styling
    $htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>$episodeTitle</title>
    <style>
        body {
            font-family: 'Segoe UI', Arial, sans-serif;
            background-color: white;
            color: #333;
            margin: 40px;
            line-height: 1.6;
        }
        .disclaimer {
            font-weight: bold;
            color: white;
            background-color: #cc0000;
            padding: 10px 15px;
            margin-bottom: 30px;
            border: 2px solid #990000;
            border-radius: 4px;
            font-size: 11px;
            line-height: 1.4;
        }
        .title {
            font-size: 20px;
            font-weight: bold;
            color: #000;
            margin-bottom: 20px;
            padding-bottom: 10px;
            border-bottom: 2px solid #cc0000;
        }
        .transcript {
            white-space: pre-wrap;
            font-family: 'Consolas', 'Courier New', monospace;
            font-size: 11px;
            color: #000;
            background-color: #fafafa;
            padding: 20px;
            border: 1px solid #ddd;
            border-radius: 4px;
        }
    </style>
</head>
<body>
    <div class="disclaimer">
        AI-GENERATED TRANSCRIPT - NOT OFFICIAL SHOW NOTES<br>
        This transcript was automatically generated from audio and may contain errors.<br>
        Official Security Now! notes: https://www.grc.com/securitynow.htm
    </div>
    <div class="title">$episodeTitle</div>
    <div class="transcript">$transcriptText</div>
</body>
</html>
"@

    # Write HTML file
    $htmlPath = Join-Path $TranscriptsFolder "temp-$ep.html"
    $htmlContent | Out-File -LiteralPath $htmlPath -Encoding UTF8 -Force

    # Convert HTML to PDF using wkhtmltopdf
    $finalAiPdf = Join-Path $yearFolder "sn-$ep-notes-ai.pdf"

    try {
        # Call Convert-HTMLtoPDF.ps1 (suppresses verbose output)
        $null = & $ConvertScript -InputHTML $htmlPath -OutputPDF $finalAiPdf -ErrorAction Stop 2>&1

        if (Test-Path -LiteralPath $finalAiPdf) {
            Write-Host " OK" -ForegroundColor Green
            $processed++
        } else {
            Write-Host " Failed (PDF not created)" -ForegroundColor Red
            $failed++
        }
    } catch {
        Write-Host " Failed: $($_.Exception.Message)" -ForegroundColor Red
        $failed++
    } finally {
        # Cleanup temporary HTML
        Remove-Item -LiteralPath $htmlPath -Force -ErrorAction SilentlyContinue
    }
}

#
# SUMMARY
#

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Processed successfully: $processed" -ForegroundColor Green
Write-Host "Failed: $failed" -ForegroundColor Red
Write-Host ""
Write-Host "PDFs location: $PdfRoot" -ForegroundColor Cyan
Write-Host ""
Write-Host "Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
