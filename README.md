# Windows Network Configuration Scripts
## Physical Adapters Only (Ethernet/Wireless)

A collection of PowerShell scripts for managing Windows network adapter configurations, including static IP and DHCP settings. These scripts are designed to work only with physical network adapters, automatically excluding VPNs, virtual adapters, and other non-physical interfaces.

## 🚀 Features

- **Physical Adapters Only** - Automatically excludes VPNs, virtual adapters, and non-physical interfaces
- **Smart Adapter Detection** - Identifies Ethernet and Wireless adapters using multiple detection methods
- **Static IP Configuration** - Set static IP addresses with validation
- **DHCP Configuration** - Switch adapters back to DHCP
- **Network Status** - Check current network configuration
- **Input Validation** - Validates all IP addresses and parameters
- **Error Handling** - Comprehensive error checking and user feedback
- **Multiple Formats** - PowerShell scripts and batch file wrappers

## 📁 Scripts Included

### PowerShell Scripts
- `NetworkConfig.ps1` - Combined utility for all network operations
- `Set-StaticIP.ps1` - Configure static IP addresses
- `Set-DHCP.ps1` - Configure DHCP settings

### Batch Files
- `network_config.bat` - Main batch wrapper
- `set_static_ip.bat` - Static IP batch wrapper
- `set_dhcp.bat` - DHCP batch wrapper
- `*_standalone.bat` - Standalone versions for direct execution

### Documentation
- `README_NetworkConfig.md` - Detailed network configuration documentation
- `Network_Scripts_Usage.txt` - Usage instructions
- `one_liner_network_commands.txt` - One-liner commands

## 🔧 Usage

### Quick Start
```powershell
# Check network status
.\NetworkConfig.ps1 -Action status

# Set static IP
.\Set-StaticIP.ps1 -IPAddress "192.168.1.100" -SubnetMask "255.255.255.0" -Gateway "192.168.1.1"

# Set DHCP
.\Set-DHCP.ps1
```

### From GitHub (No Download Required)
Set-DHCP.ps1 auto-downloads `NetworkAdapterHelpers.ps1` from this repo when run standalone—no need to clone or download multiple files.
```powershell
# Download and run Set-DHCP.ps1
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/monobrau/windows-network-config/main/Set-DHCP.ps1" -OutFile "Set-DHCP.ps1"; .\Set-DHCP.ps1; del Set-DHCP.ps1

# Download and run Set-StaticIP.ps1
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/monobrau/windows-network-config/main/Set-StaticIP.ps1" -OutFile "Set-StaticIP.ps1"; .\Set-StaticIP.ps1 -IPAddress "192.168.1.100" -SubnetMask "255.255.255.0" -Gateway "192.168.1.1"; del Set-StaticIP.ps1
```

## 🔒 Physical Adapter Filtering

The scripts automatically exclude:
- **VPN Adapters** - OpenVPN, WireGuard, NordVPN, ExpressVPN, etc.
- **Virtual Adapters** - Hyper-V, VMware, VirtualBox, Docker, WSL
- **Tunnel Interfaces** - TAP, TUN, PPP, PPTP, L2TP
- **Microsoft Virtual** - Loopback, ISATAP, Teredo, 6to4, RAS
- **Unknown/Generic** - Any adapter without proper hardware identification

The scripts will only work with:
- **Ethernet Adapters** - Wired network connections
- **Wireless Adapters** - Wi-Fi connections (802.11)
- **Physical Hardware** - Adapters with actual PCI device IDs

## 📋 Requirements

- **PowerShell 5.1+** (Windows 10/11)
- **Administrator privileges** (for network configuration)
- **Physical network adapters** (Ethernet/Wireless)

## 🛡️ Safety Features

- **Input Validation** - All IP addresses and parameters are validated
- **Confirmation Prompts** - User confirmation before making changes
- **Error Handling** - Comprehensive error checking and user feedback
- **Physical Adapter Only** - Prevents accidental configuration of virtual adapters

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 🆘 Support

For issues or questions:
1. Check the troubleshooting section in README_NetworkConfig.md
2. Verify all requirements are met
3. Ensure you have administrator privileges
4. Check that physical adapters are detected correctly