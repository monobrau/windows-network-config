# Network Adapter Helper Functions
# Shared functions for Windows Network Configuration Scripts
# Version: 1.0.0

<#
.SYNOPSIS
    Shared helper functions for network adapter configuration scripts.

.DESCRIPTION
    This module contains common functions used by NetworkConfig.ps1, Set-DHCP.ps1,
    and Set-StaticIP.ps1 to eliminate code duplication.
#>

# Write status messages with timestamps and colors
function Write-Status {
    param($Message, $Color = "White")
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $Message" -ForegroundColor $Color
}

# Validate IP addresses
function Test-IPAddress {
    param($IP)
    try {
        [System.Net.IPAddress]::Parse($IP) | Out-Null
        return $true
    } catch {
        return $false
    }
}

# Convert subnet mask to CIDR prefix length
function ConvertTo-PrefixLength {
    param([string]$SubnetMask)

    # If already a number (0-32), return it
    if ($SubnetMask -match '^\d+$') {
        $prefix = [int]$SubnetMask
        if ($prefix -ge 0 -and $prefix -le 32) {
            return $prefix
        }
    }

    # Convert dotted-decimal subnet mask to prefix length
    try {
        $ip = [System.Net.IPAddress]::Parse($SubnetMask)
        $octets = $ip.GetAddressBytes()

        $binaryString = ""
        foreach ($octet in $octets) {
            $binaryString += [Convert]::ToString($octet, 2).PadLeft(8, '0')
        }

        $prefixLength = ($binaryString.ToCharArray() | Where-Object { $_ -eq '1' }).Count
        return $prefixLength
    } catch {
        throw "Invalid subnet mask: $SubnetMask"
    }
}

# Function to identify physical adapters (Ethernet and Wireless only)
function Get-PhysicalAdapters {
    <#
    .SYNOPSIS
        Identifies physical network adapters (Ethernet and Wireless).

    .DESCRIPTION
        This function filters network adapters to return only physical adapters
        (Ethernet and Wireless), excluding VPNs, virtual adapters, and other
        non-physical interfaces.

    .OUTPUTS
        Array of physical network adapter objects.

    .EXAMPLE
        $adapters = Get-PhysicalAdapters
        $adapters | ForEach-Object { Write-Host $_.Name }
    #>

    $allAdapters = Get-NetAdapter
    $physicalAdapters = @()

    foreach ($adapter in $allAdapters) {
        # Skip if adapter is not up
        if ($adapter.Status -ne "Up") { continue }

        # Get adapter details using pipeline
        $adapterDetails = $adapter | Get-NetAdapterHardwareInfo -ErrorAction SilentlyContinue

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

# Export functions for use in other scripts
Export-ModuleMember -Function Write-Status, Test-IPAddress, ConvertTo-PrefixLength, Get-PhysicalAdapters
