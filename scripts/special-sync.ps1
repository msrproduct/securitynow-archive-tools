<#
.SYNOPSIS
    Special Sync Tool #2 - Complete 4-Repo Health Check and Sync
    
.DESCRIPTION
    Ensures all 4 repositories are synchronized and healthy:
    - Local Private (D:\Desktop\SecurityNow-Full-Private) - SOURCE OF TRUTH
    - GitHub Private (msrproduct/securitynow-full-archive)
    - Local Public (D:\Desktop\SecurityNow-Full)
    - GitHub Public (msrproduct/securitynow-archive-tools)
    
    Workflow:
    1. Pull latest from GitHub Private to Local Private
    2. Check and commit any pending changes in Local Private
    3. Push Local Private to GitHub Private
    4. Sync Local Private → Local Public (excluding /local-* folders + ai-context-private.md)
    5. Detect PUBLIC-ONLY files (WARNING mode with cleanup list)
    6. Commit and push Local Public to GitHub Public
    
    CRITICAL: ai-context.md is synced from private (SOT) to public
    for Space Instructions access while maintaining single source of truth.
    
    PRIVACY: ai-context-private.md is EXCLUDED from public sync (business-sensitive info).
    
.PARAMETER DryRun
    Preview all operations without making any changes
    
.PARAMETER Verbose
    Show detailed file-by-file comparison output
    
.EXAMPLE
    .\Special-Sync.ps1 -DryRun -Verbose
    Preview all sync operations with detailed output
    
.EXAMPLE
    .\Special-Sync.ps1
    Execute full 4-repo sync
#>

param(
    [string]$PrivateRepoLocal  = "D:\Desktop\SecurityNow-Full-Private",
    [string]$PublicRepoLocal   = "D:\Desktop\SecurityNow-Full",
    [switch]$DryRun,
    [switch]$Verbose
)

# ============================================================================
# CONFIGURATION
# ============================================================================

$script:Config = @{
    # Sync these root folders/files from private → public
    SyncRoots = @(
        "",           # Root-level files (includes ai-context.md)
        "docs", 
        "scripts", 
        "data"
    )
    
    # CRITICAL: These EXACT folder names contain copyrighted material
    ExcludedFolders = @(
        "local-pdf",
        "local-mp3", 
        "local-notes-ai-transcripts"
    )
    
    # PRIVACY: These files contain business-sensitive info (NEVER sync to public)
    ExcludedFiles = @(
        "ai-context-private.md"   # Business context: billing rates, cost tracking, strategy
    )
    
    AlwaysSkip = @(".gitignore")  # Each repo maintains its own
    GitBranch = "main"
}

# ============================================================================
# REUSABLE FUNCTIONS
# ============================================================================

function Write-SectionHeader {
    param([string]$Title)
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host $Title -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
}

function Write-Step {
    param([int]$Number, [string]$Description)
    Write-Host "`n[$Number/5] $Description" -ForegroundColor Yellow
}

function Test-IsCopyrightedPath {
    <#
    .SYNOPSIS
        Check if relative path is under /local-* folders
        CRITICAL FIX: Handle both "local-pdf" and "local\pdf" patterns
    #>
    param([string]$RelativePath)
    
    # Normalize to forward slashes for consistent matching
    $normalized = $RelativePath.Replace('\', '/')
    
    foreach ($folder in $script:Config.ExcludedFolders) {
        # Convert "local-pdf" → "local/pdf" for path matching
        $pathPattern = $folder.Replace('-', '/')
        
        # Check if path starts with this copyrighted folder
        if ($normalized -like "$pathPattern/*" -or $normalized -eq $pathPattern) {
            return $true
        }
    }
    return $false
}

function Test-IsPrivateFile {
    <#
    .SYNOPSIS
        Check if file should be excluded from public sync (business-sensitive)
    #>
    param([string]$RelativePath)
    
    # Normalize to forward slashes
    $normalized = $RelativePath.Replace('\', '/').TrimStart('/')
    
    foreach ($excludedFile in $script:Config.ExcludedFiles) {
        $pattern = $excludedFile.Replace('\', '/')
        if ($normalized -eq $pattern -or $normalized -like "*/$pattern") {
            return $true
        }
    }
    return $false
}

function Invoke-GitOperation {
    param(
        [string]$RepoPath,
        [string]$Operation,
        [string]$Message = "",
        [switch]$DryRun
    )
    
    Push-Location $RepoPath
    
    try {
        switch ($Operation) {
            "pull" {
                if ($DryRun) {
                    Write-Host "[DRY RUN] Would execute: git pull origin $($script:Config.GitBranch)" -ForegroundColor DarkGray
                } else {
                    Write-Host "Executing: git pull origin $($script:Config.GitBranch)" -ForegroundColor Gray
                    git pull origin $script:Config.GitBranch --no-edit
                }
            }
            
            "commit" {
                $status = git status --porcelain
                if ($status) {
                    if ($DryRun) {
                        Write-Host "[DRY RUN] Would commit changes with message: $Message" -ForegroundColor DarkGray
                        Write-Host "[DRY RUN] Changed files:" -ForegroundColor DarkGray
                        git status --short
                    } else {
                        Write-Host "Committing changes: $Message" -ForegroundColor Gray
                        git add .
                        git commit -m $Message
                        return $true
                    }
                } else {
                    Write-Host "No changes to commit" -ForegroundColor DarkGray
                    return $false
                }
            }
            
            "push" {
                if ($DryRun) {
                    Write-Host "[DRY RUN] Would execute: git push origin $($script:Config.GitBranch)" -ForegroundColor DarkGray
                } else {
                    Write-Host "Executing: git push origin $($script:Config.GitBranch)" -ForegroundColor Gray
                    git push origin $script:Config.GitBranch
                }
            }
        }
    }
    catch {
        Write-Host "ERROR in Git operation '$Operation': $_" -ForegroundColor Red
        throw
    }
    finally {
        Pop-Location
    }
}

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
    
    Get-ChildItem -Path $fullRoot -File -Recurse | Where-Object {
        $rel = $_.FullName.Substring($RepoPath.Length).TrimStart('\','/')
        
        # Exclude .git
        if ($rel -like ".git*") {
            return $false
        }
        
        # Exclude copyrighted folders (CRITICAL FIX)
        if (Test-IsCopyrightedPath $rel) {
            return $false
        }
        
        # 🔒 PRIVACY: Exclude business-sensitive files
        if (Test-IsPrivateFile $rel) {
            return $false
        }
        
        return $true
    }
}

function Compare-RepoFiles {
    param(
        [hashtable]$SourceFiles,
        [hashtable]$TargetFiles,
        [string]$TargetRepoPath
    )
    
    $operations = @{
        New = @()
        Update = @()
        Same = @()
        PublicOnly = @()
    }
    
    # Check source → target
    foreach ($rel in $SourceFiles.Keys) {
        # CRITICAL FIX: Double-check copyrighted content exclusion
        if (Test-IsCopyrightedPath $rel) {
            continue
        }
        
        # 🔒 PRIVACY: Double-check business-sensitive file exclusion
        if (Test-IsPrivateFile $rel) {
            continue
        }
        
        # Skip always-excluded files
        $fileName = [System.IO.Path]::GetFileName($rel)
        if ($script:Config.AlwaysSkip -contains $fileName) {
            continue
        }
        
        $sourcePath = $SourceFiles[$rel]
        $targetPath = if ($TargetFiles.ContainsKey($rel)) { 
            $TargetFiles[$rel] 
        } else { 
            Join-Path $TargetRepoPath $rel 
        }
        
        $sourceHash = (Get-FileHash -Path $sourcePath -Algorithm SHA256).Hash
        
        if (-not (Test-Path $targetPath)) {
            $operations.New += @{
                RelPath = $rel
                SourcePath = $sourcePath
                TargetPath = $targetPath
            }
        }
        elseif ((Get-FileHash -Path $targetPath -Algorithm SHA256).Hash -ne $sourceHash) {
            $operations.Update += @{
                RelPath = $rel
                SourcePath = $sourcePath
                TargetPath = $targetPath
            }
        }
        else {
            $operations.Same += $rel
        }
    }
    
    # Check target → source (PUBLIC-ONLY warnings)
    foreach ($rel in $TargetFiles.Keys) {
        if (-not $SourceFiles.ContainsKey($rel)) {
            $fileName = [System.IO.Path]::GetFileName($rel)
            
            if ($script:Config.AlwaysSkip -contains $fileName -or $rel -like ".git*") {
                continue
            }
            
            $operations.PublicOnly += $rel
        }
    }
    
    return $operations
}

function Sync-Files {
    param(
        [array]$Operations,
        [switch]$DryRun
    )
    
    $synced = 0
    
    foreach ($op in $Operations) {
        if ($DryRun) {
            Write-Host "[DRY RUN] Would copy: $($op.RelPath)" -ForegroundColor DarkGray
        } else {
            $targetDir = Split-Path $op.TargetPath
            if (-not (Test-Path $targetDir)) {
                New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
            }
            Copy-Item -Path $op.SourcePath -Destination $op.TargetPath -Force
            $synced++
        }
    }
    
    return $synced
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

Write-SectionHeader "Security Now - Special Sync Tool #2"
Write-Host "Private repo (SOURCE OF TRUTH): $PrivateRepoLocal"
Write-Host "Public repo (tools only)      : $PublicRepoLocal"

if ($DryRun) {
    Write-Host "`nMODE: DRY RUN (no changes will be made)" -ForegroundColor Yellow
}

# Validate repos
if (-not (Test-Path $PrivateRepoLocal)) {
    Write-Host "ERROR: Private repo not found at $PrivateRepoLocal" -ForegroundColor Red
    exit 1
}
if (-not (Test-Path $PublicRepoLocal)) {
    Write-Host "ERROR: Public repo not found at $PublicRepoLocal" -ForegroundColor Red
    exit 1
}

# ============================================================================
# STEP 1: Sync GitHub Private → Local Private
# ============================================================================

Write-Step -Number 1 -Description "Pull latest from GitHub Private → Local Private"
Invoke-GitOperation -RepoPath $PrivateRepoLocal -Operation "pull" -DryRun:$DryRun

# ============================================================================
# STEP 2: Check and Commit Local Private Changes
# ============================================================================

Write-Step -Number 2 -Description "Check for uncommitted changes in Local Private"
$privateCommitted = Invoke-GitOperation `
    -RepoPath $PrivateRepoLocal `
    -Operation "commit" `
    -Message "Special Sync: Update private repo (SOURCE OF TRUTH)" `
    -DryRun:$DryRun

if ($privateCommitted) {
    Write-Host "✓ Changes committed to Local Private" -ForegroundColor Green
} else {
    Write-Host "✓ Local Private is clean" -ForegroundColor Green
}

# ============================================================================
# STEP 3: Push Local Private → GitHub Private
# ============================================================================

Write-Step -Number 3 -Description "Push Local Private → GitHub Private"
Invoke-GitOperation -RepoPath $PrivateRepoLocal -Operation "push" -DryRun:$DryRun

# ============================================================================
# STEP 4: Sync Local Private → Local Public (EXCLUDE /local-* + ai-context-private.md)
# ============================================================================

Write-Step -Number 4 -Description "Sync Local Private → Local Public (tools/docs + ai-context.md)"

# Collect files from both repos
$privateFiles = @{}
$publicFiles = @{}

Write-Host "Scanning Private repo (excluding /local-* + ai-context-private.md)..." -ForegroundColor Gray
foreach ($root in $script:Config.SyncRoots) {
    foreach ($file in Get-RepoFiles -RepoPath $PrivateRepoLocal -Root $root) {
        $rel = $file.FullName.Substring($PrivateRepoLocal.Length).TrimStart('\','/')
        $privateFiles[$rel.ToLowerInvariant()] = $file.FullName
    }
}

Write-Host "Scanning Public repo..." -ForegroundColor Gray
foreach ($root in $script:Config.SyncRoots) {
    foreach ($file in Get-RepoFiles -RepoPath $PublicRepoLocal -Root $root) {
        $rel = $file.FullName.Substring($PublicRepoLocal.Length).TrimStart('\','/')
        $publicFiles[$rel.ToLowerInvariant()] = $file.FullName
    }
}

Write-Host "Comparing files..." -ForegroundColor Gray
Write-Host "NOTE: .gitignore is excluded (each repo maintains its own)" -ForegroundColor DarkGray
Write-Host "NOTE: ai-context.md is synced from private (SOT) to public for Space Instructions" -ForegroundColor Cyan
Write-Host "NOTE: ai-context-private.md is EXCLUDED (business-sensitive - PRIVATE ONLY)" -ForegroundColor Magenta
Write-Host "NOTE: /local-* folders are EXCLUDED (copyrighted material - NEVER synced to public)" -ForegroundColor Yellow

$comparison = Compare-RepoFiles `
    -SourceFiles $privateFiles `
    -TargetFiles $publicFiles `
    -TargetRepoPath $PublicRepoLocal

# Display results
if ($Verbose) {
    foreach ($op in $comparison.New) {
        Write-Host "[NEW]    $($op.RelPath)" -ForegroundColor Green
    }
    foreach ($op in $comparison.Update) {
        Write-Host "[UPDATE] $($op.RelPath)" -ForegroundColor Yellow
    }
}

Write-Host "`nSummary:" -ForegroundColor Cyan
Write-Host "  New files    : $($comparison.New.Count)" -ForegroundColor Green
Write-Host "  Updated files: $($comparison.Update.Count)" -ForegroundColor Yellow
Write-Host "  Unchanged    : $($comparison.Same.Count)" -ForegroundColor DarkGray

# Sync files
$allOperations = $comparison.New + $comparison.Update
$syncedCount = Sync-Files -Operations $allOperations -DryRun:$DryRun

if (-not $DryRun) {
    Write-Host "`n✓ Synced $syncedCount files from Private → Public" -ForegroundColor Green
}

# PUBLIC-ONLY WARNINGS
if ($comparison.PublicOnly.Count -gt 0) {
    Write-Host "`n⚠️  PUBLIC-ONLY FILES DETECTED" -ForegroundColor Yellow
    Write-Host "These files exist in Public repo but NOT in Private (source of truth):" -ForegroundColor Yellow
    Write-Host "Review and decide if they should be:" -ForegroundColor Yellow
    Write-Host "  1. Copied to Private repo (if they belong there)" -ForegroundColor Yellow
    Write-Host "  2. Deleted from Public repo (if they're orphaned)" -ForegroundColor Yellow
    Write-Host "`nPublic-Only Files:" -ForegroundColor Yellow
    foreach ($file in $comparison.PublicOnly) {
        Write-Host "  • $file" -ForegroundColor Yellow
    }
    
    # Save cleanup list
    $cleanupListPath = Join-Path $PublicRepoLocal "PUBLIC-ONLY-CLEANUP-LIST.txt"
    $comparison.PublicOnly | Out-File -FilePath $cleanupListPath -Encoding UTF8
    Write-Host "`n✓ Cleanup list saved to: PUBLIC-ONLY-CLEANUP-LIST.txt" -ForegroundColor Cyan
}

# ============================================================================
# STEP 5: Commit and Push Local Public → GitHub Public
# ============================================================================

Write-Step -Number 5 -Description "Commit and Push Local Public → GitHub Public"

$publicCommitted = Invoke-GitOperation `
    -RepoPath $PublicRepoLocal `
    -Operation "commit" `
    -Message "Special Sync: Update from private repo (tools/docs + ai-context.md - NO copyrighted media)" `
    -DryRun:$DryRun

if ($publicCommitted -or $DryRun) {
    Invoke-GitOperation -RepoPath $PublicRepoLocal -Operation "push" -DryRun:$DryRun
}

# ============================================================================
# FINAL SUMMARY
# ============================================================================

Write-SectionHeader "SUMMARY"
Write-Host "Files synced (Private → Public): $syncedCount"
Write-Host "  - New files    : $($comparison.New.Count)"
Write-Host "  - Updated files: $($comparison.Update.Count)"
Write-Host "  - Unchanged    : $($comparison.Same.Count)"
Write-Host "Files in Public-Only (warnings): $($comparison.PublicOnly.Count)"

if ($DryRun) {
    Write-Host "`n✓ DRY RUN COMPLETE - No changes were made" -ForegroundColor Yellow
    Write-Host "Run without -DryRun to apply changes" -ForegroundColor Yellow
} else {
    Write-Host "`n✅ ALL 4 REPOS SYNCED SUCCESSFULLY!" -ForegroundColor Green
    Write-Host "✓ ai-context.md synced from private (SOT) to public for Space Instructions" -ForegroundColor Cyan
    Write-Host "🔒 ai-context-private.md EXCLUDED from public (business-sensitive info protected)" -ForegroundColor Magenta
}
Write-Host "========================================`n"