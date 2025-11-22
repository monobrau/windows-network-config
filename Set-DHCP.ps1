# Set Network Adapter to DHCP
# This script configures the primary physical network adapter to use DHCP
# Version: 1.0.0

param(
    [string]$AdapterName = "",
    [switch]$Help
)

# Import shared helper functions
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
. "$scriptPath\NetworkAdapterHelpers.ps1"

function Show-Help {
    Write-Host @"
Set Network Adapter to DHCP
===========================

Usage: .\Set-DHCP.ps1 [options]

Optional Parameters:
  -AdapterName <string>  : Specific adapter name (if not specified, uses first physical adapter)
  -Help                  : Show this help message

Examples:
  .\Set-DHCP.ps1
  .\Set-DHCP.ps1 -AdapterName "Ethernet"

"@
}

if ($Help) {
    Show-Help
    exit 0
}

# Check for administrator privileges
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Status "ERROR: This script requires Administrator privileges" "Red"
    Write-Status "Please right-click PowerShell and select 'Run as Administrator'" "Yellow"
    exit 1
}

Write-Status "Setting Network Adapter to DHCP" "Cyan"
Write-Status "=================================" "Cyan"
Write-Status ""

# Get physical network adapters only (function imported from NetworkAdapterHelpers.ps1)
Write-Status "Finding physical network adapters..." "Yellow"
$adapters = Get-PhysicalAdapters

if (-not $adapters) {
    Write-Status "No active physical network adapters found!" "Red"
    exit 1
}

# Select adapter
if ($AdapterName) {
    $adapter = $adapters | Where-Object { $_.Name -eq $AdapterName }
    if (-not $adapter) {
        Write-Status "Adapter '$AdapterName' not found!" "Red"
        Write-Status "Available adapters:" "Yellow"
        $adapters | ForEach-Object { Write-Status "  - $($_.Name)" "Cyan" }
        exit 1
    }
} else {
    $adapter = $adapters[0]
}

Write-Status "Using adapter: $($adapter.Name)" "Green"
Write-Status ""

# Display current configuration
Write-Status "Current Configuration:" "Yellow"
$currentConfig = Get-NetIPConfiguration -InterfaceIndex $adapter.InterfaceIndex
if ($currentConfig.IPv4Address) {
    Write-Status "  IP Address: $($currentConfig.IPv4Address.IPAddress)" "White"
    Write-Status "  Subnet Mask: $($currentConfig.IPv4Address.PrefixLength)" "White"
    Write-Status "  Gateway: $($currentConfig.IPv4Gateway.NextHop)" "White"
    Write-Status "  DNS: $($currentConfig.DNSServer.ServerAddresses -join ', ')" "White"
    Write-Status "  DHCP Enabled: $($currentConfig.IPv4Address.AddressState)" "White"
} else {
    Write-Status "  No current IP configuration" "White"
}
Write-Status ""

# Confirm before proceeding
$confirm = Read-Host "Proceed with DHCP configuration? (y/n)"
if ($confirm -ne "y" -and $confirm -ne "Y") {
    Write-Status "Configuration cancelled" "Yellow"
    exit 0
}

try {
    Write-Status "Configuring DHCP..." "Yellow"
    
    # Remove existing IP configuration
    Write-Status "Removing existing IP configuration..." "Yellow"
    Remove-NetIPAddress -InterfaceIndex $adapter.InterfaceIndex -Confirm:$false -ErrorAction SilentlyContinue
    Remove-NetRoute -InterfaceIndex $adapter.InterfaceIndex -Confirm:$false -ErrorAction SilentlyContinue
    
    # Enable DHCP
    Write-Status "Enabling DHCP..." "Yellow"
    Set-NetIPInterface -InterfaceIndex $adapter.InterfaceIndex -Dhcp Enabled
    
    # Reset DNS to automatic
    Write-Status "Setting DNS to automatic..." "Yellow"
    Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ResetServerAddresses
    
    Write-Status "DHCP configuration completed successfully!" "Green"
    Write-Status ""

    # Restart adapter to request new DHCP lease (adapter-specific)
    Write-Status "Requesting new IP from DHCP server..." "Yellow"
    Restart-NetAdapter -Name $adapter.Name -Confirm:$false

    Write-Status ""
    
    # Verify configuration
    Write-Status "Verifying configuration..." "Yellow"
    Start-Sleep -Seconds 3
    $newConfig = Get-NetIPConfiguration -InterfaceIndex $adapter.InterfaceIndex
    
    if ($newConfig.IPv4Address) {
        Write-Status "✅ New IP Address: $($newConfig.IPv4Address.IPAddress)" "Green"
        Write-Status "✅ Subnet Mask: $($newConfig.IPv4Address.PrefixLength)" "Green"
        if ($newConfig.IPv4Gateway) {
            Write-Status "✅ Gateway: $($newConfig.IPv4Gateway.NextHop)" "Green"
        }
        if ($newConfig.DNSServer) {
            Write-Status "✅ DNS Servers: $($newConfig.DNSServer.ServerAddresses -join ', ')" "Green"
        }
        Write-Status "✅ DHCP Status: $($newConfig.IPv4Address.AddressState)" "Green"
    } else {
        Write-Status "❌ No IP address assigned yet" "Red"
        Write-Status "This may take a few moments. Try running 'ipconfig /renew' manually." "Yellow"
    }
    
    Write-Status ""
    Write-Status "DHCP configuration complete!" "Green"
    Write-Status "The adapter will now automatically obtain IP settings from DHCP." "Yellow"
    
} catch {
    Write-Status "Error configuring DHCP: $($_.Exception.Message)" "Red"
    Write-Status "Please check your network connection and try again." "Yellow"
    exit 1
}
