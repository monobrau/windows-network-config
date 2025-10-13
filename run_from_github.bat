@echo off
echo ========================================
echo Windows Autorun Analyzer - GitHub Mode
echo ========================================
echo.

echo Downloading Windows Autorun Analyzer from GitHub...
echo Repository: https://github.com/monobrau/windows-autorun-analyzer
echo.

powershell -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/monobrau/windows-autorun-analyzer/main/WindowsAutorunAnalyzer_Universal.ps1' -OutFile 'autorun.ps1'"

if %errorlevel% equ 0 (
    echo Download successful!
    echo.
    echo Running Windows Autorun Analyzer...
    echo.
    powershell -ExecutionPolicy Bypass -File "autorun.ps1"
    
    echo.
    echo Analysis complete!
    echo.
    echo Files created:
    echo - autorun.ps1 (downloaded script)
    echo - AutorunAnalysis_*.csv (analysis results)
    echo.
    echo You can delete autorun.ps1 if you don't need it anymore.
    echo.
) else (
    echo.
    echo Download failed! Please check:
    echo 1. Internet connectivity
    echo 2. GitHub repository access
    echo 3. PowerShell execution policy
    echo.
    echo You can also try running this command manually:
    echo powershell -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/monobrau/windows-autorun-analyzer/main/WindowsAutorunAnalyzer_Universal.ps1' -OutFile 'autorun.ps1'"
    echo.
)

pause
