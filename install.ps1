# KLayout Tools Installation Script for Windows (PowerShell)
#
# Run this script in PowerShell:
#   .\install.ps1
#
# If you get an execution policy error, run:
#   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  KLayout Tools Installer for Windows" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Get script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Set paths
$KLayoutDir = Join-Path $env:APPDATA "KLayout"
$MacrosDir = Join-Path $KLayoutDir "macros"
$InstallDir = Join-Path $MacrosDir "klayout-tools"
$SourceDir = Join-Path $ScriptDir "macros"

Write-Host "Source directory:  $SourceDir"
Write-Host "KLayout directory: $KLayoutDir"
Write-Host "Install directory: $InstallDir"
Write-Host ""

# Create directories if they don't exist
if (-not (Test-Path $KLayoutDir)) {
    Write-Host "Creating KLayout directory..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $KLayoutDir | Out-Null
}

if (-not (Test-Path $MacrosDir)) {
    Write-Host "Creating macros directory..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $MacrosDir | Out-Null
}

# Remove existing installation
if (Test-Path $InstallDir) {
    Write-Host "Removing existing installation..." -ForegroundColor Yellow
    Remove-Item -Recurse -Force $InstallDir
}

# Create installation directory
Write-Host "Creating installation directory..." -ForegroundColor Yellow
New-Item -ItemType Directory -Path $InstallDir | Out-Null

# Copy macros
Write-Host ""
Write-Host "Installing macros..." -ForegroundColor Green

$files = Get-ChildItem -Path $SourceDir -Filter "*.rb"
$count = 0

foreach ($file in $files) {
    Copy-Item $file.FullName -Destination $InstallDir
    Write-Host "  - $($file.Name)" -ForegroundColor White
    $count++
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Installation Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Installed $count macros to:"
Write-Host "  $InstallDir" -ForegroundColor Cyan
Write-Host ""
Write-Host "Available tools and shortcuts:" -ForegroundColor Yellow
Write-Host "  - Layer Browser      Ctrl+Shift+L"
Write-Host "  - Layer Statistics   Ctrl+Shift+S"
Write-Host "  - Cell Hierarchy     Ctrl+Shift+H"
Write-Host "  - Design Ruler       Ctrl+Shift+R"
Write-Host "  - GDS Compare        Ctrl+Shift+C"
Write-Host "  - Quick Export       Ctrl+Shift+E"
Write-Host ""
Write-Host "----------------------------------------" -ForegroundColor Cyan
Write-Host "HOW TO USE:" -ForegroundColor Cyan
Write-Host "----------------------------------------" -ForegroundColor Cyan
Write-Host "1. Restart KLayout (if it's running)"
Write-Host "2. Open a GDS file"
Write-Host "3. Go to: Macros menu > klayout-tools"
Write-Host "4. Select any tool to run it"
Write-Host ""
Write-Host "Or use the keyboard shortcuts above!"
Write-Host "----------------------------------------" -ForegroundColor Cyan
Write-Host ""

Read-Host "Press Enter to exit"
