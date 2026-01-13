# Test-wkhtmltopdf.ps1
# Test script to verify wkhtmltopdf installation and conversion

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "wkhtmltopdf Test Script" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Test 1: Check if wkhtmltopdf is installed
Write-Host "[TEST 1] Checking wkhtmltopdf installation..." -ForegroundColor Yellow

try {
    $wkhtmltopdfCmd = Get-Command wkhtmltopdf -ErrorAction Stop
    Write-Host "  [OK] Found at: $($wkhtmltopdfCmd.Source)" -ForegroundColor Green
    
    # Get version
    $version = & wkhtmltopdf --version 2>&1 | Select-Object -First 1
    Write-Host "  [OK] Version: $version" -ForegroundColor Green
} catch {
    Write-Host "  [FAIL] wkhtmltopdf not found in PATH" -ForegroundColor Red
    Write-Host "`nInstallation instructions:" -ForegroundColor Yellow
    Write-Host "  Windows: Download from https://wkhtmltopdf.org/downloads.html" -ForegroundColor White
    Write-Host "  macOS:   brew install wkhtmltopdf" -ForegroundColor White
    Write-Host "  Linux:   apt-get install wkhtmltopdf  OR  yum install wkhtmltopdf" -ForegroundColor White
    exit 1
}

# Test 2: Create test HTML file
Write-Host "`n[TEST 2] Creating test HTML file..." -ForegroundColor Yellow

$testHTML = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Security Now! Test Page</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 40px;
        }
        h1 {
            color: #333;
        }
        .episode-info {
            background-color: #f0f0f0;
            padding: 15px;
            border-left: 4px solid #0066cc;
        }
    </style>
</head>
<body>
    <h1>Security Now! Episode Test</h1>
    <div class="episode-info">
        <p><strong>Episode:</strong> Test Episode</p>
        <p><strong>Host:</strong> Steve Gibson</p>
        <p><strong>Topic:</strong> Testing wkhtmltopdf Cross-Platform PDF Generation</p>
    </div>
    <p>This is a test HTML file to verify wkhtmltopdf is working correctly on your system.</p>
</body>
</html>
"@

$testHTMLPath = Join-Path $PWD "test-episode.html"
$testPDFPath = Join-Path $PWD "test-episode.pdf"

$testHTML | Out-File -FilePath $testHTMLPath -Encoding UTF8
Write-Host "  [OK] Created: $testHTMLPath" -ForegroundColor Green

# Test 3: Convert HTML to PDF
Write-Host "`n[TEST 3] Converting HTML to PDF..." -ForegroundColor Yellow

try {
    & wkhtmltopdf --quiet --page-size Letter --margin-top 10mm --margin-bottom 10mm $testHTMLPath $testPDFPath
    
    if ($LASTEXITCODE -eq 0 -and (Test-Path $testPDFPath)) {
        $pdfSize = (Get-Item $testPDFPath).Length / 1KB
        Write-Host "  [OK] PDF created: $testPDFPath" -ForegroundColor Green
        Write-Host "  [OK] File size: $([math]::Round($pdfSize, 2)) KB" -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] PDF conversion failed" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "  [FAIL] Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Test 4: Cleanup prompt
Write-Host "`n[TEST 4] Cleanup..." -ForegroundColor Yellow
Write-Host "Test files created:"
Write-Host "  - $testHTMLPath"
Write-Host "  - $testPDFPath"

$cleanup = Read-Host "`nDelete test files? (Y/N)"
if ($cleanup -eq 'Y' -or $cleanup -eq 'y') {
    Remove-Item $testHTMLPath -ErrorAction SilentlyContinue
    Remove-Item $testPDFPath -ErrorAction SilentlyContinue
    Write-Host "  [OK] Test files deleted" -ForegroundColor Green
} else {
    Write-Host "  [OK] Test files kept for inspection" -ForegroundColor Green
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "ALL TESTS PASSED!" -ForegroundColor Green
Write-Host "wkhtmltopdf is ready to use" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Cyan
