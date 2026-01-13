param(
    [switch] $DryRun,
    [int]    $MinEpisode = 1   # lower episodes are ignored for download/AI
)

# ============================================
# Security Now - Full Notes + AI Builder (with DryRun + MinEpisode)
# Root: D:\Desktop\SecurityNow-Full\
# ============================================

# --------- CONFIG: ROOT & TOOLS ---------

$Root      = "D:\Desktop\SecurityNow-Full"
$LocalRoot = Join-Path $Root "local"

$PdfRoot   = Join-Path $LocalRoot "PDF"
$NotesRoot = Join-Path $LocalRoot "Notes"
$Mp3Folder = Join-Path $LocalRoot "mp3"
$AiFolder  = Join-Path $NotesRoot "ai-transcripts"

$IndexCsv  = Join-Path $Root "SecurityNow_NotesIndex.csv"
$EpisodeDatesCsv = Join-Path $Root "episode-dates.csv"  # NEW: Date index file

$WhisperExe   = "C:\Tools\whispercpp\whisper-cli.exe"
$WhisperModel = "C:\Tools\whispercpp\models\ggml-base.en.bin"

$EdgePath   = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
$ChromePath = "C:\Program Files\Google\Chrome\Application\chrome.exe"

$StartYear = 2005
$EndYear   = 2025

# --------- ENSURE ROOT & FOLDERS ---------

if (-not (Test-Path -LiteralPath $Root)) {
    if ($DryRun) {
        Write-Host "DRYRUN: Would create folder: $Root"
    } else {
        New-Item -ItemType Directory -Path $Root | Out-Null
    }
}
Set-Location $Root

foreach ($path in @($Root, $LocalRoot, $PdfRoot, $NotesRoot, $Mp3Folder, $AiFolder)) {
    if (-not (Test-Path -LiteralPath $path)) {
        if ($DryRun) {
            Write-Host "DRYRUN: Would create folder: $path"
        } else {
            New-Item -ItemType Directory -Path $path | Out-Null
        }
    }
}

# --------- BASIC SANITY: TOOLS ---------

if (-not $DryRun) {
    if (-not (Test-Path -LiteralPath $WhisperExe)) {
        Write-Host "ERROR: whisper-cli.exe not found at: $WhisperExe" -ForegroundColor Red
        exit 1
    }
    if (-not (Test-Path -LiteralPath $WhisperModel)) {
        Write-Host "ERROR: Whisper model not found at: $WhisperModel" -ForegroundColor Red
        exit 1
    }
}

$PdfTool = $null
if (Test-Path -LiteralPath $EdgePath) {
    $PdfTool = $EdgePath
} elseif (Test-Path -LiteralPath $ChromePath) {
    $PdfTool = $ChromePath
} else {
    if (-not $DryRun) {
        Write-Host "ERROR: Neither Edge nor Chrome found for HTML->PDF." -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "=== Security Now Full Run ==="
Write-Host "Root:       $Root"
Write-Host "LocalRoot:  $LocalRoot"
Write-Host "DryRun:     $DryRun"
Write-Host "MinEpisode: $MinEpisode"
if (-not $DryRun) {
    Write-Host "Whisper:    $WhisperExe"
    Write-Host "Model:      $WhisperModel"
    Write-Host "PDF tool:   $PdfTool"
}
Write-Host ""

# ============================================
# LOAD EPISODE DATE INDEX
# ============================================

$global:EpisodeDateIndex = @()

if (Test-Path -LiteralPath $EpisodeDatesCsv) {
    $global:EpisodeDateIndex = Import-Csv -Path $EpisodeDatesCsv
    Write-Host "✓ Loaded episode-dates.csv: $($global:EpisodeDateIndex.Count) episodes" -ForegroundColor Green
    Write-Host ""
} else {
    Write-Host "ERROR: episode-dates.csv not found at: $EpisodeDatesCsv" -ForegroundColor Red
    Write-Host "This file is REQUIRED for accurate year folder assignment." -ForegroundColor Red
    Write-Host "Please ensure episode-dates.csv exists before running." -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

# --------- Helper: archive URLs ---------

function Get-ArchiveUrls {
    $urls = @("https://www.grc.com/securitynow.htm")
    for ($y = $StartYear; $y -le $EndYear; $y++) {
        $urls += "https://www.grc.com/sn/past/$y.htm"
    }
    return $urls
}

# --------- Helper: year from episode (UPDATED TO USE episode-dates.csv) ---------

function Get-YearFromEpisode {
    param([int]$Episode)
    
    # Look up episode in date index
    $entry = $global:EpisodeDateIndex | Where-Object { [int]$_.Episode -eq $Episode }
    
    if ($entry) {
        return [int]$entry.Year
    }
    
    # Episode not in index - cannot determine year
    Write-Host "  WARNING: Episode $Episode not found in episode-dates.csv" -ForegroundColor Yellow
    return $null
}

# --------- Helper: find MP3 URL ---------

function Get-Mp3UrlForEpisode {
param([int]$Episode)

    $grcPage  = "https://www.grc.com/sn/sn-$Episode.htm"
    $twitPage = "https://twit.tv/shows/security-now/episodes/$Episode"

    $mp3Url = $null

    Write-Host ""
    Write-Host ("Episode {0}: trying to locate MP3" -f $Episode)

    try {
        $p = Invoke-WebRequest -Uri $grcPage -UseBasicParsing -ErrorAction Stop
        $link = $p.Links | Where-Object { $_.href -match '\.mp3$' } | Select-Object -First 1
        if ($link) { $mp3Url = $link.href }
    } catch {
        Write-Host "  GRC page not available or no MP3 link; trying TWiT..." -ForegroundColor DarkYellow
    }

    if (-not $mp3Url) {
        try {
            $t = Invoke-WebRequest -Uri $twitPage -UseBasicParsing -ErrorAction Stop
            $link = $t.Links | Where-Object { $_.href -match '\.mp3$' } | Select-Object -First 1
            if ($link) { $mp3Url = $link.href }
        } catch {
            Write-Host "  TWiT page not available or no MP3 link." -ForegroundColor DarkYellow
        }
    }

    if ($mp3Url) {
        Write-Host "  Found MP3: $mp3Url" -ForegroundColor Green
    } else {
        Write-Host "  No MP3 URL could be located." -ForegroundColor Yellow
    }

    return $mp3Url
}

# --------- Load or init index ---------

if (Test-Path -LiteralPath $IndexCsv) {
    $index = Import-Csv -Path $IndexCsv
} else {
    $index = @()
}

function Save-MainIndex {
param([array]$Index)
    if ($DryRun) {
        Write-Host "DRYRUN: Would update index CSV with $($Index.Count) rows -> $IndexCsv"
        return
    }
    $Index |
        Sort-Object Episode, File -Unique |
        Export-Csv -Path $IndexCsv -NoTypeInformation -Encoding UTF8
}

# ============================================
# STEP 1: Discover GRC notes PDFs
# ============================================

Write-Host ""
Write-Host "STEP 1: Discovering GRC notes PDFs..." -ForegroundColor Cyan

$BaseNotesRoot = "https://www.grc.com/sn/"
$ArchiveUrls = Get-ArchiveUrls
$allNoteLinks = @()

foreach ($archiveUrl in $ArchiveUrls) {
    Write-Host ""
    Write-Host "Scanning archive page: $archiveUrl"
    try {
        $page = Invoke-WebRequest -Uri $archiveUrl -UseBasicParsing -ErrorAction Stop
    } catch {
        Write-Host "  ERROR fetching $archiveUrl : $($_.Exception.Message)" -ForegroundColor Red
        continue
    }

    $html = $page.Content
    $matches = [regex]::Matches($html, "sn-([0-9]+)-notes\.pdf", "IgnoreCase")

    if ($matches.Count -eq 0) {
        Write-Host "  No notes links found on this page."
        continue
    }

    Write-Host ("  Found {0} notes references." -f $matches.Count)

    foreach ($m in $matches) {
        $filePart = $m.Value

        if ($filePart -like "http*") {
            $fullUrl = $filePart
        } else {
            $fullUrl = $BaseNotesRoot + $filePart
        }

        $epMatch = [regex]::Match($filePart, "sn-([0-9]+)-notes\.pdf", "IgnoreCase")
        if (-not $epMatch.Success) { continue }

        $epNum = [int]$epMatch.Groups[1].Value

        if ($epNum -lt $MinEpisode) { continue }

        $allNoteLinks += [pscustomobject]@{
            Episode = $epNum
            Url     = $fullUrl
            File    = $filePart
        }
    }
}

$uniqueNotes = $allNoteLinks | Sort-Object Episode, Url -Unique

Write-Host ""
Write-Host "Total unique notes PDFs discovered on GRC (Episode >= $MinEpisode): $($uniqueNotes.Count)"
Write-Host ""

# ============================================
# STEP 2: Processing GRC notes PDFs
# ============================================

Write-Host "STEP 2: Processing GRC notes PDFs..." -ForegroundColor Cyan

$idx = 0
foreach ($note in $uniqueNotes) {
    $idx++
    $ep   = [int]$note.Episode
    $url  = $note.Url
    $file = $note.File

    $year = Get-YearFromEpisode -Episode $ep
    
    if ($null -eq $year) {
        Write-Host "  Skipping episode $ep - no year information available" -ForegroundColor Red
        continue
    }
    
    $yearFolder = Join-Path $PdfRoot $year
    if (-not (Test-Path -LiteralPath $yearFolder)) {
        if ($DryRun) {
            Write-Host "DRYRUN: Would create year folder: $yearFolder"
        } else {
            New-Item -ItemType Directory -Path $yearFolder | Out-Null
        }
    }

    $destPath = Join-Path $yearFolder $file

    Write-Host ("{0}/{1} Episode {2} - {3}" -f $idx, $uniqueNotes.Count, $ep, $url)

    if (Test-Path -LiteralPath $destPath) {
        Write-Host "  Already exists locally, skipping download." -ForegroundColor Yellow
    } else {
        if ($DryRun) {
            Write-Host "DRYRUN: Would download $url -> $destPath"
        } else {
            try {
                Invoke-WebRequest -Uri $url -OutFile $destPath -UseBasicParsing -ErrorAction Stop
                Write-Host "  Downloaded OK -> $destPath" -ForegroundColor Green
            } catch {
                Write-Host "  Download error: $($_.Exception.Message)" -ForegroundColor DarkGray
                continue
            }
        }
    }

    $existing = $index | Where-Object { ([int]$_.Episode -eq $ep) -and ($_.File -eq $file) }
    if (-not $existing) {
        $index += [pscustomobject]@{
            Episode = $ep
            Url     = $url
            File    = $file
        }
        Save-MainIndex -Index $index
    }
}

# ============================================
# STEP 3: Computing missing notes episodes
# ============================================

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
$allEpisodesRange = $MinRange..$MaxFound

$episodesWithAnyNotes = $index |
    Where-Object { ($_.File -like "sn-*-notes.pdf" -or $_.File -like "sn-*-notes-ai.pdf") -and ([int]$_.Episode -ge $MinEpisode) } |
    ForEach-Object { $_.Episode } |
    Sort-Object -Unique

$missingEpisodes = $allEpisodesRange | Where-Object { $_ -notin $episodesWithAnyNotes }

Write-Host "Episode range considered: $MinRange .. $MaxFound"
Write-Host ("Episodes already covered by notes (>= $MinEpisode): {0}" -f ($episodesWithAnyNotes -join ", "))
Write-Host ("Episodes missing notes (candidate for AI): {0}" -f ($missingEpisodes -join ", "))
Write-Host ""

# ============================================
# STEP 4: Building AI notes for missing episodes where MP3 is available
# ============================================

Write-Host "STEP 4: Building AI notes for missing episodes where MP3 is available..." -ForegroundColor Cyan

foreach ($ep in $missingEpisodes) {
    Write-Host ""
    Write-Host ("--- Episode {0}: AI pipeline ---" -f $ep) -ForegroundColor Cyan

    $year = Get-YearFromEpisode -Episode $ep
    
    if ($null -eq $year) {
        Write-Host "  Skipping episode $ep - no year information available" -ForegroundColor Red
        continue
    }
    
    $yearFolder = Join-Path $PdfRoot $year
    if (-not (Test-Path -LiteralPath $yearFolder)) {
        if ($DryRun) {
            Write-Host "DRYRUN: Would create year folder: $yearFolder"
        } else {
            New-Item -ItemType Directory -Path $yearFolder | Out-Null
        }
    }

    $mp3Path   = Join-Path $Mp3Folder "sn-$ep.mp3"
    $txtPrefix = Join-Path $AiFolder "sn-$ep-notes-ai"
    $txtPath   = "$txtPrefix.txt"
    $htmlPath  = Join-Path $AiFolder "sn-$ep-notes-ai.html"
    $pdfPath   = Join-Path $PdfRoot "sn-$ep-notes-ai.pdf"
    $finalPdf  = Join-Path $yearFolder "sn-$ep-notes-ai.pdf"

    $alreadyAi = $index | Where-Object { ([int]$_.Episode -eq $ep) -and ($_.File -eq "sn-$ep-notes-ai.pdf") }
    if ($alreadyAi -and (Test-Path -LiteralPath $finalPdf)) {
        Write-Host "  AI notes already present for episode $ep, skipping." -ForegroundColor Yellow
        continue
    }

    $mp3Url = Get-Mp3UrlForEpisode -Episode $ep
    if (-not $mp3Url) {
        Write-Host "  Skipping episode $ep: no MP3 source found." -ForegroundColor Yellow
        continue
    }

    $haveMp3 = $false
    if (-not (Test-Path -LiteralPath $mp3Path)) {
        if ($DryRun) {
            Write-Host "DRYRUN: Would download MP3: $mp3Url -> $mp3Path"
            $haveMp3 = $true
        } else {
            Write-Host "  Downloading MP3 to $mp3Path"
            try {
                Invoke-WebRequest -Uri $mp3Url -OutFile $mp3Path -UseBasicParsing -ErrorAction Stop
                Write-Host "  MP3 downloaded." -ForegroundColor Green
                $haveMp3 = $true
            } catch {
                Write-Host "  ERROR downloading MP3 for episode $ep : $($_.Exception.Message)" -ForegroundColor Red
                $haveMp3 = $false
            }
        }
    } else {
        Write-Host "  MP3 already present at $mp3Path"
        $haveMp3 = $true
    }

    if (-not $haveMp3) {
        Write-Host "  Skipping episode $ep: MP3 not available." -ForegroundColor Yellow
        continue
    }

    if (-not (Test-Path -LiteralPath $txtPath)) {
        if ($DryRun) {
            Write-Host "DRYRUN: Would run whisper-cli to create transcript: $txtPath"
        } else {
            Write-Host "  Running whisper-cli to create transcript..."
            try {
                & $WhisperExe -m $WhisperModel -f $mp3Path -otxt -of $txtPrefix
            } catch {
                Write-Host "  ERROR running whisper-cli for episode $ep : $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    } else {
        Write-Host "  Transcript already exists at $txtPath"
    }

    if ((-not (Test-Path -LiteralPath $txtPath)) -and (-not $DryRun)) {
        Write-Host "  Transcript file was not created, skipping AI PDF step for episode $ep." -ForegroundColor Yellow
        continue
    }

    if ($DryRun) {
        Write-Host "DRYRUN: Would read transcript from $txtPath and wrap into HTML/PDF"
        $index += [pscustomobject]@{
            Episode = $ep
            Url     = $mp3Url
            File    = "sn-$ep-notes-ai.pdf"
        }
        Save-MainIndex -Index $index
        continue
    }

    Write-Host "  Transcript OK: $txtPath" -ForegroundColor Green

    $bodyText = Get-Content -LiteralPath $txtPath -Raw
    $episodeTitle = "Security Now! Episode $ep - AI-Derived Transcript"

    $htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
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
    <pre>$bodyText</pre>
</body>
</html>
"@

    $htmlContent | Out-File -LiteralPath $htmlPath -Encoding UTF8 -Force
    Write-Host "  HTML wrapper created: $htmlPath"

    Write-Host "  Converting HTML to PDF..."
    try {
        & $PdfTool --headless --disable-gpu --print-to-pdf="$pdfPath" "$htmlPath" 2>&1 | Out-Null
        Start-Sleep -Seconds 2
    } catch {
        Write-Host "  ERROR during HTML->PDF conversion for episode $ep : $($_.Exception.Message)" -ForegroundColor Red
    }

    if (Test-Path -LiteralPath $pdfPath) {
        Write-Host "  AI-derived PDF created: $pdfPath" -ForegroundColor Green
        Move-Item -LiteralPath $pdfPath -Destination $finalPdf -Force
        Write-Host "  Filed under year folder: $finalPdf" -ForegroundColor Green

        $index += [pscustomobject]@{
            Episode = $ep
            Url     = $mp3Url
            File    = "sn-$ep-notes-ai.pdf"
        }
        Save-MainIndex -Index $index
    } else {
        Write-Host "  PDF file not found after conversion; no AI PDF indexed for episode $ep." -ForegroundColor Yellow
    }

    Remove-Item -LiteralPath $htmlPath -Force -ErrorAction SilentlyContinue
}

# ============================================
# DONE
# ============================================

Write-Host ""
Write-Host "Full run complete!" -ForegroundColor Green
Write-Host "Index CSV: $IndexCsv"
Write-Host ""
Write-Host "Sample of final index (first 20 rows):"
if (Test-Path -LiteralPath $IndexCsv) {
    Import-Csv -Path $IndexCsv |
        Sort-Object { [int]$_.Episode } |
        Select-Object -First 20 |
        Format-Table
} else {
    Write-Host "No index file found."
}
