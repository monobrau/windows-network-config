@echo off
REM Download and Execute DuoProxyUpgrade.ps1 from GitHub
REM Usage: Double-click this file or run from command prompt

echo ========================================
echo Duo Proxy Upgrade Helper
echo Downloading from GitHub...
echo ========================================
echo.

powershell.exe -ExecutionPolicy Bypass -File "%~dp0Run-FromGitHub.ps1"

if errorlevel 1 (
    echo.
    echo ERROR: Failed to download or execute script
    echo.
    pause
)
