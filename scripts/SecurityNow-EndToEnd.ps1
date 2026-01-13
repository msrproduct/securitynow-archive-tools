<#
.SYNOPSIS
    Security Now! Archive Manager - Complete End-to-End Pipeline
    
.DESCRIPTION
    Downloads official show notes from GRC, generates AI transcripts for missing episodes,
    organizes everything by year, and maintains a comprehensive CSV index.
    
.PARAMETER DoTranscribe
    Run Whisper transcription for missing episodes
    
.PARAMETER DoBuildAIPDFs
    Convert AI transcripts to PDF with disclaimer
    
.PARAMETER DoOrganizeByYear
    Move all PDFs into year-based folders
    
.PARAMETER MaxEpisode
    Maximum episode number to process (default: 1200)
#>

param(
    [switch]$DoTranscribe,
    [switch]$DoBuildAIPDFs,
    [switch]$DoOrganizeByYear,
    [int]$MaxEpisode = 1200
)

# ============================================================================
# CONFIGURATION
# ============================================================================

# Paths - all relative to repo root
$RepoRoot = Split-Path -Parent $PSScriptRoot
$DataFolder = Join-Path $RepoRoot "data"
$LocalRoot = Join-Path $RepoRoot "local"
$PdfRoot = Join-Path $LocalRoot "PDF"
$Mp3Folder = Join-Path $LocalRoot "mp3"
$TranscriptsFolder = Join-Path $LocalRoot "ai-transcripts"

# Index files
$IndexCsvPath = Join-Path $DataFolder "SecurityNowNotesIndex.csv"
$EpisodeDatesPath = Join-Path $DataFolder "episode-dates.csv"

# Whisper configuration (required for AI transcription)
$WhisperExe = "C:\whisper-cli\whisper-cli.exe"
$WhisperModel = "C:\whisper-cli\ggml-base.en.bin"

# wkhtmltopdf configuration (required for PDF generation)
$WkHtmlToPdfExe = "C:\Program Files\wkhtmltopdf\bin\wkhtmltopdf.exe"

# Episodes that require AI transcription (no official GRC PDFs)
$TargetMissingEpisodes = @(1..99) + @(436, 487, 540, 592, 643, 695, 747, 798, 851, 903, 954, 1006, 1058)

# ============================================================================
# INITIALIZE
# ============================================================================

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Security Now! Archive Manager" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Ensure core directories exist
foreach ($path in @($DataFolder, $LocalRoot, $PdfRoot, $Mp3Folder, $TranscriptsFolder)) {
    if (-not (Test-Path $path)) {
        New-Item -ItemType Directory -Path $path -Force | Out-Null
        Write-Host "Created: $path" -ForegroundColor Gray
    }
}

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

function Get-EpisodeYear {
    param([int]$Episode)
    
    # Try episode-dates.csv first (accurate recording dates)
    if ($global:EpisodeDateIndex) {
        $entry = $global:EpisodeDateIndex | Where-Object { [int]$_.Episode -eq $Episode }
        if ($entry) {
            return [int]$entry.Year
        }
    }
    
    # Fallback: Use current/next year for new episodes
    $now = Get-Date
    if ($now.Month -eq 12 -and $now.Day -gt 20) {
        return $now.Year + 1
    }
    return $now.Year
}

function Get-Index {
    param([string]$Path)
    if (Test-Path $Path) {
        return Import-Csv -Path $Path
    }
    return @()
}

function Save-Index {
    param($Index, [string]$Path)
    $Index | Sort-Object Episode, File -Unique | 
        Export-Csv -Path $Path -NoTypeInformation -Encoding UTF8
}

# ============================================================================
# LOAD EPISODE DATE INDEX
# ============================================================================

if (Test-Path $EpisodeDatesPath) {
    $global:EpisodeDateIndex = Import-Csv -Path $EpisodeDatesPath
    Write-Host "✓ Loaded episode dates: $($global:EpisodeDateIndex.Count) entries" -ForegroundColor Green
} else {
    Write-Host "⚠ Warning: episode-dates.csv not found - using fallback year logic" -ForegroundColor Yellow
    Write-Host "  Run Create-EpisodeDateIndex.ps1 first for accurate year mapping" -ForegroundColor Yellow
    $global:EpisodeDateIndex = $null
}

# ============================================================================
# PHASE 1: AI TRANSCRIPTION (Optional)
# ============================================================================

if ($DoTranscribe) {
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "PHASE 1: AI Transcription" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan
    
    if (-not (Test-Path $WhisperExe)) {
        Write-Host "ERROR: whisper-cli not found at $WhisperExe" -ForegroundColor Red
        exit 1
    }
    
    if (-not (Test-Path $WhisperModel)) {
        Write-Host "ERROR: Whisper model not found at $WhisperModel" -ForegroundColor Red
        exit 1
    }
    
    $mp3MapPath = Join-Path $DataFolder "MissingEpisodesMp3Map.csv"
    if (-not (Test-Path $mp3MapPath)) {
        Write-Host "ERROR: MissingEpisodesMp3Map.csv not found" -ForegroundColor Red
        exit 1
    }
    
    $mp3MapAll = Import-Csv -Path $mp3MapPath
    $mp3Map = $mp3MapAll | Where-Object { [int]$_.Episode -in $TargetMissingEpisodes }
    
    foreach ($row in $mp3Map) {
        $ep = [int]$row.Episode
        $mp3Url = $row.Mp3Url
        $mp3File = Join-Path $Mp3Folder "sn-$ep.mp3"
        $txtFile = Join-Path $TranscriptsFolder "sn-$ep-notes-ai.txt"
        $prefix = Join-Path $TranscriptsFolder "sn-$ep-notes-ai"
        
        Write-Host "`nEpisode $ep - transcription" -ForegroundColor Yellow
        
        if (Test-Path $txtFile) {
            Write-Host "  Transcript exists, skipping" -ForegroundColor Gray
            continue
        }
        
        if (-not (Test-Path $mp3File)) {
            Write-Host "  Downloading MP3..." -ForegroundColor Gray
            try {
                Invoke-WebRequest -Uri $mp3Url -OutFile $mp3File -UseBasicParsing -ErrorAction Stop
            } catch {
                Write-Host "  ERROR downloading MP3: $($_.Exception.Message)" -ForegroundColor Red
                continue
            }
        }
        
        Write-Host "  Running Whisper..." -ForegroundColor Gray
        try {
            & $WhisperExe -m $WhisperModel -f $mp3File -otxt -of $prefix
        } catch {
            Write-Host "  ERROR during transcription: $($_.Exception.Message)" -ForegroundColor Red
            continue
        }
        
        if (Test-Path $txtFile) {
            Write-Host "  ✓ Transcript created" -ForegroundColor Green
        } else {
            Write-Host "  ✗ Transcript missing after ASR" -ForegroundColor Red
        }
    }
}

# ============================================================================
# PHASE 2: BUILD AI PDFs (Optional)
# ============================================================================

if ($DoBuildAIPDFs) {
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "PHASE 2: Build AI PDFs" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan
    
    if (-not (Test-Path $WkHtmlToPdfExe)) {
        Write-Host "ERROR: wkhtmltopdf not found at $WkHtmlToPdfExe" -ForegroundColor Red
        Write-Host "Download from: https://wkhtmltopdf.org/downloads.html" -ForegroundColor Yellow
        exit 1
    }
    
    $index = Get-Index -Path $IndexCsvPath
    $txtFiles = Get-ChildItem -Path $TranscriptsFolder -Filter "sn-*-notes-ai.txt" -File
    $newNotes = @()
    
    foreach ($txt in $txtFiles) {
        if ($txt.BaseName -notmatch 'sn-(\d+)-notes-ai') { continue }
        $ep = [int]$Matches[1]
        
        if ($ep -notin $TargetMissingEpisodes) { continue }
        
        $txtFile = $txt.FullName
        $pdfFile = Join-Path $PdfRoot "sn-$ep-notes-ai.pdf"
        
        Write-Host "`nEpisode $ep - AI PDF" -ForegroundColor Yellow
        
        $existing = $index | Where-Object { [int]$_.Episode -eq $ep -and $_.File -eq "sn-$ep-notes-ai.pdf" }
        if ($existing -and (Test-Path $pdfFile)) {
            Write-Host "  PDF exists, skipping" -ForegroundColor Gray
            continue
        }
        
        $htmlFile = Join-Path $TranscriptsFolder "sn-$ep-notes-ai.html"
        $bodyText = Get-Content -LiteralPath $txtFile -Raw
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
            background-color: white;
            color: black;
            margin: 20px;
            white-space: pre-wrap;
        }
        .disclaimer {
            font-weight: bold;
            color: red;
            background-color: white;
            padding: 10px;
            margin-bottom: 20px;
            border: 2px solid red;
        }
    </style>
</head>
<body>
    <div class="disclaimer">
⚠️ THIS IS AN AUTOMATICALLY GENERATED TRANSCRIPT/NOTES FILE CREATED FROM AUDIO.
IT IS NOT AN ORIGINAL STEVE GIBSON SHOW-NOTES DOCUMENT AND MAY CONTAIN ERRORS.
    </div>
    <pre>
$bodyText
    </pre>
</body>
</html>
"@
        
        $htmlContent | Out-File -LiteralPath $htmlFile -Encoding UTF8 -Force
        
        Write-Host "  Converting to PDF..." -ForegroundColor Gray
        try {
            & $WkHtmlToPdfExe --enable-local-file-access --quiet $htmlFile $pdfFile 2>&1 | Out-Null
            Start-Sleep -Seconds 2
        } catch {
            Write-Host "  ERROR during PDF conversion: $($_.Exception.Message)" -ForegroundColor Red
            continue
        }
        
        if (Test-Path $pdfFile) {
            Write-Host "  ✓ PDF created" -ForegroundColor Green
            $newNotes += [pscustomobject]@{
                Episode = $ep
                Url = "generated from audio"
                File = "sn-$ep-notes-ai.pdf"
            }
        } else {
            Write-Host "  ✗ PDF missing after conversion" -ForegroundColor Red
        }
        
        Remove-Item -LiteralPath $htmlFile -Force -ErrorAction SilentlyContinue
    }
    
    if ($newNotes.Count -gt 0) {
        $index = $index + $newNotes
        Save-Index -Index $index -Path $IndexCsvPath
        Write-Host "`n✓ Index updated with $($newNotes.Count) AI PDFs" -ForegroundColor Green
    }
}

# ============================================================================
# PHASE 3: ORGANIZE BY YEAR (Optional)
# ============================================================================

if ($DoOrganizeByYear) {
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "PHASE 3: Organize by Year" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan
    
    # Create year folders
    $years = 2005..2026
    foreach ($year in $years) {
        $yearFolder = Join-Path $PdfRoot $year
        if (-not (Test-Path $yearFolder)) {
            New-Item -ItemType Directory -Path $yearFolder -Force | Out-Null
        }
    }
    
    $allPdfs = Get-ChildItem -Path $PdfRoot -Filter "sn-*-notes*.pdf" -File -Recurse
    
    foreach ($pdf in $allPdfs) {
        # Skip if already in year folder
        if ($pdf.DirectoryName -match '\d{4}$') { continue }
        
        if ($pdf.BaseName -notmatch 'sn-(\d+)') { continue }
        $ep = [int]$Matches[1]
        
        $year = Get-EpisodeYear -Episode $ep
        if ($year -eq 0) {
            Write-Host "⚠ No year mapping for episode $ep" -ForegroundColor Yellow
            continue
        }
        
        $destFolder = Join-Path $PdfRoot $year
        $destPath = Join-Path $destFolder $pdf.Name
        
        Write-Host "Moving episode $ep ($($pdf.Name)) → $year" -ForegroundColor Gray
        Move-Item -LiteralPath $pdf.FullName -Destination $destPath -Force
    }
    
    Write-Host "`n✓ PDFs organized by year" -ForegroundColor Green
}

# ============================================================================
# SUMMARY
# ============================================================================

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Summary" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$indexFinal = Get-Index -Path $IndexCsvPath
if ($indexFinal.Count -gt 0) {
    $allEpisodes = 1..$MaxEpisode
    $haveEpisodes = $indexFinal.Episode | Sort-Object -Unique
    $missingEpisodes = $allEpisodes | Where-Object { $_ -notin $haveEpisodes }
    
    Write-Host "Episodes in index: $($haveEpisodes.Count)" -ForegroundColor Green
    
    if ($missingEpisodes.Count -gt 0) {
        Write-Host "Missing episodes: $($missingEpisodes.Count)" -ForegroundColor Yellow
        Write-Host "First 20: $($missingEpisodes | Select-Object -First 20 -join ', ')" -ForegroundColor Gray
    } else {
        Write-Host "✓ Complete! All episodes 1-$MaxEpisode present" -ForegroundColor Green
    }
} else {
    Write-Host "⚠ WARNING: Index is empty" -ForegroundColor Yellow
}

Write-Host "`nDone!`n" -ForegroundColor Cyan
