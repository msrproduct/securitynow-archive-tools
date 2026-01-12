<#
.SYNOPSIS
    Convert HTML files to PDF using wkhtmltopdf (cross-platform).

.DESCRIPTION
    Converts HTML show notes to PDF format using wkhtmltopdf.
    Works on Windows, macOS, and Linux.
    Auto-detects wkhtmltopdf installation or uses provided path.

.PARAMETER InputHTML
    Path to input HTML file.

.PARAMETER OutputPDF
    Path to output PDF file.

.PARAMETER wkhtmltopdfPath
    Optional. Path to wkhtmltopdf executable. Auto-detected if not specified.

.PARAMETER PageSize
    Optional. PDF page size (default: Letter). Options: Letter, A4, Legal.

.PARAMETER MarginTop
    Optional. Top margin in millimeters (default: 10).

.PARAMETER MarginBottom
    Optional. Bottom margin in millimeters (default: 10).

.PARAMETER MarginLeft
    Optional. Left margin in millimeters (default: 10).

.PARAMETER MarginRight
    Optional. Right margin in millimeters (default: 10).

.PARAMETER DisableExternalLinks
    Optional. Disable loading of external resources (default: true).

.PARAMETER JavaScriptDelay
    Optional. Milliseconds to wait for JavaScript to finish (default: 0).

.EXAMPLE
    .\Convert-HTMLtoPDF.ps1 -InputHTML "episode-001.html" -OutputPDF "episode-001.pdf"

.EXAMPLE
    .\Convert-HTMLtoPDF.ps1 -InputHTML "episode-001.html" -OutputPDF "episode-001.pdf" -PageSize A4

.EXAMPLE
    .\Convert-HTMLtoPDF.ps1 -InputHTML "episode-001.html" -OutputPDF "episode-001.pdf" -wkhtmltopdfPath "C:\Tools\wkhtmltopdf.exe"

.NOTES
    Author: Security Now Archive Tools Project
    Requires: wkhtmltopdf (https://wkhtmltopdf.org/downloads.html)
    
    Installation:
      Windows: winget install wkhtmltopdf
      macOS:   brew install wkhtmltopdf
      Linux:   apt-get install wkhtmltopdf  OR  yum install wkhtmltopdf
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$InputHTML,
    
    [Parameter(Mandatory=$true)]
    [string]$OutputPDF,
    
    [Parameter(Mandatory=$false)]
    [string]$wkhtmltopdfPath = "",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("Letter", "A4", "Legal")]
    [string]$PageSize = "Letter",
    
    [Parameter(Mandatory=$false)]
    [int]$MarginTop = 10,
    
    [Parameter(Mandatory=$false)]
    [int]$MarginBottom = 10,
    
    [Parameter(Mandatory=$false)]
    [int]$MarginLeft = 10,
    
    [Parameter(Mandatory=$false)]
    [int]$MarginRight = 10,
    
    [Parameter(Mandatory=$false)]
    [bool]$DisableExternalLinks = $true,
    
    [Parameter(Mandatory=$false)]
    [int]$JavaScriptDelay = 0
)

function Find-wkhtmltopdf {
    <#
    .SYNOPSIS
        Auto-detect wkhtmltopdf installation.
    #>
    
    Write-Verbose "Searching for wkhtmltopdf..."
    
    # Platform-specific paths
    if ($IsWindows -or $PSVersionTable.PSVersion.Major -lt 6) {
        # Windows
        $possiblePaths = @(
            "C:\Program Files\wkhtmltopdf\bin\wkhtmltopdf.exe",
            "C:\Program Files (x86)\wkhtmltopdf\bin\wkhtmltopdf.exe",
            "$env:ProgramFiles\wkhtmltopdf\bin\wkhtmltopdf.exe",
            "${env:ProgramFiles(x86)}\wkhtmltopdf\bin\wkhtmltopdf.exe"
        )
    } elseif ($IsMacOS) {
        # macOS
        $possiblePaths = @(
            "/usr/local/bin/wkhtmltopdf",
            "/opt/homebrew/bin/wkhtmltopdf",
            "/usr/bin/wkhtmltopdf"
        )
    } else {
        # Linux
        $possiblePaths = @(
            "/usr/local/bin/wkhtmltopdf",
            "/usr/bin/wkhtmltopdf",
            "/opt/wkhtmltopdf/bin/wkhtmltopdf"
        )
    }
    
    # Check each possible path
    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            Write-Verbose "  Found: $path"
            return $path
        }
    }
    
    # Try PATH environment
    try {
        $cmd = Get-Command wkhtmltopdf -ErrorAction Stop
        Write-Verbose "  Found in PATH: $($cmd.Source)"
        return $cmd.Source
    } catch {
        # Not found
    }
    
    return $null
}

function Test-wkhtmltopdf {
    <#
    .SYNOPSIS
        Verify wkhtmltopdf is working.
    #>
    param(
        [string]$Path
    )
    
    try {
        $version = & $Path --version 2>&1 | Select-Object -First 1
        Write-Verbose "  wkhtmltopdf version: $version"
        return $true
    } catch {
        Write-Warning "  Failed to execute wkhtmltopdf: $($_.Exception.Message)"
        return $false
    }
}

function Convert-HTMLtoPDFInternal {
    <#
    .SYNOPSIS
        Perform the actual HTML to PDF conversion.
    #>
    param(
        [string]$wkhtmltopdf,
        [string]$InputHTML,
        [string]$OutputPDF,
        [string]$PageSize,
        [int]$MarginTop,
        [int]$MarginBottom,
        [int]$MarginLeft,
        [int]$MarginRight,
        [bool]$DisableExternalLinks,
        [int]$JavaScriptDelay
    )
    
    # Build arguments
    $args = @(
        "--quiet",
        "--page-size", $PageSize,
        "--margin-top", "${MarginTop}mm",
        "--margin-bottom", "${MarginBottom}mm",
        "--margin-left", "${MarginLeft}mm",
        "--margin-right", "${MarginRight}mm"
    )
    
    if ($DisableExternalLinks) {
        $args += "--disable-external-links"
    }
    
    if ($JavaScriptDelay -gt 0) {
        $args += @("--javascript-delay", $JavaScriptDelay)
    }
    
    # Add input and output files
    $args += @($InputHTML, $OutputPDF)
    
    Write-Verbose "Executing: $wkhtmltopdf $($args -join ' ')"
    
    try {
        # Execute conversion
        $output = & $wkhtmltopdf $args 2>&1
        
        # Check result
        if ($LASTEXITCODE -eq 0 -and (Test-Path $OutputPDF)) {
            $pdfSize = (Get-Item $OutputPDF).Length / 1KB
            Write-Host "  [OK] Converted to PDF: $OutputPDF ($([math]::Round($pdfSize, 2)) KB)" -ForegroundColor Green
            return $true
        } else {
            Write-Warning "  [WARN] PDF conversion failed (exit code: $LASTEXITCODE)"
            if ($output) {
                Write-Verbose "wkhtmltopdf output: $output"
            }
            return $false
        }
    } catch {
        Write-Error "  [ERROR] Failed to convert HTML to PDF: $($_.Exception.Message)"
        return $false
    }
}

#
# Main Script
#

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "HTML to PDF Conversion" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Validate input file
if (-not (Test-Path $InputHTML)) {
    Write-Error "ERROR: Input HTML file not found: $InputHTML"
    exit 1
}

Write-Host "Input:  $InputHTML" -ForegroundColor White
Write-Host "Output: $OutputPDF" -ForegroundColor White
Write-Host ""

# Find wkhtmltopdf
if ([string]::IsNullOrEmpty($wkhtmltopdfPath)) {
    Write-Host "[1/3] Locating wkhtmltopdf..." -ForegroundColor Yellow
    $wkhtmltopdfPath = Find-wkhtmltopdf
    
    if ([string]::IsNullOrEmpty($wkhtmltopdfPath)) {
        Write-Error "ERROR: wkhtmltopdf not found!"
        Write-Host "`nInstallation instructions:" -ForegroundColor Yellow
        Write-Host "  Windows: winget install wkhtmltopdf" -ForegroundColor White
        Write-Host "  macOS:   brew install wkhtmltopdf" -ForegroundColor White
        Write-Host "  Linux:   apt-get install wkhtmltopdf  OR  yum install wkhtmltopdf" -ForegroundColor White
        Write-Host "`nDownload: https://wkhtmltopdf.org/downloads.html`n" -ForegroundColor White
        exit 1
    }
    
    Write-Host "  Found: $wkhtmltopdfPath" -ForegroundColor Green
} else {
    Write-Host "[1/3] Using provided wkhtmltopdf path: $wkhtmltopdfPath" -ForegroundColor Yellow
    
    if (-not (Test-Path $wkhtmltopdfPath)) {
        Write-Error "ERROR: wkhtmltopdf not found at: $wkhtmltopdfPath"
        exit 1
    }
}

# Verify wkhtmltopdf works
Write-Host "`n[2/3] Verifying wkhtmltopdf..." -ForegroundColor Yellow
if (-not (Test-wkhtmltopdf -Path $wkhtmltopdfPath)) {
    Write-Error "ERROR: wkhtmltopdf verification failed"
    exit 1
}
Write-Host "  [OK] wkhtmltopdf is functional" -ForegroundColor Green

# Convert HTML to PDF
Write-Host "`n[3/3] Converting HTML to PDF..." -ForegroundColor Yellow
$success = Convert-HTMLtoPDFInternal `
    -wkhtmltopdf $wkhtmltopdfPath `
    -InputHTML $InputHTML `
    -OutputPDF $OutputPDF `
    -PageSize $PageSize `
    -MarginTop $MarginTop `
    -MarginBottom $MarginBottom `
    -MarginLeft $MarginLeft `
    -MarginRight $MarginRight `
    -DisableExternalLinks $DisableExternalLinks `
    -JavaScriptDelay $JavaScriptDelay

if ($success) {
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "Conversion Complete!" -ForegroundColor Green
    Write-Host "========================================`n" -ForegroundColor Cyan
    exit 0
} else {
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "Conversion Failed" -ForegroundColor Red
    Write-Host "========================================`n" -ForegroundColor Cyan
    exit 1
}
