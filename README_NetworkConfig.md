# Windows Network Configuration Scripts
## Physical Adapters Only (Ethernet/Wireless)

A collection of PowerShell scripts for managing Windows network adapter configurations, including static IP and DHCP settings.

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
- `Set-StaticIP.ps1` - Configure static IP addresses
- `Set-DHCP.ps1` - Configure DHCP settings
- `NetworkConfig.ps1` - Combined utility for all network operations

### Batch Files
- `set_static_ip.bat` - Easy static IP configuration
- `set_dhcp.bat` - Easy DHCP configuration
- `network_config.bat` - Combined utility wrapper

## 🚀 Quick Start

### Set Static IP
```cmd
# Using batch file (easiest)
set_static_ip.bat 192.168.1.100 255.255.255.0 192.168.1.1

# Using PowerShell directly
powershell -ExecutionPolicy Bypass -File "Set-StaticIP.ps1" -IPAddress "192.168.1.100" -SubnetMask "255.255.255.0" -Gateway "192.168.1.1"
```

### Set DHCP
```cmd
# Using batch file (easiest)
set_dhcp.bat

# Using PowerShell directly
powershell -ExecutionPolicy Bypass -File "Set-DHCP.ps1"
```

### Check Network Status
```cmd
# Check current configuration
network_config.bat status
```

## 📋 Usage Examples

### Static IP Configuration
```powershell
# Basic static IP
.\Set-StaticIP.ps1 -IPAddress "192.168.1.100" -SubnetMask "255.255.255.0" -Gateway "192.168.1.1"

# With custom DNS servers
.\Set-StaticIP.ps1 -IPAddress "10.0.0.50" -SubnetMask "255.255.0.0" -Gateway "10.0.0.1" -DNS1 "1.1.1.1" -DNS2 "1.0.0.1"

# On specific adapter
.\Set-StaticIP.ps1 -IPAddress "192.168.1.100" -SubnetMask "255.255.255.0" -Gateway "192.168.1.1" -AdapterName "Ethernet"
```

### DHCP Configuration
```powershell
# Basic DHCP
.\Set-DHCP.ps1

# On specific adapter
.\Set-DHCP.ps1 -AdapterName "Ethernet"
```

### Network Status
```powershell
# Check all adapters
.\NetworkConfig.ps1 -Action status

# Check specific adapter
.\NetworkConfig.ps1 -Action status -AdapterName "Ethernet"
```

## 🔧 Parameters

### Set-StaticIP.ps1
- `-IPAddress` (Required) - Static IP address to assign
- `-SubnetMask` (Required) - Subnet mask
- `-Gateway` (Required) - Default gateway
- `-DNS1` (Optional) - Primary DNS server (default: 8.8.8.8)
- `-DNS2` (Optional) - Secondary DNS server (default: 8.8.4.4)
- `-AdapterName` (Optional) - Specific adapter name

### Set-DHCP.ps1
- `-AdapterName` (Optional) - Specific adapter name

### NetworkConfig.ps1
- `-Action` (Required) - Action to perform: static, dhcp, or status
- Additional parameters depend on the action selected

## ⚠️ Requirements

- **Windows PowerShell 5.1+**
- **Administrator privileges** (required for network configuration)
- **Active network adapter**

## 🔒 Safety Features

- **Input validation** - Validates all IP addresses before applying
- **User confirmation** - Asks for confirmation before making changes
- **Current status display** - Shows current configuration before changes
- **Verification** - Confirms changes were applied successfully
- **Error handling** - Comprehensive error checking and reporting

## 📊 What Gets Configured

### Static IP Mode
- IP address assignment
- Subnet mask configuration
- Default gateway setting
- DNS server configuration
- Route table updates

### DHCP Mode
- Enables DHCP on the adapter
- Resets DNS to automatic
- Releases current IP address
- Requests new IP from DHCP server

## 🚀 Enterprise Usage

### Group Policy Deployment
```cmd
# Deploy via startup script
powershell -ExecutionPolicy Bypass -File "\\server\scripts\Set-StaticIP.ps1" -IPAddress "192.168.1.100" -SubnetMask "255.255.255.0" -Gateway "192.168.1.1"
```

### Scheduled Tasks
```cmd
# Daily network configuration check
powershell -ExecutionPolicy Bypass -File "NetworkConfig.ps1" -Action status
```

### Remote Management
```powershell
# Remote execution via PowerShell
Invoke-Command -ComputerName "Workstation01" -ScriptBlock { .\Set-DHCP.ps1 }
```

## 🔄 Common Workflows

### Switching Between Static and DHCP
```cmd
# Check current status
network_config.bat status

# Set static IP
set_static_ip.bat 192.168.1.100 255.255.255.0 192.168.1.1

# Switch back to DHCP
set_dhcp.bat
```

### Troubleshooting Network Issues
```cmd
# Check all adapter status
network_config.bat status

# Reset to DHCP
set_dhcp.bat

# Test with static IP
set_static_ip.bat 192.168.1.100 255.255.255.0 192.168.1.1
```

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📞 Support

For issues or questions:
1. Check the troubleshooting section
2. Verify all requirements are met
3. Test with administrator privileges
4. Check PowerShell execution policy
