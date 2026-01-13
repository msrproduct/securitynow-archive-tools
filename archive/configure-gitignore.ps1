# Step 5: Configure .gitignore for dual-remote setup
# Run this from D:\Desktop\SecurityNow-Full

$RepoRoot = "D:\Desktop\SecurityNow-Full"
Set-Location $RepoRoot

Write-Host "`nStep 5: Configuring .gitignore for public/private remotes..." -ForegroundColor Cyan

# ========================================
# Current .gitignore (for PUBLIC repo)
# ========================================

$publicIgnore = @"
# Local media and archives - never commit to PUBLIC repo
local/
*.mp3
*.pdf
sn-*-notes.pdf
sn-*-notes-ai.pdf
sn-*.mp3

# Build artifacts
node_modules/
dist/
*.log

# OS files
.DS_Store
Thumbs.db

# PowerShell test files
*-test.ps1
*-temp.ps1
"@

# Write public .gitignore (this is the default)
$publicIgnore | Out-File -FilePath ".gitignore" -Encoding UTF8 -Force
Write-Host "✓ Updated .gitignore for public repo (blocks local/ folder)" -ForegroundColor Green

# ========================================
# Backup .gitignore for PRIVATE repo
# ========================================

$privateIgnore = @"
# Private repo - include media files but ignore build artifacts
node_modules/
dist/
*.log

# OS files
.DS_Store
Thumbs.db

# Note: local/ folder IS TRACKED in private repo
"@

# Write private .gitignore backup
$privateIgnore | Out-File -FilePath ".gitignore-private" -Encoding UTF8 -Force
Write-Host "✓ Created .gitignore-private (for use with private remote)" -ForegroundColor Green

# ========================================
# Stage and commit .gitignore changes
# ========================================

Write-Host "`nCommitting .gitignore configuration..." -ForegroundColor Yellow
git add .gitignore .gitignore-private
git commit -m "Configure .gitignore for public/private repo split"

Write-Host "`n✓ Step 5 complete!" -ForegroundColor Green
Write-Host "`nNext steps:" -ForegroundColor Cyan
Write-Host "  1. git push origin main    (pushes public files only)" -ForegroundColor White
Write-Host "  2. Run push-to-private.ps1 (pushes everything including local/)" -ForegroundColor White
