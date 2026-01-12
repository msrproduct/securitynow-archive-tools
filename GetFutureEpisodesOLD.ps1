# ============================================
# Script 2: Add a new (future) episode PDF and file it by year
# ============================================
param(
    [Parameter(Mandatory=$true)]
    [int]$Episode
)

$OutputFolder = "C:\SecurityNow\Notes"
$PdfRoot      = "C:\SecurityNow\PDF"
$IndexCsvPath = Join-Path $OutputFolder "SecurityNow_NotesIndex.csv"

if (-not (Test-Path $PdfRoot)) {
    New-Item -ItemType Directory -Path $PdfRoot | Out-Null
}

# Reuse the same episode->year mapping
function Get-SnYearFromEpisode {
param(
    [int]$Episode
)
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

# 1) Determine year and ensure year folder exists
$year = Get-SnYearFromEpisode -Episode $Episode
if ($year -eq 0) {
    Write-Host "ERROR: No year mapping for episode $Episode"
    exit 1
}

$yearFolder = Join-Path $PdfRoot $year
if (-not (Test-Path $yearFolder)) {
    New-Item -ItemType Directory -Path $yearFolder | Out-Null
}

# 2) Decide which PDF to use
$grcPdfUrl = "https://www.grc.com/sn/sn-$Episode.pdf"  # GRC original notes when available
$localPdfName = "sn-$Episode-notes.pdf"
$localPdfPath = Join-Path $PdfRoot $localPdfName

Write-Host "Processing episode $Episode for year $year"

# If PDF already exists anywhere, just file it
$existingInYear = Get-ChildItem -Path $yearFolder -Filter "sn-$Episode-*-notes*.pdf" -File -ErrorAction SilentlyContinue
if ($existingInYear) {
    Write-Host "  Episode $Episode already present in $yearFolder, skipping download."
    $destPath = $existingInYear[0].FullName
} else {
    # Try to download the GRC notes PDF
    Write-Host "  Trying to download GRC notes PDF..."
    try {
        Invoke-WebRequest -Uri $grcPdfUrl -OutFile $localPdfPath -UseBasicParsing -ErrorAction Stop
        Write-Host "  Downloaded $localPdfName"
    }
    catch {
        Write-Host "  Could not download GRC notes PDF for episode $Episode."
        Write-Host "  If you have an AI PDF (sn-$Episode-notes-ai.pdf), place it in $PdfRoot and rerun."
    }

    # Move whatever we downloaded, if present
    if (Test-Path $localPdfPath) {
        $destPath = Join-Path $yearFolder (Split-Path $localPdfPath -Leaf)
        Move-Item -LiteralPath $localPdfPath -Destination $destPath -Force
        Write-Host "  Moved to $destPath"
    } else {
        # Look for existing AI PDF in root
        $aiPdf = Join-Path $PdfRoot "sn-$Episode-notes-ai.pdf"
        if (Test-Path $aiPdf) {
            $destPath = Join-Path $yearFolder (Split-Path $aiPdf -Leaf)
            Move-Item -LiteralPath $aiPdf -Destination $destPath -Force
            Write-Host "  Found AI PDF and moved to $destPath"
        } else {
            Write-Host "  No PDF found for episode $Episode to file."
            exit 0
        }
    }
}

# 3) Update index CSV
if (Test-Path $IndexCsvPath) {
    $index = Import-Csv -Path $IndexCsvPath
} else {
    $index = @()
}

$destFileName = Split-Path $destPath -Leaf

$existingIndexRow = $index | Where-Object { [int]$_.Episode -eq $Episode -and $_.File -eq $destFileName }
if (-not $existingIndexRow) {
    $newRow = [pscustomobject]@{
        Episode = $Episode
        Url     = $grcPdfUrl  # or blank if AI-only
        File    = $destFileName
    }

    $index = $index + $newRow
    $index |
        Sort-Object Episode, File -Unique |
        Export-Csv -Path $IndexCsvPath -NoTypeInformation -Encoding UTF8

    Write-Host "  Index updated for episode $Episode."
} else {
    Write-Host "  Index already has an entry for episode $Episode and $destFileName."
}

Write-Host "Done."
