param(
    [string]$PrivateRepo = "D:\Desktop\SecurityNow-Full-Private",
    [string]$PublicRepo  = "D:\Desktop\SecurityNow-Full",
    [switch]$DryRun,
    [switch]$Verbose,
    [string]$PrivateCommitMessage = "Sync: update private repo before public sync",
    [string]$PublicCommitMessage  = "Sync from private repo (Sync-Repos.ps1: private→public + public-only warning)"
)

Write-Host "Security Now Repo Sync" -ForegroundColor Cyan
Write-Host "Private repo: $PrivateRepo"
Write-Host "Public repo : $PublicRepo"
if ($DryRun) {
    Write-Host "MODE DRY RUN (no changes will be made)" -ForegroundColor Yellow
}

# Folders we sync (relative to repo root)
$syncRoots = @(
    "",              # README.md, LICENSE, FUNDING.yml, etc.
    "docs",
    "scripts",
    "data"           # data\SecurityNowNotesIndex.csv when present
)

# Copyrighted / excluded folders (under private)
$excludedFolders = @(
    "local-pdf",
    "local-mp3",
    "local-notes-ai-transcripts",
    "local\pdf",
    "local\mp3",
    "local\notes\ai-transcripts"
)

# Extensions that must NEVER be synced to public
$blockedExtensions = @(".pdf", ".mp3", ".m4a", ".flac", ".wav")

# 0) STEP ZERO: Ensure private repo is up-to-date with remote (fast-forward only)
if (-not $DryRun) {
    Write-Host ""
    Write-Host "STEP 0: Updating private repo from remote (fast-forward only)..." -ForegroundColor Cyan
    Push-Location $PrivateRepo
    try {
        Write-Host "Running: git pull origin main --ff-only" -ForegroundColor DarkGray
        git pull origin main --ff-only
        if ($LASTEXITCODE -ne 0) {
            throw "git pull origin main --ff-only failed with exit code $LASTEXITCODE"
        }
    }
    finally {
        Pop-Location
    }
}
else {
    Write-Host ""
    Write-Host "STEP 0 (DRY RUN): Would run 'git pull origin main --ff-only' in private repo." -ForegroundColor Yellow
}

# 1) STEP ONE: Commit & push private repo changes (if any)
if (-not $DryRun) {
    Write-Host ""
    Write-Host "STEP 1: Committing and pushing private repo changes..." -ForegroundColor Cyan

    Push-Location $PrivateRepo
    try {
        $status = git status --porcelain
        if ($LASTEXITCODE -ne 0) {
            throw "git status failed in private repo"
        }

        if ([string]::IsNullOrWhiteSpace($status)) {
            if ($Verbose) {
                Write-Host "Private repo: no changes to commit." -ForegroundColor DarkGray
            }
        }
        else {
            if ($Verbose) {
                Write-Host "Private repo has changes:" -ForegroundColor Yellow
                $status
            }

            git add .
            if ($LASTEXITCODE -ne 0) {
                throw "git add failed in private repo"
            }

            git commit -m $PrivateCommitMessage
            if ($LASTEXITCODE -ne 0) {
                throw "git commit failed in private repo"
            }

            git push origin main
            if ($LASTEXITCODE -ne 0) {
                throw "git push failed in private repo"
            }

            Write-Host "Private repo changes committed and pushed." -ForegroundColor Green
        }
    }
    finally {
        Pop-Location
    }
}
else {
    Write-Host ""
    Write-Host "STEP 1 (DRY RUN): Would commit and push private repo changes if any exist." -ForegroundColor Yellow
}

# 2) STEP TWO: Build file maps for private vs public
$privateFiles = @{}
$publicFiles  = @{}

foreach ($root in $syncRoots) {
    # PRIVATE: map relative path (from private root) → full path
    $privateRoot = if ([string]::IsNullOrWhiteSpace($root)) { $PrivateRepo } else { Join-Path $PrivateRepo $root }
    if (Test-Path $privateRoot) {
        foreach ($file in Get-ChildItem -Path $privateRoot -File -Recurse -ErrorAction SilentlyContinue) {
            $rel = $file.FullName.Substring($PrivateRepo.Length).TrimStart('\','/')

            # 1) Exclude .git internals
            if ($rel -like ".git*") { continue }

            # 2) Exclude any file under copyrighted folders
            $exclude = $false
            foreach ($ex in $excludedFolders) {
                if ($rel -like "$ex*" -or $rel -like "*\$ex\*" -or $rel -like "*/$ex/*") {
                    $exclude = $true
                    break
                }
            }
            if ($exclude) { continue }

            # 3) Exclude any blocked media extensions anywhere
            $ext = [System.IO.Path]::GetExtension($file.Name).ToLowerInvariant()
            if ($blockedExtensions -contains $ext) { continue }

            $privateFiles[$rel.ToLowerInvariant()] = $file.FullName
        }
    }

    # PUBLIC: map relative path (from public root) → full path
    $publicRoot = if ([string]::IsNullOrWhiteSpace($root)) { $PublicRepo } else { Join-Path $PublicRepo $root }
    if (Test-Path $publicRoot) {
        foreach ($file in Get-ChildItem -Path $publicRoot -File -Recurse -ErrorAction SilentlyContinue) {
            $rel = $file.FullName.Substring($PublicRepo.Length).TrimStart('\','/')

            # Ignore .git internals only
            if ($rel -like ".git*") { continue }

            $publicFiles[$rel.ToLowerInvariant()] = $file.FullName
        }
    }
}

Write-Host ""
Write-Host "STEP 2: Comparing private and public repos..." -ForegroundColor Cyan
Write-Host "NOTE: .gitignore is excluded (each repo maintains its own)" -ForegroundColor DarkGray

# 3) STEP THREE: New / updated files from PRIVATE -> PUBLIC
$filesSynced  = 0
$filesSkipped = 0

foreach ($rel in $privateFiles.Keys) {
    $privatePath = $privateFiles[$rel]
    $publicPath  = if ($publicFiles.ContainsKey($rel)) { $publicFiles[$rel] } else { Join-Path $PublicRepo $rel }

    # Skip .gitignore entirely
    if ([System.IO.Path]::GetFileName($rel).ToLowerInvariant() -eq ".gitignore") {
        if ($Verbose) {
            Write-Host "SKIP  (EXCLUDE)  $rel (.gitignore is repo-specific)" -ForegroundColor DarkGray
        }
        $filesSkipped++
        continue
    }

    $privateHash = (Get-FileHash -Path $privatePath -Algorithm SHA256).Hash
    $publicHash  = $null

    if (Test-Path $publicPath) {
        $publicHash = (Get-FileHash -Path $publicPath -Algorithm SHA256).Hash
    }

    if (-not (Test-Path $publicPath)) {
        Write-Host "NEW   $rel" -ForegroundColor Green
        if (-not $DryRun) {
            New-Item -ItemType Directory -Path (Split-Path $publicPath) -Force | Out-Null
            Copy-Item $privatePath $publicPath -Force
        }
        $filesSynced++
    }
    elseif ($privateHash -ne $publicHash) {
        Write-Host "UPDATE $rel" -ForegroundColor Yellow
        if (-not $DryRun) {
            Copy-Item $privatePath $publicPath -Force
        }
        $filesSynced++
    }
    else {
        if ($Verbose) {
            Write-Host "SAME  $rel"
        }
    }
}

# 4) STEP FOUR: Check for files that exist only in PUBLIC (private should be superset)
$publicOnly = @()

foreach ($rel in $publicFiles.Keys) {
    if (-not $privateFiles.ContainsKey($rel)) {
        # Ignore .gitignore and .git internals
        $name = [System.IO.Path]::GetFileName($rel)
        if ($name.ToLowerInvariant() -eq ".gitignore" -or $rel -like ".git*") {
            continue
        }

        $publicOnly += $rel
    }
}

if ($publicOnly.Count -gt 0) {
    Write-Host ""
    Write-Host "WARNING: Detected files present in PUBLIC repo but missing in PRIVATE repo." -ForegroundColor Yellow
    Write-Host "Private is supposed to be the source of truth. Review and copy these into private:" -ForegroundColor Yellow
    foreach ($rel in $publicOnly) {
        Write-Host "  PUBLIC-ONLY: $rel" -ForegroundColor Yellow
    }
    $filesSkipped += $publicOnly.Count
}

Write-Host ""
Write-Host "SUMMARY" -ForegroundColor Cyan
Write-Host "Files synced (private → public): $filesSynced"
Write-Host "Files skipped                 : $filesSkipped"

# 5) STEP FIVE: Commit & push public repo changes (if any)
if ($DryRun) {
    Write-Host "DRY RUN COMPLETE - No changes were made anywhere." -ForegroundColor Yellow
}
else {
    if ($filesSynced -gt 0) {
        Write-Host ""
        Write-Host "STEP 5: Committing and pushing public repo changes..." -ForegroundColor Cyan

        Push-Location $PublicRepo
        try {
            git add .
            if ($LASTEXITCODE -ne 0) {
                throw "git add failed in public repo"
            }

            git commit -m $PublicCommitMessage
            $commitExit = $LASTEXITCODE

            if ($commitExit -ne 0) {
                # If nothing to commit, treat as already up to date (no push)
                $status = git status --porcelain
                if ($LASTEXITCODE -ne 0) {
                    throw "git status failed in public repo after commit attempt"
                }

                if ([string]::IsNullOrWhiteSpace($status)) {
                    Write-Host "Public repo: no changes to commit (already up to date)." -ForegroundColor DarkGray
                }
                else {
                    throw "git commit failed in public repo"
                }
            }
            else {
                git push origin main
                if ($LASTEXITCODE -ne 0) {
                    throw "git push failed in public repo"
                }

                Write-Host "Public repo changes committed and pushed." -ForegroundColor Green
            }
        }
        finally {
            Pop-Location
        }
    }
    else {
        Write-Host ""
        Write-Host "STEP 5: No public changes to commit or push (repos already in sync)." -ForegroundColor DarkGray
    }

    Write-Host ""
    Write-Host "COMPLETE: Private and public repos are in sync, with both GitHub remotes updated." -ForegroundColor Green
}
