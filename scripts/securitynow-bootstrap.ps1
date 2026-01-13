param(
    [string]$PublicRoot  = "D:\Desktop\SecurityNow-Full",
    [string]$PrivateRoot = "D:\Desktop\SecurityNow-Full-Private"
)

Write-Host "Security Now – Bootstrap public & private folders" -ForegroundColor Cyan

# 0. Ensure both roots exist (folders only at D:\Desktop\)
foreach ($path in @($PublicRoot, $PrivateRoot)) {
    if (-not (Test-Path -LiteralPath $path)) {
        New-Item -ItemType Directory -Path $path -Force | Out-Null
    }
}

# 1. Public repo structure (tools + index only)
$pubData    = Join-Path $PublicRoot "data"
$pubScripts = Join-Path $PublicRoot "scripts"
$pubDocs    = Join-Path $PublicRoot "docs"

foreach ($path in @($pubData, $pubScripts, $pubDocs)) {
    if (-not (Test-Path -LiteralPath $path)) {
        New-Item -ItemType Directory -Path $path -Force | Out-Null
    }
}

# .gitignore – keep media out of public repo
$gitIgnoreContent = @"
# Public repo: tools and index only
# Never commit local media or archives here

local/
*.mp3
sn-*-notes.pdf
sn-*-notes-ai.pdf
sn-*-transcript.*
*.zip
"@

$gitIgnorePath = Join-Path $PublicRoot ".gitignore"
$gitIgnoreContent | Out-File -LiteralPath $gitIgnorePath -Encoding UTF8 -Force

# README.md – public tools/index explanation
$readmeContent = @"
# Security Now! Tools & Index

This repository contains tooling and index data to help researchers and fans work with Steve Gibson's **Security** Now! podcast episodes.[file:1]

## What this repo contains

- PowerShell scripts to:
  - Discover official show-notes PDFs (\`sn-XXXX-notes.pdf\`) on Gibson Research Corporation (GRC).[file:1]
  - Detect episodes with no official notes and (optionally) generate clearly marked AI-derived notes locally.
  - Organize local notes PDFs by year.
  - Maintain a CSV index of all episodes and their associated notes files.

- A CSV index under \`data\` (for example \`SecurityNowNotesIndex.csv\`) with:
  - Episode number
  - Title (when available)
  - Original show-notes URL on GRC and TWiT.tv
  - Local file name (on **your** system)
  - Flags indicating whether AI-derived notes exist locally.[file:1]

## What this repo does NOT contain

This public repository does **not** contain:

- Original Security Now! show-notes PDFs from GRC (\`sn-XXXX-notes.pdf\`).[file:1]
- TWiT.tv transcripts or audio files (MP3s).
- Any copyrighted content from GRC or TWiT.tv.

Instead, it provides tools and an index so that you can obtain that material yourself from the official sources and keep it in a separate private archive.[file:1]

## Respecting Steve Gibson and TWiT

All Security Now! content is authored and owned by Steve Gibson / Gibson Research Corporation and published in cooperation with TWiT.tv.[file:1]
This project exists to assist with personal research and archival and to avoid making others re-implement the same tooling.

Any AI-derived notes workflow is intended only to fill gaps for episodes which never had official show notes, and generated files must always be clearly labeled as automatically generated and **not** official show notes.[file:1]

## High-level workflow

1. Clone this repo locally.
2. Place the end-to-end PowerShell script into \`scripts\SecurityNow-EndToEnd.ps1\`.
3. Run the script to:
   - Build or update your local notes archive under a separate \`local\` folder (kept out of this public repo).
   - Update the CSV index under \`data\`.
4. Maintain a **private** clone of this repo (or a separate private repo) that stores:
   - PDFs (official and AI-derived).
   - MP3s.
   - AI-generated transcripts under \`local\`.[file:1]
"@

$readmePath = Join-Path $PublicRoot "README.md"
$readmeContent | Out-File -LiteralPath $readmePath -Encoding UTF8 -Force

# WORKFLOW.md placeholder
$workflowContent = @"
# Security Now Archive Workflow (placeholder)

This document will describe:

- How to configure local paths.
- How to run the end-to-end script to:
  - Fetch official notes from GRC/TWiT.
  - Generate AI-derived notes for missing episodes.
  - Organize everything by year.
- How to maintain a separate private archive repo containing media files under \`local\`.

TODO: Fill in after the end-to-end script is finalized and stable.[file:1]
"@

$workflowPath = Join-Path $pubDocs "WORKFLOW.md"
$workflowContent | Out-File -LiteralPath $workflowPath -Encoding UTF8 -Force

# End-to-end script placeholder
$endToEndPath = Join-Path $pubScripts "SecurityNow-EndToEnd.ps1"
if (-not (Test-Path -LiteralPath $endToEndPath)) {
    @"
# Placeholder for the full end-to-end pipeline.
# After testing, replace this file with your working SecurityNow-EndToEnd.ps1
# that:
# - Reads/writes CSV under .\data
# - Stores media under a sibling .\local folder (in your private clone only).[file:1]
"@ | Out-File -LiteralPath $endToEndPath -Encoding UTF8 -Force
}

# 2. Initialize Git for public repo (local only – no remote)
Set-Location $PublicRoot
if (-not (Test-Path (Join-Path $PublicRoot ".git"))) {
    git init | Out-Null
}

git add README.md .gitignore docs scripts data 2>$null

Write-Host ""
Write-Host "Public repo scaffold created at: $PublicRoot" -ForegroundColor Green
Write-Host "Review files, then commit with:" -ForegroundColor Yellow
Write-Host "  cd `"$PublicRoot`""
Write-Host "  git status"
Write-Host "  git commit -m `"Initial Security Now tools scaffold`""

# 3. Private archive structure (mirror + local/)
$privData    = Join-Path $PrivateRoot "data"
$privScripts = Join-Path $PrivateRoot "scripts"
$privDocs    = Join-Path $PrivateRoot "docs"
$privLocal   = Join-Path $PrivateRoot "local"

foreach ($path in @($privData, $privScripts, $privDocs, $privLocal)) {
    if (-not (Test-Path -LiteralPath $path)) {
        New-Item -ItemType Directory -Path $path -Force | Out-Null
    }
}

# Private README
$privateReadme = @"
# Security Now Full Archive – Private

This directory is intended for **private use only**. It should contain:

- A clone of the public tools-and-index repository.
- A \`local\` folder holding:
  - Official GRC show-notes PDFs (\`sn-XXXX-notes.pdf\`).[file:1]
  - TWiT audio files (MP3s).
  - AI-derived transcripts and notes PDFs.

This directory is **not** meant to be shared publicly or pushed to a public remote (GitHub or otherwise).[file:1]
"@

$privateReadmePath = Join-Path $PrivateRoot "README.md"
$privateReadme | Out-File -LiteralPath $privateReadmePath -Encoding UTF8 -Force

Write-Host ""
Write-Host "Private archive scaffold created at: $PrivateRoot" -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1) Copy or clone the public repo into $PrivateRoot"
Write-Host "  2) Use SecurityNow-EndToEnd.ps1 from the private root to populate .\local with PDFs/MP3s/AI TXT"
