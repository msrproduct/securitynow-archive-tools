<#
.SYNOPSIS
    Diagnostic tool to verify Special-Sync.ps1 file detection logic

.DESCRIPTION
    Compares actual directory listings with what the sync script detects
    to identify any files being missed or incorrectly categorized
#>

param(
    [string]$PrivateRepo = "D:\Desktop\SecurityNow-Full-Private",
    [string]$PublicRepo = "D:\Desktop\SecurityNow-Full"
)

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Sync Detection Diagnostic Tool" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "Private repo: $PrivateRepo" -ForegroundColor Yellow
Write-Host "Public repo : $PublicRepo`n" -ForegroundColor Yellow

# Excluded folders (copyrighted media)
$excludedFolders = @('local-pdf', 'local-mp3', 'local-notes-ai-transcripts')

# Roots to sync
$syncRoots = @(
    "",              # Root-level files (README.md, LICENSE, etc.)
    "docs",
    "scripts",
    "data"
)

function Get-RepoFiles {
    param(
        [string]$RepoPath,
        [string]$Root
    )
    
    $fullRoot = if ([string]::IsNullOrWhiteSpace($Root)) {
        $RepoPath
    } else {
        Join-Path $RepoPath $Root
    }
    
    if (-not (Test-Path $fullRoot)) {
        return @()
    }
    
    # Get all files recursively
    $allFiles = Get-ChildItem -Path $fullRoot -File -Recurse -ErrorAction SilentlyContinue
    
    # Filter out excluded paths
    $filteredFiles = $allFiles | Where-Object {
        $rel = $_.FullName.Substring($RepoPath.Length).TrimStart('\', '/')
        
        # Exclude .git folder
        if ($rel -like '.git*') {
            return $false
        }
        
        # Exclude copyrighted media folders
        foreach ($excludedFolder in $excludedFolders) {
            if ($rel -like "$excludedFolder\*" -or $rel -like "$excludedFolder/*") {
                return $false
            }
        }
        
        return $true
    }
    
    return $filteredFiles
}

# 1. RAW DIRECTORY LISTING
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "1. RAW DIRECTORY LISTING (All Files)" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "--- PRIVATE REPO (excluding /local-*) ---" -ForegroundColor Yellow
$privateAllFiles = @{}
foreach ($root in $syncRoots) {
    $files = Get-RepoFiles -RepoPath $PrivateRepo -Root $root
    foreach ($file in $files) {
        $rel = $file.FullName.Substring($PrivateRepo.Length).TrimStart('\', '/')
        $privateAllFiles[$rel.ToLowerInvariant()] = $file.FullName
        Write-Host "  $rel" -ForegroundColor DarkGray
    }
}
Write-Host "Total: $($privateAllFiles.Count) files`n" -ForegroundColor Green

Write-Host "--- PUBLIC REPO ---" -ForegroundColor Yellow
$publicAllFiles = @{}
foreach ($root in $syncRoots) {
    $files = Get-RepoFiles -RepoPath $PublicRepo -Root $root
    foreach ($file in $files) {
        $rel = $file.FullName.Substring($PublicRepo.Length).TrimStart('\', '/')
        $publicAllFiles[$rel.ToLowerInvariant()] = $file.FullName
        Write-Host "  $rel" -ForegroundColor DarkGray
    }
}
Write-Host "Total: $($publicAllFiles.Count) files`n" -ForegroundColor Green

# 2. CATEGORIZE FILES
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "2. FILE CATEGORIZATION" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$inBoth = @()
$privateOnly = @()
$publicOnly = @()

# Files in Private
foreach ($rel in $privateAllFiles.Keys) {
    $fileName = [System.IO.Path]::GetFileName($rel)
    
    # Skip .gitignore
    if ($fileName.ToLowerInvariant() -eq '.gitignore') {
        Write-Host "  SKIP (EXCLUDE): $rel (.gitignore is repo-specific)" -ForegroundColor DarkGray
        continue
    }
    
    if ($publicAllFiles.ContainsKey($rel)) {
        $inBoth += $rel
    } else {
        $privateOnly += $rel
    }
}

# Files in Public only
foreach ($rel in $publicAllFiles.Keys) {
    $fileName = [System.IO.Path]::GetFileName($rel)
    
    # Skip .gitignore
    if ($fileName.ToLowerInvariant() -eq '.gitignore') {
        continue
    }
    
    if (-not $privateAllFiles.ContainsKey($rel)) {
        $publicOnly += $rel
    }
}

Write-Host "--- FILES IN BOTH REPOS ---" -ForegroundColor Green
if ($inBoth.Count -eq 0) {
    Write-Host "  (none)" -ForegroundColor DarkGray
} else {
    foreach ($file in $inBoth | Sort-Object) {
        Write-Host "  ✓ $file" -ForegroundColor DarkGray
    }
}
Write-Host "Total: $($inBoth.Count)`n" -ForegroundColor Green

Write-Host "--- PRIVATE-ONLY FILES (missing from Public) ---" -ForegroundColor Yellow
if ($privateOnly.Count -eq 0) {
    Write-Host "  (none)" -ForegroundColor DarkGray
} else {
    foreach ($file in $privateOnly | Sort-Object) {
        Write-Host "  → $file" -ForegroundColor Yellow
    }
}
Write-Host "Total: $($privateOnly.Count)`n" -ForegroundColor Yellow

Write-Host "--- PUBLIC-ONLY FILES (missing from Private SOURCE OF TRUTH) ---" -ForegroundColor Red
if ($publicOnly.Count -eq 0) {
    Write-Host "  (none)" -ForegroundColor DarkGray
} else {
    foreach ($file in $publicOnly | Sort-Object) {
        Write-Host "  ⚠️  $file" -ForegroundColor Red
    }
}
Write-Host "Total: $($publicOnly.Count)`n" -ForegroundColor Red

# 3. FIND TEST FILES (delete*.txt)
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "3. TEST FILE DETECTION (delete*.txt)" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$privateTestFiles = $privateAllFiles.Keys | Where-Object { $_ -like '*delete*.txt' } | Sort-Object
$publicTestFiles = $publicAllFiles.Keys | Where-Object { $_ -like '*delete*.txt' } | Sort-Object

Write-Host "--- PRIVATE REPO ---" -ForegroundColor Yellow
if ($privateTestFiles.Count -eq 0) {
    Write-Host "  (no delete*.txt files found)" -ForegroundColor DarkGray
} else {
    foreach ($file in $privateTestFiles) {
        Write-Host "  • $file" -ForegroundColor Yellow
    }
}
Write-Host "Total: $($privateTestFiles.Count)`n" -ForegroundColor Yellow

Write-Host "--- PUBLIC REPO ---" -ForegroundColor Yellow
if ($publicTestFiles.Count -eq 0) {
    Write-Host "  (no delete*.txt files found)" -ForegroundColor DarkGray
} else {
    foreach ($file in $publicTestFiles) {
        Write-Host "  • $file" -ForegroundColor Yellow
    }
}
Write-Host "Total: $($publicTestFiles.Count)`n" -ForegroundColor Yellow

# 4. SUMMARY
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "SUMMARY" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "Total files in Private (excluding /local-*): $($privateAllFiles.Count)" -ForegroundColor White
Write-Host "Total files in Public                      : $($publicAllFiles.Count)" -ForegroundColor White
Write-Host "Files in both repos                        : $($inBoth.Count)" -ForegroundColor Green
Write-Host "Files ONLY in Private (should sync to pub) : $($privateOnly.Count)" -ForegroundColor Yellow
Write-Host "Files ONLY in Public (orphaned/incorrect)  : $($publicOnly.Count)" -ForegroundColor Red
Write-Host ""

if ($publicOnly.Count -gt 0) {
    Write-Host "⚠️  WARNING: Public repo contains $($publicOnly.Count) file(s) NOT in Private (source of truth)" -ForegroundColor Red
    Write-Host "   These files should either:" -ForegroundColor Red
    Write-Host "   1. Be copied to Private repo, OR" -ForegroundColor Red
    Write-Host "   2. Be deleted from Public repo" -ForegroundColor Red
}

if ($privateOnly.Count -gt 0) {
    Write-Host "ℹ️  INFO: Private repo contains $($privateOnly.Count) file(s) NOT yet synced to Public" -ForegroundColor Yellow
    Write-Host "   Next sync run should copy these to Public" -ForegroundColor Yellow
}

Write-Host "`n========================================`n" -ForegroundColor Cyan
