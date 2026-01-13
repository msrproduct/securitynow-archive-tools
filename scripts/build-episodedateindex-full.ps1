<#
.SYNOPSIS
    Comprehensive GRC Archive Scraper Test - All Years, All Episodes
    
.DESCRIPTION
    Fetches real GRC archive pages (2005-2026) and tests regex extraction
    for every episode. Creates a complete episode-dates.csv file.
    
.NOTES
    Version: 1.0 - Production Scraper Test
    Date: January 13, 2026
#>

param(
    [string]$OutputCsv = "D:\desktop\SecurityNow-Test\data\episode-dates.csv"
)

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "GRC Archive Scraper - Full Test" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Ensure output directory exists
$outputDir = Split-Path -Parent $OutputCsv
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

# Results collection
$allEpisodes = @()
$stats = @{
    YearsProcessed = 0
    YearsFailed = 0
    EpisodesFound = 0
    RegexErrors = 0
}

# Regex pattern (confirmed working)
$episodePattern = "Episode\s*#(\d+)\s*\|\s*(\d{1,2})\s+(\w+)\s+(\d{4})"

# Process years 2005-2026
$years = 2005..2026

foreach ($year in $years) {
    Write-Host "Processing Year $year..." -NoNewline -ForegroundColor Yellow
    
    # Determine archive URL
    $archiveUrl = if ($year -ge 2025) {
        "https://www.grc.com/securitynow.htm"
    } else {
        "https://www.grc.com/sn/past/$year.htm"
    }
    
    try {
        # Fetch archive page
        $response = Invoke-WebRequest -Uri $archiveUrl -UseBasicParsing -TimeoutSec 20 -ErrorAction Stop
        
        # Extract all episodes from this page
        $matches = [regex]::Matches($response.Content, $episodePattern)
        
        if ($matches.Count -eq 0) {
            Write-Host " No episodes found (may be future year)" -ForegroundColor Gray
            $stats.YearsFailed++
            continue
        }
        
        Write-Host " Found $($matches.Count) episodes" -ForegroundColor Green
        $stats.YearsProcessed++
        
        # Process each match
        foreach ($match in $matches) {
            try {
                $episode = [int]$match.Groups[1].Value
                $day = $match.Groups[2].Value.PadLeft(2, '0')
                $monthName = $match.Groups[3].Value
                $episodeYear = [int]$match.Groups[4].Value
                
                # Convert month name to number
                $monthNum = switch ($monthName) {
                    "Jan" { "01" } "Feb" { "02" } "Mar" { "03" } "Apr" { "04" }
                    "May" { "05" } "Jun" { "06" } "Jul" { "07" } "Aug" { "08" }
                    "Sep" { "09" } "Oct" { "10" } "Nov" { "11" } "Dec" { "12" }
                    default { 
                        Write-Host "  WARNING: Unknown month '$monthName' for episode $episode" -ForegroundColor Yellow
                        $stats.RegexErrors++
                        "01" 
                    }
                }
                
                $recordDate = "$episodeYear-$monthNum-$day"
                
                # Add to results
                $allEpisodes += [PSCustomObject]@{
                    Episode = $episode
                    RecordDate = $recordDate
                    Year = $episodeYear
                    Source = "GRC-$year"
                }
                
                $stats.EpisodesFound++
                
            }
            catch {
                Write-Host "  ERROR parsing match: $($_.Exception.Message)" -ForegroundColor Red
                $stats.RegexErrors++
            }
        }
        
        # Rate limiting - be nice to GRC
        Start-Sleep -Milliseconds 500
    }
    catch {
        Write-Host " FAILED: $($_.Exception.Message)" -ForegroundColor Red
        $stats.YearsFailed++
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Scraping Complete - Analyzing Results" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($allEpisodes.Count -eq 0) {
    Write-Host "ERROR: No episodes found! Check network connection or GRC website status." -ForegroundColor Red
    exit 1
}

# Remove duplicates (in case current year appears in multiple pages)
$uniqueEpisodes = $allEpisodes | Sort-Object Episode -Unique

Write-Host "Total Episodes Found: $($uniqueEpisodes.Count)" -ForegroundColor Green
Write-Host "Years Processed: $($stats.YearsProcessed)" -ForegroundColor Cyan
Write-Host "Years Failed: $($stats.YearsFailed)" -ForegroundColor $(if ($stats.YearsFailed -gt 0) { "Yellow" } else { "Gray" })
Write-Host "Regex Errors: $($stats.RegexErrors)" -ForegroundColor $(if ($stats.RegexErrors -gt 0) { "Yellow" } else { "Gray" })
Write-Host ""

# Show statistics by year
Write-Host "Episodes by Year:" -ForegroundColor Cyan
$byYear = $uniqueEpisodes | Group-Object Year | Sort-Object Name
foreach ($group in $byYear) {
    $yearEpisodes = $group.Group | Sort-Object Episode
    $first = $yearEpisodes[0].Episode
    $last = $yearEpisodes[-1].Episode
    Write-Host "  $($group.Name): $($group.Count) episodes (#$first - #$last)" -ForegroundColor White
}

Write-Host ""

# Show first and last episodes
$firstEpisode = $uniqueEpisodes | Sort-Object Episode | Select-Object -First 1
$lastEpisode = $uniqueEpisodes | Sort-Object Episode | Select-Object -Last 1

Write-Host "Episode Range:" -ForegroundColor Cyan
Write-Host "  First: Episode $($firstEpisode.Episode) - $($firstEpisode.RecordDate)" -ForegroundColor White
Write-Host "  Last:  Episode $($lastEpisode.Episode) - $($lastEpisode.RecordDate)" -ForegroundColor White
Write-Host ""

# Check for gaps in episode numbers
Write-Host "Checking for gaps in episode sequence..." -ForegroundColor Cyan
$episodeNumbers = $uniqueEpisodes | Sort-Object Episode | Select-Object -ExpandProperty Episode
$expectedRange = $firstEpisode.Episode..$lastEpisode.Episode
$missing = $expectedRange | Where-Object { $_ -notin $episodeNumbers }

if ($missing.Count -gt 0) {
    Write-Host "  Found $($missing.Count) missing episodes:" -ForegroundColor Yellow
    $missing | ForEach-Object { Write-Host "    Episode $_" -ForegroundColor Gray }
} else {
    Write-Host "  ✓ No gaps found - complete sequence!" -ForegroundColor Green
}

Write-Host ""

# Save to CSV
Write-Host "Saving to CSV: $OutputCsv" -ForegroundColor Cyan
$uniqueEpisodes | 
    Sort-Object Episode | 
    Export-Csv -Path $OutputCsv -NoTypeInformation -Encoding UTF8

Write-Host "✓ CSV saved successfully" -ForegroundColor Green
Write-Host ""

# Display sample entries
Write-Host "Sample Entries (First 10):" -ForegroundColor Cyan
$uniqueEpisodes | 
    Sort-Object Episode | 
    Select-Object -First 10 | 
    Format-Table -AutoSize

Write-Host ""
Write-Host "Sample Entries (Last 10):" -ForegroundColor Cyan
$uniqueEpisodes | 
    Sort-Object Episode | 
    Select-Object -Last 10 | 
    Format-Table -AutoSize

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "✓ Complete! CSV Ready for Production" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Output: $OutputCsv" -ForegroundColor White
Write-Host "Episodes: $($uniqueEpisodes.Count)" -ForegroundColor White
Write-Host ""
