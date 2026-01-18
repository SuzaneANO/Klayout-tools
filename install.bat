@echo off
REM KLayout Tools Installation Script for Windows
REM
REM This script installs the KLayout tools to your macros folder.

echo KLayout Tools Installer
echo =======================
echo.

set KLAYOUT_DIR=%APPDATA%\KLayout
set MACROS_DIR=%KLAYOUT_DIR%\macros
set SCRIPT_DIR=%~dp0

echo KLayout directory: %KLAYOUT_DIR%
echo Macros directory: %MACROS_DIR%
echo Source directory: %SCRIPT_DIR%
echo.

REM Create macros directory if it doesn't exist
if not exist "%MACROS_DIR%" (
    echo Creating macros directory...
    mkdir "%MACROS_DIR%"
)

REM Create klayout-tools subdirectory
set INSTALL_DIR=%MACROS_DIR%\klayout-tools

if exist "%INSTALL_DIR%" (
    echo Removing existing installation...
    rmdir /s /q "%INSTALL_DIR%"
)

echo Creating installation directory...
mkdir "%INSTALL_DIR%"

REM Copy macros
echo Installing macros...
copy "%SCRIPT_DIR%macros\*.rb" "%INSTALL_DIR%\" >nul

echo.
echo Installation complete!
echo Installed macros to: %INSTALL_DIR%
echo.
echo Available tools:
echo   - Layer Browser      (Ctrl+Shift+L)
echo   - Layer Statistics   (Ctrl+Shift+S)
echo   - Cell Hierarchy     (Ctrl+Shift+H)
echo   - Design Ruler       (Ctrl+Shift+R)
echo   - GDS Compare        (Ctrl+Shift+C)
echo   - Quick Export       (Ctrl+Shift+E)
echo.
echo To use:
echo   1. Restart KLayout
echo   2. Go to Macros menu and run any tool
echo   3. Or use the keyboard shortcuts listed above
echo.
pause
