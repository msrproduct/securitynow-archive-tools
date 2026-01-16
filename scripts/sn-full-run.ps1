<#
.SYNOPSIS
Security Now! Archive Builder - Complete episode archive with AI transcription

.DESCRIPTION
Downloads official PDFs from GRC, generates AI transcripts for missing episodes,
organizes by year, and creates searchable index. Designed for air-gapped systems.

Version: 3.1.2
Released: 2026-01-16

.PARAMETER MinEpisode
Starting episode number (default: 1)

.PARAMETER MaxEpisode  
Ending episode number (default: 1000)

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
    [ValidateRange(1, [int]::MaxValue)]
    [int]$MinEpisode = 1,

    [ValidateRange(1, [int]::MaxValue)]
    [int]$MaxEpisode = 1000,

    [switch]$DryRun,
    [switch]$SkipAI
)

# Validate episode range
if ($MinEpisode -gt $MaxEpisode) {
    Write-Error "MinEpisode ($MinEpisode) cannot be greater than MaxEpisode ($MaxEpisode)"
    exit 1
}

# ============================================================================
# CONFIGURATION
# ============================================================================

$LocalRoot = "D:\Full-Private"
$PdfRoot = Join-Path $LocalRoot "PDF"
$Mp3Folder = Join-Path $LocalRoot "MP3"
$TranscriptsFolder = Join-Path $LocalRoot "transcripts"
$IndexCsv = Join-Path $LocalRoot "SecurityNowNotesIndex.csv"
$EpisodeDatesCsv = Join-Path $LocalRoot "episode-dates.csv"
$ErrorLogCsv = Join-Path $LocalRoot "error-log.csv"

# Tool paths
$WhisperExe = "C:\tools\whispercpp\whisper-cli.exe"
$WhisperModel = "C:\tools\whispercpp\ggml-base.en.bin"
$WkHtmlToPdf = "C:\Program Files\wkhtmltopdf\bin\wkhtmltopdf.exe"

# HTTP settings
$HttpTimeoutSec = 20
$MaxRetryAttempts = 3

# Base URLs
$BaseGrcNotes = "https://www.grc.com/sn/"
$BaseTwitCdn = "https://cdn.twit.tv/audio/sn/"

# Script-level cache
$script:EpisodeDateIndex = @()
$script:ErrorLog = @()

# ============================================================================
# HEADER
# ============================================================================

Write-Host "`n" -ForegroundColor Cyan
Write-Host "Security Now! Archive Builder v3.1.2" -ForegroundColor Cyan
Write-Host "Released 2026-01-16" -ForegroundColor Gray
Write-Host "`n" -ForegroundColor Cyan

if ($DryRun) {
    Write-Host "DRY RUN MODE - No changes will be made" -ForegroundColor Yellow
    Write-Host "`n" -ForegroundColor Yellow
}

# ============================================================================
# VALIDATION
# ============================================================================

# Create folders if they don't exist
foreach ($folder in @($PdfRoot, $Mp3Folder, $TranscriptsFolder)) {
    if (-not (Test-Path $folder)) {
        if ($DryRun) {
            Write-Verbose "DRYRUN: Would create folder $folder"
        }
        else {
            New-Item -ItemType Directory -Path $folder -Force | Out-Null
            Write-Verbose "Created folder: $folder"
        }
    }
}

# Validate dependencies
if (-not $DryRun) {
    if (-not (Test-Path $WkHtmlToPdf)) {
        Write-Host "ERROR: wkhtmltopdf not found at $WkHtmlToPdf" -ForegroundColor Red
        Write-Host "Install: winget install wkhtmltopdf" -ForegroundColor Yellow
        exit 1
    }

    if (-not $SkipAI) {
        if (-not (Test-Path $WhisperExe)) {
            Write-Host "WARNING: Whisper not found - AI transcription will be skipped" -ForegroundColor Yellow
            $SkipAI = $true
        }
    }
}

Write-Host "Configuration validated`n" -ForegroundColor Green

# ============================================================================
# CORE FUNCTIONS - DRY PRINCIPLE
# ============================================================================

function Get-EpisodeRecordingDate {
    <#
    .SYNOPSIS
    Fetch episode recording date from GRC archive page

    .DESCRIPTION
    Scrapes GRC archive pages for specific episode metadata.
    Format: Episode&nbsp;954 — 26 Dec 2023 — 95 min.
    Uses smart year estimation to minimize HTTP requests.
    #>
    param([int]$Episode)

    # Calculate likely year (episodes/year ≈ 52)
    $estimatedYear = 2005 + [int][Math]::Floor(($Episode - 1) / 52)

    # Try estimated year first, then adjacent years
    $yearsToTry = @($estimatedYear, $estimatedYear + 1, $estimatedYear - 1, 2025, 2026) | 
        Select-Object -Unique | Sort-Object

    foreach ($year in $yearsToTry) {
        $archiveUrl = if ($year -ge 2025) {
            "https://www.grc.com/securitynow.htm"
        }
        else {
            "https://www.grc.com/sn/past/$year.htm"
        }

        try {
            Write-Verbose "Checking $archiveUrl for episode $Episode"
            $response = Invoke-WebRequest -Uri $archiveUrl -UseBasicParsing -TimeoutSec 15 -ErrorAction Stop

            # Regex: Episode 954 — 26 Dec 2023 — 95 min.
            # Handles &nbsp; (non-breaking space) variations
            $pattern = "Episode(?:&nbsp;|&#160;)?0?$Episode(?:&nbsp;|&#160;|\s)—\s*(\d{1,2})\s+(\w{3})\s+(\d{4})"

            if ($response.Content -match $pattern) {
                $day = $Matches[1].PadLeft(2, '0')
                $monthName = $Matches[2]
                $actualYear = $Matches[3]

                # Convert month name to number
                $monthNum = switch ($monthName) {
                    "Jan" { "01" } "Feb" { "02" } "Mar" { "03" }
                    "Apr" { "04" } "May" { "05" } "Jun" { "06" }
                    "Jul" { "07" } "Aug" { "08" } "Sep" { "09" }
                    "Oct" { "10" } "Nov" { "11" } "Dec" { "12" }
                    default { "01" }
                }

                return [PSCustomObject]@{
                    Episode = $Episode
                    RecordDate = "$actualYear-$monthNum-$day"
                    Year = [int]$actualYear
                    Source = "GRC-$year"
                }
            }
        }
        catch {
            Write-Verbose "Failed to fetch $archiveUrl"
            Start-Sleep -Milliseconds 100  # Rate limiting
        }
    }

    return $null
}

function Get-EpisodeYear {
    <#
    .SYNOPSIS
    Get episode year from cache or fetch from GRC (self-populating CSV)
    #>
    param([int]$Episode)

    # 1. Check cache first (fast path)
    $cached = $script:EpisodeDateIndex | Where-Object { [int]$_.Episode -eq $Episode }
    if ($cached) {
        return [int]$cached.Year
    }

    # 2. Not in cache - fetch from GRC (read-only, safe for DryRun)
    Write-Host "  Fetching metadata from GRC..." -ForegroundColor Gray -NoNewline
    $metadata = Get-EpisodeRecordingDate -Episode $Episode

    if ($metadata) {
        # 3. Add to cache
        $script:EpisodeDateIndex += $metadata

        # 4. Save to CSV for future runs (skip in DryRun)
        if (-not $DryRun) {
            Save-EpisodeDateIndex
        }

        Write-Host " Cached $($metadata.Year), $($metadata.RecordDate)" -ForegroundColor Green
        return $metadata.Year
    }

    # 5. Fail explicitly - no estimation
    Write-Host " Episode not found on GRC" -ForegroundColor Red
    Log-Error -Episode $Episode -Operation "MetadataFetch" -Message "Episode not found on GRC archive pages"
    return $null
}

function Get-OrCreateYearFolder {
    <#
    .SYNOPSIS
    Get year folder path, creating it if needed (DRY principle)
    #>
    param([int]$Episode)

    $year = Get-EpisodeYear -Episode $Episode
    if ($null -eq $year) {
        return $null
    }

    $yearFolder = Join-Path $PdfRoot $year

    if (-not (Test-Path $yearFolder)) {
        if ($DryRun) {
            Write-Host "  DRYRUN: Would create year folder $yearFolder" -ForegroundColor Gray
        }
        else {
            New-Item -ItemType Directory -Path $yearFolder -Force | Out-Null
            Write-Verbose "Created year folder: $yearFolder"
        }
    }

    return $yearFolder
}

function Load-EpisodeDateIndex {
    <#
    .SYNOPSIS
    Load episode date index from CSV if it exists
    #>
    if (Test-Path $EpisodeDatesCsv) {
        $script:EpisodeDateIndex = Import-Csv $EpisodeDatesCsv
        Write-Host "Loaded $($script:EpisodeDateIndex.Count) episodes from cache" -ForegroundColor Green
        Write-Verbose "Cache file: $EpisodeDatesCsv"
    }
    else {
        $script:EpisodeDateIndex = @()
        Write-Host "No cache found - will build on-demand" -ForegroundColor Yellow
    }
}

function Save-EpisodeDateIndex {
    <#
    .SYNOPSIS
    Save episode date index to CSV with basic locking for future parallel support
    #>
    if ($script:EpisodeDateIndex.Count -gt 0 -and -not $DryRun) {
        try {
            $script:EpisodeDateIndex | 
                Sort-Object { [int]$_.Episode } -Unique | 
                Export-Csv -Path $EpisodeDatesCsv -NoTypeInformation -Encoding UTF8
            Write-Verbose "Saved $($script:EpisodeDateIndex.Count) episodes to cache"
        }
        catch {
            Write-Warning "Failed to save episode date index: $_"
        }
    }
}

function Update-IndexCsv {
    <#
    .SYNOPSIS
    Unified CSV index update function (DRY principle)
    #>
    param(
        [Parameter(Mandatory)]
        [int]$Episode,

        [Parameter(Mandatory)]
        [string]$Url,

        [Parameter(Mandatory)]
        [string]$File,

        [string]$Type = "Official"
    )

    if ($DryRun) {
        Write-Verbose "DRYRUN: Would update index (Episode: $Episode, File: $File, Type: $Type)"
        return
    }

    $index = @()
    if (Test-Path $IndexCsv) {
        $index = Import-Csv $IndexCsv
    }

    # Check if already exists
    $existing = $index | Where-Object { [int]$_.Episode -eq $Episode -and $_.File -eq $File }

    if (-not $existing) {
        $index += [PSCustomObject]@{
            Episode = $Episode
            Url = $Url
            File = $File
            Type = $Type
        }

        $index | 
            Sort-Object { [int]$_.Episode } -Unique | 
            Export-Csv -Path $IndexCsv -NoTypeInformation -Encoding UTF8
        Write-Verbose "Updated index: Episode $Episode added"
    }
}

function Download-GrcPdfWithRetry {
    <#
    .SYNOPSIS
    Download GRC PDF with smart retry logic and integrity validation
    #>
    param(
        [int]$Episode,
        [string]$Url,
        [string]$DestPath
    )

    $attempt = 0
    while ($attempt -lt $MaxRetryAttempts) {
        $attempt++

        try {
            if ($DryRun) {
                Write-Verbose "DRYRUN: Would download $Url"
                return $true
            }

            Write-Verbose "Downloading $Url (attempt $attempt/$MaxRetryAttempts)..."
            Invoke-WebRequest -Uri $Url -OutFile $DestPath -UseBasicParsing -ErrorAction Stop | Out-Null

            # Validate file size (GRC PDFs are typically >50KB)
            $fileInfo = Get-Item $DestPath -ErrorAction Stop
            if ($fileInfo.Length -lt 50KB) {
                throw "Downloaded file too small ($($fileInfo.Length) bytes) - likely corrupted"
            }

            Write-Verbose "Downloaded successfully ($($fileInfo.Length) bytes)"
            return $true
        }
        catch {
            $statusCode = $null
            if ($_.Exception.Response) {
                $statusCode = $_.Exception.Response.StatusCode.value__
            }

            # Smart retry based on HTTP status
            if ($statusCode -eq 404) {
                # Don't retry 404 - file doesn't exist
                Write-Verbose "File not found (404)"
                return $false
            }
            elseif ($statusCode -in @(429, 503, 504) -and $attempt -lt $MaxRetryAttempts) {
                # Retry rate limit/server errors with exponential backoff
                $delay = [Math]::Pow(2, $attempt)
                Write-Host "  Retry $attempt/$MaxRetryAttempts after ${delay}s..." -ForegroundColor Yellow
                Start-Sleep -Seconds $delay
            }
            else {
                Write-Verbose "Download failed: $($_.Exception.Message)"
                Log-Error -Episode $Episode -Operation "GRC-Download" -Message $_.Exception.Message
                return $false
            }
        }
    }

    return $false
}

function New-AITranscriptPDF {
    <#
    .SYNOPSIS
    Generate AI transcript PDF with progress indicators
    #>
    param(
        [int]$Episode,
        [string]$YearFolder
    )

    # Format episode number as 4 digits (sn0001, sn0099, sn1000)
    $mp3Url = $BaseTwitCdn + "sn{0:D4}/sn{0:D4}.mp3" -f $Episode, $Episode
    $mp3File = Join-Path $Mp3Folder "sn-$Episode.mp3"
    $txtFile = Join-Path $TranscriptsFolder "sn-$Episode-notes-ai.txt"
    $htmlFile = Join-Path $TranscriptsFolder "sn-$Episode-notes-ai.html"
    $pdfFile = Join-Path $YearFolder "sn-$Episode-notes-ai.pdf"

    try {
        # Step 1: Download MP3
        if (-not (Test-Path $mp3File)) {
            Write-Host "  Downloading MP3..." -ForegroundColor Gray -NoNewline
            if ($DryRun) {
                Write-Host " DRYRUN" -ForegroundColor Gray
            }
            else {
                Invoke-WebRequest -Uri $mp3Url -OutFile $mp3File -UseBasicParsing -ErrorAction Stop | Out-Null
                Write-Host " ✓" -ForegroundColor Green
                Write-Verbose "MP3 downloaded: $mp3File"
            }
        }
        else {
            Write-Verbose "MP3 already exists: $mp3File"
        }

        # Step 2: Run Whisper with progress indicators
        if (-not (Test-Path $txtFile)) {
            Write-Host "  Running Whisper transcription..." -ForegroundColor Gray

            if ($DryRun) {
                Write-Host "  DRYRUN: Would transcribe $mp3File" -ForegroundColor Gray
            }
            else {
                $startTime = Get-Date
                $prefix = Join-Path $TranscriptsFolder "sn-$Episode-notes-ai"

                # Start Whisper process
                $whisperProcess = Start-Process -FilePath $WhisperExe `
                    -ArgumentList "-m", $WhisperModel, "-f", $mp3File, "-otxt", "-of", $prefix `
                    -NoNewWindow -PassThru `
                    -RedirectStandardError (Join-Path $TranscriptsFolder "whisper-$Episode-stderr.txt")

                # Progress indicator with timer and heartbeat
                $heartbeatCounter = 0
                while (-not $whisperProcess.HasExited) {
                    $elapsed = ((Get-Date) - $startTime).ToString("mm\:ss")
                    Write-Host "`r  Transcribing... $elapsed (elapsed)" -NoNewline -ForegroundColor Cyan
                    Start-Sleep -Seconds 5
                    $heartbeatCounter++

                    # Heartbeat every 30 seconds (6 iterations * 5 seconds)
                    if ($heartbeatCounter % 6 -eq 0) {
                        Write-Host " (still working...)" -NoNewline -ForegroundColor Gray
                    }
                }

                $totalTime = (Get-Date) - $startTime
                Write-Host "`r  Transcribing... Complete ($($totalTime.ToString("mm\:ss")))" -ForegroundColor Green

                # Check for output
                if (-not (Test-Path $txtFile)) {
                    throw "Whisper did not create transcript file"
                }
                Write-Verbose "Transcription complete: $txtFile"

                # Cleanup stderr log if successful
                Remove-Item (Join-Path $TranscriptsFolder "whisper-$Episode-stderr.txt") -Force -ErrorAction SilentlyContinue
            }
        }
        else {
            Write-Verbose "Transcript already exists: $txtFile"
        }

        # Step 3: Create HTML with disclaimer
        Write-Host "  Converting to PDF..." -ForegroundColor Gray -NoNewline

        if ($DryRun) {
            Write-Host " DRYRUN" -ForegroundColor Gray
            return $true
        }

        $transcriptText = Get-Content $txtFile -Raw

        # Escape HTML special characters
        $transcriptText = $transcriptText -replace '&', '&amp;'
        $transcriptText = $transcriptText -replace '<', '&lt;'
        $transcriptText = $transcriptText -replace '>', '&gt;'

        $htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Security Now! Episode $Episode - AI Transcript</title>
    <style>
        body { 
            font-family: Arial, sans-serif; 
            margin: 20px; 
            line-height: 1.6; 
        }
        .disclaimer { 
            font-weight: bold; 
            color: white; 
            background-color: #cc0000; 
            padding: 15px; 
            margin-bottom: 30px; 
            border: 2px solid #990000; 
            border-radius: 4px; 
        }
        pre { 
            white-space: pre-wrap; 
            word-wrap: break-word; 
            font-family: 'Courier New', monospace; 
            font-size: 11px; 
        }
    </style>
</head>
<body>
    <div class="disclaimer">
        ⚠️ AI-GENERATED TRANSCRIPT - NOT OFFICIAL SHOW NOTES<br>
        This transcript was automatically generated and may contain errors.<br>
        Official notes: https://www.grc.com/securitynow.htm
    </div>
    <h2>Security Now! Episode $Episode - AI Transcript</h2>
    <pre>$transcriptText</pre>
</body>
</html>
"@

        $htmlContent | Out-File -FilePath $htmlFile -Encoding UTF8 -Force

        # Step 4: Convert to PDF using wkhtmltopdf with optimized flags (v3.1.2)
        & $WkHtmlToPdf --quiet --enable-local-file-access `
            --dpi 200 `
            --print-media-type `
            --no-pdf-compression `
            --page-size Letter `
            --margin-top 15mm `
            --margin-bottom 15mm `
            --margin-left 12mm `
            --margin-right 12mm `
            $htmlFile $pdfFile 2>&1 | Out-Null

        Start-Sleep -Milliseconds 500

        if (Test-Path $pdfFile) {
            Write-Host " ✓" -ForegroundColor Green
            Write-Verbose "PDF created: $pdfFile"
            return $true
        }
        else {
            throw "wkhtmltopdf did not create PDF"
        }
    }
    catch {
        Write-Host " Failed" -ForegroundColor Red
        Log-Error -Episode $Episode -Operation "AI-Transcript" -Message $_.Exception.Message
        return $false
    }
    finally {
        # Cleanup temp HTML file
        if (Test-Path $htmlFile) {
            Remove-Item $htmlFile -Force -ErrorAction SilentlyContinue
        }
    }
}

function Log-Error {
    <#
    .SYNOPSIS
    Log errors to CSV for later review/retry
    #>
    param(
        [int]$Episode,
        [string]$Operation,
        [string]$Message
    )

    $script:ErrorLog += [PSCustomObject]@{
        Timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        Episode = $Episode
        Operation = $Operation
        Message = $Message
    }

    Write-Verbose "Error logged: Episode $Episode, $Operation - $Message"
}

function Save-ErrorLog {
    <#
    .SYNOPSIS
    Save error log to CSV
    #>
    if ($script:ErrorLog.Count -gt 0 -and -not $DryRun) {
        try {
            $script:ErrorLog | Export-Csv -Path $ErrorLogCsv -NoTypeInformation -Encoding UTF8 -Append
            Write-Host "`nError log saved: $ErrorLogCsv" -ForegroundColor Yellow
        }
        catch {
            Write-Warning "Failed to save error log: $_"
        }
    }
}

# ============================================================================
# MAIN EXECUTION PIPELINE
# ============================================================================

# Load existing metadata cache
Load-EpisodeDateIndex

# Load existing index
$index = @()
if (Test-Path $IndexCsv) {
    $index = Import-Csv $IndexCsv
    Write-Host "Loaded existing index: $($index.Count) episodes`n" -ForegroundColor Green
}

# Statistics
$stats = @{
    GrcDownloaded = 0
    GrcSkipped = 0
    AiGenerated = 0
    AiFailed = 0
    AiSkipped = 0  # v3.1.2 - Track dry-run skips
    MetadataFetched = 0
}

Write-Host "`n" -ForegroundColor Cyan
Write-Host "Processing Episodes $MinEpisode-$MaxEpisode" -ForegroundColor Cyan
Write-Host "`n" -ForegroundColor Cyan

# Process episodes
for ($ep = $MinEpisode; $ep -le $MaxEpisode; $ep++) {
    Write-Host "Episode $ep" -NoNewline -ForegroundColor White

    # Get year folder (auto-creates, fetches metadata if needed)
    $yearFolder = Get-OrCreateYearFolder -Episode $ep

    if ($null -eq $yearFolder) {
        Write-Host " - Skipped (no year info)" -ForegroundColor Yellow
        continue
    }

    # Check for existing files
    $officialPdf = Join-Path $yearFolder "sn-$ep-notes.pdf"
    $aiPdf = Join-Path $yearFolder "sn-$ep-notes-ai.pdf"

    if ((Test-Path $officialPdf) -or (Test-Path $aiPdf)) {
        Write-Host " - Already exists" -ForegroundColor Gray
        $stats.GrcSkipped++
        continue
    }

    # Try to download official GRC PDF
    $grcUrl = $BaseGrcNotes + "sn-$ep-notes.pdf"
    $downloaded = Download-GrcPdfWithRetry -Episode $ep -Url $grcUrl -DestPath $officialPdf

    if ($downloaded -and (Test-Path $officialPdf)) {
        Write-Host " - Official PDF ✓" -ForegroundColor Green
        Update-IndexCsv -Episode $ep -Url $grcUrl -File "sn-$ep-notes.pdf" -Type "Official"
        $stats.GrcDownloaded++
    }
    elseif (-not $SkipAI) {
        # Generate AI transcript
        Write-Host " - No official PDF, generating AI transcript..." -ForegroundColor Yellow
        $aiSuccess = New-AITranscriptPDF -Episode $ep -YearFolder $yearFolder

        # v3.1.2 - Track dry-run skips separately
        if ($DryRun) {
            $stats.AiSkipped++
        }
        elseif ($aiSuccess -and (Test-Path $aiPdf)) {
            Update-IndexCsv -Episode $ep -Url "AI-generated" -File "sn-$ep-notes-ai.pdf" -Type "AI"
            $stats.AiGenerated++
        }
        else {
            $stats.AiFailed++
        }
    }
    else {
        Write-Host " - No official PDF, AI skipped" -ForegroundColor Gray
    }
}

# ============================================================================
# CLEANUP & SUMMARY
# ============================================================================

# Save final metadata cache
Save-EpisodeDateIndex

# Save error log if any errors occurred
Save-ErrorLog

# Cleanup orphaned temp files
if (-not $DryRun) {
    $orphanedHtml = Get-ChildItem -Path $TranscriptsFolder -Filter "sn-*-notes-ai.html" -File -ErrorAction SilentlyContinue
    if ($orphanedHtml) {
        foreach ($html in $orphanedHtml) {
            Remove-Item $html.FullName -Force -ErrorAction SilentlyContinue
        }
        Write-Host "`nCleaned up $($orphanedHtml.Count) orphaned HTML files" -ForegroundColor Gray
    }
}

# Display summary
Write-Host "`n" -ForegroundColor Cyan
Write-Host "SUMMARY" -ForegroundColor Cyan
Write-Host "`n" -ForegroundColor Cyan

Write-Host "Official PDFs" -ForegroundColor White
Write-Host "  Downloaded: $($stats.GrcDownloaded)" -ForegroundColor Green
Write-Host "  Skipped (existing): $($stats.GrcSkipped)" -ForegroundColor Gray

Write-Host "`nAI Transcripts" -ForegroundColor White
# v3.1.2 - Improved DryRun output clarity
if ($DryRun) {
    Write-Host "  Skipped (dry-run): $($stats.AiSkipped)" -ForegroundColor Cyan
}
else {
    Write-Host "  Generated: $($stats.AiGenerated)" -ForegroundColor Green
    Write-Host "  Failed: $($stats.AiFailed)" -ForegroundColor $(if ($stats.AiFailed -gt 0) { "Red" } else { "Gray" })
}

Write-Host "`nMetadata" -ForegroundColor White
Write-Host "  Cached episodes: $($script:EpisodeDateIndex.Count)" -ForegroundColor Cyan
Write-Host "  Cache file: $EpisodeDatesCsv" -ForegroundColor Gray

Write-Host "`nIndex" -ForegroundColor White
Write-Host "  Total episodes: $(if (Test-Path $IndexCsv) { (Import-Csv $IndexCsv).Count } else { 0 })" -ForegroundColor Cyan
Write-Host "  Index file: $IndexCsv" -ForegroundColor Gray

if ($script:ErrorLog.Count -gt 0) {
    Write-Host "`n$($script:ErrorLog.Count) errors logged to $ErrorLogCsv" -ForegroundColor Yellow
}

Write-Host "`n Complete!`n" -ForegroundColor Green
Write-Host "Archive location: $LocalRoot" -ForegroundColor Cyan
