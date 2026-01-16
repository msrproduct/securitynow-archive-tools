<#
.SYNOPSIS
    Complete System Audit for Security Now Project Cleanup
    
.DESCRIPTION
    Performs comprehensive scan of:
    - C:\ root (tools, Whisper, wkhtmltopdf)
    - D:\ root (orphaned test files, old folders)
    - D:\Desktop (test files, old scripts)
    - D:\SecurityNow-Full-Private (local private repo)
    - D:\SecurityNow-Full (local public repo)
    - GitHub: msrproduct/securitynow-full-archive (remote private)
    - GitHub: msrproduct/securitynow-archive-tools (remote public)
    
    Identifies:
    - Test files (delete.txt, Test-*.ps1, *-test.ps1)
    - Obsolete scripts (old versions, deprecated names)
    - Orphaned directories
    - Duplicate files
    - Files needing sync
    
.EXAMPLE
    .\Audit-Complete-System.ps1 -Verbose
    .\Audit-Complete-System.ps1 -OutputFile "audit-report.txt"
#>

[CmdletBinding()]
param(
    [string]$OutputFile = "COMPLETE-SYSTEM-AUDIT-$(Get-Date -Format 'yyyy-MM-dd-HHmmss').txt"
)

$ErrorActionPreference = "Continue"
$ReportLines = @()

function Write-Report {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
    $script:ReportLines += $Message
}

function Write-SectionHeader {
    param([string]$Title)
    Write-Report "`n═══════════════════════════════════════════════════════════════════"
    Write-Report "  $Title"
    Write-Report "═══════════════════════════════════════════════════════════════════`n"
}

function Get-SecurityNowFiles {
    param(
        [string]$Path,
        [string[]]$Exclude = @()
    )
    
    if (-not (Test-Path $Path)) {
        return @()
    }
    
    Get-ChildItem $Path -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object {
            $file = $_
            $shouldExclude = $false
            foreach ($pattern in $Exclude) {
                if ($file.FullName -like "*$pattern*") {
                    $shouldExclude = $true
                    break
                }
            }
            -not $shouldExclude
        }
}

Write-SectionHeader "SECURITY NOW PROJECT - COMPLETE SYSTEM AUDIT"
Write-Report "Audit Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Report "Computer: $env:COMPUTERNAME"
Write-Report "User: $env:USERNAME"

# ===== C:\ ROOT SCAN =====
Write-SectionHeader "C:\ ROOT - Tool Installations"

Write-Report "`n[SCANNING] C:\ for SecurityNow-related files..." "Yellow"
$cRootFiles = Get-ChildItem C:\ -File -ErrorAction SilentlyContinue | 
    Where-Object { $_.Name -like "*security*" -or $_.Name -like "*test*" -or $_.Name -like "*delete*" }

if ($cRootFiles.Count -gt 0) {
    Write-Report "`n❌ SUSPICIOUS FILES IN C:\ ROOT:" "Red"
    foreach ($file in $cRootFiles) {
        Write-Report "   - $($file.Name) [$($file.Length) bytes] [Modified: $($file.LastWriteTime)]" "Red"
    }
} else {
    Write-Report "✓ No suspicious files in C:\ root" "Green"
}

# Check C:\Tools
Write-Report "`n[CHECKING] C:\Tools directory..."
$cTools = @(
    "C:\Tools\Whisper",
    "C:\Tools\wkhtmltopdf"
)

foreach ($toolPath in $cTools) {
    if (Test-Path $toolPath) {
        $size = (Get-ChildItem $toolPath -Recurse -File -ErrorAction SilentlyContinue | 
            Measure-Object -Property Length -Sum).Sum / 1MB
        Write-Report "   ✓ $toolPath [${size:N2} MB]" "Green"
    } else {
        Write-Report "   ❌ MISSING: $toolPath" "Red"
    }
}

# ===== D:\ ROOT SCAN =====
Write-SectionHeader "D:\ ROOT - Orphaned Files & Old Folders"

Write-Report "`n[SCANNING] D:\ root for test/orphaned files..." "Yellow"
$dRootFiles = Get-ChildItem D:\ -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -like "*test*" -or $_.Name -like "*delete*" -or $_.Name -like "*.txt" }

if ($dRootFiles.Count -gt 0) {
    Write-Report "`n❌ CLEANUP NEEDED - Files in D:\ root:" "Red"
    foreach ($file in $dRootFiles) {
        Write-Report "   - $($file.Name) [$($file.Length) bytes] [Modified: $($file.LastWriteTime)]" "Red"
    }
} else {
    Write-Report "✓ No orphaned files in D:\ root" "Green"
}

# Check for old SecurityNow folders
Write-Report "`n[CHECKING] D:\ for SecurityNow directories..."
$dSecurityNowDirs = Get-ChildItem D:\ -Directory -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -like "*SecurityNow*" -or $_.Name -like "*security-now*" }

Write-Report "`nFound $($dSecurityNowDirs.Count) SecurityNow directories:"
foreach ($dir in $dSecurityNowDirs) {
    $fileCount = (Get-ChildItem $dir.FullName -Recurse -File -ErrorAction SilentlyContinue).Count
    $size = (Get-ChildItem $dir.FullName -Recurse -File -ErrorAction SilentlyContinue | 
        Measure-Object -Property Length -Sum).Sum / 1GB
    
    $isExpected = $dir.Name -eq "SecurityNow-Full-Private" -or $dir.Name -eq "SecurityNow-Full"
    $marker = if ($isExpected) { "✓" } else { "❌ ORPHANED" }
    $color = if ($isExpected) { "Green" } else { "Red" }
    
    Write-Report "   $marker $($dir.Name) [$fileCount files, ${size:N2} GB]" $color
}

# ===== D:\DESKTOP SCAN =====
Write-SectionHeader "D:\DESKTOP - Test Files & Old Scripts"

if (Test-Path "D:\Desktop") {
    Write-Report "`n[SCANNING] D:\Desktop for SecurityNow files..." "Yellow"
    
    # PowerShell scripts
    $desktopPS = Get-ChildItem D:\Desktop -Filter "*.ps1" -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -like "*security*" -or $_.Name -like "*sync*" -or $_.Name -like "*test*" }
    
    if ($desktopPS.Count -gt 0) {
        Write-Report "`n❌ PowerShell scripts on Desktop:" "Red"
        foreach ($file in $desktopPS) {
            Write-Report "   - $($file.Name) [Modified: $($file.LastWriteTime)]" "Red"
        }
    } else {
        Write-Report "✓ No SecurityNow PowerShell scripts on Desktop" "Green"
    }
    
    # Test/delete files
    $desktopTest = Get-ChildItem D:\Desktop -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -like "*delete*" -or $_.Name -like "*test*" }
    
    if ($desktopTest.Count -gt 0) {
        Write-Report "`n❌ Test/delete files on Desktop:" "Red"
        foreach ($file in $desktopTest) {
            Write-Report "   - $($file.Name)" "Red"
        }
    }
} else {
    Write-Report "⚠ D:\Desktop not found - skipping" "Yellow"
}

# ===== LOCAL PRIVATE REPO =====
Write-SectionHeader "D:\SECURITYNOW-FULL-PRIVATE - Local Private Repository"

$privateRepo = "D:\SecurityNow-Full-Private"
if (Test-Path $privateRepo) {
    Write-Report "`n[ANALYZING] Local private repository..." "Yellow"
    
    # Git status
    Push-Location $privateRepo
    $gitStatus = git status --porcelain 2>&1
    Pop-Location
    
    if ($gitStatus) {
        Write-Report "`n⚠ UNCOMMITTED CHANGES:" "Yellow"
        Write-Report $gitStatus
    } else {
        Write-Report "✓ Working tree clean" "Green"
    }
    
    # Test files
    $privateTest = Get-SecurityNowFiles -Path $privateRepo -Exclude @("local-pdf", "local-mp3", "local-notes-ai-transcripts", ".git") |
        Where-Object { $_.Name -like "*delete*" -or $_.Name -like "*test*.ps1" -or $_.Name -eq "Test-*.ps1" }
    
    if ($privateTest.Count -gt 0) {
        Write-Report "`n❌ TEST FILES FOUND:" "Red"
        foreach ($file in $privateTest) {
            $relPath = $file.FullName.Replace($privateRepo, "")
            Write-Report "   - $relPath" "Red"
        }
    } else {
        Write-Report "✓ No test files found" "Green"
    }
    
    # Obsolete scripts
    $obsoleteScripts = @(
        "Sync-Repos.ps1",
        "Sync-Repo.ps1", 
        "SecurityNow-EndToEnd.ps1",
        "Diagnose-Sync.ps1",
        "push-to-private.ps1"
    )
    
    Write-Report "`n[CHECKING] Obsolete script names..."
    $foundObsolete = @()
    foreach ($script in $obsoleteScripts) {
        $found = Get-ChildItem $privateRepo -Recurse -Filter $script -ErrorAction SilentlyContinue
        if ($found) {
            $foundObsolete += $found
            Write-Report "   ❌ OBSOLETE: $script" "Red"
        }
    }
    
    if ($foundObsolete.Count -eq 0) {
        Write-Report "   ✓ No obsolete scripts found" "Green"
    }
    
    # Current production files
    Write-Report "`n[PRODUCTION FILES]"
    $productionFiles = @(
        "sn-full-run.ps1",
        "Special-Sync.ps1",
        "Convert-HTMLtoPDF.ps1",
        "Fix-AI-PDFs.ps1",
        "SecurityNow-Bootstrap.ps1"
    )
    
    foreach ($prod in $productionFiles) {
        $found = Get-ChildItem $privateRepo -Recurse -Filter $prod -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($found) {
            Write-Report "   ✓ $prod [Modified: $($found.LastWriteTime)]" "Green"
        } else {
            Write-Report "   ❌ MISSING: $prod" "Red"
        }
    }
    
} else {
    Write-Report "❌ CRITICAL: Private repo not found at $privateRepo" "Red"
}

# ===== LOCAL PUBLIC REPO =====
Write-SectionHeader "D:\SECURITYNOW-FULL - Local Public Repository"

$publicRepo = "D:\SecurityNow-Full"
if (Test-Path $publicRepo) {
    Write-Report "`n[ANALYZING] Local public repository..." "Yellow"
    
    # Git status
    Push-Location $publicRepo
    $gitStatus = git status --porcelain 2>&1
    Pop-Location
    
    if ($gitStatus) {
        Write-Report "`n⚠ UNCOMMITTED CHANGES:" "Yellow"
        Write-Report $gitStatus
    } else {
        Write-Report "✓ Working tree clean" "Green"
    }
    
    # Check for copyrighted content
    Write-Report "`n[CHECKING] Copyrighted content (should be NONE)..."
    $copyrightedFolders = @("local-pdf", "local-mp3", "local-notes-ai-transcripts")
    $foundCopyright = $false
    
    foreach ($folder in $copyrightedFolders) {
        if (Test-Path (Join-Path $publicRepo $folder)) {
            Write-Report "   ❌ FOUND COPYRIGHTED FOLDER: $folder" "Red"
            $foundCopyright = $true
        }
    }
    
    if (-not $foundCopyright) {
        Write-Report "   ✓ No copyrighted content folders" "Green"
    }
    
    # Test files
    $publicTest = Get-SecurityNowFiles -Path $publicRepo -Exclude @(".git") |
        Where-Object { $_.Name -like "*delete*" -or $_.Name -like "*test*.ps1" }
    
    if ($publicTest.Count -gt 0) {
        Write-Report "`n❌ TEST FILES FOUND:" "Red"
        foreach ($file in $publicTest) {
            $relPath = $file.FullName.Replace($publicRepo, "")
            Write-Report "   - $relPath" "Red"
        }
    } else {
        Write-Report "✓ No test files found" "Green"
    }
    
} else {
    Write-Report "❌ CRITICAL: Public repo not found at $publicRepo" "Red"
}

# ===== GITHUB REPOS =====
Write-SectionHeader "GITHUB REPOSITORIES - Remote State"

Write-Report "`n[NOTE] GitHub repo contents require manual verification via web or Git commands"
Write-Report "To check remote files, run:"
Write-Report "   cd D:\SecurityNow-Full-Private && git fetch && git log origin/main -1"
Write-Report "   cd D:\SecurityNow-Full && git fetch && git log origin/main -1"

# ===== SUMMARY =====
Write-SectionHeader "AUDIT SUMMARY & RECOMMENDED ACTIONS"

Write-Report "`n[NEXT STEPS]"
Write-Report "1. Review this audit report carefully"
Write-Report "2. Back up both repos before cleanup: git tag pre-cleanup-$(Get-Date -Format 'yyyy-MM-dd')"
Write-Report "3. Run cleanup script (to be created) to remove identified files"
Write-Report "4. Sync all 4 repos with Special-Sync.ps1"
Write-Report "5. Verify GitHub repos match local state"
Write-Report "`nAudit complete: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

# ===== SAVE REPORT =====
$ReportLines | Out-File $OutputFile -Encoding UTF8
Write-Host "`n✓ Audit report saved to: $OutputFile" -ForegroundColor Green
Write-Host "Review the report and run cleanup actions as needed.`n"
