@echo off
echo ========================================
echo Set Network Adapter to DHCP
echo (Physical Adapters Only - Ethernet/Wireless)
echo ========================================
echo.

echo This will configure the physical network adapter to use DHCP.
echo VPNs and virtual adapters are automatically excluded.
echo.

powershell -ExecutionPolicy Bypass -File "Set-DHCP.ps1"

echo.
pause
