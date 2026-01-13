<#
.SYNOPSIS
    Security Now! Archive Builder - Production Script

.DESCRIPTION
    Complete end-to-end workflow for Security Now podcast archiving:
    - Downloads GRC official PDFs
    - Generates AI transcripts for missing episodes (Whisper)
    - Creates PDFs with wkhtmltopdf
    - Organizes by year using episode-dates.csv

.NOTES
    Version:        3.1.0
    Release Date:   2026-01-13
    Author:         MSRProduct
    Repository:     github.com/msrproduct/SecurityNow-Full-Private
    
    Changelog:
    3.1.0 (2026-01-13) - Post-cleanup standardization, renamed from v3
    3.0.0 (2026-01-13) - Aggressive rewrite, fixed Whisper paths, GRC regex
    2.1.0 (2026-01-12) - Added wkhtmltopdf support, episode-dates.csv
    2.0.0 (2026-01-11) - Initial production release with AI transcription
    
.PARAMETER DryRun
    Test mode - shows what would happen without making changes

.PARAMETER MinEpisode
    Starting episode number (default: 1)

.PARAMETER MaxEpisode
    Ending episode number (default: current latest)

.EXAMPLE
    .\sn-full-run.ps1 -DryRun -MinEpisode 1 -MaxEpisode 5
    Test episodes 1-5 without downloads

.EXAMPLE
    .\sn-full-run.ps1 -MinEpisode 1000
    Process all episodes from 1000 to latest

.LINK
    https://github.com/msrproduct/SecurityNow-Full-Private/blob/main/docs/QUICK-START.md
#>

[CmdletBinding()]
param(
    [switch]$DryRun,
    [int]$MinEpisode = 1,
    [int]$MaxEpisode = 1200
)

# Script version (Semantic Versioning: MAJOR.MINOR.PATCH)
$ScriptVersion = "3.1.0"
$ScriptDate = "2026-01-13"

Write-Host "Security Now! Archive Builder v$ScriptVersion ($ScriptDate)" -ForegroundColor Cyan

#==============================================================================
# CONFIGURATION WITH VALIDATION
#==============================================================================

# Paths - All relative to script root
$RepoRoot = $PSScriptRoot
$LocalRoot = Join-Path $RepoRoot "local"
$DataFolder = Join-Path $RepoRoot "data"
$PdfRoot = Join-Path $LocalRoot "PDF"
$Mp3Folder = Join-Path $LocalRoot "mp3"
$NotesRoot = Join-Path $LocalRoot "Notes"
$TranscriptsFolder = Join-Path $NotesRoot "ai-transcripts"

# Index files
$IndexCsv = Join-Path $DataFolder "SecurityNowNotesIndex.csv"
$EpisodeDatesCsv = Join-Path $DataFolder "episode-dates.csv"
$ErrorLogCsv = Join-Path $DataFolder "error-log.csv"

# Tool paths (CORRECTED - verified working paths)
$WhisperExe = "C:\tools\whispercpp\whisper-cli.exe"
$WhisperModel = "C:\tools\whispercpp\models\ggml-base.en.bin"
$WkHtmlToPdf = "C:\Program Files\wkhtmltopdf\bin\wkhtmltopdf.exe"

# URLs
$BaseGrcNotes = "https://www.grc.com/sn/"
$BaseTwitCdn = "https://cdn.twit.tv/audio/sn/"

# Global metadata cache
$script:EpisodeDateIndex = @()
$script:ErrorLog = @()

#==============================================================================
# INITIALIZATION & VALIDATION
#==============================================================================

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Security Now! Archive Builder v3.0" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

if ($DryRun) {
    Write-Host "*** DRY RUN MODE - No changes will be made ***`n" -ForegroundColor Yellow
}

# Create directory structure
$folders = @($LocalRoot, $DataFolder, $PdfRoot, $Mp3Folder, $NotesRoot, $TranscriptsFolder)
foreach ($folder in $folders) {
    if (-not (Test-Path $folder)) {
        if ($DryRun) {
            Write-Host "[DRYRUN] Would create: $folder" -ForegroundColor Gray
        } else {
            New-Item -ItemType Directory -Path $folder -Force | Out-Null
            Write-Host "Created folder: $folder" -ForegroundColor Green
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

#==============================================================================
# CORE FUNCTIONS - DRY PRINCIPLE
#==============================================================================

function Get-EpisodeRecordingDateFromGRC {
    param([int]$Episode)
    
    # Estimate year
    $episodesPerYear = 52
    $estimatedYear = 2005 + [int][Math]::Floor(($Episode - 1) / $episodesPerYear)
    $yearsToTry = @($estimatedYear, ($estimatedYear - 1), ($estimatedYear + 1), 2025, 2026) | Select-Object -Unique | Sort-Object
    
    foreach ($year in $yearsToTry) {
        $archiveUrl = if ($year -ge 2025) {
            "https://www.grc.com/securitynow.htm"
        } else {
            "https://www.grc.com/sn/past/$year.htm"
        }
        
        try {
            $response = Invoke-WebRequest -Uri $archiveUrl -UseBasicParsing -TimeoutSec 20 -ErrorAction Stop
            
            # GRC format: "Episode&nbsp;#954 | 26 Dec 2023 | 95 min."
            $pattern = "Episode&nbsp;#$Episode\s*\|\s*(\d{1,2})\s+(\w{3})\s+(\d{4})"
            
            if ($response.Content -match $pattern) {
                $day = $matches[1].PadLeft(2, '0')
                $monthName = $matches[2]
                $actualYear = $matches[3]
                
                $monthNum = switch ($monthName) {
                    "Jan" { "01" } "Feb" { "02" } "Mar" { "03" } "Apr" { "04" }
                    "May" { "05" } "Jun" { "06" } "Jul" { "07" } "Aug" { "08" }
                    "Sep" { "09" } "Oct" { "10" } "Nov" { "11" } "Dec" { "12" }
                    default { "01" }
                }
                
                return @{
                    Year = [int]$actualYear
                    Date = "$actualYear-$monthNum-$day"
                    Source = "GRC-$year"
                }
            }
        }
        catch {
            Start-Sleep -Milliseconds 500
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
    $metadata = Get-EpisodeRecordingDateFromGRC -Episode $Episode
    
    if ($metadata) {
        # 3. Add to cache
        $newEntry = [PSCustomObject]@{
            Episode = $Episode
            RecordDate = $metadata.Date
            Year = $metadata.Year
            Source = $metadata.Source
        }
        $script:EpisodeDateIndex += $newEntry
        
        # 4. Save to CSV for future runs (skip in DryRun)
        if (-not $DryRun) {
            Save-EpisodeDateIndex
        }
        
        Write-Host " ✓ Cached ($($metadata.Year), $($metadata.Date))" -ForegroundColor Green
        return $metadata.Year
    }
    
    # 5. Fail explicitly - no estimation
    Write-Host " ✗ Episode not found on GRC" -ForegroundColor Red
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
            Write-Host "[DRYRUN] Would create year folder: $yearFolder" -ForegroundColor Gray
        } else {
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
        $script:EpisodeDateIndex = @(Import-Csv $EpisodeDatesCsv)
        Write-Host "Loaded $($script:EpisodeDateIndex.Count) episodes from cache" -ForegroundColor Green
    } else {
        $script:EpisodeDateIndex = @()
        Write-Host "No cache found - will build on-demand" -ForegroundColor Yellow
    }
}

function Save-EpisodeDateIndex {
    <#
    .SYNOPSIS
        Save episode date index to CSV
    #>
    if ($script:EpisodeDateIndex.Count -gt 0 -and -not $DryRun) {
        $script:EpisodeDateIndex | Sort-Object { [int]$_.Episode } -Unique | 
            Export-Csv -Path $EpisodeDatesCsv -NoTypeInformation -Encoding UTF8
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
    
    if ($DryRun) { return }
    
    $index = @()
    if (Test-Path $IndexCsv) {
        $index = @(Import-Csv $IndexCsv)
    }
    
    # Check if already exists
    $existing = $index | Where-Object { 
        [int]$_.Episode -eq $Episode -and $_.File -eq $File 
    }
    
    if (-not $existing) {
        $index += [PSCustomObject]@{
            Episode = $Episode
            Url = $Url
            File = $File
            Type = $Type
        }
        
        $index | Sort-Object { [int]$_.Episode } -Unique | 
            Export-Csv -Path $IndexCsv -NoTypeInformation -Encoding UTF8
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
    
    $maxAttempts = 3
    $attempt = 0
    
    while ($attempt -lt $maxAttempts) {
        $attempt++
        
        try {
            if ($DryRun) {
                Write-Host "[DRYRUN] Would download $Url" -ForegroundColor Gray
                return $true
            }
            
            Invoke-WebRequest -Uri $Url -OutFile $DestPath -UseBasicParsing -ErrorAction Stop | Out-Null
            
            # Validate file size (GRC PDFs are typically > 50KB)
            $fileInfo = Get-Item $DestPath
            if ($fileInfo.Length -lt 50KB) {
                throw "Downloaded file too small ($($fileInfo.Length) bytes) - likely corrupted"
            }
            
            return $true
        }
        catch {
            $statusCode = $_.Exception.Response.StatusCode.value__
            
            # Smart retry based on HTTP status
            if ($statusCode -in @(404)) {
                # Don't retry 404 - file doesn't exist
                return $false
            }
            elseif ($statusCode -in @(429, 503, 504) -and $attempt -lt $maxAttempts) {
                # Retry rate limit / server errors with exponential backoff
                $delay = [Math]::Pow(2, $attempt)
                Write-Host "  Retry $attempt/$maxAttempts after ${delay}s..." -ForegroundColor Yellow
                Start-Sleep -Seconds $delay
            }
            else {
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
    
    $mp3Url = "${BaseTwitCdn}sn$('{0:D4}' -f $Episode)/sn$('{0:D4}' -f $Episode).mp3"
    $mp3File = Join-Path $Mp3Folder "sn-$Episode.mp3"
    $txtFile = Join-Path $TranscriptsFolder "sn-$Episode-notes-ai.txt"
    $htmlFile = Join-Path $TranscriptsFolder "sn-$Episode-notes-ai.html"
    $pdfFile = Join-Path $YearFolder "sn-$Episode-notes-ai.pdf"
    
    try {
        # Step 1: Download MP3
        if (-not (Test-Path $mp3File)) {
            Write-Host "  Downloading MP3..." -ForegroundColor Gray -NoNewline
            if ($DryRun) {
                Write-Host " [DRYRUN]" -ForegroundColor Gray
            } else {
                Invoke-WebRequest -Uri $mp3Url -OutFile $mp3File -UseBasicParsing -ErrorAction Stop | Out-Null
                Write-Host " ✓" -ForegroundColor Green
            }
        }
        
        # Step 2: Run Whisper with progress indicators
        if (-not (Test-Path $txtFile)) {
            Write-Host "  Running Whisper transcription..." -ForegroundColor Gray
            
            if ($DryRun) {
                Write-Host "  [DRYRUN] Would transcribe $mp3File" -ForegroundColor Gray
            } else {
                $startTime = Get-Date
                $prefix = Join-Path $TranscriptsFolder "sn-$Episode-notes-ai"
                
                # Start Whisper process
                $whisperProcess = Start-Process -FilePath $WhisperExe `
                    -ArgumentList "-m `"$WhisperModel`" -f `"$mp3File`" -otxt -of `"$prefix`"" `
                    -NoNewWindow -PassThru -RedirectStandardError (Join-Path $TranscriptsFolder "whisper-$Episode-stderr.txt")
                
                # Progress indicator with timer
                $heartbeatCounter = 0
                while (-not $whisperProcess.HasExited) {
                    $elapsed = ((Get-Date) - $startTime).ToString("mm\:ss")
                    Write-Host "`r  Transcribing... ${elapsed} elapsed" -NoNewline -ForegroundColor Cyan
                    
                    Start-Sleep -Seconds 5
                    $heartbeatCounter++
                    
                    # Heartbeat every 30 seconds
                    if ($heartbeatCounter % 6 -eq 0) {
                        Write-Host " (still working...)" -NoNewline -ForegroundColor Gray
                    }
                }
                
                Write-Host "`r  Transcribing... Complete ($((Get-Date) - $startTime).ToString('mm\:ss'))" -ForegroundColor Green
                
                # Check for output
                if (-not (Test-Path $txtFile)) {
                    throw "Whisper did not create transcript file"
                }
                
                # Cleanup stderr log if successful
                Remove-Item (Join-Path $TranscriptsFolder "whisper-$Episode-stderr.txt") -Force -ErrorAction SilentlyContinue
            }
        }
        
        # Step 3: Create HTML with disclaimer
        Write-Host "  Converting to PDF..." -ForegroundColor Gray -NoNewline
        
        if ($DryRun) {
            Write-Host " [DRYRUN]" -ForegroundColor Gray
            return $true
        }
        
        $transcriptText = Get-Content $txtFile -Raw
        
        # Escape HTML
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
        
        # Step 4: Convert to PDF
        & $WkHtmlToPdf --quiet --enable-local-file-access $htmlFile $pdfFile 2>&1 | Out-Null
        Start-Sleep -Milliseconds 500
        
        if (Test-Path $pdfFile) {
            Write-Host " ✓" -ForegroundColor Green
            return $true
        } else {
            throw "wkhtmltopdf did not create PDF"
        }
    }
    catch {
        Write-Host " ✗ Failed: $_" -ForegroundColor Red
        Log-Error -Episode $Episode -Operation "AI-Transcript" -Message $_.Exception.Message
        return $false
    }
    finally {
        # Cleanup temp HTML
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
        Timestamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
        Episode = $Episode
        Operation = $Operation
        Message = $Message
    }
}

function Save-ErrorLog {
    <#
    .SYNOPSIS
        Save error log to CSV
    #>
    if ($script:ErrorLog.Count -gt 0 -and -not $DryRun) {
        $script:ErrorLog | Export-Csv -Path $ErrorLogCsv -NoTypeInformation -Encoding UTF8 -Append
        Write-Host "`nError log saved: $ErrorLogCsv" -ForegroundColor Yellow
    }
}

#==============================================================================
# MAIN EXECUTION PIPELINE
#==============================================================================

# Load existing metadata cache
Load-EpisodeDateIndex

# Load existing index
$index = @()
if (Test-Path $IndexCsv) {
    $index = @(Import-Csv $IndexCsv)
    Write-Host "Loaded existing index: $($index.Count) episodes`n" -ForegroundColor Green
}

# Statistics
$stats = @{
    GrcDownloaded = 0
    GrcSkipped = 0
    AiGenerated = 0
    AiFailed = 0
    MetadataFetched = 0
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Processing Episodes $MinEpisode-$MaxEpisode" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

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
    $grcUrl = "${BaseGrcNotes}sn-$ep-notes.pdf"
    $downloaded = Download-GrcPdfWithRetry -Episode $ep -Url $grcUrl -DestPath $officialPdf
    
    if ($downloaded -and (Test-Path $officialPdf)) {
        Write-Host " - ✓ Official PDF" -ForegroundColor Green
        Update-IndexCsv -Episode $ep -Url $grcUrl -File "sn-$ep-notes.pdf" -Type "Official"
        $stats.GrcDownloaded++
    }
    elseif (-not $SkipAI) {
        # Generate AI transcript
        Write-Host " - No official PDF, generating AI transcript..." -ForegroundColor Yellow
        $aiSuccess = New-AITranscriptPDF -Episode $ep -YearFolder $yearFolder
        
        if ($aiSuccess -and (Test-Path $aiPdf)) {
            Update-IndexCsv -Episode $ep -Url "AI-generated" -File "sn-$ep-notes-ai.pdf" -Type "AI"
            $stats.AiGenerated++
        } else {
            $stats.AiFailed++
        }
    }
    else {
        Write-Host " - No official PDF, AI skipped" -ForegroundColor Gray
    }
}

#==============================================================================
# CLEANUP & SUMMARY
#==============================================================================

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
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "SUMMARY" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "Official PDFs:" -ForegroundColor White
Write-Host "  Downloaded: $($stats.GrcDownloaded)" -ForegroundColor Green
Write-Host "  Skipped (existing): $($stats.GrcSkipped)" -ForegroundColor Gray

Write-Host "`nAI Transcripts:" -ForegroundColor White
Write-Host "  Generated: $($stats.AiGenerated)" -ForegroundColor Green
Write-Host "  Failed: $($stats.AiFailed)" -ForegroundColor $(if ($stats.AiFailed -gt 0) { 'Red' } else { 'Gray' })

Write-Host "`nMetadata:" -ForegroundColor White
Write-Host "  Cached episodes: $($script:EpisodeDateIndex.Count)" -ForegroundColor Cyan
Write-Host "  Cache file: $EpisodeDatesCsv" -ForegroundColor Gray

Write-Host "`nIndex:" -ForegroundColor White
Write-Host "  Total episodes: $(if (Test-Path $IndexCsv) { (Import-Csv $IndexCsv).Count } else { 0 })" -ForegroundColor Cyan
Write-Host "  Index file: $IndexCsv" -ForegroundColor Gray

if ($script:ErrorLog.Count -gt 0) {
    Write-Host "`n⚠ $($script:ErrorLog.Count) errors logged to: $ErrorLogCsv" -ForegroundColor Yellow
}

Write-Host "`n✓ Complete!`n" -ForegroundColor Green
Write-Host "Archive location: $LocalRoot" -ForegroundColor Cyan
