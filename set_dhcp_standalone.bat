@echo off
echo ========================================
echo Set Network Adapter to DHCP (Standalone)
echo ========================================
echo.

echo This will configure the network adapter to use DHCP.
echo.

REM Download the PowerShell script first
echo Downloading Set-DHCP.ps1 from GitHub...
powershell -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/monobrau/windows-network-config/main/Set-DHCP.ps1' -OutFile 'Set-DHCP.ps1'"

if %errorlevel% equ 0 (
    echo Download successful!
    echo.
    echo Running DHCP configuration...
    powershell -ExecutionPolicy Bypass -File "Set-DHCP.ps1"
    
    echo.
    echo Cleaning up...
    del Set-DHCP.ps1
    echo.
    echo DHCP configuration complete!
) else (
    echo.
    echo Download failed! Please check:
    echo 1. Internet connectivity
    echo 2. GitHub repository access
    echo 3. PowerShell execution policy
    echo.
    echo You can also try running this command manually:
    echo powershell -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/monobrau/windows-network-config/main/Set-DHCP.ps1' -OutFile 'Set-DHCP.ps1'"
    echo.
)

pause
