# Security Now! Archive Builder - TEST VERSION
# Episodes 1-5, 500-505, 1000-1005
# Version 2.1 TEST - wkhtmltopdf Method Only - BUGFIX
# Date: January 13, 2026

param(
    [switch]$DryRun,
    [string]$Root = "D:\SecurityNow-Test-wkhtmltopdf"
)

# CONFIGURATION
$LocalRoot = Join-Path $Root "local"
$PdfRoot = Join-Path $LocalRoot "PDF"
$NotesRoot = Join-Path $LocalRoot "Notes"
$Mp3Folder = Join-Path $LocalRoot "mp3"
$AiFolder = Join-Path $NotesRoot "ai-transcripts"
$IndexCsv = Join-Path $Root "SecurityNowNotesIndex.csv"

# Whisper.cpp paths (adjust if needed)
$WhisperExe = "C:\whisper-cli\whisper-cli.exe"
$WhisperModel = "C:\whisper-cli\ggml-base.en.bin"

# TEST: Only process these specific episodes  
$TestEpisodes = @(1..5) + @(500..505) + @(1000..1005)

# GRC base URLs
$BaseNotesRoot = "https://www.grc.com/sn/"
$BaseTwitCdn = "https://cdn.twit.tv/audio/sn/"

# SETUP VALIDATION
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Security Now! TEST Run - wkhtmltopdf" -ForegroundColor Cyan  
Write-Host "Episodes: 1-5, 500-505, 1000-1005" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Create folders
foreach ($path in @($Root, $LocalRoot, $PdfRoot, $NotesRoot, $Mp3Folder, $AiFolder)) {
    if (-not (Test-Path $path)) {
        if ($DryRun) {
            Write-Host "[DRYRUN] Would create: $path"
        } else {
            New-Item -ItemType Directory -Path $path -Force | Out-Null
        }
    }
}

# Validate wkhtmltopdf
if (-not $DryRun) {
    $wkhtmltopdf = Get-Command wkhtmltopdf -ErrorAction SilentlyContinue
    if (-not $wkhtmltopdf) {
        Write-Host "ERROR: wkhtmltopdf not found!" -ForegroundColor Red
        Write-Host "Install: winget install wkhtmltopdf`n" -ForegroundColor Yellow
        exit 1
    }
}

# HELPER FUNCTIONS
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

# STEP 1: DOWNLOAD OFFICIAL GRC PDFs
Write-Host "`nSTEP 1: Downloading official GRC PDFs...`n" -ForegroundColor Cyan

$index = @()
if (Test-Path $IndexCsv) {
    $index = @(Import-Csv $IndexCsv)
}

foreach ($ep in $TestEpisodes) {
    $year = Get-YearFromEpisode -Episode $ep
    $yearFolder = Join-Path $PdfRoot $year
    
    if (-not (Test-Path $yearFolder)) {
        if (-not $DryRun) {
            New-Item -ItemType Directory -Path $yearFolder -Force | Out-Null
        }
    }
    
    $file = "sn-$ep-notes.pdf"
    $url = "$BaseNotesRoot$file"
    $destPath = Join-Path $yearFolder $file
    
    Write-Host "Episode $ep - $url"
    
    if (Test-Path $destPath) {
        Write-Host "  Already exists, skipping." -ForegroundColor Yellow
    } else {
        if ($DryRun) {
            Write-Host "  [DRYRUN] Would download -> $destPath"
        } else {
            try {
                $response = Invoke-WebRequest -Uri $url -Method Head -UseBasicParsing -ErrorAction Stop
                
                if ($response.StatusCode -eq 200) {
                    Invoke-WebRequest -Uri $url -OutFile $destPath -UseBasicParsing -ErrorAction Stop
                    Write-Host "  Downloaded OK" -ForegroundColor Green
                    
                    $existing = $index | Where-Object { [int]$_.Episode -eq $ep -and $_.File -eq $file }
                    if (-not $existing) {
                        $index += [pscustomobject]@{
                            Episode = $ep
                            Url = $url
                            File = $file
                        }
                    }
                } else {
                    Write-Host "  Not found (HTTP $($response.StatusCode))" -ForegroundColor DarkGray
                }
            } catch {
                Write-Host "  Not found or error: $($_.Exception.Message)" -ForegroundColor DarkGray
            }
        }
    }
}

# Save index
if (-not $DryRun -and $index.Count -gt 0) {
    $index | Sort-Object Episode -Unique | Export-Csv $IndexCsv -NoTypeInformation
}

# STEP 2: IDENTIFY MISSING EPISODES  
Write-Host "`nSTEP 2: Identifying missing episodes...`n" -ForegroundColor Cyan

$episodesWithNotes = $index | Where-Object { $_.File -like "sn-*-notes*.pdf" } |
    ForEach-Object { [int]$_.Episode } | Sort-Object -Unique

$missingEpisodes = @($TestEpisodes | Where-Object { $_ -notin $episodesWithNotes })

Write-Host "Missing episodes needing AI transcripts: $($missingEpisodes.Count)" -ForegroundColor Yellow
if ($missingEpisodes.Count -gt 0) {
    Write-Host "Episodes: $($missingEpisodes -join ', ')" -ForegroundColor Gray
}

Write-Host "`n✓ Test complete!`n" -ForegroundColor Green
Write-Host "Archive: $LocalRoot"  
Write-Host "Index: $IndexCsv`n"
