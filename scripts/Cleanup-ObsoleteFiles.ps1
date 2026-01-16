<#
.SYNOPSIS
    Cleanup obsolete test files and diagnostic scripts from SecurityNow project

.DESCRIPTION
    This script removes test files that are no longer needed after development
    stabilized. It creates a backup before deletion and provides rollback instructions.
    
    SAFE TO DELETE:
    - diagnose-sync.ps1 (diagnostic tool, no longer needed)
    - 5 test scripts (securitynow-testbatch, testrun, sn-test variants)
    - securitynow-test folder (orphaned test directory)
    
    PRESERVED:
    - sn-full-run.ps1 (production engine)
    - special-sync.ps1 (sync tool)
    - All utility scripts (Convert-HTMLtoPDF, Fix-AI-PDFs, bootstrap, etc.)

.PARAMETER WhatIf
    Show what would be deleted without actually deleting

.EXAMPLE
    .\Cleanup-ObsoleteFiles.ps1
    Performs cleanup with backup

.EXAMPLE
    .\Cleanup-ObsoleteFiles.ps1 -WhatIf
    Preview what will be deleted

.NOTES
    Created: 2026-01-15
    Cleanup Date: 2026-01-15 22:36 CST
    Backup Location: D:\Desktop\SecurityNow-Full\_cleanup-backup_YYYY-MM-DD\
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter()]
    [switch]$WhatIf
)

$ErrorActionPreference = "Stop"

# Determine repo root (works from any location)
$repoRoot = if ($PSScriptRoot) {
    Split-Path $PSScriptRoot -Parent
} else {
    "D:\Desktop\SecurityNow-Full"
}

# Backup folder with timestamp
$timestamp = Get-Date -Format "yyyy-MM-dd_HHmmss"
$backupRoot = Join-Path $repoRoot "_cleanup-backup_$timestamp"

Write-Host "`n" -NoNewline
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  SecurityNow Project Cleanup - Test Files Removal" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "`nDate: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host "Repo: $repoRoot" -ForegroundColor Gray

if ($WhatIf) {
    Write-Host "`n⚠️  DRY RUN MODE - No files will be deleted" -ForegroundColor Yellow
}

# Files to delete
$filesToDelete = @(
    # Diagnostic script
    "scripts\diagnose-sync.ps1"
    
    # Test scripts
    "scripts\securitynow-testbatch-1-20.ps1"
    "scripts\securitynow-testrun.ps1"
    "scripts\sn-test-wkhtmltopdf.ps1"
    "scripts\sn-test.ps1"
    "securitynow-test\securitynow-testrun.ps1"
)

# Directories to delete
$dirsToDelete = @(
    "securitynow-test"
)

# Track results
$filesDeleted = 0
$filesFailed = 0
$dirsDeleted = 0
$dirsFailed = 0

# Create backup directory if not in WhatIf mode
if (-not $WhatIf) {
    Write-Host "`n📦 Creating backup folder..." -ForegroundColor Cyan
    New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null
    Write-Host "   ✓ Backup location: $backupRoot" -ForegroundColor Green
}

# Backup and delete files
Write-Host "`n🗑️  Processing files for deletion..." -ForegroundColor Cyan
foreach ($file in $filesToDelete) {
    $fullPath = Join-Path $repoRoot $file
    
    if (Test-Path $fullPath) {
        try {
            if ($WhatIf) {
                Write-Host "   [WHATIF] Would delete: $file" -ForegroundColor Yellow
            } else {
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
            }
        } catch {
            Write-Host "   ✗ Failed: $file - $($_.Exception.Message)" -ForegroundColor Red
            $filesFailed++
        }
    } else {
        Write-Host "   ⊘ Not found: $file (already removed?)" -ForegroundColor Gray
    }
}

# Backup and delete directories
Write-Host "`n🗑️  Processing directories for deletion..." -ForegroundColor Cyan
foreach ($dir in $dirsToDelete) {
    $fullPath = Join-Path $repoRoot $dir
    
    if (Test-Path $fullPath) {
        try {
            if ($WhatIf) {
                Write-Host "   [WHATIF] Would delete folder: $dir\" -ForegroundColor Yellow
            } else {
                # Backup first
                $backupPath = Join-Path $backupRoot $dir
                Copy-Item -LiteralPath $fullPath -Destination $backupPath -Recurse -Force
                
                # Delete
                Remove-Item -LiteralPath $fullPath -Recurse -Force
                Write-Host "   ✓ Deleted folder: $dir\" -ForegroundColor Green
                $dirsDeleted++
            }
        } catch {
            Write-Host "   ✗ Failed: $dir\ - $($_.Exception.Message)" -ForegroundColor Red
            $dirsFailed++
        }
    } else {
        Write-Host "   ⊘ Not found: $dir\ (already removed?)" -ForegroundColor Gray
    }
}

# Summary
Write-Host "`n" -NoNewline
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  CLEANUP SUMMARY" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan

if ($WhatIf) {
    Write-Host "`n⚠️  This was a DRY RUN - no changes were made" -ForegroundColor Yellow
    Write-Host "   Remove -WhatIf parameter to perform actual cleanup" -ForegroundColor Gray
} else {
    Write-Host "`n✅ Files removed: $filesDeleted" -ForegroundColor Green
    Write-Host "✅ Folders removed: $dirsDeleted" -ForegroundColor Green
    
    if ($filesFailed -gt 0 -or $dirsFailed -gt 0) {
        Write-Host "❌ Failed: $($filesFailed + $dirsFailed)" -ForegroundColor Red
    }
    
    Write-Host "`n📦 Backup location:" -ForegroundColor Cyan
    Write-Host "   $backupRoot" -ForegroundColor White
    
    Write-Host "`n🔄 Rollback instructions (if needed):" -ForegroundColor Yellow
    Write-Host "   Copy-Item -Path '$backupRoot\*' -Destination '$repoRoot' -Recurse -Force" -ForegroundColor Gray
}

Write-Host "`n📋 Production files preserved:" -ForegroundColor Cyan
$preservedFiles = @(
    "scripts\sn-full-run.ps1"
    "scripts\special-sync.ps1"
    "scripts\Convert-HTMLtoPDF.ps1"
    "scripts\Fix-AI-PDFs.ps1"
    "scripts\securitynow-bootstrap.ps1"
    "scripts\audit-projectfiles.ps1"
    "scripts\build-episodedateindex-full.ps1"
    "scripts\inspect-grc-html.ps1"
)

foreach ($file in $preservedFiles) {
    $fullPath = Join-Path $repoRoot $file
    if (Test-Path $fullPath) {
        Write-Host "   ✓ $file" -ForegroundColor Green
    }
}

Write-Host "`n✅ Cleanup complete!" -ForegroundColor Green
Write-Host "" # Blank line at end
