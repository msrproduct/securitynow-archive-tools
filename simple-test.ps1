<#
.SYNOPSIS
    Simple file detection test - no complex logic
#>

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "SIMPLE FILE DETECTION TEST" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$privateRepo = "D:\Desktop\SecurityNow-Full-Private"
$publicRepo = "D:\Desktop\SecurityNow-Full"

# Test 1: Root-level files
Write-Host "=== PRIVATE REPO ROOT FILES ===" -ForegroundColor Yellow
Get-ChildItem $privateRepo -File | ForEach-Object { 
    Write-Host "  $($_.Name)" -ForegroundColor White
}

Write-Host "`n=== PUBLIC REPO ROOT FILES ===" -ForegroundColor Yellow
Get-ChildItem $publicRepo -File | ForEach-Object { 
    Write-Host "  $($_.Name)" -ForegroundColor White
}

# Test 2: Scripts folder
Write-Host "`n=== PRIVATE /scripts FOLDER ===" -ForegroundColor Yellow
if (Test-Path "$privateRepo\scripts") {
    Get-ChildItem "$privateRepo\scripts" -File | ForEach-Object { 
        Write-Host "  $($_.Name)" -ForegroundColor White
    }
} else {
    Write-Host "  [folder does not exist]" -ForegroundColor Red
}

Write-Host "`n=== PUBLIC /scripts FOLDER ===" -ForegroundColor Yellow
if (Test-Path "$publicRepo\scripts") {
    Get-ChildItem "$publicRepo\scripts" -File | ForEach-Object { 
        Write-Host "  $($_.Name)" -ForegroundColor White
    }
} else {
    Write-Host "  [folder does not exist]" -ForegroundColor Red
}

# Test 3: Docs folder
Write-Host "`n=== PRIVATE /docs FOLDER ===" -ForegroundColor Yellow
if (Test-Path "$privateRepo\docs") {
    Get-ChildItem "$privateRepo\docs" -File | ForEach-Object { 
        Write-Host "  $($_.Name)" -ForegroundColor White
    }
} else {
    Write-Host "  [folder does not exist]" -ForegroundColor Red
}

Write-Host "`n=== PUBLIC /docs FOLDER ===" -ForegroundColor Yellow
if (Test-Path "$publicRepo\docs") {
    Get-ChildItem "$publicRepo\docs" -File | ForEach-Object { 
        Write-Host "  $($_.Name)" -ForegroundColor White
    }
} else {
    Write-Host "  [folder does not exist]" -ForegroundColor Red
}

# Test 4: Find ALL delete*.txt files
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "SEARCHING FOR delete*.txt FILES" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "=== IN PRIVATE REPO ===" -ForegroundColor Yellow
$privateDeleteFiles = Get-ChildItem $privateRepo -Filter "delete*.txt" -Recurse -File -ErrorAction SilentlyContinue
if ($privateDeleteFiles.Count -eq 0) {
    Write-Host "  [no delete*.txt files found]" -ForegroundColor DarkGray
} else {
    foreach ($file in $privateDeleteFiles) {
        $relPath = $file.FullName.Substring($privateRepo.Length).TrimStart('\', '/')
        Write-Host "  $relPath" -ForegroundColor Green
    }
}
Write-Host "  Total: $($privateDeleteFiles.Count)" -ForegroundColor Cyan

Write-Host "`n=== IN PUBLIC REPO ===" -ForegroundColor Yellow
$publicDeleteFiles = Get-ChildItem $publicRepo -Filter "delete*.txt" -Recurse -File -ErrorAction SilentlyContinue
if ($publicDeleteFiles.Count -eq 0) {
    Write-Host "  [no delete*.txt files found]" -ForegroundColor DarkGray
} else {
    foreach ($file in $publicDeleteFiles) {
        $relPath = $file.FullName.Substring($publicRepo.Length).TrimStart('\', '/')
        Write-Host "  $relPath" -ForegroundColor Green
    }
}
Write-Host "  Total: $($publicDeleteFiles.Count)" -ForegroundColor Cyan

# Test 5: Total file count (excluding /local-*)
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "TOTAL FILE COUNTS" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$privateAll = Get-ChildItem $privateRepo -File -Recurse -ErrorAction SilentlyContinue | Where-Object {
    $rel = $_.FullName.Substring($privateRepo.Length).TrimStart('\', '/')
    -not ($rel -like 'local-pdf\*') -and
    -not ($rel -like 'local-mp3\*') -and
    -not ($rel -like 'local-notes-ai-transcripts\*') -and
    -not ($rel -like '.git\*')
}

$publicAll = Get-ChildItem $publicRepo -File -Recurse -ErrorAction SilentlyContinue | Where-Object {
    $rel = $_.FullName.Substring($publicRepo.Length).TrimStart('\', '/')
    -not ($rel -like '.git\*')
}

Write-Host "Private repo (excluding /local-*): $($privateAll.Count) files" -ForegroundColor White
Write-Host "Public repo                      : $($publicAll.Count) files" -ForegroundColor White

Write-Host "`n========================================`n" -ForegroundColor Cyan
