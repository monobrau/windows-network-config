@echo off
echo ========================================
echo Network Configuration Utility
echo (Physical Adapters Only - Ethernet/Wireless)
echo ========================================
echo.

if "%1"=="" (
    echo Usage: network_config.bat ^<action^> [options]
    echo.
    echo Actions:
    echo   status                    - Show current network status
    echo   static ^<IP^> ^<MASK^> ^<GW^> - Set static IP
    echo   dhcp                     - Set DHCP
    echo.
    echo Note: Only works with physical adapters (Ethernet/Wireless)
    echo       VPNs and virtual adapters are automatically excluded
    echo.
    echo Examples:
    echo   network_config.bat status
    echo   network_config.bat static 192.168.1.100 255.255.255.0 192.168.1.1
    echo   network_config.bat dhcp
    echo.
    pause
    exit /b 1
)

if "%1"=="status" (
    powershell -ExecutionPolicy Bypass -File "NetworkConfig.ps1" -Action status
) else if "%1"=="static" (
    if "%4"=="" (
        echo Error: Static IP requires IP, SubnetMask, and Gateway
        echo Usage: network_config.bat static ^<IP^> ^<MASK^> ^<GW^>
        pause
        exit /b 1
    )
    powershell -ExecutionPolicy Bypass -File "NetworkConfig.ps1" -Action static -IPAddress "%2" -SubnetMask "%3" -Gateway "%4"
) else if "%1"=="dhcp" (
    powershell -ExecutionPolicy Bypass -File "NetworkConfig.ps1" -Action dhcp
) else (
    echo Invalid action: %1
    echo Use: status, static, or dhcp
    pause
    exit /b 1
)

echo.
pause
