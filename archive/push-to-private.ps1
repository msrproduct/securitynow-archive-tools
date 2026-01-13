# Push to private repo (includes local/ folder with media)
# Run this from D:\Desktop\SecurityNow-Full

$RepoRoot = "D:\Desktop\SecurityNow-Full"
Set-Location $RepoRoot

Write-Host "`nPushing FULL archive to private repo..." -ForegroundColor Cyan

# ========================================
# Temporarily swap .gitignore
# ========================================

if (Test-Path ".gitignore") {
    Move-Item .gitignore .gitignore.public -Force
    Write-Host "✓ Backed up public .gitignore" -ForegroundColor Green
}

if (Test-Path ".gitignore-private") {
    Copy-Item .gitignore-private .gitignore -Force
    Write-Host "✓ Activated private .gitignore (allows local/ folder)" -ForegroundColor Green
}

# ========================================
# Stage ALL files (including local/)
# ========================================

Write-Host "`nStaging files for private repo..." -ForegroundColor Yellow
git add -A

# Check if there are changes
$status = git status --porcelain
if ($status) {
    git commit -m "Add full archive with media files to private repo"
    Write-Host "✓ Committed changes" -ForegroundColor Green
} else {
    Write-Host "✓ No new changes to commit" -ForegroundColor Yellow
}

# ========================================
# Push to private remote
# ========================================

Write-Host "`nPushing to private remote..." -ForegroundColor Yellow
git push private main

Write-Host "`n✓ Push to private complete!" -ForegroundColor Green

# ========================================
# Restore public .gitignore
# ========================================

if (Test-Path ".gitignore.public") {
    Move-Item .gitignore.public .gitignore -Force
    Write-Host "✓ Restored public .gitignore" -ForegroundColor Green
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "✓ Public repo (origin):  Scripts + docs only" -ForegroundColor Green
Write-Host "✓ Private repo (private): Everything + local/ folder" -ForegroundColor Green
