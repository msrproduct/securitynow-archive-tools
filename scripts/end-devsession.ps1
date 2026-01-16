<#
.SYNOPSIS
    End Development Time Tracking Session
.DESCRIPTION
    Ends the current tracked development session, calculates billable time,
    and appends the entry to the project time log CSV file.
.PARAMETER Notes
    Optional notes about what was accomplished during this session
.PARAMETER Rate
    Override the hourly rate set at session start (optional)
.EXAMPLE
    .\End-DevSession.ps1
.EXAMPLE
    .\End-DevSession.ps1 -Notes "Fixed TEXT WALL bug, tested episodes 1-5"
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$Notes = "",
    
    [Parameter(Mandatory=$false)]
    [int]$Rate = 0
)

$ErrorActionPreference = 'Stop'

# Session tracking file
$sessionFile = Join-Path $PSScriptRoot "..\data\current-dev-session.json"
$logFile = Join-Path $PSScriptRoot "..\data\project-time-log.csv"

# Check if session exists
if (-not (Test-Path $sessionFile)) {
    Write-Host "ERROR: No active development session found!" -ForegroundColor Red
    Write-Host "" 
    Write-Host "Start a session first with:" -ForegroundColor Cyan
    Write-Host "  .\Start-DevSession.ps1 -Task 'Your task description'" -ForegroundColor White
    exit 1
}

# Load session
$session = Get-Content $sessionFile | ConvertFrom-Json
$startTime = [DateTime]::Parse($session.StartTime)
$endTime = Get-Date

# Calculate duration
$duration = $endTime - $startTime
$hoursWorked = [math]::Round($duration.TotalHours, 2)

# Use override rate if provided, otherwise use session rate
$finalRate = if ($Rate -gt 0) { $Rate } else { $session.Rate }
$cost = [math]::Round($hoursWorked * $finalRate, 2)

# Prepare log entry
$logEntry = [PSCustomObject]@{
    Date = $endTime.ToString("yyyy-MM-dd")
    StartTime = $session.StartTime
    EndTime = $endTime.ToString("yyyy-MM-dd HH:mm:ss")
    Task = $session.Task
    Type = $session.Type
    Hours = $hoursWorked
    Rate = $finalRate
    Cost = $cost
    Notes = $Notes
}

# Create CSV header if file doesn't exist
if (-not (Test-Path $logFile)) {
    $header = "Date,StartTime,EndTime,Task,Type,Hours,Rate,Cost,Notes"
    $header | Set-Content $logFile -Encoding UTF8
}

# Append to log
$logEntry | Export-Csv -Path $logFile -Append -NoTypeInformation -Encoding UTF8

# Delete session file
Remove-Item $sessionFile -Force

# Display summary
Write-Host ""
Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  DEV SESSION COMPLETE" -ForegroundColor Green
Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Task:      $($session.Task)" -ForegroundColor White
Write-Host "  Type:      $($session.Type)" -ForegroundColor White
Write-Host "  Duration:  $hoursWorked hours" -ForegroundColor White
Write-Host "  Rate:      `$$finalRate/hour" -ForegroundColor White
Write-Host "  Cost:      `$$cost" -ForegroundColor Yellow
if ($Notes) {
    Write-Host "  Notes:     $Notes" -ForegroundColor White
}
Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "✓ Time logged to: project-time-log.csv" -ForegroundColor Green
Write-Host ""
