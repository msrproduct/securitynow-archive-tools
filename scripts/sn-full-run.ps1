<#
⚠️ AI MODIFICATION CHECKPOINT ⚠️
BEFORE modifying this script, AI assistant MUST verify:

□ Confirmed paths via: Test-Path "D:\Desktop\SecurityNow-Full-Private\scripts\sn-full-run.ps1"
□ Read COMMON-MISTAKES.md to avoid 14 documented errors
□ Verified this is correct script: sn-full-run.ps1 (NOT Sync-Repos.ps1)
□ Checked Whisper path: C:\tools\whispercpp\whisper-cli.exe (NOT C:\whisper-cli\)
□ Reviewed ai-context.md for current architecture

IF ANY CHECKBOX UNCHECKED: Load context files FIRST before suggesting changes.
See: https://github.com/msrproduct/securitynow-archive-tools/blob/main/ai-context.md
#>

<#
.SYNOPSIS
Security Now! Archive Builder - Complete episode archive with AI transcription

.DESCRIPTION
Downloads official PDFs from GRC, generates AI transcripts for missing episodes,
organizes by year, and creates searchable index. Designed for air-gapped systems.

Version 3.1.3
Released 2026-01-17
Updated 2026-01-17 - Quantized base.en-q5_1 (2-3x speedup, realistic)

.PARAMETER MinEpisode
Starting episode number (default 1)

.PARAMETER MaxEpisode
Ending episode number (default 1000)

.PARAMETER DryRun
Test mode - no downloads or file changes

.PARAMETER SkipAI
Skip AI transcript generation (GRC PDFs only)

.EXAMPLE
.\sn-full-run.ps1 -DryRun -MinEpisode 1 -MaxEpisode 5
Test the script before running for real

.EXAMPLE
.\sn-full-run.ps1 -MinEpisode 500 -MaxEpisode 505
Download episodes 500-505 with AI transcripts for missing PDFs

.EXAMPLE
.\sn-full-run.ps1 -MinEpisode 1 -MaxEpisode 1000 -SkipAI
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
Write-Host "Security Now! Archive Builder v3.1.3" -ForegroundColor Cyan
Write-Host "Released 2026-01-17 | Quantized base.en-q5_1 (2-3x Speedup)" -ForegroundColor Cyan
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

# ⚠️ CRITICAL: Whisper.cpp paths - See ai-context.md for correct paths
# Common mistake: C:\whisper.cpp\ or C:\whispercpp\ (WRONG)
# Correct path: C:\tools\whispercpp\ (as documented)
$whisperExe     = "C:\tools\whispercpp\whisper-cli.exe"

# v3.1.3: Quantized base.en-q5_1 for realistic 2-3x transcription speedup
# Download: https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.en-q5_1.bin
# File size: ~60 MB (vs 74 MB full, vs 1.4 GB Distil-large unquantized)
# Performance: 2-3x faster than full base.en, ~95% accuracy retained
# Fallback: If q5_1 not found, will attempt to use full base.en
$whisperModelQ5 = "C:\tools\whispercpp\models\ggml-base.en-q5_1.bin"
$whisperModelFull = "C:\tools\whispercpp\models\ggml-base.en.bin"

if (Test-Path $whisperModelQ5) {
    $whisperModel = $whisperModelQ5
    $modelType = "Quantized Q5 (2-3x faster)"
} elseif (Test-Path $whisperModelFull) {
    $whisperModel = $whisperModelFull
    $modelType = "Full precision (baseline)"
} else {
    Write-Host "ERROR: No Whisper model found" -ForegroundColor Red
    Write-Host "  Tried Q5: $whisperModelQ5" -ForegroundColor Yellow
    Write-Host "  Tried Full: $whisperModelFull" -ForegroundColor Yellow
    exit 1
}

$wkhtmltopdf    = "C:\Program Files\wkhtmltopdf\bin\wkhtmltopdf.exe"

# Ensure required directories exist
foreach ($dir in @($dataDir, $localRoot, $pdfRoot, $notesRoot, $transcriptsRoot, $mp3Root)) {
    if (-not (Test-Path $dir)) {
        if ($DryRun) {
            Write-Host "Would create directory: $dir" -ForegroundColor Yellow
        } else {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
    }
}

# Verify AI tools exist (only if not skipping AI)
if (-not $SkipAI) {
    if (-not (Test-Path $whisperExe)) {
        Write-Host "ERROR: Whisper.cpp not found at $whisperExe" -ForegroundColor Red
        Write-Host "Please install Whisper.cpp or use -SkipAI flag" -ForegroundColor Yellow
        Write-Host "See ai-context.md for correct installation paths" -ForegroundColor Yellow
        exit 1
    }
    if (-not (Test-Path $wkhtmltopdf)) {
        Write-Host "WARNING: wkhtmltopdf not found at $wkhtmltopdf" -ForegroundColor Yellow
        Write-Host "AI transcripts will be text-only (no PDF)" -ForegroundColor Yellow
    }
}

# Ensure error log exists
if (-not (Test-Path $errorLogPath)) {
    if (-not $DryRun) {
        "Episode,Stage,Message" | Out-File -FilePath $errorLogPath -Encoding UTF8
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
        "$Episode,`"$Stage`",`"$Message`"" | Out-File -FilePath $errorLogPath -Encoding UTF8 -Append
    }
}

# Load or create index
$index = @()
if (Test-Path $indexCsvPath) {
    try {
        $index = @(Import-Csv -Path $indexCsvPath)
    } catch {
        Write-Host "WARNING: Failed to read index, will rebuild" -ForegroundColor Yellow
    }
}

function Save-Index {
    param(
        [array]$IndexData
    )
    
    if (-not $DryRun) {
        $IndexData | Sort-Object @{Expression={[int]$_.Episode}}, File -Unique | 
            Export-Csv -Path $indexCsvPath -NoTypeInformation -Encoding UTF8
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

if (-not $SkipAI) {
    Write-Host "AI Tools: Whisper.cpp + wkhtmltopdf" -ForegroundColor Green
    Write-Host "Model: $modelType" -ForegroundColor Green
    Write-Host "Path: $whisperModel" -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "Processing Episodes $MinEpisode-$MaxEpisode" -ForegroundColor Cyan
Write-Host ""

# Helper: estimate year from episode number
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

    $estimatedYear = Get-EstimatedYear -Episode $Episode

    $yearsToTry = @()

    if ($estimatedYear -ne $null) {
        $base = [int]$estimatedYear
        $yearsToTry += $base
        $yearsToTry += ($base + 1)
        $yearsToTry += ($base - 1)
    } else {
        $yearsToTry += 2005
        $yearsToTry += 2006
    }

    $yearsToTry = $yearsToTry |
        Where-Object { $_ -ge 2005 -and $_ -le 2100 } |
        Select-Object -Unique

    $episodeStr = $Episode.ToString()

    foreach ($year in $yearsToTry) {
        try {
            $yearUrl  = "https://www.grc.com/sn/past/$year.htm"
            $html     = Invoke-WebRequest -Uri $yearUrl -UseBasicParsing -ErrorAction Stop
            $content  = $html.Content

            # ⚠️ CRITICAL: GRC uses HTML entity &#160; not space
            # See COMMON-MISTAKES.md Mistake #4 - Regex failed 4× before this was documented
            $pattern = "Episode&#160;$episodeStr&#160;-"

            if ($content -match $pattern) {
                Write-Host " $year" -ForegroundColor Green
                return $year
            }
        } catch {
            continue
        }
    }

    Write-Host " not found" -ForegroundColor Yellow
    return $null
}

# Helper: Find MP3 URL for episode (TWiT CDN pattern)
function Get-Mp3Url {
    param(
        [int]$Episode
    )

    # TWiT CDN pattern: https://cdn.twit.tv/audio/sn/sn####/sn####.mp3
    $paddedEp = '{0:D4}' -f $Episode
    $mp3Url = "https://cdn.twit.tv/audio/sn/sn$paddedEp/sn$paddedEp.mp3"
    
    return $mp3Url
}

# Helper: Generate AI transcript and PDF
function Generate-AITranscript {
    param(
        [int]$Episode,
        [int]$Year
    )

    $paddedEp = '{0:D4}' -f $Episode
    $mp3File = Join-Path $mp3Root "sn-$paddedEp.mp3"
    $txtPrefix = Join-Path $transcriptsRoot "sn-$paddedEp-notes-ai"
    $txtFile = "$txtPrefix.txt"
    $htmlFile = Join-Path $transcriptsRoot "sn-$paddedEp-notes-ai.html"
    $pdfFile = Join-Path (Join-Path $pdfRoot $Year) "sn-$paddedEp-notes-ai.pdf"

    # Check if AI PDF already exists
    if (Test-Path $pdfFile) {
        Write-Host "Episode $Episode  AI PDF already exists, skipping" -ForegroundColor DarkGray
        return $true
    }

    Write-Host "Episode $Episode  Generating AI transcript..." -ForegroundColor Cyan

    # Step 1: Download MP3 if not present
    if (-not (Test-Path $mp3File)) {
        $mp3Url = Get-Mp3Url -Episode $Episode
        Write-Host "  Downloading MP3 from TWiT CDN..." -NoNewline
        
        try {
            Invoke-WebRequest -Uri $mp3Url -OutFile $mp3File -UseBasicParsing -ErrorAction Stop
            Write-Host " OK" -ForegroundColor Green
        } catch {
            Write-Host " Failed" -ForegroundColor Red
            Log-Error -Episode $Episode -Stage "MP3Download" -Message $_.Exception.Message
            return $false
        }
    } else {
        Write-Host "  MP3 already exists" -ForegroundColor DarkGray
    }

    # Step 2: Run Whisper.cpp transcription
    if (-not (Test-Path $txtFile)) {
        Write-Host "  Running Whisper transcription ($modelType)..." -NoNewline
        
        try {
            & $whisperExe -m $whisperModel -f $mp3File -otxt -of $txtPrefix 2>&1 | Out-Null
            
            if (Test-Path $txtFile) {
                Write-Host " OK" -ForegroundColor Green
            } else {
                Write-Host " Failed (no output)" -ForegroundColor Red
                Log-Error -Episode $Episode -Stage "Whisper" -Message "Transcription produced no output"
                return $false
            }
        } catch {
            Write-Host " Failed" -ForegroundColor Red
            Log-Error -Episode $Episode -Stage "Whisper" -Message $_.Exception.Message
            return $false
        }
    } else {
        Write-Host "  Transcript already exists" -ForegroundColor DarkGray
    }

    # Step 3: Create HTML with disclaimer
    Write-Host "  Creating HTML wrapper..." -NoNewline
    
    try {
        $transcriptText = Get-Content -LiteralPath $txtFile -Raw
        $episodeTitle = "Security Now! Episode $Episode - AI-Derived Transcript"
        
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
            margin: 20px;
        }
        .disclaimer {
            font-weight: bold;
            color: red;
            background-color: #fff3cd;
            padding: 15px;
            margin-bottom: 20px;
            border: 2px solid red;
        }
    </style>
</head>
<body>
    <div class="disclaimer">
        ⚠️ AI-GENERATED TRANSCRIPT - NOT OFFICIAL SHOW NOTES
        <br><br>
        This transcript was automatically generated using Whisper speech recognition.
        It may contain errors, omissions, or inaccuracies. This is NOT an official
        Steve Gibson show notes document from GRC.com.
        <br><br>
        For official episode notes (when available), visit https://www.grc.com/securitynow.htm
    </div>
    <h1>$episodeTitle</h1>
    <pre>$transcriptText</pre>
</body>
</html>
"@

        $htmlContent | Out-File -FilePath $htmlFile -Encoding UTF8 -Force
        Write-Host " OK" -ForegroundColor Green
    } catch {
        Write-Host " Failed" -ForegroundColor Red
        Log-Error -Episode $Episode -Stage "HTML" -Message $_.Exception.Message
        return $false
    }

    # Step 4: Convert HTML to PDF using wkhtmltopdf
    if (Test-Path $wkhtmltopdf) {
        Write-Host "  Converting to PDF..." -NoNewline
        
        try {
            & $wkhtmltopdf --quiet --page-size Letter $htmlFile $pdfFile 2>&1 | Out-Null
            Start-Sleep -Seconds 1
            
            if (Test-Path $pdfFile) {
                Write-Host " OK" -ForegroundColor Green
                
                # Add to index
                $script:index += [PSCustomObject]@{
                    Episode = $Episode
                    Url     = Get-Mp3Url -Episode $Episode
                    File    = "sn-$paddedEp-notes-ai.pdf"
                }
                
                # Clean up intermediate HTML
                Remove-Item -LiteralPath $htmlFile -Force -ErrorAction SilentlyContinue
                
                return $true
            } else {
                Write-Host " Failed (no output)" -ForegroundColor Red
                Log-Error -Episode $Episode -Stage "PDF" -Message "wkhtmltopdf produced no output"
                return $false
            }
        } catch {
            Write-Host " Failed" -ForegroundColor Red
            Log-Error -Episode $Episode -Stage "PDF" -Message $_.Exception.Message
            return $false
        }
    } else {
        Write-Host "  PDF conversion skipped (wkhtmltopdf not found)" -ForegroundColor Yellow
        Write-Host "  Transcript saved as: $txtFile" -ForegroundColor Yellow
        return $true
    }
}

# Main loop counters
$downloadedPdfs   = 0
$skippedPdfs      = 0
$generatedAI      = 0
$skippedAI        = 0
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

    # Try to download official GRC PDF first
    if (Test-Path $pdfPath) {
        Write-Host "Episode $ep  PDF already exists, skipping download." -ForegroundColor DarkGray
        $skippedPdfs++
        
        # Add to index if not already present
        $existing = $index | Where-Object { [int]$_.Episode -eq $ep -and $_.File -eq $pdfFileName }
        if (-not $existing -and -not $DryRun) {
            $index += [PSCustomObject]@{
                Episode = $ep
                Url     = $grcPdfUrl
                File    = $pdfFileName
            }
        }
    } else {
        Write-Host "Episode $ep  Downloading official PDF..." -NoNewline
        if ($DryRun) {
            Write-Host " DRY-RUN" -ForegroundColor Yellow
        } else {
            try {
                Invoke-WebRequest -Uri $grcPdfUrl -OutFile $pdfPath -UseBasicParsing -ErrorAction Stop
                Write-Host " OK" -ForegroundColor Green
                $downloadedPdfs++
                
                # Add to index
                $index += [PSCustomObject]@{
                    Episode = $ep
                    Url     = $grcPdfUrl
                    File    = $pdfFileName
                }
            } catch {
                Write-Host " Not available" -ForegroundColor Yellow
                
                # If official PDF not available and AI not skipped, generate AI transcript
                if (-not $SkipAI -and -not $DryRun) {
                    if (Generate-AITranscript -Episode $ep -Year $year) {
                        $generatedAI++
                    } else {
                        $skippedAI++
                    }
                }
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

# Save index
if (-not $DryRun) {
    Save-Index -IndexData $index
}

Write-Host ""
Write-Host "SUMMARY" -ForegroundColor Cyan
Write-Host ""
Write-Host "Official PDFs" -ForegroundColor Cyan
Write-Host "  Downloaded: $downloadedPdfs"
Write-Host "  Skipped (existing): $skippedPdfs"
Write-Host ""
Write-Host "AI Transcripts" -ForegroundColor Cyan
Write-Host "  Generated: $generatedAI"
Write-Host "  Skipped/Failed: $skippedAI"
Write-Host "  Model: $modelType" -ForegroundColor Green
Write-Host ""
Write-Host "Metadata" -ForegroundColor Cyan
Write-Host "  Cached episodes: $cachedCount"
Write-Host "  Cache file: $datesCsvPath"
Write-Host ""
Write-Host "Index" -ForegroundColor Cyan
Write-Host "  Total entries: $($index.Count)"
Write-Host "  Index file: $indexCsvPath"
Write-Host ""
Write-Host "Errors" -ForegroundColor Cyan
Write-Host "  Logged to: $errorLogPath"
Write-Host ""
Write-Host "✅ Complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Archive location: $Root"
Write-Host ""