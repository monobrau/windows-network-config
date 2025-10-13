# Test DHCP Script - Fixed Version
# This script configures the primary physical network adapter to use DHCP

param(
    [string]$AdapterName = "",
    [switch]$Help
)

function Write-Status {
    param($Message, $Color = "White")
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $Message" -ForegroundColor $Color
}

if ($Help) {
    Write-Host "Test DHCP Script - Fixed Version"
    Write-Host "Usage: .\Test-DHCP.ps1 [options]"
    Write-Host "Optional: -AdapterName <string>"
    exit 0
}

Write-Status "Test DHCP Script - Fixed Version" "Cyan"
Write-Status "=================================" "Cyan"
Write-Status ""

# Function to identify physical adapters (Ethernet and Wireless only)
function Get-PhysicalAdapters {
    $allAdapters = Get-NetAdapter
    $physicalAdapters = @()
    
    foreach ($adapter in $allAdapters) {
        # Skip if adapter is not up
        if ($adapter.Status -ne "Up") { continue }
        
        # Get adapter details - FIXED: Use -Name parameter
        $adapterDetails = Get-NetAdapterHardwareInfo -Name $adapter.Name -ErrorAction SilentlyContinue
        
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
    
    # Request new IP from DHCP
    Write-Status "Requesting new IP from DHCP server..." "Yellow"
    ipconfig /release
    ipconfig /renew
    
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
