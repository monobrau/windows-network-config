@echo off
echo ========================================
echo Set Network Adapter to Static IP
echo ========================================
echo.

if "%1"=="" (
    echo Usage: set_static_ip.bat ^<IP^> ^<SubnetMask^> ^<Gateway^> [DNS1] [DNS2]
    echo.
    echo Examples:
    echo   set_static_ip.bat 192.168.1.100 255.255.255.0 192.168.1.1
    echo   set_static_ip.bat 10.0.0.50 255.255.0.0 10.0.0.1 1.1.1.1 1.0.0.1
    echo.
    pause
    exit /b 1
)

set IP=%1
set MASK=%2
set GATEWAY=%3
set DNS1=%4
set DNS2=%5

if "%DNS1%"=="" set DNS1=8.8.8.8
if "%DNS2%"=="" set DNS2=8.8.4.4

echo IP Address: %IP%
echo Subnet Mask: %MASK%
echo Gateway: %GATEWAY%
echo DNS1: %DNS1%
echo DNS2: %DNS2%
echo.

powershell -ExecutionPolicy Bypass -File "Set-StaticIP.ps1" -IPAddress "%IP%" -SubnetMask "%MASK%" -Gateway "%GATEWAY%" -DNS1 "%DNS1%" -DNS2 "%DNS2%"

echo.
pause
