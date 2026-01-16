<#
.SYNOPSIS
    Project Cost Dashboard and Reporting Tool
.DESCRIPTION
    Generates comprehensive cost reports from the project time log, including
    total hours, costs by task type, burn rate, and ROI projections.
.PARAMETER Days
    Show costs for last N days (default: all time)
.PARAMETER Type
    Filter by session type: 'coding', 'learning', 'debugging', 'docs', 'research'
.PARAMETER Export
    Export detailed report to HTML file
.EXAMPLE
    .\Get-ProjectCosts.ps1
.EXAMPLE
    .\Get-ProjectCosts.ps1 -Days 7
.EXAMPLE
    .\Get-ProjectCosts.ps1 -Type coding -Export
#>

param(
    [Parameter(Mandatory=$false)]
    [int]$Days = 0,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet('', 'coding', 'learning', 'debugging', 'docs', 'research', 'meeting')]
    [string]$Type = '',
    
    [Parameter(Mandatory=$false)]
    [switch]$Export
)

$ErrorActionPreference = 'Stop'

$logFile = Join-Path $PSScriptRoot "..\data\project-time-log.csv"

# Check if log exists
if (-not (Test-Path $logFile)) {
    Write-Host "ERROR: No project time log found!" -ForegroundColor Red
    Write-Host "" 
    Write-Host "Start tracking time with:" -ForegroundColor Cyan
    Write-Host "  .\Start-DevSession.ps1 -Task 'Your task'" -ForegroundColor White
    exit 1
}

# Load and parse log
$entries = Import-Csv $logFile

# Apply filters
if ($Days -gt 0) {
    $cutoffDate = (Get-Date).AddDays(-$Days)
    $entries = $entries | Where-Object { [DateTime]::Parse($_.Date) -ge $cutoffDate }
}

if ($Type) {
    $entries = $entries | Where-Object { $_.Type -eq $Type }
}

if ($entries.Count -eq 0) {
    Write-Host "No time entries found matching your filters." -ForegroundColor Yellow
    exit 0
}

# Calculate totals
$totalHours = ($entries | Measure-Object -Property Hours -Sum).Sum
$totalCost = ($entries | Measure-Object -Property Cost -Sum).Sum
$avgRate = [math]::Round($totalCost / $totalHours, 2)
$sessionCount = $entries.Count

# Group by type
$byType = $entries | Group-Object Type | ForEach-Object {
    $typeHours = ($_.Group | Measure-Object -Property Hours -Sum).Sum
    $typeCost = ($_.Group | Measure-Object -Property Cost -Sum).Sum
    [PSCustomObject]@{
        Type = $_.Name
        Sessions = $_.Count
        Hours = [math]::Round($typeHours, 2)
        Cost = [math]::Round($typeCost, 2)
        Percentage = [math]::Round(($typeCost / $totalCost) * 100, 1)
    }
} | Sort-Object Cost -Descending

# Recent sessions
$recent = $entries | Select-Object -Last 5 | ForEach-Object {
    [PSCustomObject]@{
        Date = $_.Date
        Task = if ($_.Task.Length -gt 40) { $_.Task.Substring(0, 37) + "..." } else { $_.Task }
        Type = $_.Type
        Hours = $_.Hours
        Cost = "`$$($_.Cost)"
    }
}

# Calculate date range
$firstEntry = [DateTime]::Parse(($entries | Sort-Object Date | Select-Object -First 1).Date)
$lastEntry = [DateTime]::Parse(($entries | Sort-Object Date | Select-Object -Last 1).Date)
$projectDays = ($lastEntry - $firstEntry).Days + 1
$burnRate = if ($projectDays -gt 0) { [math]::Round($totalCost / $projectDays, 2) } else { 0 }

# Display dashboard
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  SECURITY NOW ARCHIVE TOOLS - PROJECT COST DASHBOARD" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

Write-Host "PROJECT SUMMARY" -ForegroundColor Yellow
Write-Host "  Total Hours:        $totalHours hours" -ForegroundColor White
Write-Host "  Total Cost:         `$$totalCost" -ForegroundColor White
Write-Host "  Average Rate:       `$$avgRate/hour" -ForegroundColor White
Write-Host "  Sessions Logged:    $sessionCount" -ForegroundColor White
Write-Host "  Project Duration:   $projectDays days" -ForegroundColor White
Write-Host "  Daily Burn Rate:    `$$burnRate/day" -ForegroundColor White
Write-Host ""

Write-Host "COST BY TASK TYPE" -ForegroundColor Yellow
$byType | Format-Table -AutoSize | Out-String | Write-Host

Write-Host "RECENT SESSIONS (Last 5)" -ForegroundColor Yellow
$recent | Format-Table -AutoSize | Out-String | Write-Host

Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# ROI Projections
Write-Host "REVENUE PROJECTIONS (Based on Go-to-Market Plan)" -ForegroundColor Yellow
Write-Host "  Phase 1 (Fan Launch):       `$10K - `$25K ARR" -ForegroundColor White
Write-Host "  Phase 2 (Prosumer):         `$120K - `$220K ARR" -ForegroundColor White
Write-Host "  Phase 3 (Enterprise):       `$300K - `$750K ACV" -ForegroundColor White
Write-Host "" -ForegroundColor White
Write-Host "  Current Investment:         `$$totalCost" -ForegroundColor Cyan
Write-Host "  Break-even at Phase 1:      " -NoNewline
if ($totalCost -lt 10000) {
    Write-Host "✓ ACHIEVABLE" -ForegroundColor Green
} else {
    Write-Host "Requires Phase 2+" -ForegroundColor Yellow
}
Write-Host ""

Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Export if requested
if ($Export) {
    $exportPath = Join-Path $PSScriptRoot "..\data\project-cost-report.html"
    
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Security Now Archive Tools - Cost Report</title>
    <style>
        body { font-family: 'Segoe UI', Arial, sans-serif; margin: 40px; background: #f5f5f5; }
        .container { background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        h1 { color: #2c3e50; border-bottom: 3px solid #3498db; padding-bottom: 10px; }
        h2 { color: #34495e; margin-top: 30px; }
        table { width: 100%; border-collapse: collapse; margin: 20px 0; }
        th, td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background-color: #3498db; color: white; }
        tr:hover { background-color: #f5f5f5; }
        .summary { display: grid; grid-template-columns: repeat(3, 1fr); gap: 20px; margin: 20px 0; }
        .stat-box { background: #ecf0f1; padding: 20px; border-radius: 6px; text-align: center; }
        .stat-value { font-size: 32px; font-weight: bold; color: #2c3e50; }
        .stat-label { color: #7f8c8d; margin-top: 8px; }
        .footer { margin-top: 40px; padding-top: 20px; border-top: 1px solid #ddd; color: #7f8c8d; text-align: center; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Security Now Archive Tools<br/>Project Cost Report</h1>
        <p>Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
        
        <div class="summary">
            <div class="stat-box">
                <div class="stat-value">$totalHours</div>
                <div class="stat-label">Total Hours</div>
            </div>
            <div class="stat-box">
                <div class="stat-value">`$$totalCost</div>
                <div class="stat-label">Total Cost</div>
            </div>
            <div class="stat-box">
                <div class="stat-value">$sessionCount</div>
                <div class="stat-label">Sessions</div>
            </div>
        </div>
        
        <h2>Cost by Task Type</h2>
        <table>
            <tr><th>Type</th><th>Sessions</th><th>Hours</th><th>Cost</th><th>%</th></tr>
"@

    foreach ($item in $byType) {
        $html += "            <tr><td>$($item.Type)</td><td>$($item.Sessions)</td><td>$($item.Hours)</td><td>`$$($item.Cost)</td><td>$($item.Percentage)%</td></tr>`n"
    }

    $html += @"
        </table>
        
        <h2>All Sessions</h2>
        <table>
            <tr><th>Date</th><th>Task</th><th>Type</th><th>Hours</th><th>Rate</th><th>Cost</th></tr>
"@

    foreach ($entry in $entries) {
        $html += "            <tr><td>$($entry.Date)</td><td>$($entry.Task)</td><td>$($entry.Type)</td><td>$($entry.Hours)</td><td>`$$($entry.Rate)</td><td>`$$($entry.Cost)</td></tr>`n"
    }

    $html += @"
        </table>
        
        <div class="footer">
            <p>Security Now Archive Tools Project<br/>
            Developer Rate: `$40-45/hour (blended)<br/>
            Report generated by Get-ProjectCosts.ps1</p>
        </div>
    </div>
</body>
</html>
"@

    $html | Set-Content $exportPath -Encoding UTF8
    Write-Host "✓ Detailed report exported to: $exportPath" -ForegroundColor Green
    Write-Host ""
}
