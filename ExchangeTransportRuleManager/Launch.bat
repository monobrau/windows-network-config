@echo off
echo Starting Exchange Transport Rule Manager...
echo Optimized for PowerShell 7+
echo.

REM Change to the script directory
cd /d "%~dp0"

REM Try pwsh first (PowerShell 7+), fallback to powershell.exe
where pwsh >nul 2>nul
if %errorlevel% == 0 (
    echo Using PowerShell 7+
    pwsh -ExecutionPolicy Bypass -File "ExchangeTransportRuleManager.ps1"
) else (
    echo PowerShell 7+ not found, using Windows PowerShell
    powershell.exe -ExecutionPolicy Bypass -File "ExchangeTransportRuleManager.ps1"
)

echo.
echo Script execution completed.
pause
