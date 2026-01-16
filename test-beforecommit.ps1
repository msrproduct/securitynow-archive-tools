<#
.SYNOPSIS
    Quick smoke test before committing changes to sn-full-run.ps1
.DESCRIPTION
    Runs basic validation to catch obvious errors before pushing to GitHub
.NOTES
    Version: 1.0
    Date: 2026-01-15
    Author: Security Now Archive Tools Project
#>

[CmdletBinding()]
param()

Write-Host "`n🔍 Running Pre-Commit Smoke Tests..." -ForegroundColor Cyan

$ErrorCount = 0

# Test 1: Script syntax is valid
Write-Host "`n✓ Test 1: PowerShell syntax validation" -ForegroundColor Yellow
try {
    $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content .\sn-full-run.ps1 -Raw), [ref]$null)
    Write-Host "  ✓ Syntax valid" -ForegroundColor Green
} catch {
    Write-Host "  ✗ Syntax error: $_" -ForegroundColor Red
    $ErrorCount++
}

# Test 2: DryRun mode works
Write-Host "`n✓ Test 2: DryRun mode execution" -ForegroundColor Yellow
try {
    $output = .\sn-full-run.ps1 -DryRun -MinEpisode 1 -MaxEpisode 1 2>&1
    if ($LASTEXITCODE -eq 0 -or $null -eq $LASTEXITCODE) {
        Write-Host "  ✓ DryRun executed successfully" -ForegroundColor Green
    } else {
        Write-Host "  ✗ DryRun failed with exit code: $LASTEXITCODE" -ForegroundColor Red
        $ErrorCount++
    }
} catch {
    Write-Host "  ✗ DryRun crashed: $_" -ForegroundColor Red
    $ErrorCount++
}

# Test 3: Critical parameters exist
Write-Host "`n✓ Test 3: Required parameters defined" -ForegroundColor Yellow
$scriptContent = Get-Content .\sn-full-run.ps1 -Raw
$requiredParams = @('DryRun', 'MinEpisode', 'MaxEpisode', 'SkipAI')
foreach ($param in $requiredParams) {
    if ($scriptContent -match "\`$$param") {
        Write-Host "  ✓ Parameter '$param' found" -ForegroundColor Green
    } else {
        Write-Host "  ✗ Parameter '$param' missing" -ForegroundColor Red
        $ErrorCount++
    }
}

# Results
Write-Host "`n" + ("="*50) -ForegroundColor Cyan
if ($ErrorCount -eq 0) {
    Write-Host "✅ ALL TESTS PASSED - Safe to commit" -ForegroundColor Green
    exit 0
} else {
    Write-Host "❌ $ErrorCount TEST(S) FAILED - DO NOT COMMIT" -ForegroundColor Red
    exit 1
}
