@echo off
echo ========================================
echo Set Network Adapter to DHCP
echo ========================================
echo.

echo This will configure the network adapter to use DHCP.
echo.

powershell -ExecutionPolicy Bypass -File "Set-DHCP.ps1"

echo.
pause
