# Set Network Adapter to Static IP
# This script configures the primary physical network adapter with a static IP address
# Version: 1.0.0

param(
    [Parameter(Mandatory=$true)]
    [string]$IPAddress,

    [Parameter(Mandatory=$true)]
    [string]$SubnetMask,

    [Parameter(Mandatory=$true)]
    [string]$Gateway,

    [string]$DNS1 = "8.8.8.8",
    [string]$DNS2 = "8.8.4.4",
    [string]$AdapterName = "",
    [switch]$Help
)

# Import shared helper functions
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
. "$scriptPath\NetworkAdapterHelpers.ps1"

function Show-Help {
    Write-Host @"
Set Network Adapter to Static IP
================================

Usage: .\Set-StaticIP.ps1 -IPAddress <IP> -SubnetMask <Mask> -Gateway <Gateway> [options]

Required Parameters:
  -IPAddress <string>    : Static IP address to assign (e.g., 192.168.1.100)
  -SubnetMask <string>   : Subnet mask (e.g., 255.255.255.0)
  -Gateway <string>      : Default gateway (e.g., 192.168.1.1)

Optional Parameters:
  -DNS1 <string>         : Primary DNS server (default: 8.8.8.8)
  -DNS2 <string>         : Secondary DNS server (default: 8.8.4.4)
  -AdapterName <string>  : Specific adapter name (if not specified, uses first physical adapter)
  -Help                  : Show this help message

Examples:
  .\Set-StaticIP.ps1 -IPAddress "192.168.1.100" -SubnetMask "255.255.255.0" -Gateway "192.168.1.1"
  .\Set-StaticIP.ps1 -IPAddress "10.0.0.50" -SubnetMask "255.255.0.0" -Gateway "10.0.0.1" -DNS1 "1.1.1.1" -DNS2 "1.0.0.1"

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

# Validate required parameters (helper functions imported from NetworkAdapterHelpers.ps1)
if (-not (Test-IPAddress $IPAddress)) {
    Write-Status "Invalid IP address: $IPAddress" "Red"
    exit 1
}

# Validate and convert subnet mask
try {
    $prefixLength = ConvertTo-PrefixLength -SubnetMask $SubnetMask
    if ($prefixLength -lt 0 -or $prefixLength -gt 32) {
        Write-Status "Invalid subnet mask/prefix length: $SubnetMask (must be 0-32)" "Red"
        exit 1
    }
} catch {
    Write-Status "Invalid subnet mask: $SubnetMask" "Red"
    Write-Status "Use dotted-decimal (e.g., 255.255.255.0) or CIDR notation (e.g., 24)" "Yellow"
    exit 1
}

if (-not (Test-IPAddress $Gateway)) {
    Write-Status "Invalid gateway: $Gateway" "Red"
    exit 1
}

if ($DNS1 -and -not (Test-IPAddress $DNS1)) {
    Write-Status "Invalid DNS1: $DNS1" "Red"
    exit 1
}

if ($DNS2 -and -not (Test-IPAddress $DNS2)) {
    Write-Status "Invalid DNS2: $DNS2" "Red"
    exit 1
}

Write-Status "Setting Network Adapter to Static IP" "Cyan"
Write-Status "=====================================" "Cyan"
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
} else {
    Write-Status "  No current IP configuration" "White"
}
Write-Status ""

# Display new configuration
Write-Status "New Configuration:" "Yellow"
Write-Status "  IP Address: $IPAddress" "White"
Write-Status "  Subnet Mask: $SubnetMask (/$prefixLength)" "White"
Write-Status "  Gateway: $Gateway" "White"
Write-Status "  DNS: $DNS1, $DNS2" "White"
Write-Status ""

# Confirm before proceeding
$confirm = Read-Host "Proceed with static IP configuration? (y/n)"
if ($confirm -ne "y" -and $confirm -ne "Y") {
    Write-Status "Configuration cancelled" "Yellow"
    exit 0
}

try {
    Write-Status "Configuring static IP..." "Yellow"
    
    # Remove existing IP configuration
    Write-Status "Removing existing IP configuration..." "Yellow"
    Remove-NetIPAddress -InterfaceIndex $adapter.InterfaceIndex -Confirm:$false -ErrorAction SilentlyContinue
    Remove-NetRoute -InterfaceIndex $adapter.InterfaceIndex -Confirm:$false -ErrorAction SilentlyContinue
    
    # Set static IP
    Write-Status "Setting static IP address..." "Yellow"
    New-NetIPAddress -InterfaceIndex $adapter.InterfaceIndex -IPAddress $IPAddress -PrefixLength $prefixLength -DefaultGateway $Gateway
    
    # Set DNS servers
    Write-Status "Setting DNS servers..." "Yellow"
    Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ServerAddresses $DNS1, $DNS2
    
    Write-Status "Static IP configuration completed successfully!" "Green"
    Write-Status ""
    
    # Verify configuration
    Write-Status "Verifying configuration..." "Yellow"
    Start-Sleep -Seconds 2
    $newConfig = Get-NetIPConfiguration -InterfaceIndex $adapter.InterfaceIndex
    
    if ($newConfig.IPv4Address.IPAddress -eq $IPAddress) {
        Write-Status "✅ IP Address: $($newConfig.IPv4Address.IPAddress)" "Green"
    } else {
        Write-Status "❌ IP Address mismatch" "Red"
    }
    
    if ($newConfig.IPv4Gateway.NextHop -eq $Gateway) {
        Write-Status "✅ Gateway: $($newConfig.IPv4Gateway.NextHop)" "Green"
    } else {
        Write-Status "❌ Gateway mismatch" "Red"
    }
    
    $dnsServers = $newConfig.DNSServer.ServerAddresses
    if ($dnsServers -contains $DNS1 -and $dnsServers -contains $DNS2) {
        Write-Status "✅ DNS Servers: $($dnsServers -join ', ')" "Green"
    } else {
        Write-Status "❌ DNS configuration mismatch" "Red"
    }
    
    Write-Status ""
    Write-Status "Static IP configuration complete!" "Green"
    Write-Status "You may need to restart network services or reboot for full effect." "Yellow"
    
} catch {
    Write-Status "Error configuring static IP: $($_.Exception.Message)" "Red"
    Write-Status "Please check your parameters and try again." "Yellow"
    exit 1
}
