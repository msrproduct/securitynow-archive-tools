<# 
.SYNOPSIS
    Start Development Time Tracking Session
.DESCRIPTION
    Begins a tracked development session with task description and automatically
    records start time. Used for project cost accounting and time tracking.
.PARAMETER Task
    Brief description of the development task (e.g., "Engine v3.1.2 PDF fix")
.PARAMETER Rate
    Hourly rate for this session (default: $45 blended rate)
.PARAMETER Type
    Session type: 'coding', 'learning', 'debugging', 'docs', 'research'
.EXAMPLE
    .\Start-DevSession.ps1 -Task "Fix wkhtmltopdf TEXT WALL bug" -Type coding
.EXAMPLE
    .\Start-DevSession.ps1 -Task "Learning Whisper optimization" -Rate 30 -Type learning
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Task,
    
    [Parameter(Mandatory=$false)]
    [int]$Rate = 45,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet('coding', 'learning', 'debugging', 'docs', 'research', 'meeting')]
    [string]$Type = 'coding'
)

$ErrorActionPreference = 'Stop'

# Session tracking file (temporary - cleared on End-DevSession)
$sessionFile = Join-Path $PSScriptRoot "..\data\current-dev-session.json"

# Check if session already active
if (Test-Path $sessionFile) {
    $existing = Get-Content $sessionFile | ConvertFrom-Json
    Write-Host "ERROR: Development session already in progress!" -ForegroundColor Red
    Write-Host "  Task: $($existing.Task)" -ForegroundColor Yellow
    Write-Host "  Started: $($existing.StartTime)" -ForegroundColor Yellow
    Write-Host "" 
    Write-Host "End the current session first with:" -ForegroundColor Cyan
    Write-Host "  .\End-DevSession.ps1" -ForegroundColor White
    exit 1
}

# Create session object
$session = @{
    Task = $Task
    Type = $Type
    Rate = $Rate
    StartTime = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    StartTimestamp = (Get-Date).ToUniversalTime().ToString("o")
}

# Ensure data directory exists
$dataDir = Join-Path $PSScriptRoot "..\data"
if (-not (Test-Path $dataDir)) {
    New-Item -ItemType Directory -Path $dataDir -Force | Out-Null
}

# Save session
$session | ConvertTo-Json | Set-Content $sessionFile -Encoding UTF8

# Display confirmation
Write-Host ""
Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  DEV SESSION STARTED" -ForegroundColor Green
Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Task:  $Task" -ForegroundColor White
Write-Host "  Type:  $Type" -ForegroundColor White
Write-Host "  Rate:  `$$Rate/hour" -ForegroundColor White
Write-Host "  Time:  $($session.StartTime)" -ForegroundColor White
Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "When finished, run:" -ForegroundColor Cyan
Write-Host "  .\End-DevSession.ps1" -ForegroundColor Yellow
Write-Host ""
