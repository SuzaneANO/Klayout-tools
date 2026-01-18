@echo off
REM KLayout Tools Installation Script for Windows
REM
REM This script installs the KLayout tools to your macros folder.
REM Run this script by double-clicking it or from Command Prompt.

setlocal enabledelayedexpansion

echo.
echo ========================================
echo   KLayout Tools Installer for Windows
echo ========================================
echo.

REM Get the directory where this script is located
set "SCRIPT_DIR=%~dp0"

REM Set KLayout macros directory
set "KLAYOUT_DIR=%APPDATA%\KLayout"
set "MACROS_DIR=%KLAYOUT_DIR%\macros"
set "INSTALL_DIR=%MACROS_DIR%\klayout-tools"

echo Source directory:  %SCRIPT_DIR%
echo KLayout directory: %KLAYOUT_DIR%
echo Install directory: %INSTALL_DIR%
echo.

REM Check if KLayout directory exists
if not exist "%KLAYOUT_DIR%" (
    echo Creating KLayout directory...
    mkdir "%KLAYOUT_DIR%"
)

REM Create macros directory if it doesn't exist
if not exist "%MACROS_DIR%" (
    echo Creating macros directory...
    mkdir "%MACROS_DIR%"
)

REM Remove existing installation if present
if exist "%INSTALL_DIR%" (
    echo Removing existing installation...
    rmdir /s /q "%INSTALL_DIR%"
)

REM Create installation directory
echo Creating installation directory...
mkdir "%INSTALL_DIR%"

REM Copy macros
echo.
echo Installing macros...
set "COUNT=0"

for %%f in ("%SCRIPT_DIR%macros\*.rb") do (
    copy "%%f" "%INSTALL_DIR%\" >nul
    set /a COUNT+=1
    echo   - %%~nxf
)

echo.
echo ========================================
echo   Installation Complete!
echo ========================================
echo.
echo Installed %COUNT% macros to:
echo   %INSTALL_DIR%
echo.
echo Available tools and shortcuts:
echo   - Layer Browser      Ctrl+Shift+L
echo   - Layer Statistics   Ctrl+Shift+S
echo   - Cell Hierarchy     Ctrl+Shift+H
echo   - Design Ruler       Ctrl+Shift+R
echo   - GDS Compare        Ctrl+Shift+C
echo   - Quick Export       Ctrl+Shift+E
echo.
echo ----------------------------------------
echo HOW TO USE:
echo ----------------------------------------
echo 1. Restart KLayout (if it's running)
echo 2. Open a GDS file
echo 3. Go to: Macros menu ^> klayout-tools
echo 4. Select any tool to run it
echo.
echo Or use the keyboard shortcuts above!
echo ----------------------------------------
echo.
pause
