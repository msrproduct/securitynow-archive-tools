# Sync-Repos.ps1
# Synchronize non-copyrighted files between private and public Security Now repos

param(
    [string]$PrivateRepo = "D:\Desktop\SecurityNow-Full-Private",
    [string]$PublicRepo = "D:\Desktop\SecurityNow-Full",
    [switch]$DryRun,
    [switch]$Verbose
)

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Security Now Repo Sync" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Private repo: $PrivateRepo"
Write-Host "Public repo:  $PublicRepo"
if ($DryRun) {
    Write-Host "MODE: DRY RUN (no changes will be made)" -ForegroundColor Yellow
}
Write-Host ""

# ========================================
# VALIDATE REPOS
# ========================================

if (-not (Test-Path -LiteralPath $PrivateRepo)) {
    Write-Host "ERROR: Private repo not found: $PrivateRepo" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path -LiteralPath $PublicRepo)) {
    Write-Host "ERROR: Public repo not found: $PublicRepo" -ForegroundColor Red
    exit 1
}

# ========================================
# DEFINE SYNC RULES
# ========================================

# Files/folders to sync (non-copyrighted content only)
# NOTE: .gitignore is intentionally EXCLUDED because it differs between repos:
#   - Public repo: doesn't need to ignore media files (they don't exist)
#   - Private repo: must track media files (PDFs, MP3s, transcripts)
$SyncItems = @(
    "README.md",
    "LICENSE",
    "FUNDING.yml",
    "docs",
    "scripts",
    "data\SecurityNowNotesIndex.csv"
)

# Folders to NEVER sync (copyrighted content)
$ExcludeFolders = @(
    "local\PDF",
    "local\mp3",
    "local\Notes\ai-transcripts"
)

# ========================================
# COMPARE AND SYNC FILES
# ========================================

Write-Host "Comparing files..." -ForegroundColor Yellow
Write-Host "NOTE: .gitignore is excluded (each repo maintains its own)" -ForegroundColor Cyan
Write-Host ""

$syncCount = 0
$skipCount = 0
$deleteCount = 0

foreach ($item in $SyncItems) {
    $sourcePath = Join-Path $PrivateRepo $item
    $destPath = Join-Path $PublicRepo $item
    
    # Check if source exists
    if (-not (Test-Path -LiteralPath $sourcePath)) {
        if ($Verbose) {
            Write-Host "[SKIP] Source not found: $item" -ForegroundColor Yellow
        }
        $skipCount++
        continue
    }
    
    # Handle directories
    if (Test-Path -LiteralPath $sourcePath -PathType Container) {
        Write-Host "[SYNC] Directory: $item" -ForegroundColor Cyan
        
        if (-not $DryRun) {
            # Create destination directory if it doesn't exist
            if (-not (Test-Path -LiteralPath $destPath)) {
                New-Item -ItemType Directory -Path $destPath -Force | Out-Null
            }
            
            # Copy all files recursively, excluding copyrighted content
            $files = Get-ChildItem -LiteralPath $sourcePath -Recurse -File
            
            foreach ($file in $files) {
                $relativePath = $file.FullName.Substring($sourcePath.Length + 1)
                $destFile = Join-Path $destPath $relativePath
                
                # Skip if in excluded folder
                $shouldExclude = $false
                foreach ($excludeFolder in $ExcludeFolders) {
                    if ($file.FullName -like "*$excludeFolder*") {
                        $shouldExclude = $true
                        break
                    }
                }
                
                if ($shouldExclude) {
                    if ($Verbose) {
                        Write-Host "  [EXCLUDE] $relativePath" -ForegroundColor DarkGray
                    }
                    continue
                }
                
                # Create parent directory if needed
                $destParent = Split-Path -Parent $destFile
                if (-not (Test-Path -LiteralPath $destParent)) {
                    New-Item -ItemType Directory -Path $destParent -Force | Out-Null
                }
                
                # Compare and copy if different
                if (-not (Test-Path -LiteralPath $destFile)) {
                    Copy-Item -LiteralPath $file.FullName -Destination $destFile -Force
                    Write-Host "  [NEW] $relativePath" -ForegroundColor Green
                    $syncCount++
                } else {
                    $sourceHash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
                    $destHash = (Get-FileHash -LiteralPath $destFile -Algorithm SHA256).Hash
                    
                    if ($sourceHash -ne $destHash) {
                        Copy-Item -LiteralPath $file.FullName -Destination $destFile -Force
                        Write-Host "  [UPDATE] $relativePath" -ForegroundColor Yellow
                        $syncCount++
                    } else {
                        if ($Verbose) {
                            Write-Host "  [SAME] $relativePath" -ForegroundColor DarkGray
                        }
                    }
                }
            }
        } else {
            Write-Host "  [DRY RUN] Would sync directory contents" -ForegroundColor DarkYellow
        }
        
    } else {
        # Handle single files
        if (Test-Path -LiteralPath $destPath) {
            # Compare file hashes
            $sourceHash = (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash
            $destHash = (Get-FileHash -LiteralPath $destPath -Algorithm SHA256).Hash
            
            if ($sourceHash -ne $destHash) {
                Write-Host "[UPDATE] $item" -ForegroundColor Yellow
                
                if (-not $DryRun) {
                    Copy-Item -LiteralPath $sourcePath -Destination $destPath -Force
                }
                $syncCount++
            } else {
                if ($Verbose) {
                    Write-Host "[SAME] $item" -ForegroundColor DarkGray
                }
            }
        } else {
            Write-Host "[NEW] $item" -ForegroundColor Green
            
            if (-not $DryRun) {
                # Create parent directory if needed
                $destParent = Split-Path -Parent $destPath
                if (-not (Test-Path -LiteralPath $destParent)) {
                    New-Item -ItemType Directory -Path $destParent -Force | Out-Null
                }
                Copy-Item -LiteralPath $sourcePath -Destination $destPath -Force
            }
            $syncCount++
        }
    }
}

# ========================================
# GIT COMMIT AND PUSH
# ========================================

if ($syncCount -gt 0 -and -not $DryRun) {
    Write-Host ""
    Write-Host "Committing changes to public repo..." -ForegroundColor Yellow
    
    Push-Location $PublicRepo
    try {
        git add .
        git commit -m "Sync from private repo: $syncCount file(s) updated"
        git push origin main
        Write-Host "  Pushed to public GitHub repo" -ForegroundColor Green
    } catch {
        Write-Host "  Warning: Git operations failed" -ForegroundColor Yellow
        Write-Host "  $($_.Exception.Message)" -ForegroundColor Yellow
    } finally {
        Pop-Location
    }
}

# ========================================
# SUMMARY
# ========================================

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Files synced:  $syncCount" -ForegroundColor Green
Write-Host "Files skipped: $skipCount" -ForegroundColor Yellow

if ($DryRun) {
    Write-Host ""
    Write-Host "DRY RUN COMPLETE - No changes were made" -ForegroundColor Yellow
    Write-Host "Run without -DryRun to apply changes" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
