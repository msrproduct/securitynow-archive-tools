<#
.SYNOPSIS
    Raw HTML Inspector - See EXACTLY what GRC returns
#>

Write-Host "Fetching RAW HTML from GRC Archive..." -ForegroundColor Cyan
Write-Host ""

# Test a known archive page
$testUrl = "https://www.grc.com/sn/past/2023.htm"

try {
    $response = Invoke-WebRequest -Uri $testUrl -UseBasicParsing -TimeoutSec 20 -ErrorAction Stop
    
    Write-Host "✓ Successfully fetched: $testUrl" -ForegroundColor Green
    Write-Host "Content Length: $($response.Content.Length) bytes" -ForegroundColor Gray
    Write-Host ""
    
    # Extract and display the first 3000 characters
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "RAW HTML (First 3000 characters):" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host $response.Content.Substring(0, [Math]::Min(3000, $response.Content.Length))
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host ""
    
    # Look for episode-related patterns
    Write-Host "Searching for 'Episode' keyword..." -ForegroundColor Cyan
    
    # Find all lines containing "Episode"
    $lines = $response.Content -split "`n"
    $episodeLines = $lines | Where-Object { $_ -match "Episode" } | Select-Object -First 10
    
    if ($episodeLines) {
        Write-Host "Found episode-related lines:" -ForegroundColor Green
        Write-Host ""
        foreach ($line in $episodeLines) {
            Write-Host $line.Trim() -ForegroundColor White
        }
    } else {
        Write-Host "No 'Episode' keyword found in HTML!" -ForegroundColor Red
    }
    
    Write-Host ""
    
    # Save full HTML to file for inspection
    $debugFile = "D:\desktop\SecurityNow-Test\grc-archive-debug.html"
    $response.Content | Out-File -FilePath $debugFile -Encoding UTF8
    Write-Host "Full HTML saved to: $debugFile" -ForegroundColor Cyan
    Write-Host "Open this file in a text editor to see the complete source." -ForegroundColor Gray
    
}
catch {
    Write-Host "Failed to fetch page: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Also try the main current page
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Testing Current Episodes Page" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$currentUrl = "https://www.grc.com/securitynow.htm"

try {
    $response2 = Invoke-WebRequest -Uri $currentUrl -UseBasicParsing -TimeoutSec 20 -ErrorAction Stop
    
    Write-Host "✓ Successfully fetched: $currentUrl" -ForegroundColor Green
    Write-Host "Content Length: $($response2.Content.Length) bytes" -ForegroundColor Gray
    Write-Host ""
    
    # Extract episode lines
    $lines2 = $response2.Content -split "`n"
    $episodeLines2 = $lines2 | Where-Object { $_ -match "Episode" } | Select-Object -First 10
    
    if ($episodeLines2) {
        Write-Host "Found episode-related lines:" -ForegroundColor Green
        Write-Host ""
        foreach ($line in $episodeLines2) {
            Write-Host $line.Trim() -ForegroundColor White
        }
    } else {
        Write-Host "No 'Episode' keyword found!" -ForegroundColor Red
    }
    
    # Save this too
    $debugFile2 = "D:\desktop\SecurityNow-Test\grc-current-debug.html"
    $response2.Content | Out-File -FilePath $debugFile2 -Encoding UTF8
    Write-Host ""
    Write-Host "Full HTML saved to: $debugFile2" -ForegroundColor Cyan
    
}
catch {
    Write-Host "Failed to fetch page: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "Open the debug HTML files to see the exact format!" -ForegroundColor Yellow
