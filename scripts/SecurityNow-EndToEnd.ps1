# Security Now! - Complete End-to-End Archive Builder
# This script downloads official show notes from GRC and generates AI transcripts for missing episodes

param(
    [string]$Root = "$HOME\SecurityNowArchive",
    [string]$WhisperExe = "C:\whisper\whisper-cli.exe",
    [string]$WhisperModel = "C:\whisper\ggml-base.en.bin",
    [int]$MinEpisode = 1,
    [int]$MaxEpisode = 1060,
    [switch]$SkipAI,
    [switch]$Verbose
)

# ========================================
# CONFIGURATION
# ========================================

$DataFolder = Join-Path $Root "data"
$LocalRoot = Join-Path $Root "local"
$NotesFolder = Join-Path $LocalRoot "Notes"
$PdfRoot = Join-Path $LocalRoot "PDF"
$Mp3Folder = Join-Path $LocalRoot "mp3"
$TranscriptsFolder = Join-Path $NotesFolder "ai-transcripts"
$IndexCsvPath = Join-Path $DataFolder "SecurityNowNotesIndex.csv"

# Browser paths for HTML to PDF conversion
$EdgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
$ChromePath = "C:\Program Files\Google\Chrome\Application\chrome.exe"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Security Now! Archive Builder" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Root: $Root"
Write-Host "Episodes: $MinEpisode to $MaxEpisode"
Write-Host "Whisper: $WhisperExe"
Write-Host "Skip AI: $SkipAI"
Write-Host ""

# ========================================
# CREATE FOLDER STRUCTURE
# ========================================

Write-Host "Creating folder structure..." -ForegroundColor Yellow
foreach ($path in @($Root, $DataFolder, $LocalRoot, $NotesFolder, $PdfRoot, $Mp3Folder, $TranscriptsFolder)) {
    if (-not (Test-Path -LiteralPath $path)) {
        New-Item -ItemType Directory -Path $path -Force | Out-Null
        if ($Verbose) { Write-Host "  Created: $path" }
    }
}

# ========================================
# VALIDATE TOOLS
# ========================================

Write-Host "Validating tools..." -ForegroundColor Yellow

# Check PDF tool
$PdfTool = $null
if (Test-Path -LiteralPath $EdgePath) {
    $PdfTool = $EdgePath
    Write-Host "  PDF Tool: Microsoft Edge" -ForegroundColor Green
} elseif (Test-Path -LiteralPath $ChromePath) {
    $PdfTool = $ChromePath
    Write-Host "  PDF Tool: Google Chrome" -ForegroundColor Green
} else {
    Write-Host "  ERROR: Neither Edge nor Chrome found for HTML-to-PDF conversion" -ForegroundColor Red
    Write-Host "  Install Edge or Chrome to generate AI PDFs" -ForegroundColor Red
    if (-not $SkipAI) {
        exit 1
    }
}

# Check Whisper (only if not skipping AI)
if (-not $SkipAI) {
    if (-not (Test-Path -LiteralPath $WhisperExe)) {
        Write-Host "  ERROR: whisper-cli.exe not found at $WhisperExe" -ForegroundColor Red
        Write-Host "  Install whisper.cpp or use -SkipAI to skip AI transcript generation" -ForegroundColor Red
        exit 1
    }
    if (-not (Test-Path -LiteralPath $WhisperModel)) {
        Write-Host "  ERROR: Whisper model not found at $WhisperModel" -ForegroundColor Red
        Write-Host "  Download ggml-base.en.bin from whisper.cpp releases" -ForegroundColor Red
        exit 1
    }
    Write-Host "  Whisper: Ready" -ForegroundColor Green
}

# ========================================
# EPISODE TO YEAR MAPPING
# ========================================

function Get-SnYearFromEpisode {
    param([int]$Episode)
    
    switch ($Episode) {
        { $_ -ge 1 -and $_ -le 20 } { return 2005 }
        { $_ -ge 21 -and $_ -le 72 } { return 2006 }
        { $_ -ge 73 -and $_ -le 124 } { return 2007 }
        { $_ -ge 125 -and $_ -le 176 } { return 2008 }
        { $_ -ge 177 -and $_ -le 228 } { return 2009 }
        { $_ -ge 229 -and $_ -le 280 } { return 2010 }
        { $_ -ge 281 -and $_ -le 332 } { return 2011 }
        { $_ -ge 333 -and $_ -le 384 } { return 2012 }
        { $_ -ge 385 -and $_ -le 436 } { return 2013 }
        { $_ -ge 437 -and $_ -le 488 } { return 2014 }
        { $_ -ge 489 -and $_ -le 540 } { return 2015 }
        { $_ -ge 541 -and $_ -le 592 } { return 2016 }
        { $_ -ge 593 -and $_ -le 644 } { return 2017 }
        { $_ -ge 645 -and $_ -le 696 } { return 2018 }
        { $_ -ge 697 -and $_ -le 748 } { return 2019 }
        { $_ -ge 749 -and $_ -le 800 } { return 2020 }
        { $_ -ge 801 -and $_ -le 852 } { return 2021 }
        { $_ -ge 853 -and $_ -le 904 } { return 2022 }
        { $_ -ge 905 -and $_ -le 956 } { return 2023 }
        { $_ -ge 957 -and $_ -le 1008 } { return 2024 }
        { $_ -ge 1009 -and $_ -le 1060 } { return 2025 }
        { $_ -ge 1061 } { return 2026 }
        default { return 0 }
    }
}

# ========================================
# LOAD OR INITIALIZE INDEX
# ========================================

Write-Host "Loading episode index..." -ForegroundColor Yellow
$index = @()
if (Test-Path -LiteralPath $IndexCsvPath) {
    $index = @(Import-Csv -Path $IndexCsvPath)
    Write-Host "  Loaded $($index.Count) existing episodes from index" -ForegroundColor Green
} else {
    Write-Host "  Creating new index" -ForegroundColor Green
}

function Save-Index {
    param([array]$Index)
    $Index | Sort-Object { [int]$_.Episode } -Unique | Export-Csv -Path $IndexCsvPath -NoTypeInformation -Encoding UTF8
}

# ========================================
# MAIN PROCESSING LOOP
# ========================================

Write-Host ""
Write-Host "Processing episodes $MinEpisode to $MaxEpisode..." -ForegroundColor Cyan
Write-Host ""

$processed = 0
$downloaded = 0
$aiGenerated = 0
$skipped = 0

for ($ep = $MinEpisode; $ep -le $MaxEpisode; $ep++) {
    
    $year = Get-SnYearFromEpisode -Episode $ep
    if ($year -eq 0) {
        Write-Host "[Episode $ep] WARNING: No year mapping, skipping" -ForegroundColor Yellow
        continue
    }
    
    $yearFolder = Join-Path $PdfRoot $year
    if (-not (Test-Path -LiteralPath $yearFolder)) {
        New-Item -ItemType Directory -Path $yearFolder -Force | Out-Null
    }
    
    # Check if already processed
    $existingOfficial = Join-Path $yearFolder "sn-$ep-notes.pdf"
    $existingAI = Join-Path $yearFolder "sn-$ep-notes-ai.pdf"
    
    if ((Test-Path -LiteralPath $existingOfficial) -or (Test-Path -LiteralPath $existingAI)) {
        if ($Verbose) { Write-Host "[Episode $ep] Already exists, skipping" }
        $skipped++
        continue
    }
    
    # ========================================
    # TRY TO DOWNLOAD OFFICIAL GRC PDF
    # ========================================
    
    $grcUrl = "https://www.grc.com/sn/sn-$ep-notes.pdf"
    $tempPdf = Join-Path $PdfRoot "sn-$ep-notes.pdf"
    $finalPdf = Join-Path $yearFolder "sn-$ep-notes.pdf"
    
    Write-Host "[Episode $ep] Checking GRC for official notes..." -NoNewline
    
    try {
        Invoke-WebRequest -Uri $grcUrl -OutFile $tempPdf -UseBasicParsing -ErrorAction Stop | Out-Null
        Move-Item -LiteralPath $tempPdf -Destination $finalPdf -Force
        Write-Host " Downloaded" -ForegroundColor Green
        
        $index += [PSCustomObject]@{
            Episode = $ep
            Url = $grcUrl
            File = "sn-$ep-notes.pdf"
        }
        
        $downloaded++
        $processed++
        
    } catch {
        Write-Host " Not found" -ForegroundColor Yellow
        
        # ========================================
        # GENERATE AI TRANSCRIPT IF NO OFFICIAL NOTES
        # ========================================
        
        if ($SkipAI) {
            Write-Host "[Episode $ep] Skipping AI generation (SkipAI flag set)" -ForegroundColor Yellow
            continue
        }
        
        Write-Host "[Episode $ep] Attempting AI transcript generation..." -ForegroundColor Cyan
        
        # Try to download MP3
        $mp3Path = Join-Path $Mp3Folder "sn-$ep.mp3"
        $mp3Url = "https://cdn.twit.tv/audio/sn/sn$('{0:D4}' -f $ep)/sn$('{0:D4}' -f $ep).mp3"
        
        if (-not (Test-Path -LiteralPath $mp3Path)) {
            Write-Host "[Episode $ep]   Downloading MP3..." -NoNewline
            try {
                Invoke-WebRequest -Uri $mp3Url -OutFile $mp3Path -UseBasicParsing -ErrorAction Stop | Out-Null
                Write-Host " OK" -ForegroundColor Green
            } catch {
                Write-Host " Failed" -ForegroundColor Red
                Write-Host "[Episode $ep]   Cannot generate AI transcript without audio" -ForegroundColor Yellow
                continue
            }
        } else {
            Write-Host "[Episode $ep]   MP3 already exists" -ForegroundColor Green
        }
        
        # Run Whisper transcription
        $txtPrefix = Join-Path $TranscriptsFolder "sn-$ep-notes-ai"
        $txtPath = "$txtPrefix.txt"
        
        if (-not (Test-Path -LiteralPath $txtPath)) {
            Write-Host "[Episode $ep]   Running Whisper transcription..." -NoNewline
            try {
                & $WhisperExe -m $WhisperModel -f $mp3Path -otxt -of $txtPrefix 2>&1 | Out-Null
                if (Test-Path -LiteralPath $txtPath) {
                    Write-Host " OK" -ForegroundColor Green
                } else {
                    Write-Host " Failed (no output)" -ForegroundColor Red
                    continue
                }
            } catch {
                Write-Host " Failed" -ForegroundColor Red
                Write-Host "[Episode $ep]   Error: $($_.Exception.Message)" -ForegroundColor Red
                continue
            }
        } else {
            Write-Host "[Episode $ep]   Transcript already exists" -ForegroundColor Green
        }
        
        # Create HTML with disclaimer
        Write-Host "[Episode $ep]   Creating AI PDF with disclaimer..." -NoNewline
        
        $bodyText = Get-Content -LiteralPath $txtPath -Raw
        $episodeTitle = "Security Now! Episode $ep - AI-Derived Transcript"
        
        $htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>$episodeTitle</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            white-space: pre-wrap;
        }
        .disclaimer {
            font-weight: bold;
            color: red;
            margin-bottom: 1em;
            padding: 1em;
            border: 2px solid red;
            background-color: #fff8f8;
        }
    </style>
</head>
<body>
    <div class="disclaimer">
        ⚠️ THIS IS AN AUTOMATICALLY GENERATED TRANSCRIPT/NOTES FILE CREATED FROM AUDIO.
        <br><br>
        IT IS NOT AN ORIGINAL STEVE GIBSON SHOW-NOTES DOCUMENT AND MAY CONTAIN ERRORS.
        <br><br>
        Official Security Now! notes are available at: https://www.grc.com/securitynow.htm
    </div>
    <pre>$bodyText</pre>
</body>
</html>
"@
        
        $htmlPath = Join-Path $TranscriptsFolder "sn-$ep-notes-ai.html"
        $htmlContent | Out-File -LiteralPath $htmlPath -Encoding UTF8 -Force
        
        # Convert HTML to PDF
        $pdfPath = Join-Path $PdfRoot "sn-$ep-notes-ai.pdf"
        $finalAiPdf = Join-Path $yearFolder "sn-$ep-notes-ai.pdf"
        
        try {
            & $PdfTool --headless --disable-gpu --print-to-pdf="$pdfPath" $htmlPath 2>&1 | Out-Null
            Start-Sleep -Seconds 2
            
            if (Test-Path -LiteralPath $pdfPath) {
                Move-Item -LiteralPath $pdfPath -Destination $finalAiPdf -Force
                Write-Host " OK" -ForegroundColor Green
                
                $index += [PSCustomObject]@{
                    Episode = $ep
                    Url = "(AI-generated)"
                    File = "sn-$ep-notes-ai.pdf"
                }
                
                $aiGenerated++
                $processed++
            } else {
                Write-Host " Failed (PDF not created)" -ForegroundColor Red
            }
        } catch {
            Write-Host " Failed" -ForegroundColor Red
            Write-Host "[Episode $ep]   Error: $($_.Exception.Message)" -ForegroundColor Red
        } finally {
            # Cleanup HTML
            Remove-Item -LiteralPath $htmlPath -Force -ErrorAction SilentlyContinue
        }
    }
}

# ========================================
# SAVE INDEX
# ========================================

Write-Host ""
Write-Host "Saving index..." -ForegroundColor Yellow
Save-Index -Index $index

# ========================================
# SUMMARY
# ========================================

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Total processed:      $processed"
Write-Host "  Official GRC PDFs:  $downloaded" -ForegroundColor Green
Write-Host "  AI-generated PDFs:  $aiGenerated" -ForegroundColor Yellow
Write-Host "Skipped (existing):   $skipped"
Write-Host ""
Write-Host "Archive location:     $Root" -ForegroundColor Cyan
Write-Host "Index file:           $IndexCsvPath" -ForegroundColor Cyan
Write-Host ""
Write-Host "Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
