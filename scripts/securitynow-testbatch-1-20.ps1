<#
.SYNOPSIS
Security Now Batch Test - Episodes 1-20

.DESCRIPTION
Validates the "loophole" workflow for missing PDF episodes:
- Checks GRC for official PDF first
- If missing, downloads MP3 from TWiT CDN
- Uses Whisper to transcribe
- Creates AI-generated PDF with disclaimer
- Updates index with AI-generated flag

This tests the complete workflow for episodes 1-20 before running full 1-120 range.
#>

[CmdletBinding()]
param(
    [switch]$SkipExisting,
    [int]$StartEpisode = 1,
    [int]$EndEpisode = 20
)

# === CONFIGURATION ===
$TestRoot = "D:\desktop\SecurityNow-Test"
$DataFolder = Join-Path $TestRoot "data"
$LocalRoot = Join-Path $TestRoot "local"
$NotesFolder = Join-Path $LocalRoot "Notes"
$PdfRoot = Join-Path $LocalRoot "PDF"
$Mp3Folder = Join-Path $LocalRoot "mp3"
$TranscriptsFolder = Join-Path $NotesFolder "ai-transcripts"
$IndexCsvPath = Join-Path $DataFolder "SecurityNowNotesIndex.csv"

# === TOOLS ===
$AsrCli = "C:\Tools\whispercpp\whisper-cli.exe"
$Model = "C:\Tools\whispercpp\models\ggml-base.en.bin"
$EdgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
$ChromePath = "C:\Program Files\Google\Chrome\Application\chrome.exe"

# === HELPER FUNCTION: Episode to Year ===
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

# === ENSURE DIRECTORIES ===
foreach ($path in $TestRoot, $DataFolder, $LocalRoot, $NotesFolder, $PdfRoot, $Mp3Folder, $TranscriptsFolder) {
    if (-not (Test-Path $path)) {
        New-Item -ItemType Directory -Path $path | Out-Null
    }
}

# === TOOL VALIDATION ===
if (-not (Test-Path $AsrCli)) {
    Write-Host "ERROR: whisper-cli.exe not found at $AsrCli" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $Model)) {
    Write-Host "ERROR: Whisper model not found at $Model" -ForegroundColor Red
    exit 1
}

$PdfTool = $null
if (Test-Path $EdgePath) {
    $PdfTool = $EdgePath
} elseif (Test-Path $ChromePath) {
    $PdfTool = $ChromePath
}

if (-not $PdfTool) {
    Write-Host "ERROR: Edge/Chrome not found for HTML->PDF conversion." -ForegroundColor Red
    exit 1
}

# === LOAD OR INITIALIZE INDEX ===
if (Test-Path $IndexCsvPath) {
    $index = @(Import-Csv -Path $IndexCsvPath)
} else {
    $index = @()
}

# === COUNTERS ===
$stats = @{
    Total = 0
    GrcFound = 0
    GrcDownloaded = 0
    AiGenerated = 0
    Skipped = 0
    Failed = 0
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Security Now Batch Test: Episodes $StartEpisode-$EndEpisode" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# === PROCESS EACH EPISODE ===
for ($ep = $StartEpisode; $ep -le $EndEpisode; $ep++) {
    $stats.Total++
    
    $year = Get-SnYearFromEpisode -Episode $ep
    if ($year -eq 0) {
        Write-Host "Episode $ep : ERROR - No year mapping" -ForegroundColor Red
        $stats.Failed++
        continue
    }
    
    $yearFolder = Join-Path $PdfRoot $year
    if (-not (Test-Path $yearFolder)) {
        New-Item -ItemType Directory -Path $yearFolder | Out-Null
    }
    
    $epPadded = $ep.ToString("D4")
    
    # Check if already processed
    $existingGrc = Join-Path $yearFolder "sn-$ep-notes.pdf"
    $existingAi = Join-Path $yearFolder "sn-$ep-notes-ai.pdf"
    
    if ($SkipExisting -and ((Test-Path $existingGrc) -or (Test-Path $existingAi))) {
        Write-Host "Episode $ep : Skipped (already exists)" -ForegroundColor DarkGray
        $stats.Skipped++
        continue
    }
    
    # === TRY GRC FIRST ===
    $grcUrl = "https://www.grc.com/sn/sn-$ep-notes.pdf"
    $tmpGrcPdf = Join-Path $PdfRoot "sn-$ep-notes.pdf"
    $finalGrcPdf = Join-Path $yearFolder "sn-$ep-notes.pdf"
    
    try {
        $response = Invoke-WebRequest -Uri $grcUrl -Method Head -UseBasicParsing -ErrorAction Stop
        
        if ($response.StatusCode -eq 200) {
            Write-Host "Episode $ep : GRC PDF found, downloading..." -ForegroundColor Green
            Invoke-WebRequest -Uri $grcUrl -OutFile $tmpGrcPdf -UseBasicParsing -ErrorAction Stop
            Move-Item -LiteralPath $tmpGrcPdf -Destination $finalGrcPdf -Force
            
            $stats.GrcDownloaded++
            
            # Add to index
            $existing = $index | Where-Object { $_.Episode -eq $ep }
            if (-not $existing) {
                $index += [PSCustomObject]@{
                    Episode = $ep
                    Year = $year
                    Url = $grcUrl
                    File = "sn-$ep-notes.pdf"
                    Type = "Official GRC"
                }
            }
            
            continue
        }
    } catch {
        # GRC PDF not found - proceed to AI generation
        $stats.GrcFound++
    }
    
    # === AI GENERATION PATH ===
    Write-Host "Episode $ep : No GRC PDF, generating AI transcript..." -ForegroundColor Yellow
    
    $mp3Url = "https://cdn.twit.tv/audio/sn/sn$epPadded/sn$epPadded.mp3"
    $mp3File = Join-Path $Mp3Folder "sn-$ep.mp3"
    $txtFile = Join-Path $TranscriptsFolder "sn-$ep-notes-ai.txt"
    $txtPrefix = Join-Path $TranscriptsFolder "sn-$ep-notes-ai"
    $htmlFile = Join-Path $TranscriptsFolder "sn-$ep-notes-ai.html"
    $aiPdf = Join-Path $PdfRoot "sn-$ep-notes-ai.pdf"
    $finalAiPdf = Join-Path $yearFolder "sn-$ep-notes-ai.pdf"
    
    # Download MP3
    if (-not (Test-Path $mp3File)) {
        try {
            Write-Host "  → Downloading MP3 from TWiT..." -ForegroundColor Gray
            Invoke-WebRequest -Uri $mp3Url -OutFile $mp3File -UseBasicParsing -ErrorAction Stop
        } catch {
            Write-Host "  → ERROR downloading MP3: $($_.Exception.Message)" -ForegroundColor Red
            $stats.Failed++
            continue
        }
    }
    
    # Run Whisper
    if (-not (Test-Path $txtFile)) {
        Write-Host "  → Running Whisper transcription..." -ForegroundColor Gray
        try {
            & $AsrCli -m $Model -f $mp3File -otxt -of $txtPrefix 2>&1 | Out-Null
        } catch {
            Write-Host "  → ERROR during transcription: $($_.Exception.Message)" -ForegroundColor Red
            $stats.Failed++
            continue
        }
    }
    
    if (-not (Test-Path $txtFile)) {
        Write-Host "  → ERROR: Transcript not created" -ForegroundColor Red
        $stats.Failed++
        continue
    }
    
    # Create AI PDF with disclaimer
    $bodyText = Get-Content -LiteralPath $txtFile -Raw
    $episodeTitle = "Security Now! Episode $ep - AI-Derived Transcript"
    
    $htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>$episodeTitle</title>
    <style>
        body { font-family: Arial, sans-serif; white-space: pre-wrap; margin: 2em; }
        .disclaimer { 
            font-weight: bold; 
            color: red; 
            border: 3px solid red; 
            padding: 1em; 
            margin-bottom: 2em; 
            background-color: #fff3cd;
        }
    </style>
</head>
<body>
    <div class="disclaimer">
        ⚠️ AI-GENERATED TRANSCRIPT ⚠️<br><br>
        This document was automatically generated using speech-to-text AI from the Security Now! audio.<br>
        It is NOT an official Steve Gibson show notes document.<br>
        It may contain transcription errors and should be considered a convenience reference only.<br><br>
        For official content, visit: https://www.grc.com/securitynow.htm
    </div>
    <h2>$episodeTitle</h2>
    <pre>$bodyText</pre>
</body>
</html>
"@
    
    $htmlContent | Out-File -LiteralPath $htmlFile -Encoding UTF8 -Force
    
    try {
        Write-Host "  → Converting to PDF..." -ForegroundColor Gray
        & $PdfTool --headless --disable-gpu "--print-to-pdf=$aiPdf" $htmlFile 2>&1 | Out-Null
        Start-Sleep -Seconds 2
    } catch {
        Write-Host "  → ERROR during PDF conversion: $($_.Exception.Message)" -ForegroundColor Red
        $stats.Failed++
        continue
    }
    
    if (Test-Path $aiPdf) {
        Move-Item -LiteralPath $aiPdf -Destination $finalAiPdf -Force
        Write-Host "  → AI PDF created: $finalAiPdf" -ForegroundColor Green
        
        $stats.AiGenerated++
        
        # Add to index
        $existing = $index | Where-Object { $_.Episode -eq $ep }
        if (-not $existing) {
            $index += [PSCustomObject]@{
                Episode = $ep
                Year = $year
                Url = "AI-generated from TWiT MP3"
                File = "sn-$ep-notes-ai.pdf"
                Type = "AI-Generated"
            }
        }
        
        # Cleanup HTML
        Remove-Item -LiteralPath $htmlFile -Force -ErrorAction SilentlyContinue
    } else {
        Write-Host "  → ERROR: PDF not created" -ForegroundColor Red
        $stats.Failed++
    }
}

# === SAVE INDEX ===
$index | Sort-Object Episode -Unique | Export-Csv -Path $IndexCsvPath -NoTypeInformation -Encoding UTF8

# === SUMMARY ===
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "BATCH TEST COMPLETE" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Total Episodes Processed: $($stats.Total)" -ForegroundColor White
Write-Host "  GRC PDFs Downloaded:      $($stats.GrcDownloaded)" -ForegroundColor Green
Write-Host "  AI PDFs Generated:        $($stats.AiGenerated)" -ForegroundColor Yellow
Write-Host "  Skipped (existing):       $($stats.Skipped)" -ForegroundColor Gray
Write-Host "  Failed:                   $($stats.Failed)" -ForegroundColor Red
Write-Host ""
Write-Host "  Index CSV: $IndexCsvPath" -ForegroundColor Cyan
Write-Host "  PDF Root:  $PdfRoot" -ForegroundColor Cyan
Write-Host ""
