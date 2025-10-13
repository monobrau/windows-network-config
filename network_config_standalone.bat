@echo off
echo ========================================
echo Network Configuration Utility (Standalone)
echo (Physical Adapters Only - Ethernet/Wireless)
echo ========================================
echo.

if "%1"=="" (
    echo Usage: network_config_standalone.bat ^<action^> [options]
    echo.
    echo Actions:
    echo   status                    - Show current network status
    echo   static ^<IP^> ^<MASK^> ^<GW^> - Set static IP
    echo   dhcp                     - Set DHCP
    echo.
    echo Examples:
    echo   network_config_standalone.bat status
    echo   network_config_standalone.bat static 192.168.1.100 255.255.255.0 192.168.1.1
    echo   network_config_standalone.bat dhcp
    echo.
    pause
    exit /b 1
)

REM Download the PowerShell script first
echo Downloading NetworkConfig.ps1 from GitHub...
powershell -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/monobrau/windows-network-config/main/NetworkConfig.ps1' -OutFile 'NetworkConfig.ps1'"

if %errorlevel% neq 0 (
    echo Download failed! Please check internet connectivity.
    pause
    exit /b 1
)

if "%1"=="status" (
    powershell -ExecutionPolicy Bypass -File "NetworkConfig.ps1" -Action status
) else if "%1"=="static" (
    if "%4"=="" (
        echo Error: Static IP requires IP, SubnetMask, and Gateway
        echo Usage: network_config_standalone.bat static ^<IP^> ^<MASK^> ^<GW^>
        del NetworkConfig.ps1
        pause
        exit /b 1
    )
    powershell -ExecutionPolicy Bypass -File "NetworkConfig.ps1" -Action static -IPAddress "%2" -SubnetMask "%3" -Gateway "%4"
) else if "%1"=="dhcp" (
    powershell -ExecutionPolicy Bypass -File "NetworkConfig.ps1" -Action dhcp
) else (
    echo Invalid action: %1
    echo Use: status, static, or dhcp
    del NetworkConfig.ps1
    pause
    exit /b 1
)

echo.
echo Cleaning up...
del NetworkConfig.ps1
echo.
pause
