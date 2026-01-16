<#
.SYNOPSIS
    Cleanup utility/diagnostic scripts from SecurityNow project

.DESCRIPTION
    Removes development and diagnostic utility scripts that are no longer needed.
    These were useful during development but aren't part of the production workflow.
    
    SAFE TO DELETE:
    - audit-projectfiles.ps1 (project file auditing tool)
    - build-episodedateindex-full.ps1 (episode date index builder)
    - inspect-grc-html.ps1 (GRC HTML debugging tool)
    
    PRESERVED:
    - sn-full-run.ps1 (production engine)
    - special-sync.ps1 (sync tool)
    - Convert-HTMLtoPDF.ps1 (PDF generation utility)
    - Fix-AI-PDFs.ps1 (PDF repair utility)
    - securitynow-bootstrap.ps1 (initial setup)
    - Cleanup-ObsoleteFiles.ps1 (this cleanup tool)

.EXAMPLE
    .\Cleanup-UtilityScripts.ps1
    Performs cleanup with backup

.EXAMPLE
    .\Cleanup-UtilityScripts.ps1 -WhatIf
    Preview what will be deleted

.NOTES
    Created: 2026-01-15
    Purpose: Final cleanup for production-ready repository
#>

[CmdletBinding(SupportsShouldProcess)]
param()

$ErrorActionPreference = "Stop"

# Determine repo root
$repoRoot = if ($PSScriptRoot) {
    Split-Path $PSScriptRoot -Parent
} else {
    "D:\Desktop\SecurityNow-Full"
}

# Backup folder with timestamp
$timestamp = Get-Date -Format "yyyy-MM-dd_HHmmss"
$backupRoot = Join-Path $repoRoot "_cleanup-utilities_$timestamp"

Write-Host "`n" -NoNewline
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  SecurityNow Project - Utility Scripts Cleanup" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "`nDate: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host "Repo: $repoRoot" -ForegroundColor Gray

if ($WhatIfPreference) {
    Write-Host "`n⚠️  DRY RUN MODE - No files will be deleted" -ForegroundColor Yellow
}

# Utility scripts to delete
$filesToDelete = @(
    "scripts\audit-projectfiles.ps1"
    "scripts\build-episodedateindex-full.ps1"
    "scripts\inspect-grc-html.ps1"
)

# Track results
$filesDeleted = 0
$filesFailed = 0

# Create backup directory if not in WhatIf mode
if (-not $WhatIfPreference) {
    Write-Host "`n📦 Creating backup folder..." -ForegroundColor Cyan
    New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null
    Write-Host "   ✓ Backup location: $backupRoot" -ForegroundColor Green
}

# Backup and delete files
Write-Host "`n🗑️  Processing utility scripts for deletion..." -ForegroundColor Cyan
foreach ($file in $filesToDelete) {
    $fullPath = Join-Path $repoRoot $file
    
    if (Test-Path $fullPath) {
        if ($PSCmdlet.ShouldProcess($file, "Delete utility script")) {
            try {
                # Backup first
                $backupPath = Join-Path $backupRoot $file
                $backupDir = Split-Path $backupPath -Parent
                if (-not (Test-Path $backupDir)) {
                    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
                }
                Copy-Item -LiteralPath $fullPath -Destination $backupPath -Force
                
                # Delete
                Remove-Item -LiteralPath $fullPath -Force
                Write-Host "   ✓ Deleted: $file" -ForegroundColor Green
                $filesDeleted++
            } catch {
                Write-Host "   ✗ Failed: $file - $($_.Exception.Message)" -ForegroundColor Red
                $filesFailed++
            }
        }
    } else {
        Write-Host "   ⊘ Not found: $file (already removed?)" -ForegroundColor Gray
    }
}

# Summary
Write-Host "`n" -NoNewline
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  CLEANUP SUMMARY" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan

if ($WhatIfPreference) {
    Write-Host "`n⚠️  This was a DRY RUN - no changes were made" -ForegroundColor Yellow
    Write-Host "   Remove -WhatIf parameter to perform actual cleanup" -ForegroundColor Gray
} else {
    Write-Host "`n✅ Utility scripts removed: $filesDeleted" -ForegroundColor Green
    
    if ($filesFailed -gt 0) {
        Write-Host "❌ Failed: $filesFailed" -ForegroundColor Red
    }
    
    Write-Host "`n📦 Backup location:" -ForegroundColor Cyan
    Write-Host "   $backupRoot" -ForegroundColor White
    
    Write-Host "`n🔄 Rollback instructions (if needed):" -ForegroundColor Yellow
    Write-Host "   Copy-Item -Path '$backupRoot\*' -Destination '$repoRoot' -Recurse -Force" -ForegroundColor Gray
}

Write-Host "`n📋 Production scripts preserved:" -ForegroundColor Cyan
$preservedFiles = @(
    "scripts\sn-full-run.ps1"
    "scripts\special-sync.ps1"
    "scripts\Convert-HTMLtoPDF.ps1"
    "scripts\Fix-AI-PDFs.ps1"
    "scripts\securitynow-bootstrap.ps1"
    "scripts\Cleanup-ObsoleteFiles.ps1"
)

foreach ($file in $preservedFiles) {
    $fullPath = Join-Path $repoRoot $file
    if (Test-Path $fullPath) {
        Write-Host "   ✓ $file" -ForegroundColor Green
    }
}

Write-Host "`n✅ Repository is now production-ready with core scripts only!" -ForegroundColor Green
Write-Host "" # Blank line at end
