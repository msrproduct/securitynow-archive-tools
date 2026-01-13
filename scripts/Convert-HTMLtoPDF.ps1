<#
.SYNOPSIS
    Convert HTML files to PDF using wkhtmltopdf

.DESCRIPTION
    Cross-platform HTML to PDF converter with auto-detection of wkhtmltopdf.
    Includes critical flags for local file access and proper PDF generation.

.PARAMETER InputHTML
    Path to the input HTML file

.PARAMETER OutputPDF
    Path where the PDF should be saved

.PARAMETER wkhtmltopdfPath
    Optional: Explicit path to wkhtmltopdf executable

.EXAMPLE
    .\Convert-HTMLtoPDF.ps1 -InputHTML "episode.html" -OutputPDF "episode.pdf"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$InputHTML,

    [Parameter(Mandatory=$true)]
    [string]$OutputPDF,

    [string]$wkhtmltopdfPath = ""
)

Write-Host "`n=== HTML to PDF Conversion ===" -ForegroundColor Cyan
Write-Host "Input:  $InputHTML" -ForegroundColor Gray
Write-Host "Output: $OutputPDF" -ForegroundColor Gray

# Step 1: Locate wkhtmltopdf
Write-Host "`n[1/3] Locating wkhtmltopdf..." -ForegroundColor Yellow

if ([string]::IsNullOrEmpty($wkhtmltopdfPath)) {
    Write-Verbose "Searching for wkhtmltopdf..."

    $possiblePaths = @(
        "C:\Program Files\wkhtmltopdf\bin\wkhtmltopdf.exe",
        "C:\Program Files (x86)\wkhtmltopdf\bin\wkhtmltopdf.exe",
        "/usr/local/bin/wkhtmltopdf",
        "/usr/bin/wkhtmltopdf"
    )

    foreach ($path in $possiblePaths) {
        Write-Verbose "Checking: $path"
        if (Test-Path $path) {
            $wkhtmltopdfPath = $path
            Write-Verbose "Found: $path"
            break
        }
    }
}

if ([string]::IsNullOrEmpty($wkhtmltopdfPath) -or !(Test-Path $wkhtmltopdfPath)) {
    Write-Host "✗ ERROR: wkhtmltopdf not found" -ForegroundColor Red
    Write-Host "  Please install from: https://wkhtmltopdf.org/downloads.html" -ForegroundColor Yellow
    exit 1
}

Write-Host "  ✓ Found: $wkhtmltopdfPath" -ForegroundColor Green

# Step 2: Verify wkhtmltopdf
Write-Host "`n[2/3] Verifying wkhtmltopdf..." -ForegroundColor Yellow

try {
    $version = & $wkhtmltopdfPath --version 2>&1 | Select-Object -First 1
    Write-Verbose "wkhtmltopdf version: $version"
    Write-Host "  ✓ OK: wkhtmltopdf is functional" -ForegroundColor Green
} catch {
    Write-Host "✗ WARN: Could not verify wkhtmltopdf version" -ForegroundColor Yellow
}

# Step 3: Convert HTML to PDF
Write-Host "`n[3/3] Converting HTML to PDF..." -ForegroundColor Yellow

# Verify input file exists
if (!(Test-Path -LiteralPath $InputHTML)) {
    Write-Host "✗ ERROR: Input HTML file not found: $InputHTML" -ForegroundColor Red
    exit 1
}

# Build command with critical flags
$arguments = @(
    "--enable-local-file-access",      # CRITICAL: Allow reading temp HTML files
    "--no-stop-slow-scripts",          # Don't timeout on scripts
    "--disable-external-links",        # Ignore external resources
    "--quiet",                          # Suppress verbose output
    "--page-size", "Letter",           # Standard US letter size
    "--margin-top", "10mm",            # Top margin
    "--margin-bottom", "10mm",         # Bottom margin
    "--margin-left", "10mm",           # Left margin
    "--margin-right", "10mm",          # Right margin
    "--no-pdf-header-footer",          # Remove browser artifacts
    $InputHTML,
    $OutputPDF
)

Write-Verbose "Executing: $wkhtmltopdfPath $($arguments -join ' ')"

try {
    # Execute wkhtmltopdf
    $output = & $wkhtmltopdfPath @arguments 2>&1

    # Check results
    if ($LASTEXITCODE -eq 0 -and (Test-Path -LiteralPath $OutputPDF)) {
        $fileSize = (Get-Item -LiteralPath $OutputPDF).Length / 1KB
        Write-Host "  ✓ OK: Converted to PDF: $OutputPDF ($([math]::Round($fileSize, 2)) KB)" -ForegroundColor Green
        Write-Host "`n=== Conversion Complete! ===" -ForegroundColor Cyan
        return $true
    } else {
        Write-Host "  ✗ WARN: PDF conversion failed (exit code: $LASTEXITCODE)" -ForegroundColor Yellow
        if ($output) {
            Write-Verbose "wkhtmltopdf output: $output"
        }
        return $false
    }

} catch {
    Write-Host "  ✗ ERROR: Failed to convert HTML to PDF" -ForegroundColor Red
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
    return $false
}
