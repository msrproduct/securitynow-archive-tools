param(
    [switch]$VerboseTest  # optional extra logging
)

# ============================================
# TEST RUN CONFIG
# ============================================
$TestRoot         = "D:\TestRun"
$DataFolder       = Join-Path $TestRoot "data"
$LocalRoot        = Join-Path $TestRoot "local"
$NotesFolder      = Join-Path $LocalRoot "Notes"
$PdfRoot          = Join-Path $LocalRoot "PDF"
$Mp3Folder        = Join-Path $LocalRoot "mp3"
$TranscriptsFolder= Join-Path $NotesFolder "ai-transcripts"

$IndexCsvPath     = Join-Path $DataFolder "SecurityNow_NotesIndex.csv"

# Known-good episodes for the test
$GrcEpisode       = 1000   # has official notes PDF on GRC
$AiEpisode        = 1      # in your AI-missing list

# MP3 URL for episode 1 (from your earlier MissingEpisodesMp3Map.csv)
# You can adjust this if needed.
$AiEpisode1Mp3Url = "https://cdn.twit.tv/audio/sn/sn0001/sn0001.mp3"

# Tools
$AsrCli  = "C:\Tools\whispercpp\whisper-cli.exe"
$Model   = "C:\Tools\whispercpp\models\ggml-base.en.bin"
$EdgePath   = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
$ChromePath = "C:\Program Files\Google\Chrome\Application\chrome.exe"

# ============================================
# Helper: episode -> year mapping
# ============================================
function Get-SnYearFromEpisode {
param([int]$Episode)
    switch ($Episode) {
        { $_ -ge 1   -and $_ -le 20  } { return 2005 }
        { $_ -ge 21  -and $_ -le 72  } { return 2006 }
        { $_ -ge 73  -and $_ -le 124 } { return 2007 }
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
        { $_ -ge 1061 }                { return 2026 }
        default { return 0 }
    }
}

# ============================================
# Ensure test folders exist
# ============================================
foreach ($path in @($TestRoot, $DataFolder, $LocalRoot, $NotesFolder, $PdfRoot, $Mp3Folder, $TranscriptsFolder)) {
    if (-not (Test-Path $path)) {
        New-Item -ItemType Directory -Path $path | Out-Null
        if ($VerboseTest) { Write-Host "Created: $path" }
    }
}

# Initialize a fresh index for the test
$index = @()

# Detect PDF tool
$PdfTool = $null
if (Test-Path $EdgePath)      { $PdfTool = $EdgePath }
elseif (Test-Path $ChromePath){ $PdfTool = $ChromePath }

if (-not $PdfTool) {
    Write-Host "ERROR: Edge/Chrome not found on this system for HTML->PDF."
    exit 1
}

# ============================================
# TEST 1: Pull episode 1000 PDF from GRC
# ============================================
Write-Host ""
Write-Host "=== TEST 1: GRC PDF for episode $GrcEpisode ==="

$year = Get-SnYearFromEpisode -Episode $GrcEpisode
if ($year -eq 0) {
    Write-Host "  ERROR: No year mapping for episode $GrcEpisode."
} else {
    $yearFolder = Join-Path $PdfRoot $year
    if (-not (Test-Path $yearFolder)) {
        New-Item -ItemType Directory -Path $yearFolder | Out-Null
    }

    $grcPdfUrl = "https://www.grc.com/sn/sn-$GrcEpisode-notes.pdf"
    $tmpPdf    = Join-Path $PdfRoot "sn-$GrcEpisode-notes.pdf"
    $destPdf   = Join-Path $yearFolder "sn-$GrcEpisode-notes.pdf"

    Write-Host "  Downloading GRC notes PDF from $grcPdfUrl"
    try {
        Invoke-WebRequest -Uri $grcPdfUrl -OutFile $tmpPdf -UseBasicParsing -ErrorAction Stop
        Write-Host "  Downloaded to $tmpPdf"
        Move-Item -LiteralPath $tmpPdf -Destination $destPdf -Force
        Write-Host "  Moved to $destPdf"

        $index += [pscustomobject]@{
            Episode = $GrcEpisode
            Url     = $grcPdfUrl
            File    = "sn-$GrcEpisode-notes.pdf"
        }
    }
    catch {
        Write-Host "  ERROR downloading GRC PDF: $($_.Exception.Message)"
    }
}

# ============================================
# TEST 2: AI-derived PDF for missing episode 1
# ============================================
Write-Host ""
Write-Host "=== TEST 2: AI-derived PDF for episode $AiEpisode ==="

if (-not (Test-Path $AsrCli)) {
    Write-Host "  ERROR: whisper-cli.exe not found at $AsrCli"
} elseif (-not (Test-Path $Model)) {
    Write-Host "  ERROR: Whisper model not found at $Model"
} else {
    $year2 = Get-SnYearFromEpisode -Episode $AiEpisode
    if ($year2 -eq 0) {
        Write-Host "  ERROR: No year mapping for episode $AiEpisode."
    } else {
        $yearFolder2 = Join-Path $PdfRoot $year2
        if (-not (Test-Path $yearFolder2)) {
            New-Item -ItemType Directory -Path $yearFolder2 | Out-Null
        }

        $mp3File = Join-Path $Mp3Folder "sn-$AiEpisode.mp3"
        $txtFile = Join-Path $TranscriptsFolder "sn-$AiEpisode-notes-ai.txt"
        $prefix  = Join-Path $TranscriptsFolder "sn-$AiEpisode-notes-ai"
        $aiPdf   = Join-Path $PdfRoot "sn-$AiEpisode-notes-ai.pdf"

        # 2.1 Download MP3
        if (-not (Test-Path $mp3File)) {
            Write-Host "  Downloading MP3 for episode $AiEpisode..."
            try {
                Invoke-WebRequest -Uri $AiEpisode1Mp3Url -OutFile $mp3File -UseBasicParsing -ErrorAction Stop
                Write-Host "  MP3 downloaded: $mp3File"
            }
            catch {
                Write-Host "  ERROR downloading MP3: $($_.Exception.Message)"
            }
        } else {
            Write-Host "  MP3 already exists: $mp3File"
        }

        # 2.2 Run whisper-cli
        if (Test-Path $mp3File -and -not (Test-Path $txtFile)) {
            Write-Host "  Running whisper-cli..."
            try {
                & $AsrCli -m $Model -f $mp3File -otxt -of $prefix
            }
            catch {
                Write-Host "  ERROR during ASR: $($_.Exception.Message)"
            }
        }

        if (Test-Path $txtFile) {
            Write-Host "  Transcript created: $txtFile"

            # 2.3 Build AI PDF with disclaimer
            if (-not $PdfTool) {
                Write-Host "  ERROR: No PDF-capable browser found."
            } else {
                $htmlFile = Join-Path $TranscriptsFolder "sn-$AiEpisode-notes-ai.html"
                $bodyText = Get-Content -LiteralPath $txtFile -Raw
                $episodeTitle = "Security Now! Episode $AiEpisode - AI-Derived Transcript"

                $htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8" />
    <title>$episodeTitle</title>
    <style>
        body { font-family: Arial, sans-serif; white-space: pre-wrap; }
        .disclaimer {
            font-weight: bold;
            color: red;
            margin-bottom: 1em;
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

                $htmlContent | Out-File -LiteralPath $htmlFile -Encoding UTF8 -Force

                Write-Host "  Converting AI transcript HTML to PDF..."
                try {
                    & $PdfTool --headless --disable-gpu --print-to-pdf="$aiPdf" "$htmlFile" 2>&1 | Out-Null
                    Start-Sleep -Seconds 2
                }
                catch {
                    Write-Host "  ERROR during AI PDF conversion: $($_.Exception.Message)"
                }

                if (Test-Path $aiPdf) {
                    $destAiPdf = Join-Path $yearFolder2 (Split-Path $aiPdf -Leaf)
                    Move-Item -LiteralPath $aiPdf -Destination $destAiPdf -Force
                    Write-Host "  AI PDF created and filed: $destAiPdf"

                    $index += [pscustomobject]@{
                        Episode = $AiEpisode
                        Url     = ""  # locally generated AI
                        File    = (Split-Path $destAiPdf -Leaf)
                    }
                } else {
                    Write-Host "  AI PDF missing after conversion."
                }

                Remove-Item -LiteralPath $htmlFile -Force -ErrorAction SilentlyContinue
            }
        } else {
            Write-Host "  Transcript for episode $AiEpisode not found; skipping AI PDF."
        }
    }
}

# ============================================
# Save test index and summarize
# ============================================
if ($index.Count -gt 0) {
    $index |
        Sort-Object Episode, File -Unique |
        Export-Csv -Path $IndexCsvPath -NoTypeInformation -Encoding UTF8

    Write-Host ""
    Write-Host "Test index written to: $IndexCsvPath"
} else {
    Write-Host ""
    Write-Host "No index rows created during test."
}

Write-Host ""
Write-Host "=== TEST RUN SUMMARY ==="
Write-Host "Root:    $TestRoot"
Write-Host "PDFs:    $PdfRoot"
Write-Host "MP3s:    $Mp3Folder"
Write-Host "AI TXT:  $TranscriptsFolder"
Write-Host "Index:   $IndexCsvPath"
