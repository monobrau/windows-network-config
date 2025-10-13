# Network Configuration Utility
# Switch between Static IP and DHCP configurations

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

function Write-Status {
    param($Message, $Color = "White")
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $Message" -ForegroundColor $Color
}

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

# Function to identify physical adapters (Ethernet and Wireless only)
function Get-PhysicalAdapters {
    $allAdapters = Get-NetAdapter
    $physicalAdapters = @()
    
    foreach ($adapter in $allAdapters) {
        # Skip if adapter is not up
        if ($adapter.Status -ne "Up") { continue }
        
        # Get adapter details
        $adapterDetails = Get-NetAdapterHardwareInfo -InterfaceIndex $adapter.InterfaceIndex -ErrorAction SilentlyContinue
        
        # Check if it's a physical adapter by examining various properties
        $isPhysical = $false
        
        # Method 1: Check PhysicalMediaType for Ethernet or Wireless
        if ($adapter.PhysicalMediaType -eq "802.11" -or $adapter.PhysicalMediaType -eq "Ethernet") {
            $isPhysical = $true
        }
        
        # Method 2: Check InterfaceDescription for common physical adapter patterns
        $description = $adapter.InterfaceDescription.ToLower()
        if ($description -match "ethernet|wireless|wi-fi|wifi|802\.11|realtek|intel|broadcom|qualcomm|atheros|marvell") {
            $isPhysical = $true
        }
        
        # Method 3: Exclude known virtual/VPN adapters
        $excludePatterns = @(
            "virtual", "vpn", "tunnel", "tap", "tun", "ppp", "pptp", "l2tp", "openvpn", 
            "wireguard", "nordvpn", "expressvpn", "surfshark", "proton", "mullvad",
            "hyper-v", "vmware", "virtualbox", "docker", "wsl", "loopback", "isatap",
            "teredo", "6to4", "microsoft", "ras", "remote access", "miniport"
        )
        
        $isExcluded = $false
        foreach ($pattern in $excludePatterns) {
            if ($description -match $pattern) {
                $isExcluded = $true
                break
            }
        }
        
        # Method 4: Check if adapter has physical hardware info
        if ($adapterDetails -and $adapterDetails.PciDeviceId -and $adapterDetails.PciDeviceId -ne "Unknown") {
            $isPhysical = $true
        }
        
        # Final decision: physical if not excluded and meets physical criteria
        if ($isPhysical -and -not $isExcluded) {
            $physicalAdapters += $adapter
        }
    }
    
    return $physicalAdapters
}

# Get physical network adapters only
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
        
        Write-Status "Setting Static IP Configuration..." "Yellow"
        Write-Status "IP: $IPAddress" "White"
        Write-Status "Mask: $SubnetMask" "White"
        Write-Status "Gateway: $Gateway" "White"
        Write-Status "DNS: $DNS1, $DNS2" "White"
        Write-Status ""
        
        try {
            # Remove existing configuration
            Remove-NetIPAddress -InterfaceIndex $adapter.InterfaceIndex -Confirm:$false -ErrorAction SilentlyContinue
            Remove-NetRoute -InterfaceIndex $adapter.InterfaceIndex -Confirm:$false -ErrorAction SilentlyContinue
            
            # Set static IP
            New-NetIPAddress -InterfaceIndex $adapter.InterfaceIndex -IPAddress $IPAddress -PrefixLength $SubnetMask -DefaultGateway $Gateway
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
            
            # Request new IP
            ipconfig /release | Out-Null
            ipconfig /renew | Out-Null
            
            Write-Status "DHCP configuration completed!" "Green"
        } catch {
            Write-Status "Error: $($_.Exception.Message)" "Red"
            exit 1
        }
    }
}

Write-Status ""
Write-Status "Operation completed!" "Green"
