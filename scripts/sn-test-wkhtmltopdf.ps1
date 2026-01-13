# ============================================================================
# Security Now! Archive Builder - TEST VERSION (Episodes 1-5, 500-505, 1000-1005)
# Version: 2.1 TEST - wkhtmltopdf Method Only - BUGFIX
# Date: January 13, 2026
# ============================================================================

param(
    [switch]$DryRun,
    [string]$Root = "D:\SecurityNow-Test-wkhtmltopdf"
)

# ============================================================================
# CONFIGURATION
# ============================================================================

$LocalRoot = Join-Path $Root "local"
$PdfRoot = Join-Path $LocalRoot "PDF"
$NotesRoot = Join-Path $LocalRoot "Notes"
$Mp3Folder = Join-Path $LocalRoot "mp3"
$AiFolder = Join-Path $NotesRoot "ai-transcripts"
$IndexCsv = Join-Path $Root "SecurityNowNotesIndex.csv"

# Whisper.cpp paths (adjust if needed)
$WhisperExe = "C:\Tools\whispercpp\whisper-cli.exe"
$WhisperModel = "C:\Tools\whispercpp\models\ggml-base.en.bin"

# TEST: Only process these specific episodes
$TestEpisodes = @(1..5) + @(500..505) + @(1000..1005)

# GRC base URLs
$BaseNotesRoot = "https://www.grc.com/sn/"
$BaseTwitCdn = "https://cdn.twit.tv/audio/sn/"

# ============================================================================
# SETUP & VALIDATION
# ============================================================================

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Security Now! TEST Run - wkhtmltopdf v2.1" -ForegroundColor Cyan
Write-Host "Episodes: 1-5, 500-505, 1000-1005" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Root:   $Root"
Write-Host "DryRun: $DryRun"
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
        Write-Host "Install with: winget install wkhtmltopdf" -ForegroundColor Yellow
        Write-Host ""
        exit 1
    }
    
    Write-Host "✓ wkhtmltopdf: $($wkhtmltopdf.Path)" -ForegroundColor Green
    
    # Validate Whisper (optional for test)
    if (Test-Path -LiteralPath $WhisperExe) {
        Write-Host "✓ Whisper:     $WhisperExe" -ForegroundColor Green
    } else {
        Write-Host "⚠ Whisper not found - AI transcripts will be skipped" -ForegroundColor Yellow
    }
    
    # BUG FIX #1: Only change directory if folder exists (not in DryRun)
    if (Test-Path -LiteralPath $Root) {
        Set-Location $Root
    }
} else {
    Write-Host "✓ DryRun mode - skipping tool validation"
}

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

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

# ============================================================================
# STEP 1: TEST GRC SHOW-NOTES PDFs FOR SELECTED EPISODES
# ============================================================================

Write-Host ""
Write-Host "STEP 1: Downloading official GRC PDFs..." -ForegroundColor Cyan

# BUG FIX #2: Force $index to always be an array
if (Test-Path -LiteralPath $IndexCsv) {
    $index = @(Import-Csv -Path $IndexCsv)
} else {
    $index = @()
}

foreach ($ep in $TestEpisodes) {
    $year = Get-YearFromEpisode -Episode $ep
    $yearFolder = Join-Path $PdfRoot $year
    
    if (-not (Test-Path -LiteralPath $yearFolder)) {
        if ($DryRun) {
            Write-Host "  DRYRUN: Would create year folder: $yearFolder"
        } else {
            New-Item -ItemType Directory -Path $yearFolder -Force | Out-Null
        }
    }
    
    $file = "sn-$ep-notes.pdf"
    $url = "$BaseNotesRoot$file"
    $destPath = Join-Path $yearFolder $file
    
    Write-Host "  Episode $ep -> $url"
    
    if (Test-Path -LiteralPath $destPath) {
        Write-Host "    Already exists, skipping." -ForegroundColor Yellow
    } else {
        if ($DryRun) {
            Write-Host "    DRYRUN: Would download -> $destPath"
        } else {
            try {
                $response = Invoke-WebRequest -Uri $url -Method Head -UseBasicParsing -ErrorAction Stop
                if ($response.StatusCode -eq 200) {
                    Invoke-WebRequest -Uri $url -OutFile $destPath -UseBasicParsing -ErrorAction Stop
                    Write-Host "    Downloaded OK" -ForegroundColor Green
                    
                    $existing = $index | Where-Object { [int]$_.Episode -eq $ep -and $_.File -eq $file }
                    if (-not $existing) {
                        $index += [pscustomobject]@{
                            Episode = $ep
                            Url     = $url
                            File    = $file
                        }
                        Save-MainIndex -Index $index
                    }
                } else {
                    Write-Host "    Not found (HTTP $($response.StatusCode))" -ForegroundColor DarkGray
                }
            }
            catch {
                Write-Host "    Not found or error: $($_.Exception.Message)" -ForegroundColor DarkGray
            }
        }
    }
}

# ============================================================================
# STEP 2: IDENTIFY MISSING EPISODES (FOR AI TRANSCRIPTS)
# ============================================================================

Write-Host ""
Write-Host "STEP 2: Identifying missing episodes..." -ForegroundColor Cyan

$episodesWithNotes = $index | 
    Where-Object { ($_.File -like "sn-*-notes.pdf" -or $_.File -like "sn-*-notes-ai.pdf") } | 
    ForEach-Object { [int]$_.Episode } | 
    Sort-Object -Unique

$missingEpisodes = $TestEpisodes | Where-Object { $_ -notin $episodesWithNotes }

Write-Host "Missing episodes requiring AI transcripts: $($missingEpisodes.Count)" -ForegroundColor Yellow

if ($missingEpisodes.Count -eq 0) {
    Write-Host ""
    Write-Host "All test episodes have official PDFs. Test complete!" -ForegroundColor Green
    Write-Host "Index CSV: $IndexCsv"
    exit 0
}

Write-Host "Missing: $($missingEpisodes -join ', ')"

# ============================================================================
# STEP 3: GENERATE AI TRANSCRIPTS FOR MISSING EPISODES
# ============================================================================

Write-Host ""
Write-Host "STEP 3: Generating AI transcripts with wkhtmltopdf..." -ForegroundColor Cyan

if ($DryRun) {
    Write-Host "DRYRUN: Would process $($missingEpisodes.Count) episodes with AI transcription"
}

foreach ($ep in $missingEpisodes) {
    Write-Host ""
    Write-Host "--- Episode $ep (AI transcript) ---" -ForegroundColor Magenta
    
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
    
    # 3a. Discover MP3 URL
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
            Write-Host "  WARNING: No MP3 found for episode $ep, skipping" -ForegroundColor Yellow
            continue
        }
    }
    
    if (-not $mp3Url) {
        Write-Host "  No MP3 found, skipping episode $ep" -ForegroundColor Yellow
        continue
    }
    
    # 3b. Download MP3
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
    
    # 3c. Run Whisper transcription
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
    
    # 3d. Create HTML wrapper and convert to PDF
    if ($DryRun) {
        Write-Host "  DRYRUN: Would wrap transcript in HTML and convert to PDF with wkhtmltopdf"
        
        # BUG FIX #2: Ensure we're adding to an array
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
    
    # 3e. Convert HTML to PDF using wkhtmltopdf
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
            
            # BUG FIX #2: Ensure we're adding to an array
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
Write-Host "TEST RUN COMPLETE!" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Index CSV: $IndexCsv"
Write-Host ""

if (Test-Path -LiteralPath $IndexCsv) {
    Write-Host "Final index (all test episodes):"
    Import-Csv -Path $IndexCsv | Sort-Object { [int]$_.Episode } | Format-Table -AutoSize
} else {
    Write-Host "No index file found (DryRun mode)."
}

Write-Host ""
Write-Host "Archive location: $LocalRoot" -ForegroundColor Green
Write-Host ""
Write-Host "✓ Test complete! Review PDFs in year folders under:" -ForegroundColor Green
Write-Host "  $PdfRoot" -ForegroundColor Green
Write-Host ""
