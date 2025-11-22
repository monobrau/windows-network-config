# Network Configuration Utility
# Switch between Static IP and DHCP configurations
# Version: 1.0.0

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("static", "dhcp", "status")]
    [string]$Action,

    [string]$IPAddress = "",
    [string]$SubnetMask = "",
    [string]$Gateway = "",
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
Network Configuration Utility
============================

Usage: .\NetworkConfig.ps1 -Action <action> [options]

Actions:
  static    : Set static IP configuration
  dhcp      : Set DHCP configuration  
  status    : Show current network status

Static IP Options (required when Action=static):
  -IPAddress <string>    : Static IP address (e.g., 192.168.1.100)
  -SubnetMask <string>   : Subnet mask (e.g., 255.255.255.0)
  -Gateway <string>      : Default gateway (e.g., 192.168.1.1)
  -DNS1 <string>         : Primary DNS server (default: 8.8.8.8)
  -DNS2 <string>         : Secondary DNS server (default: 8.8.4.4)

Common Options:
  -AdapterName <string>  : Specific adapter name (if not specified, uses first physical adapter)
  -Help                  : Show this help message

Examples:
  .\NetworkConfig.ps1 -Action status
  .\NetworkConfig.ps1 -Action static -IPAddress "192.168.1.100" -SubnetMask "255.255.255.0" -Gateway "192.168.1.1"
  .\NetworkConfig.ps1 -Action dhcp
  .\NetworkConfig.ps1 -Action static -IPAddress "10.0.0.50" -SubnetMask "255.255.0.0" -Gateway "10.0.0.1" -DNS1 "1.1.1.1"

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

# Get physical network adapters only (function imported from NetworkAdapterHelpers.ps1)
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

Write-Status "Network Configuration Utility" "Cyan"
Write-Status "=============================" "Cyan"
Write-Status "Using adapter: $($adapter.Name)" "Green"
Write-Status ""

switch ($Action.ToLower()) {
    "status" {
        Write-Status "Current Network Status:" "Yellow"
        Write-Status "======================" "Yellow"
        
        $config = Get-NetIPConfiguration -InterfaceIndex $adapter.InterfaceIndex
        
        Write-Status "Adapter Name: $($adapter.Name)" "White"
        Write-Status "Status: $($adapter.Status)" "White"
        Write-Status "Link Speed: $($adapter.LinkSpeed)" "White"
        
        if ($config.IPv4Address) {
            Write-Status "IP Address: $($config.IPv4Address.IPAddress)" "White"
            Write-Status "Subnet Mask: $($config.IPv4Address.PrefixLength)" "White"
            Write-Status "Gateway: $($config.IPv4Gateway.NextHop)" "White"
            Write-Status "DNS: $($config.DNSServer.ServerAddresses -join ', ')" "White"
            Write-Status "DHCP: $($config.IPv4Address.AddressState)" "White"
        } else {
            Write-Status "No IP configuration" "Red"
        }
        
        Write-Status ""
        Write-Status "All Physical Network Adapters:" "Yellow"
        $allPhysicalAdapters = Get-PhysicalAdapters
        $allPhysicalAdapters | ForEach-Object {
            $adapterConfig = Get-NetIPConfiguration -InterfaceIndex $_.InterfaceIndex
            $ipAddress = if ($adapterConfig.IPv4Address) { $adapterConfig.IPv4Address.IPAddress } else { "No IP" }
            Write-Status "  $($_.Name): $ipAddress" "Cyan"
        }
    }
    
    "static" {
        if (-not $IPAddress -or -not $SubnetMask -or -not $Gateway) {
            Write-Status "Error: IPAddress, SubnetMask, and Gateway are required for static configuration" "Red"
            Write-Status "Use -Help to see usage examples" "Yellow"
            exit 1
        }

        # Validate IP addresses
        if (-not (Test-IPAddress $IPAddress)) {
            Write-Status "Invalid IP address: $IPAddress" "Red"
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

        Write-Status "Setting Static IP Configuration..." "Yellow"
        Write-Status "IP: $IPAddress" "White"
        Write-Status "Mask: $SubnetMask (/$prefixLength)" "White"
        Write-Status "Gateway: $Gateway" "White"
        Write-Status "DNS: $DNS1, $DNS2" "White"
        Write-Status ""

        try {
            # Remove existing configuration
            Remove-NetIPAddress -InterfaceIndex $adapter.InterfaceIndex -Confirm:$false -ErrorAction SilentlyContinue
            Remove-NetRoute -InterfaceIndex $adapter.InterfaceIndex -Confirm:$false -ErrorAction SilentlyContinue

            # Set static IP
            New-NetIPAddress -InterfaceIndex $adapter.InterfaceIndex -IPAddress $IPAddress -PrefixLength $prefixLength -DefaultGateway $Gateway
            Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ServerAddresses $DNS1, $DNS2

            Write-Status "Static IP configuration completed!" "Green"
        } catch {
            Write-Status "Error: $($_.Exception.Message)" "Red"
            exit 1
        }
    }
    
    "dhcp" {
        Write-Status "Setting DHCP Configuration..." "Yellow"
        
        try {
            # Remove existing configuration
            Remove-NetIPAddress -InterfaceIndex $adapter.InterfaceIndex -Confirm:$false -ErrorAction SilentlyContinue
            Remove-NetRoute -InterfaceIndex $adapter.InterfaceIndex -Confirm:$false -ErrorAction SilentlyContinue

            # Enable DHCP
            Set-NetIPInterface -InterfaceIndex $adapter.InterfaceIndex -Dhcp Enabled
            Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ResetServerAddresses

            # Restart adapter to request new DHCP lease (adapter-specific)
            Write-Status "Requesting new IP from DHCP server..." "Yellow"
            Restart-NetAdapter -Name $adapter.Name -Confirm:$false

            Write-Status "DHCP configuration completed!" "Green"
        } catch {
            Write-Status "Error: $($_.Exception.Message)" "Red"
            exit 1
        }
    }
}

Write-Status ""
Write-Status "Operation completed!" "Green"
