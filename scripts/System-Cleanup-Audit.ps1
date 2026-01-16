<![CDATA[#Requires -Version 7.0
<#
.SYNOPSIS
    System-wide cleanup audit for Security Now Archive Tools project.

.DESCRIPTION
    Scans C:\, D:\ root, D:\Desktop, and both local repos to identify:
    - Test files and obsolete scripts for removal
    - Orphaned directories from earlier development
    - Documentation with outdated paths
    - Duplicate or versioned script files
    
    Safe read-only audit - generates report without deleting files.
    Uses correct paths from .ai-context.md v3.1.

.PARAMETER ReportPath
    Output path for audit report (default: Desktop\cleanup-audit-report.txt)

.PARAMETER IncludeHiddenFiles
    Include hidden files in the audit

.EXAMPLE
    .\System-Cleanup-Audit.ps1
    Runs full system audit and saves report to Desktop

.EXAMPLE
    .\System-Cleanup-Audit.ps1 -ReportPath "C:\Temp\audit.txt" -IncludeHiddenFiles
    Custom report path with hidden files included

.NOTES
    Version: 1.0.0
    Author: Security Now Archive Tools Project
    Created: 2026-01-16
    Last Updated: 2026-01-16
    
    CRITICAL PATHS (from .ai-context.md v3.1):
    - Primary Repo: D:\Desktop\SecurityNow-Full\
    - Public Repo: D:\Desktop\SecurityNow-Full-Public\
    - Correct Sync Script: Special-Sync.ps1
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$ReportPath = "$env:USERPROFILE\Desktop\cleanup-audit-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt",
    
    [Parameter()]
    [switch]$IncludeHiddenFiles
)

# Configuration
$ErrorActionPreference = "Continue"
$WarningPreference = "Continue"

# ANSI color codes for console output
$colors = @{
    Header    = "`e[1;36m"  # Cyan bold
    Section   = "`e[1;33m"  # Yellow bold
    Warning   = "`e[1;31m"  # Red bold
    Success   = "`e[1;32m"  # Green bold
    Info      = "`e[0;37m"  # White
    Reset     = "`e[0m"     # Reset
}

# Audit configuration
$auditConfig = @{
    # Paths to scan (from .ai-context.md v3.1)
    ScanPaths = @(
        @{ Path = "C:\"; Name = "C:\ Drive Root"; Depth = 1; Include = @("SecurityNow*", "sn-*", "*test*", "*Test*") }
        @{ Path = "D:\"; Name = "D:\ Drive Root"; Depth = 1; Include = @("SecurityNow*", "sn-*", "*test*", "*Test*") }
        @{ Path = "D:\Desktop"; Name = "D:\Desktop"; Depth = 2; Include = @("*") }
        @{ Path = "D:\Desktop\SecurityNow-Full"; Name = "Primary Repo (Private)"; Depth = 3; Include = @("*") }
        @{ Path = "D:\Desktop\SecurityNow-Full-Public"; Name = "Public Repo"; Depth = 3; Include = @("*") }
    )
    
    # Patterns for obsolete/test files
    ObsoletePatterns = @{
        # Old sync scripts (replaced by Special-Sync.ps1)
        "Sync-Repos.ps1" = "Obsolete sync script - replaced by Special-Sync.ps1"
        "Sync-Repo.ps1" = "Typo version - never existed, but AI might have created it"
        
        # Test/diagnostic scripts
        "Diagnose-Sync.ps1" = "Temporary diagnostic script"
        "*-test.ps1" = "Test script pattern"
        "*-Test.ps1" = "Test script pattern (capitalized)"
        "test-*.ps1" = "Test script prefix pattern"
        "Test-*.ps1" = "Test script prefix pattern (capitalized)"
        
        # Versioned scripts (only production version needed)
        "sn-full-run-v*.ps1" = "Versioned script - only production sn-full-run.ps1 needed"
        "sn-full-run.v*.ps1" = "Versioned script alternate naming"
        "*-v[0-9]*.ps1" = "Generic versioned script pattern"
        
        # Delete/cleanup temp files
        "delete*.txt" = "Temporary delete list files"
        "cleanup*.txt" = "Temporary cleanup list files"
        "temp-*.ps1" = "Temporary PowerShell scripts"
        
        # Old naming conventions
        "SecurityNowNotesIndex-old.csv" = "Old CSV backup"
        "SecurityNowNotesIndex.bak" = "CSV backup file"
        "*.tmp" = "Temporary files"
        "*.bak" = "Backup files"
    }
    
    # Patterns for orphaned directories
    OrphanedDirPatterns = @(
        "D:\SecurityNow-Test"
        "D:\SecurityNow-Full-Archive"  # Wrong path created by AI in error
        "D:\Desktop\SecurityNow-Test*"
        "D:\Desktop\*-old"
        "D:\Desktop\*-backup"
    )
    
    # Documentation files to check for path errors
    DocsToCheck = @(
        "README.md"
        "WORKFLOW.md"
        "FAQ.md"
        "TROUBLESHOOTING.md"
        "QUICK-START*.md"
        "PROJECT-STATUS.md"
        ".ai-context.md"
    )
    
    # Wrong paths to flag in documentation
    WrongPaths = @(
        "D:\Desktop\SecurityNow-Full-Archive\"  # Wrong repo path
        "C:\whisper.cpp\"                       # Wrong Whisper path (has dot)
        "Sync-Repos.ps1"                        # Wrong sync script name
        "Sync-Repo.ps1"                         # Wrong sync script name
    )
}

# ============================================================
# FUNCTIONS
# ============================================================

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "Info",
        [switch]$NoNewline
    )
    
    $colorCode = $colors[$Color]
    if ($NoNewline) {
        Write-Host "$colorCode$Message$($colors.Reset)" -NoNewline
    } else {
        Write-Host "$colorCode$Message$($colors.Reset)"
    }
}

function Get-FormattedSize {
    param([long]$Bytes)
    
    if ($Bytes -ge 1GB) { return "{0:N2} GB" -f ($Bytes / 1GB) }
    if ($Bytes -ge 1MB) { return "{0:N2} MB" -f ($Bytes / 1MB) }
    if ($Bytes -ge 1KB) { return "{0:N2} KB" -f ($Bytes / 1KB) }
    return "$Bytes bytes"
}

function Test-ObsoleteFile {
    param(
        [System.IO.FileInfo]$File,
        [hashtable]$Patterns
    )
    
    foreach ($pattern in $Patterns.Keys) {
        if ($File.Name -like $pattern) {
            return @{
                IsObsolete = $true
                Reason = $Patterns[$pattern]
                Pattern = $pattern
            }
        }
    }
    
    return @{ IsObsolete = $false }
}

function Search-PathInFile {
    param(
        [string]$FilePath,
        [string[]]$SearchPatterns
    )
    
    try {
        $content = Get-Content -Path $FilePath -Raw -ErrorAction Stop
        $found = @()
        
        foreach ($pattern in $SearchPatterns) {
            if ($content -match [regex]::Escape($pattern)) {
                $found += $pattern
            }
        }
        
        return $found
    } catch {
        return @()
    }
}

# ============================================================
# MAIN AUDIT LOGIC
# ============================================================

Write-ColorOutput "═══════════════════════════════════════════════════════════════" "Header"
Write-ColorOutput "  Security Now Archive Tools - System Cleanup Audit v1.0" "Header"
Write-ColorOutput "═══════════════════════════════════════════════════════════════" "Header"
Write-ColorOutput ""
Write-ColorOutput "Audit started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" "Info"
Write-ColorOutput "Report will be saved to: $ReportPath" "Info"
Write-ColorOutput ""

# Initialize report
$report = @()
$report += "═══════════════════════════════════════════════════════════════"
$report += "  Security Now Archive Tools - System Cleanup Audit"
$report += "═══════════════════════════════════════════════════════════════"
$report += "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$report += "Machine: $env:COMPUTERNAME"
$report += "User: $env:USERNAME"
$report += ""

# Results tracking
$results = @{
    ObsoleteFiles = @()
    OrphanedDirs = @()
    DocsWithWrongPaths = @()
    TotalFilesScanned = 0
    TotalDirsScanned = 0
    TotalSizeReclaimed = 0
}

# ============================================================
# SCAN 1: Check for orphaned directories
# ============================================================

Write-ColorOutput "───────────────────────────────────────────────────────────────" "Section"
Write-ColorOutput "[1/3] Scanning for Orphaned Directories..." "Section"
Write-ColorOutput "───────────────────────────────────────────────────────────────" "Section"

$report += "═══════════════════════════════════════════════════════════════"
$report += "ORPHANED DIRECTORIES"
$report += "═══════════════════════════════════════════════════════════════"
$report += ""

foreach ($pattern in $auditConfig.OrphanedDirPatterns) {
    $dirs = Get-ChildItem -Path (Split-Path $pattern -Parent) -Directory -Filter (Split-Path $pattern -Leaf) -ErrorAction SilentlyContinue
    
    foreach ($dir in $dirs) {
        if (Test-Path $dir.FullName) {
            $size = (Get-ChildItem -Path $dir.FullName -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
            $fileCount = (Get-ChildItem -Path $dir.FullName -Recurse -File -ErrorAction SilentlyContinue).Count
            
            $results.OrphanedDirs += @{
                Path = $dir.FullName
                Size = $size
                FileCount = $fileCount
            }
            
            $results.TotalSizeReclaimed += $size
            $results.TotalDirsScanned++
            
            Write-ColorOutput "  ⚠️  FOUND: $($dir.FullName)" "Warning"
            Write-ColorOutput "      Size: $(Get-FormattedSize $size) ($fileCount files)" "Info"
            
            $report += "❌ Orphaned Directory: $($dir.FullName)"
            $report += "   Size: $(Get-FormattedSize $size) ($fileCount files)"
            $report += "   Recommendation: Review contents and remove if obsolete"
            $report += ""
        }
    }
}

if ($results.OrphanedDirs.Count -eq 0) {
    Write-ColorOutput "  ✓ No orphaned directories found" "Success"
    $report += "✓ No orphaned directories found"
} else {
    Write-ColorOutput "  Total orphaned directories: $($results.OrphanedDirs.Count)" "Warning"
    $report += "Total Orphaned Directories: $($results.OrphanedDirs.Count)"
}

$report += ""
Write-ColorOutput ""

# ============================================================
# SCAN 2: Scan paths for obsolete files
# ============================================================

Write-ColorOutput "───────────────────────────────────────────────────────────────" "Section"
Write-ColorOutput "[2/3] Scanning for Obsolete Files..." "Section"
Write-ColorOutput "───────────────────────────────────────────────────────────────" "Section"

$report += "═══════════════════════════════════════════════════════════════"
$report += "OBSOLETE FILES"
$report += "═══════════════════════════════════════════════════════════════"
$report += ""

foreach ($scanPath in $auditConfig.ScanPaths) {
    if (-not (Test-Path $scanPath.Path)) {
        Write-ColorOutput "  ⊘ SKIP: $($scanPath.Name) (path not found)" "Info"
        continue
    }
    
    Write-ColorOutput "  Scanning: $($scanPath.Name)..." "Info"
    
    $gciParams = @{
        Path = $scanPath.Path
        Recurse = $true
        File = $true
        ErrorAction = "SilentlyContinue"
    }
    
    if ($scanPath.Depth) {
        $gciParams.Depth = $scanPath.Depth
    }
    
    if (-not $IncludeHiddenFiles) {
        $gciParams.Force = $false
    }
    
    $files = Get-ChildItem @gciParams | Where-Object {
        $file = $_
        $scanPath.Include | ForEach-Object { $file.Name -like $_ } | Where-Object { $_ -eq $true }
    }
    
    foreach ($file in $files) {
        $results.TotalFilesScanned++
        
        $obsoleteCheck = Test-ObsoleteFile -File $file -Patterns $auditConfig.ObsoletePatterns
        
        if ($obsoleteCheck.IsObsolete) {
            $results.ObsoleteFiles += @{
                Path = $file.FullName
                Size = $file.Length
                Reason = $obsoleteCheck.Reason
                Pattern = $obsoleteCheck.Pattern
            }
            
            $results.TotalSizeReclaimed += $file.Length
            
            Write-ColorOutput "    ⚠️  $($file.FullName)" "Warning"
            Write-ColorOutput "       Reason: $($obsoleteCheck.Reason)" "Info"
            Write-ColorOutput "       Size: $(Get-FormattedSize $file.Length)" "Info"
            
            $report += "❌ Obsolete File: $($file.FullName)"
            $report += "   Reason: $($obsoleteCheck.Reason)"
            $report += "   Pattern: $($obsoleteCheck.Pattern)"
            $report += "   Size: $(Get-FormattedSize $file.Length)"
            $report += ""
        }
    }
}

if ($results.ObsoleteFiles.Count -eq 0) {
    Write-ColorOutput "  ✓ No obsolete files found" "Success"
    $report += "✓ No obsolete files found"
} else {
    Write-ColorOutput "  Total obsolete files: $($results.ObsoleteFiles.Count)" "Warning"
    $report += "Total Obsolete Files: $($results.ObsoleteFiles.Count)"
}

$report += ""
Write-ColorOutput ""

# ============================================================
# SCAN 3: Check documentation for wrong paths
# ============================================================

Write-ColorOutput "───────────────────────────────────────────────────────────────" "Section"
Write-ColorOutput "[3/3] Checking Documentation for Wrong Paths..." "Section"
Write-ColorOutput "───────────────────────────────────────────────────────────────" "Section"

$report += "═══════════════════════════════════════════════════════════════"
$report += "DOCUMENTATION WITH WRONG PATHS"
$report += "═══════════════════════════════════════════════════════════════"
$report += ""

$repoPaths = @(
    "D:\Desktop\SecurityNow-Full",
    "D:\Desktop\SecurityNow-Full-Public"
)

foreach ($repoPath in $repoPaths) {
    if (-not (Test-Path $repoPath)) { continue }
    
    Write-ColorOutput "  Checking: $repoPath..." "Info"
    
    foreach ($docPattern in $auditConfig.DocsToCheck) {
        $docs = Get-ChildItem -Path $repoPath -Filter $docPattern -Recurse -File -ErrorAction SilentlyContinue
        
        foreach ($doc in $docs) {
            $wrongPaths = Search-PathInFile -FilePath $doc.FullName -SearchPatterns $auditConfig.WrongPaths
            
            if ($wrongPaths.Count -gt 0) {
                $results.DocsWithWrongPaths += @{
                    Path = $doc.FullName
                    WrongPaths = $wrongPaths
                }
                
                Write-ColorOutput "    ⚠️  $($doc.FullName)" "Warning"
                foreach ($wrongPath in $wrongPaths) {
                    Write-ColorOutput "       Contains: $wrongPath" "Info"
                }
                
                $report += "❌ Documentation with wrong paths: $($doc.FullName)"
                $report += "   Wrong paths found:"
                foreach ($wrongPath in $wrongPaths) {
                    $report += "     - $wrongPath"
                }
                $report += ""
            }
        }
    }
}

if ($results.DocsWithWrongPaths.Count -eq 0) {
    Write-ColorOutput "  ✓ No documentation issues found" "Success"
    $report += "✓ No documentation with wrong paths found"
} else {
    Write-ColorOutput "  Total docs with issues: $($results.DocsWithWrongPaths.Count)" "Warning"
    $report += "Total Documentation Files with Issues: $($results.DocsWithWrongPaths.Count)"
}

$report += ""
Write-ColorOutput ""

# ============================================================
# SUMMARY
# ============================================================

Write-ColorOutput "═══════════════════════════════════════════════════════════════" "Header"
Write-ColorOutput "  AUDIT SUMMARY" "Header"
Write-ColorOutput "═══════════════════════════════════════════════════════════════" "Header"
Write-ColorOutput ""

$report += "═══════════════════════════════════════════════════════════════"
$report += "AUDIT SUMMARY"
$report += "═══════════════════════════════════════════════════════════════"
$report += ""

$summaryLines = @(
    "Files Scanned: $($results.TotalFilesScanned)",
    "Directories Scanned: $($results.TotalDirsScanned)",
    "",
    "Issues Found:",
    "  - Obsolete Files: $($results.ObsoleteFiles.Count)",
    "  - Orphaned Directories: $($results.OrphanedDirs.Count)",
    "  - Docs with Wrong Paths: $($results.DocsWithWrongPaths.Count)",
    "",
    "Total Disk Space Reclaimable: $(Get-FormattedSize $results.TotalSizeReclaimed)"
)

foreach ($line in $summaryLines) {
    Write-ColorOutput $line "Info"
    $report += $line
}

$report += ""
Write-ColorOutput ""

# ============================================================
# RECOMMENDATIONS
# ============================================================

if (($results.ObsoleteFiles.Count -gt 0) -or ($results.OrphanedDirs.Count -gt 0) -or ($results.DocsWithWrongPaths.Count -gt 0)) {
    Write-ColorOutput "───────────────────────────────────────────────────────────────" "Section"
    Write-ColorOutput "RECOMMENDATIONS" "Section"
    Write-ColorOutput "───────────────────────────────────────────────────────────────" "Section"
    Write-ColorOutput ""
    
    $report += "═══════════════════════════════════════════════════════════════"
    $report += "RECOMMENDATIONS"
    $report += "═══════════════════════════════════════════════════════════════"
    $report += ""
    
    $recommendations = @(
        "1. BACKUP FIRST",
        "   - Create backup of both repos before deletion",
        "   - Command: Copy-Item -Recurse -Path 'D:\Desktop\SecurityNow-Full' -Destination 'D:\Backup\SecurityNow-Full-$(Get-Date -Format yyyyMMdd)'",
        "",
        "2. REVIEW OBSOLETE FILES",
        "   - Manually verify each file before deletion",
        "   - Check if any contain unique logic not in production versions",
        "",
        "3. REMOVE ORPHANED DIRECTORIES",
        "   - D:\SecurityNow-Test\ - Old test sandbox",
        "   - D:\SecurityNow-Full-Archive\ - Created by AI in error",
        "",
        "4. UPDATE DOCUMENTATION",
        "   - Replace wrong paths with correct ones from .ai-context.md v3.1",
        "   - Correct repo path: D:\Desktop\SecurityNow-Full\",
        "   - Correct sync script: Special-Sync.ps1",
        "",
        "5. VERIFY PRODUCTION STATE",
        "   - Confirm sn-full-run.ps1 (single version, no v*.ps1)",
        "   - Confirm Special-Sync.ps1 exists and works",
        "   - Run test: .\scripts\sn-full-run.ps1 -DryRun -MinEpisode 1 -MaxEpisode 1"
    )
    
    foreach ($rec in $recommendations) {
        Write-ColorOutput $rec "Info"
        $report += $rec
    }
    
    $report += ""
    Write-ColorOutput ""
}

# ============================================================
# SAVE REPORT
# ============================================================

try {
    $report | Out-File -FilePath $ReportPath -Encoding UTF8 -Force
    Write-ColorOutput "✓ Report saved successfully: $ReportPath" "Success"
    Write-ColorOutput ""
} catch {
    Write-ColorOutput "✗ Failed to save report: $_" "Warning"
}

Write-ColorOutput "═══════════════════════════════════════════════════════════════" "Header"
Write-ColorOutput "  Audit Complete - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" "Header"
Write-ColorOutput "═══════════════════════════════════════════════════════════════" "Header"
Write-ColorOutput ""

# Return results object for programmatic use
return $results
]]>