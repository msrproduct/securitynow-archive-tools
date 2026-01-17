<#
.SYNOPSIS
Security Now! Archive Builder - Complete episode archive with AI transcription

.DESCRIPTION
Downloads official PDFs from GRC, generates AI transcripts for missing episodes,
organizes by year, and creates searchable index. Designed for air-gapped systems.

Version 3.1.2
Released 2026-01-16

.PARAMETER MinEpisode
Starting episode number (default 1)

.PARAMETER MaxEpisode
Ending episode number (default 1000)

.PARAMETER DryRun
Test mode - no downloads or file changes

.PARAMETER SkipAI
Skip AI transcript generation (GRC PDFs only)

.EXAMPLE
.\sn-full-run-v3.1.2.ps1 -DryRun -MinEpisode 1 -MaxEpisode 5
Test the script before running for real

.EXAMPLE
.\sn-full-run-v3.1.2.ps1 -MinEpisode 500 -MaxEpisode 505
Download episodes 500-505 with AI transcripts for missing PDFs

.EXAMPLE
.\sn-full-run-v3.1.2.ps1 -MinEpisode 1 -MaxEpisode 1000 -SkipAI
Download only official GRC PDFs, skip AI generation
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, [int]::MaxValue)]
    [int]$MinEpisode = 1,

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, [int]::MaxValue)]
    [int]$MaxEpisode = 1000,

    [switch]$DryRun,
    [switch]$SkipAI
)

$ErrorActionPreference = 'Stop'

# Resolve script root and repo root
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Root      = Split-Path -Parent $ScriptDir

Write-Host ""
Write-Host "Security Now! Archive Builder v3.1.2" -ForegroundColor Cyan
Write-Host "Released 2026-01-16" -ForegroundColor Cyan
Write-Host ""

if ($DryRun) {
    Write-Host ""
    Write-Host "DRY RUN MODE - No changes will be made" -ForegroundColor Yellow
    Write-Host ""
}

# Paths
$dataDir        = Join-Path $Root "data"
$datesCsvPath   = Join-Path $dataDir "episode-dates.csv"
$indexCsvPath   = Join-Path $Root "SecurityNowNotesIndex.csv"
$errorLogPath   = Join-Path $Root "error-log.csv"

# Local media roots (private only, not exposed to public repo)
$localRoot      = Join-Path $Root "local"
$pdfRoot        = Join-Path $localRoot "pdf"
$notesRoot      = Join-Path $localRoot "Notes"
$transcriptsRoot= Join-Path $notesRoot "ai-transcripts"
$mp3Root        = Join-Path $localRoot "mp3"

# AI transcription tools (adjust paths as needed)
$whisperExe     = "C:\whisper\whisper-cli.exe"
$whisperModel   = "C:\whisper\models\ggml-base.en.bin"
$wkhtmltopdf    = "C:\Program Files\wkhtmltopdf\bin\wkhtmltopdf.exe"

# Ensure data directory exists
if (-not (Test-Path $dataDir)) {
    if ($DryRun) {
        Write-Host "Would create data directory at $dataDir" -ForegroundColor Yellow
    } else {
        New-Item -ItemType Directory -Path $dataDir -Force | Out-Null
    }
}

# Ensure error log exists
if (-not (Test-Path $errorLogPath)) {
    if (-not $DryRun) {
        "Episode,Stage,Message" | Out-File -FilePath $errorLogPath -Encoding UTF8
    }
}

# Ensure AI working directories exist
if (-not $SkipAI) {
    foreach ($dir in @($transcriptsRoot, $mp3Root)) {
        if (-not (Test-Path $dir)) {
            if ($DryRun) {
                Write-Host "Would create directory $dir" -ForegroundColor Yellow
            } else {
                New-Item -ItemType Directory -Path $dir -Force | Out-Null
            }
        }
    }
}

function Log-Error {
    param(
        [int]$Episode,
        [string]$Stage,
        [string]$Message
    )

    Write-Host "ERROR (Ep $Episode, $Stage): $Message" -ForegroundColor Red

    if (-not $DryRun) {
        "$Episode,""$Stage"",""$Message""" | Out-File -FilePath $errorLogPath -Encoding UTF8 -Append
    }
}

# Load or create episode-dates cache
$episodeDates = @{}

if (Test-Path $datesCsvPath) {
    try {
        Import-Csv -Path $datesCsvPath | ForEach-Object {
            $ep = [int]$_.Episode
            $yr = [int]$_.Year
            $episodeDates[$ep] = $yr
        }
    } catch {
        Write-Host "WARNING: Failed to read episode-dates.csv, will rebuild on demand." -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Configuration validated" -ForegroundColor Green
Write-Host ""

if ($episodeDates.Count -eq 0) {
    Write-Host "No cache found - will build on-demand" -ForegroundColor Yellow
} else {
    Write-Host "Loaded $($episodeDates.Count) cached episode dates" -ForegroundColor Green
}

# Check AI tools
if (-not $SkipAI) {
    Write-Host ""
    Write-Host "AI Tools Configuration" -ForegroundColor Cyan
    
    $aiReady = $true
    
    if (Test-Path $whisperExe) {
        Write-Host "  Whisper: OK" -ForegroundColor Green
    } else {
        Write-Host "  Whisper: NOT FOUND at $whisperExe" -ForegroundColor Yellow
        $aiReady = $false
    }
    
    if (Test-Path $whisperModel) {
        Write-Host "  Model: OK" -ForegroundColor Green
    } else {
        Write-Host "  Model: NOT FOUND at $whisperModel" -ForegroundColor Yellow
        $aiReady = $false
    }
    
    if (Test-Path $wkhtmltopdf) {
        Write-Host "  wkhtmltopdf: OK" -ForegroundColor Green
    } else {
        Write-Host "  wkhtmltopdf: NOT FOUND at $wkhtmltopdf" -ForegroundColor Yellow
        $aiReady = $false
    }
    
    if (-not $aiReady) {
        Write-Host ""
        Write-Host "WARNING: AI tools not fully configured. AI transcripts will be skipped." -ForegroundColor Yellow
        Write-Host "To enable AI transcripts, install:" -ForegroundColor Yellow
        Write-Host "  - Whisper.cpp: https://github.com/ggml-org/whisper.cpp" -ForegroundColor Yellow
        Write-Host "  - wkhtmltopdf: winget install wkhtmltopdf" -ForegroundColor Yellow
        $script:SkipAI = $true
    }
}

Write-Host ""
Write-Host "Processing Episodes $MinEpisode-$MaxEpisode" -ForegroundColor Cyan
Write-Host ""

# Helper: estimate year from episode number (simple mapping, used when cache miss)
function Get-EstimatedYear {
    param(
        [int]$Episode
    )

    switch ($Episode) {
        { $_ -ge 1   -and $_ -le 20 }   { return 2005 }
        { $_ -ge 21  -and $_ -le 72 }   { return 2006 }
        { $_ -ge 73  -and $_ -le 124 }  { return 2007 }
        { $_ -ge 125 -and $_ -le 176 }  { return 2008 }
        { $_ -ge 177 -and $_ -le 228 }  { return 2009 }
        { $_ -ge 229 -and $_ -le 280 }  { return 2010 }
        { $_ -ge 281 -and $_ -le 332 }  { return 2011 }
        { $_ -ge 333 -and $_ -le 384 }  { return 2012 }
        { $_ -ge 385 -and $_ -le 436 }  { return 2013 }
        { $_ -ge 437 -and $_ -le 488 }  { return 2014 }
        { $_ -ge 489 -and $_ -le 540 }  { return 2015 }
        { $_ -ge 541 -and $_ -le 592 }  { return 2016 }
        { $_ -ge 593 -and $_ -le 644 }  { return 2017 }
        { $_ -ge 645 -and $_ -le 696 }  { return 2018 }
        { $_ -ge 697 -and $_ -le 748 }  { return 2019 }
        { $_ -ge 749 -and $_ -le 800 }  { return 2020 }
        { $_ -ge 801 -and $_ -le 852 }  { return 2021 }
        { $_ -ge 853 -and $_ -le 904 }  { return 2022 }
        { $_ -ge 905 -and $_ -le 956 }  { return 2023 }
        { $_ -ge 957 -and $_ -le 1008 } { return 2024 }
        { $_ -ge 1009 -and $_ -le 1060 }{ return 2025 }
        { $_ -ge 1061 }                 { return 2026 }
        default { return $null }
    }
}

# Helper: fetch metadata HTML and extract date/year from GRC
function Get-GrcYearForEpisode {
    param(
        [int]$Episode
    )

    Write-Host "Episode $Episode  Fetching metadata from GRC..." -NoNewline

    # Estimate a base year using mapping above
    $estimatedYear = Get-EstimatedYear -Episode $Episode

    # NEW: robust year list construction to avoid op_Subtraction on arrays
    $yearsToTry = @()

    if ($estimatedYear -ne $null) {
        $base = [int]$estimatedYear
        $yearsToTry += $base
        $yearsToTry += ($base + 1)
        $yearsToTry += ($base - 1)
    } else {
        # Fallback range if we truly have no estimate
        $yearsToTry += 2005
        $yearsToTry += 2006
    }

    # Sanity: keep years in a reasonable range and unique
    $yearsToTry = $yearsToTry |
        Where-Object { $_ -ge 2005 -and $_ -le 2100 } |
        Select-Object -Unique

    $episodeStr = $Episode.ToString()

    foreach ($year in $yearsToTry) {
        try {
            $yearUrl  = "https://www.grc.com/sn/past/$year.htm"
            $html     = Invoke-WebRequest -Uri $yearUrl -UseBasicParsing -ErrorAction Stop
            $content  = $html.Content

            # GRC uses HTML non-breaking space; regex matches Episode&nbsp;###&nbsp;-
            $pattern = "Episode&#160;$episodeStr&#160;-"

            if ($content -match $pattern) {
                # Once matched, we can simply return the year we're on.
                Write-Host " $year" -ForegroundColor Green
                return $year
            }
        } catch {
            # Ignore errors for that year and try next
            continue
        }
    }

    Write-Host " not found" -ForegroundColor Yellow
    return $null
}

# Helper: Create HTML with AI disclaimer
function New-AITranscriptHtml {
    param(
        [int]$Episode,
        [string]$TranscriptText
    )

    $episodeTitle = "Security Now! Episode $Episode - AI-Generated Transcript"
    
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>$episodeTitle</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background-color: white;
            color: black;
            margin: 20px;
            white-space: pre-wrap;
            line-height: 1.4;
        }
        .disclaimer {
            font-weight: bold;
            color: white;
            background-color: #cc0000;
            padding: 15px;
            margin-bottom: 20px;
            border: 2px solid #990000;
            border-radius: 4px;
            font-size: 11px;
            line-height: 1.6;
        }
        .transcript {
            font-family: 'Consolas', 'Courier New', monospace;
            font-size: 10px;
            color: #000;
            background-color: #fafafa;
            padding: 15px;
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
    <div class="transcript">
$TranscriptText
    </div>
</body>
</html>
"@

    return $html
}

# Main loop counters
$downloadedPdfs   = 0
$skippedPdfs      = 0
$generatedAI      = 0
$skippedAI        = 0
$failedAI         = 0
$cachedCount      = 0

for ($ep = $MinEpisode; $ep -le $MaxEpisode; $ep++) {

    $year = $null

    if ($episodeDates.ContainsKey($ep)) {
        $year = $episodeDates[$ep]
        $cachedCount++
    } else {
        $year = Get-GrcYearForEpisode -Episode $ep
        if ($year -ne $null) {
            $episodeDates[$ep] = $year
        }
    }

    if ($year -eq $null) {
        Write-Host " Episode not found on GRC" -ForegroundColor Yellow
        Write-Host " - Skipped (no year info)"
        continue
    }

    $yearFolder = Join-Path $pdfRoot $year
    if (-not (Test-Path $yearFolder)) {
        if ($DryRun) {
            Write-Host "Would create PDF year folder $yearFolder" -ForegroundColor Yellow
        } else {
            New-Item -ItemType Directory -Path $yearFolder -Force | Out-Null
        }
    }

    $pdfFileName = "sn-$('{0:D4}' -f $ep)-notes.pdf"
    $pdfPath     = Join-Path $yearFolder $pdfFileName

    $grcPdfUrl   = "https://www.grc.com/sn/sn-$('{0:D3}' -f $ep)-notes.pdf"

    if (Test-Path $pdfPath) {
        Write-Host "Episode $ep  PDF already exists, skipping download." -ForegroundColor DarkGray
        $skippedPdfs++
    } else {
        Write-Host "Episode $ep  Downloading PDF..." -NoNewline
        if ($DryRun) {
            Write-Host " DRY-RUN" -ForegroundColor Yellow
        } else {
            try {
                Invoke-WebRequest -Uri $grcPdfUrl -OutFile $pdfPath -UseBasicParsing -ErrorAction Stop
                Write-Host " OK" -ForegroundColor Green
                $downloadedPdfs++
            } catch {
                Write-Host " Failed ($($_.Exception.Message))" -ForegroundColor Red
                Log-Error -Episode $ep -Stage "DownloadPDF" -Message $_.Exception.Message
            }
        }
    }

    # AI transcript generation
    if (-not $SkipAI) {
        $aiPdfName = "sn-$('{0:D4}' -f $ep)-notes-ai.pdf"
        $aiPdfPath = Join-Path $yearFolder $aiPdfName

        if ($DryRun) {
            if (-not (Test-Path $aiPdfPath)) {
                Write-Host "Episode $ep  Would generate AI transcript (DRY-RUN)" -ForegroundColor Yellow
            }
            continue
        }

        if (Test-Path $aiPdfPath) {
            Write-Host "Episode $ep  AI PDF already exists, skipping." -ForegroundColor DarkGray
            $skippedAI++
        } else {
            Write-Host "Episode $ep  Generating AI transcript..." -ForegroundColor Cyan
            
            # Define file paths
            $epStr = '{0:D4}' -f $ep
            $mp3File = Join-Path $mp3Root "sn-$epStr.mp3"
            $txtFile = Join-Path $transcriptsRoot "sn-$epStr-notes-ai.txt"
            $htmlFile = Join-Path $transcriptsRoot "sn-$epStr-notes-ai.html"
            
            # TWiT CDN MP3 URL
            $mp3Url = "https://cdn.twit.tv/audio/sn/sn$epStr/sn$epStr.mp3"
            
            try {
                # Step 1: Download MP3 if needed
                if (-not (Test-Path $mp3File)) {
                    Write-Host "  Downloading MP3 from TWiT..." -NoNewline
                    Invoke-WebRequest -Uri $mp3Url -OutFile $mp3File -UseBasicParsing -ErrorAction Stop
                    Write-Host " OK" -ForegroundColor Green
                }
                
                # Step 2: Run Whisper transcription if needed
                if (-not (Test-Path $txtFile)) {
                    Write-Host "  Running Whisper transcription..." -NoNewline
                    $prefix = Join-Path $transcriptsRoot "sn-$epStr-notes-ai"
                    & $whisperExe -m $whisperModel -f $mp3File -otxt -of $prefix 2>&1 | Out-Null
                    
                    if (Test-Path $txtFile) {
                        Write-Host " OK" -ForegroundColor Green
                    } else {
                        throw "Whisper did not create transcript file"
                    }
                }
                
                # Step 3: Create HTML with disclaimer
                $transcriptText = Get-Content -Path $txtFile -Raw
                $html = New-AITranscriptHtml -Episode $ep -TranscriptText $transcriptText
                $html | Out-File -FilePath $htmlFile -Encoding UTF8 -Force
                
                # Step 4: Convert to PDF with wkhtmltopdf
                Write-Host "  Converting to PDF..." -NoNewline
                & $wkhtmltopdf --quiet --page-size Letter --margin-top 10mm --margin-bottom 10mm --margin-left 10mm --margin-right 10mm --enable-local-file-access --no-stop-slow-scripts --enable-javascript --javascript-delay 1000 $htmlFile $aiPdfPath 2>&1 | Out-Null
                
                if (Test-Path $aiPdfPath) {
                    Write-Host " OK" -ForegroundColor Green
                    $generatedAI++
                    
                    # Cleanup temp HTML
                    Remove-Item -Path $htmlFile -Force -ErrorAction SilentlyContinue
                } else {
                    throw "wkhtmltopdf did not create PDF"
                }
                
            } catch {
                Write-Host " Failed" -ForegroundColor Red
                Log-Error -Episode $ep -Stage "AITranscript" -Message $_.Exception.Message
                $failedAI++
                
                # Cleanup on failure
                if (Test-Path $htmlFile) { Remove-Item -Path $htmlFile -Force -ErrorAction SilentlyContinue }
            }
        }
    }
}

# Save updated episode date cache
if (-not $DryRun -and $episodeDates.Count -gt 0) {
    $episodeDates.GetEnumerator() |
        Sort-Object Key |
        ForEach-Object {
            [PSCustomObject]@{
                Episode = $_.Key
                Year    = $_.Value
            }
        } | Export-Csv -Path $datesCsvPath -NoTypeInformation -Encoding UTF8
}

Write-Host ""
Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host "SUMMARY" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host ""
Write-Host "Official PDFs" -ForegroundColor Cyan
Write-Host "  Downloaded: $downloadedPdfs"
Write-Host "  Skipped (existing): $skippedPdfs"
Write-Host ""
Write-Host "AI Transcripts" -ForegroundColor Cyan
Write-Host "  Generated: $generatedAI"
Write-Host "  Skipped (existing): $skippedAI"
Write-Host "  Failed: $failedAI"
Write-Host ""
Write-Host "Metadata" -ForegroundColor Cyan
Write-Host "  Cached episodes: $cachedCount"
Write-Host "  Cache file: $datesCsvPath"
Write-Host ""
Write-Host "Errors" -ForegroundColor Cyan
Write-Host "  Logged to: $errorLogPath"
Write-Host ""
Write-Host "=" * 60 -ForegroundColor Green
Write-Host " Complete!" -ForegroundColor Green
Write-Host "=" * 60 -ForegroundColor Green
Write-Host ""
Write-Host "Archive location: $Root"
Write-Host ""
