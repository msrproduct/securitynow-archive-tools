# ============================================================================
# Security Now! Archive Builder - PRODUCTION VERSION
# Version: 2.1 PRODUCTION - wkhtmltopdf Method
# Date: January 13, 2026
# 
# Purpose:
#   - Downloads all official GRC show-notes PDFs
#   - Generates AI transcripts for missing episodes using Whisper
#   - Creates professional PDFs using wkhtmltopdf (no browser required)
#   - Maintains CSV index of all episodes
#   - Organizes by year (2005-2026+)
#
# Requirements:
#   - PowerShell 7+
#   - wkhtmltopdf (install: winget install wkhtmltopdf)
#   - Whisper.cpp (for AI transcription of missing episodes)
#
# Usage:
#   .\sn-full-run.ps1                    # Full run (uses repo root)
#   .\sn-full-run.ps1 -DryRun            # Preview only
#   .\sn-full-run.ps1 -MinEpisode 900    # Process episodes 900+
#   .\sn-full-run.ps1 -Root "C:\Custom"  # Use custom root path
# ============================================================================

param(
    [switch]$DryRun,
    [int]$MinEpisode = 1,
    [int]$MaxEpisode = 9999,
    [string]$Root = ""
)

# ============================================================================
# CONFIGURATION
# ============================================================================

# Auto-detect repository root (parent of scripts folder)
if ([string]::IsNullOrWhiteSpace($Root)) {
    $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $Root = Split-Path -Parent $ScriptDir
}

$LocalRoot = Join-Path $Root "local"
$PdfRoot = Join-Path $LocalRoot "PDF"
$NotesRoot = Join-Path $LocalRoot "Notes"
$Mp3Folder = Join-Path $LocalRoot "mp3"
$AiFolder = Join-Path $NotesRoot "ai-transcripts"
$IndexCsv = Join-Path $Root "SecurityNowNotesIndex.csv"
$EpisodeDatesCsv = Join-Path $Root "episode-dates.csv"

# Whisper.cpp paths (adjust if needed)
$WhisperExe = "C:\whisper.cpp\whisper-cli.exe"
$WhisperModel = "C:\whisper.cpp\ggml-base.en.bin"

# Archive years to scan
$StartYear = 2005
$EndYear = [DateTime]::Now.Year

# GRC and TWiT base URLs
$BaseNotesRoot = "https://www.grc.com/sn/"
$BaseTwitCdn = "https://cdn.twit.tv/audio/sn/"

# CONFIRMED WORKING REGEX - Tested on 1000+ episodes
$EpisodePattern = "Episode\s*\&#0*160;\s*(\d{1,4})\s*\&#0*160;\s*(\d{1,2})\s+(\w{3})\s+(\d{4})"

# ============================================================================
# SETUP & VALIDATION
# ============================================================================

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Security Now! Archive Builder v2.1" -ForegroundColor Cyan
Write-Host "wkhtmltopdf Method - Production Edition" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Root:        $Root"
Write-Host "DryRun:      $DryRun"
Write-Host "MinEpisode:  $MinEpisode"
Write-Host "MaxEpisode:  $MaxEpisode"
Write-Host ""

# Create folders
foreach ($path in @($Root, $LocalRoot, $PdfRoot, $NotesRoot, $Mp3Folder, $AiFolder)) {
    if (-not (Test-Path -LiteralPath $path)) {
        if ($DryRun) {
            Write-Host "DRYRUN: Would create folder: $path"
        } else {
            New-Item -ItemType Directory -Path $path -Force | Out-Null
            Write-Host "Created folder: $path" -ForegroundColor Green
        }
    }
}

# Validate wkhtmltopdf
if (-not $DryRun) {
    $wkhtmltopdf = Get-Command wkhtmltopdf -ErrorAction SilentlyContinue
    
    if (-not $wkhtmltopdf) {
        Write-Host ""
        Write-Host "ERROR: wkhtmltopdf not found!" -ForegroundColor Red
        Write-Host ""
        Write-Host "Please install wkhtmltopdf:" -ForegroundColor Yellow
        Write-Host "  Windows:  winget install wkhtmltopdf" -ForegroundColor Yellow
        Write-Host "  macOS:    brew install wkhtmltopdf" -ForegroundColor Yellow
        Write-Host "  Linux:    sudo apt install wkhtmltopdf" -ForegroundColor Yellow
        Write-Host ""
        exit 1
    }
    
    Write-Host "✓ wkhtmltopdf: $($wkhtmltopdf.Path)" -ForegroundColor Green
    
    # Validate Whisper
    if (-not (Test-Path -LiteralPath $WhisperExe)) {
        Write-Host "WARNING: Whisper not found at: $WhisperExe" -ForegroundColor Yellow
        Write-Host "AI transcript generation will be skipped." -ForegroundColor Yellow
    } else {
        Write-Host "✓ Whisper:     $WhisperExe" -ForegroundColor Green
    }
    
    # Only change directory if folder exists
    if (Test-Path -LiteralPath $Root) {
        Set-Location $Root
    }
} else {
    Write-Host "✓ DryRun mode - skipping tool validation"
}

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

function Get-ArchiveUrls {
    $urls = @("https://www.grc.com/securitynow.htm")
    for ($y = $StartYear; $y -le $EndYear; $y++) {
        $urls += "https://www.grc.com/sn/past/$y.htm"
    }
    return $urls
}

function Get-YearFromEpisode {
    param([int]$Episode)
    
    if ($Episode -le 20) { return 2005 }
    elseif ($Episode -le 72) { return 2006 }
    elseif ($Episode -le 124) { return 2007 }
    elseif ($Episode -le 176) { return 2008 }
    elseif ($Episode -le 228) { return 2009 }
    elseif ($Episode -le 280) { return 2010 }
    elseif ($Episode -le 332) { return 2011 }
    elseif ($Episode -le 384) { return 2012 }
    elseif ($Episode -le 436) { return 2013 }
    elseif ($Episode -le 488) { return 2014 }
    elseif ($Episode -le 540) { return 2015 }
    elseif ($Episode -le 592) { return 2016 }
    elseif ($Episode -le 644) { return 2017 }
    elseif ($Episode -le 696) { return 2018 }
    elseif ($Episode -le 748) { return 2019 }
    elseif ($Episode -le 800) { return 2020 }
    elseif ($Episode -le 852) { return 2021 }
    elseif ($Episode -le 904) { return 2022 }
    elseif ($Episode -le 956) { return 2023 }
    elseif ($Episode -le 1008) { return 2024 }
    elseif ($Episode -le 1060) { return 2025 }
    else { return 2026 }
}

function Save-MainIndex {
    param([array]$Index)
    
    if (-not $DryRun) {
        $Index | Sort-Object Episode, Url -Unique | 
            Select-Object Episode, Url, File | 
            Export-Csv -Path $IndexCsv -NoTypeInformation -Encoding UTF8
    }
}

function Get-EpisodeDateFromArchive {
    param(
        [int]$Episode,
        [string]$HtmlContent
    )
    
    $matches = [regex]::Matches($HtmlContent, $EpisodePattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    
    foreach ($match in $matches) {
        if ($match.Groups.Count -lt 5) { continue }
        
        $epNum = [int]$match.Groups[1].Value
        if ($epNum -ne $Episode) { continue }
        
        $day = $match.Groups[2].Value
        $month = $match.Groups[3].Value
        $year = $match.Groups[4].Value
        
        try {
            $dateStr = "$day $month $year"
            $date = [DateTime]::ParseExact($dateStr, "d MMM yyyy", $null)
            return $date.ToString("yyyy-MM-dd")
        }
        catch {
            continue
        }
    }
    
    return $null
}

# ============================================================================
# STEP 1: DISCOVER ALL GRC SHOW-NOTES PDFs
# ============================================================================

Write-Host ""
Write-Host "STEP 1: Scanning GRC archive pages..." -ForegroundColor Cyan

$archiveUrls = Get-ArchiveUrls
$allNoteLinks = @()
$episodeDates = @{}

foreach ($archiveUrl in $archiveUrls) {
    Write-Host "  Fetching: $archiveUrl"
    
    try {
        $page = Invoke-WebRequest -Uri $archiveUrl -UseBasicParsing -ErrorAction Stop
        $pageContent = $page.Content
        
        # Extract episode dates using confirmed working pattern
        $dateMatches = [regex]::Matches($pageContent, $EpisodePattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        
        foreach ($match in $dateMatches) {
            if ($match.Groups.Count -lt 5) { continue }
            
            $epNum = [int]$match.Groups[1].Value
            $day = $match.Groups[2].Value
            $month = $match.Groups[3].Value
            $year = $match.Groups[4].Value
            
            try {
                $dateStr = "$day $month $year"
                $date = [DateTime]::ParseExact($dateStr, "d MMM yyyy", $null)
                $episodeDates[$epNum] = $date.ToString("yyyy-MM-dd")
            }
            catch {
                # Skip invalid dates
            }
        }
        
        # Extract PDF links
        $matches = [regex]::Matches($pageContent, 'sn-\d+-notes\.pdf', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        
        foreach ($m in $matches) {
            $filePart = $m.Value
            $fullUrl = if ($filePart -like "http*") { $filePart } else { "$BaseNotesRoot$filePart" }
            
            $epMatch = [regex]::Match($filePart, 'sn-(\d+)-notes\.pdf', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
            if (-not $epMatch.Success) { continue }
            
            $epNum = [int]$epMatch.Groups[1].Value
            if ($epNum -lt $MinEpisode -or $epNum -gt $MaxEpisode) { continue }
            
            $allNoteLinks += [pscustomobject]@{
                Episode = $epNum
                Url     = $fullUrl
                File    = $filePart
            }
        }
    }
    catch {
        Write-Host "  WARNING: Could not fetch $archiveUrl" -ForegroundColor Yellow
    }
}

# Save episode dates to CSV
if (-not $DryRun -and $episodeDates.Count -gt 0) {
    $dateRecords = $episodeDates.GetEnumerator() | ForEach-Object {
        [pscustomobject]@{
            Episode = $_.Key
            Date = $_.Value
        }
    } | Sort-Object Episode
    
    $dateRecords | Export-Csv -Path $EpisodeDatesCsv -NoTypeInformation -Encoding UTF8
    Write-Host "  Extracted $($episodeDates.Count) episode dates -> episode-dates.csv" -ForegroundColor Green
}

$uniqueNotes = $allNoteLinks | Sort-Object Episode, Url -Unique
Write-Host ""
Write-Host "Discovered $($uniqueNotes.Count) official GRC show-notes PDFs (Episode $MinEpisode-$MaxEpisode)" -ForegroundColor Green

# ============================================================================
# STEP 2: DOWNLOAD GRC SHOW-NOTES PDFs
# ============================================================================

Write-Host ""
Write-Host "STEP 2: Downloading GRC show-notes PDFs..." -ForegroundColor Cyan

# Force $index to always be an array
if (Test-Path -LiteralPath $IndexCsv) {
    $index = @(Import-Csv -Path $IndexCsv)
} else {
    $index = @()
}

$idx = 0

foreach ($note in $uniqueNotes) {
    $idx++
    $ep = [int]$note.Episode
    $url = $note.Url
    $file = $note.File
    
    $year = Get-YearFromEpisode -Episode $ep
    $yearFolder = Join-Path $PdfRoot $year
    
    if (-not (Test-Path -LiteralPath $yearFolder)) {
        if ($DryRun) {
            Write-Host "DRYRUN: Would create year folder: $yearFolder"
        } else {
            New-Item -ItemType Directory -Path $yearFolder -Force | Out-Null
        }
    }
    
    $destPath = Join-Path $yearFolder $file
    Write-Host "[$idx/$($uniqueNotes.Count)] Episode $ep -> $url"
    
    if (Test-Path -LiteralPath $destPath) {
        Write-Host "  Already exists, skipping." -ForegroundColor Yellow
    } else {
        if ($DryRun) {
            Write-Host "  DRYRUN: Would download -> $destPath"
        } else {
            try {
                Invoke-WebRequest -Uri $url -OutFile $destPath -UseBasicParsing -ErrorAction Stop
                Write-Host "  Downloaded OK" -ForegroundColor Green
            }
            catch {
                Write-Host "  Download error: $($_.Exception.Message)" -ForegroundColor DarkGray
                continue
            }
        }
    }
    
    $existing = $index | Where-Object { [int]$_.Episode -eq $ep -and $_.File -eq $file }
    if (-not $existing) {
        $index = @($index) + @([pscustomobject]@{
            Episode = $ep
            Url     = $url
            File    = $file
        })
        Save-MainIndex -Index $index
    }
}

# ============================================================================
# STEP 3: IDENTIFY MISSING EPISODES
# ============================================================================

Write-Host ""
Write-Host "STEP 3: Computing missing notes episodes..." -ForegroundColor Cyan

if ($uniqueNotes.Count -gt 0) {
    $MinFound = ($uniqueNotes | Measure-Object Episode -Minimum).Minimum
    $MaxFound = ($uniqueNotes | Measure-Object Episode -Maximum).Maximum
} else {
    $MinFound = $MinEpisode
    $MaxFound = $MinEpisode
}

$MinRange = [Math]::Max($MinFound, $MinEpisode)
$MaxRange = [Math]::Min($MaxFound, $MaxEpisode)
$allEpisodesRange = $MinRange..$MaxRange

$episodesWithAnyNotes = $index | 
    Where-Object { ($_.File -like "sn-*-notes.pdf" -or $_.File -like "sn-*-notes-ai.pdf") -and [int]$_.Episode -ge $MinEpisode -and [int]$_.Episode -le $MaxEpisode } | 
    Select-Object -ExpandProperty Episode | 
    ForEach-Object { [int]$_ } | 
    Sort-Object -Unique

$missingEpisodes = $allEpisodesRange | Where-Object { $_ -notin $episodesWithAnyNotes }

Write-Host "Missing episodes requiring AI transcripts: $($missingEpisodes.Count)" -ForegroundColor Yellow

if ($missingEpisodes.Count -eq 0) {
    Write-Host ""
    Write-Host "No missing episodes found. Archive is complete!" -ForegroundColor Green
    Write-Host "Index CSV: $IndexCsv"
    Write-Host "Episode dates CSV: $EpisodeDatesCsv"
    exit 0
}

Write-Host "Missing episodes: $($missingEpisodes -join ', ')"

# ============================================================================
# STEP 4: GENERATE AI TRANSCRIPTS FOR MISSING EPISODES
# ============================================================================

Write-Host ""
Write-Host "STEP 4: Generating AI transcripts for missing episodes..." -ForegroundColor Cyan

if ($DryRun) {
    Write-Host "DRYRUN: Would process $($missingEpisodes.Count) episodes with AI transcription"
}

$processedCount = 0
foreach ($ep in $missingEpisodes) {
    $processedCount++
    Write-Host ""
    Write-Host "[$processedCount/$($missingEpisodes.Count)] Processing Episode $ep (AI transcript)..." -ForegroundColor Magenta
    
    $year = Get-YearFromEpisode -Episode $ep
    $yearFolder = Join-Path $PdfRoot $year
    
    if (-not (Test-Path -LiteralPath $yearFolder)) {
        if ($DryRun) {
            Write-Host "  DRYRUN: Would create year folder: $yearFolder"
        } else {
            New-Item -ItemType Directory -Path $yearFolder -Force | Out-Null
        }
    }
    
    $mp3Path = Join-Path $Mp3Folder "sn-$ep.mp3"
    $txtPrefix = Join-Path $AiFolder "sn-$ep-notes-ai"
    $txtPath = "$txtPrefix.txt"
    $htmlPath = Join-Path $AiFolder "sn-$ep-notes-ai.html"
    $pdfPath = Join-Path $PdfRoot "sn-$ep-notes-ai.pdf"
    $finalPdf = Join-Path $yearFolder "sn-$ep-notes-ai.pdf"
    
    # Skip if AI PDF already exists
    if (Test-Path -LiteralPath $finalPdf) {
        Write-Host "  AI PDF already exists, skipping."
        continue
    }
    
    # 4a. Discover MP3 URL
    $mp3Url = $null
    
    # Try GRC first
    $grcMp3 = "https://www.grc.com/sn/sn-$ep.mp3"
    try {
        $response = Invoke-WebRequest -Uri $grcMp3 -Method Head -UseBasicParsing -ErrorAction Stop
        if ($response.StatusCode -eq 200) {
            $mp3Url = $grcMp3
            Write-Host "  Found MP3 on GRC: $mp3Url"
        }
    }
    catch {
        # Try TWiT CDN
        $epPadded = $ep.ToString("D4")
        $twitMp3 = "${BaseTwitCdn}sn$epPadded/sn$epPadded.mp3"
        
        try {
            $response = Invoke-WebRequest -Uri $twitMp3 -Method Head -UseBasicParsing -ErrorAction Stop
            if ($response.StatusCode -eq 200) {
                $mp3Url = $twitMp3
                Write-Host "  Found MP3 on TWiT CDN: $mp3Url"
            }
        }
        catch {
            Write-Host "  WARNING: Could not find MP3 for episode $ep, skipping" -ForegroundColor Yellow
            continue
        }
    }
    
    if (-not $mp3Url) {
        Write-Host "  No MP3 found, skipping episode $ep" -ForegroundColor Yellow
        continue
    }
    
    # 4b. Download MP3
    if (-not (Test-Path -LiteralPath $mp3Path)) {
        if ($DryRun) {
            Write-Host "  DRYRUN: Would download MP3 to: $mp3Path"
        } else {
            Write-Host "  Downloading MP3..."
            try {
                Invoke-WebRequest -Uri $mp3Url -OutFile $mp3Path -UseBasicParsing -ErrorAction Stop
                Write-Host "  MP3 downloaded OK" -ForegroundColor Green
            }
            catch {
                Write-Host "  ERROR downloading MP3: $($_.Exception.Message)" -ForegroundColor Red
                continue
            }
        }
    } else {
        Write-Host "  MP3 already present"
    }
    
    # 4c. Run Whisper transcription
    if (-not (Test-Path -LiteralPath $txtPath)) {
        if ($DryRun) {
            Write-Host "  DRYRUN: Would run Whisper on MP3"
        } else {
            if (-not (Test-Path -LiteralPath $WhisperExe)) {
                Write-Host "  ERROR: Whisper not found, skipping" -ForegroundColor Red
                continue
            }
            
            Write-Host "  Running Whisper transcription (this may take several minutes)..."
            try {
                & $WhisperExe -m $WhisperModel -f $mp3Path -otxt -of $txtPrefix
                Write-Host "  Transcription complete" -ForegroundColor Green
            }
            catch {
                Write-Host "  ERROR running Whisper: $($_.Exception.Message)" -ForegroundColor Red
                continue
            }
        }
    } else {
        Write-Host "  Transcript already exists"
    }
    
    if (-not (Test-Path -LiteralPath $txtPath) -and -not $DryRun) {
        Write-Host "  Transcript file not created, skipping PDF step" -ForegroundColor Yellow
        continue
    }
    
    # 4d. Create HTML wrapper with disclaimer
    if ($DryRun) {
        Write-Host "  DRYRUN: Would wrap transcript in HTML and convert to PDF with wkhtmltopdf"
        
        $index = @($index) + @([pscustomobject]@{
            Episode = $ep
            Url     = $mp3Url
            File    = "sn-$ep-notes-ai.pdf"
        })
        Save-MainIndex -Index $index
        continue
    }
    
    Write-Host "  Creating HTML wrapper with disclaimer..."
    
    $bodyText = Get-Content -LiteralPath $txtPath -Raw
    $episodeTitle = "Security Now! Episode $ep - AI-Derived Transcript"
    
    $htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8" />
    <title>$episodeTitle</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background-color: white;
            color: black;
            padding: 20px;
            white-space: pre-wrap;
        }
        .disclaimer {
            background-color: #cc0000;
            color: white;
            padding: 15px;
            font-weight: bold;
            margin-bottom: 20px;
            text-align: center;
        }
    </style>
</head>
<body>
<div class="disclaimer">
THIS IS AN AUTOMATICALLY GENERATED TRANSCRIPT/NOTES FILE CREATED FROM AUDIO.
IT IS NOT AN ORIGINAL STEVE GIBSON SHOW-NOTES DOCUMENT AND MAY CONTAIN ERRORS.
</div>
<pre>
$bodyText
</pre>
</body>
</html>
"@
    
    $htmlContent | Out-File -LiteralPath $htmlPath -Encoding UTF8 -Force
    Write-Host "  HTML wrapper created"
    
    # 4e. Convert HTML to PDF using wkhtmltopdf
    Write-Host "  Converting HTML to PDF with wkhtmltopdf..."
    
    try {
        & wkhtmltopdf `
            --quiet `
            --page-size Letter `
            --margin-top 10mm `
            --margin-bottom 10mm `
            --margin-left 10mm `
            --margin-right 10mm `
            --disable-external-links `
            --enable-local-file-access `
            $htmlPath `
            $pdfPath
        
        Start-Sleep -Seconds 1
        
        if (Test-Path -LiteralPath $pdfPath) {
            Write-Host "  PDF created successfully" -ForegroundColor Green
            Move-Item -LiteralPath $pdfPath -Destination $finalPdf -Force
            Write-Host "  Filed under year folder: $finalPdf" -ForegroundColor Green
            
            $index = @($index) + @([pscustomobject]@{
                Episode = $ep
                Url     = $mp3Url
                File    = "sn-$ep-notes-ai.pdf"
            })
            Save-MainIndex -Index $index
        } else {
            Write-Host "  PDF file not found after conversion" -ForegroundColor Red
        }
    }
    catch {
        Write-Host "  ERROR during PDF conversion: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # Cleanup HTML file
    Remove-Item -LiteralPath $htmlPath -Force -ErrorAction SilentlyContinue
}

# ============================================================================
# COMPLETION SUMMARY
# ============================================================================

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Full run complete!" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Index CSV: $IndexCsv"
Write-Host "Episode dates CSV: $EpisodeDatesCsv"
Write-Host ""

if (Test-Path -LiteralPath $IndexCsv) {
    Write-Host "Archive statistics:"
    $stats = Import-Csv -Path $IndexCsv
    $officialCount = ($stats | Where-Object { $_.File -like "sn-*-notes.pdf" }).Count
    $aiCount = ($stats | Where-Object { $_.File -like "sn-*-notes-ai.pdf" }).Count
    
    Write-Host "  Official GRC PDFs: $officialCount" -ForegroundColor Green
    Write-Host "  AI-generated PDFs: $aiCount" -ForegroundColor Yellow
    Write-Host "  Total episodes:    $($stats.Count)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Sample of index (first 20 episodes):"
    $stats | Sort-Object { [int]$_.Episode } | Select-Object -First 20 | Format-Table -AutoSize
} else {
    Write-Host "No index file found."
}

Write-Host ""
Write-Host "Archive location: $LocalRoot" -ForegroundColor Green
Write-Host ""
