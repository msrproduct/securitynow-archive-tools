# Create-EpisodeDateIndex.ps1
# Scrapes episode dates from GRC archive pages

param(
    [string]$OutputPath = ".\data\episode-dates.csv"
)

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Security Now Episode Date Scraper" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$dateIndex = @()
$years = 2005..2026

foreach ($year in $years) {
    Write-Host "Scraping $year archive..." -ForegroundColor Yellow
    
    $archiveUrl = if ($year -ge 2025) {
        "https://www.grc.com/securitynow.htm"
    } else {
        "https://www.grc.com/sn/past-$year.htm"
    }
    
    try {
        $response = Invoke-WebRequest -Uri $archiveUrl -UseBasicParsing -ErrorAction Stop
        $pattern = 'Episode\s*(?:&nbsp;)?(\d{1,4})\s+(\d{1,2})\s+(\w{3})\s+(\d{4})'
        $matches = [regex]::Matches($response.Content, $pattern)
        
        if ($matches.Count -gt 0) {
            Write-Host "  Found $($matches.Count) episodes" -ForegroundColor Green
            
            foreach ($match in $matches) {
                $ep = [int]$match.Groups[1].Value
                $day = $match.Groups[2].Value.PadLeft(2, '0')
                $monthName = $match.Groups[3].Value
                $yr = $match.Groups[4].Value
                
                $monthNum = switch ($monthName) {
                    'Jan' { '01' }; 'Feb' { '02' }; 'Mar' { '03' }
                    'Apr' { '04' }; 'May' { '05' }; 'Jun' { '06' }
                    'Jul' { '07' }; 'Aug' { '08' }; 'Sep' { '09' }
                    'Oct' { '10' }; 'Nov' { '11' }; 'Dec' { '12' }
                    default { '01' }
                }
                
                $dateIndex += [PSCustomObject]@{
                    Episode = $ep
                    RecordDate = "$yr-$monthNum-$day"
                    Year = [int]$yr
                    Source = "GRC/$year"
                }
            }
        } else {
            Write-Host "  WARNING: No episodes found" -ForegroundColor Yellow
        }
        
        Start-Sleep -Milliseconds 500
        
    } catch {
        Write-Host "  ERROR: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n----------------------------------------" -ForegroundColor Cyan

if ($dateIndex.Count -eq 0) {
    Write-Host "FAILED: No episodes scraped!" -ForegroundColor Red
    exit 1
}

$dateIndex = $dateIndex | Sort-Object Episode -Unique

$outputDir = Split-Path -Parent $OutputPath
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

$dateIndex | Sort-Object Episode | Export-Csv $OutputPath -NoTypeInformation

Write-Host "✓ SUCCESS: Indexed $($dateIndex.Count) episodes" -ForegroundColor Green
Write-Host "✓ Output: $OutputPath`n" -ForegroundColor Cyan

$byYear = $dateIndex | Group-Object Year | Sort-Object Name
Write-Host "Episodes by Year:" -ForegroundColor Cyan
foreach ($group in $byYear) {
    Write-Host "  $($group.Name): $($group.Count) episodes" -ForegroundColor Gray
}

$first = $dateIndex | Sort-Object Episode | Select-Object -First 1
$last = $dateIndex | Sort-Object Episode | Select-Object -Last 1
Write-Host "`nRange: Episode $($first.Episode) ($($first.RecordDate)) to Episode $($last.Episode) ($($last.RecordDate))" -ForegroundColor Cyan
Write-Host "`n✓ Date index ready for use!`n" -ForegroundColor Green
