@echo off
REM Duo Proxy Upgrade Helper - Launcher
REM Runs the PowerShell GUI version (SentinelOne Safe)

echo ========================================
echo Duo Proxy Upgrade Helper
echo SentinelOne Safe - PowerShell Version
echo ========================================
echo.
echo Starting GUI...
echo.

powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0DuoProxyUpgrade.ps1"

if errorlevel 1 (
    echo.
    echo ERROR: Failed to start PowerShell script
    echo.
    echo Try running manually:
    echo powershell.exe -ExecutionPolicy Bypass -File "DuoProxyUpgrade.ps1"
    echo.
    pause
)
