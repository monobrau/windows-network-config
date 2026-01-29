# Windows Autorun Analyzer - Deployment Guide

This tool can be deployed and run in three different scenarios:

## 🚀 Quick Start

### Option 1: Auto-Detection (Recommended)
```powershell
.\WindowsAutorunAnalyzer_Launcher.ps1
```

### Option 2: Direct Execution
```powershell
# For portable version (no dependencies)
.\WindowsAutorunAnalyzer_Portable.ps1

# For full version (requires ImportExcel module)
.\WindowsAutorunAnalyzer.ps1
```

## 📋 Deployment Scenarios

### 1. 🌐 With Internet (GitHub)
**Use when:** You have internet connectivity and want the latest version

```powershell
# Auto-detect and download from GitHub
.\WindowsAutorunAnalyzer_Launcher.ps1 -Mode github

# Or use the GitHub deployment script directly
.\Deploy_GitHub.ps1
```

**Requirements:**
- Internet connectivity
- PowerShell execution policy allows scripts
- GitHub URL is accessible

### 2. 💻 No Internet (Local)
**Use when:** You have the script files locally and no internet access

```powershell
# Auto-detect local script
.\WindowsAutorunAnalyzer_Launcher.ps1 -Mode local

# Or use the local deployment script directly
.\Deploy_Local.ps1
```

**Requirements:**
- Script files present locally
- PowerShell execution policy allows scripts

### 3. 🏢 LAN Share
**Use when:** Script is stored on a network share

```powershell
# Auto-detect from share
.\WindowsAutorunAnalyzer_Launcher.ps1 -Mode share -SharePath "\\server\share\script.ps1"

# Or use the share deployment script directly
.\Deploy_Share.ps1 -SharePath "\\server\share\WindowsAutorunAnalyzer_Portable.ps1"
```

**Requirements:**
- Network connectivity to share
- Access permissions to the share
- PowerShell execution policy allows scripts

## 📁 File Structure

```
C:\dev\
├── WindowsAutorunAnalyzer_Launcher.ps1    # Main launcher (auto-detection)
├── WindowsAutorunAnalyzer_Portable.ps1    # Portable version (no dependencies)
├── WindowsAutorunAnalyzer.ps1             # Full version (requires ImportExcel)
├── Deploy_GitHub.ps1                      # GitHub deployment
├── Deploy_Local.ps1                       # Local deployment
├── Deploy_Share.ps1                       # LAN share deployment
├── run_autorun_analyzer.bat               # Simple batch launcher
└── README_Deployment.md                   # This file
```

## ⚙️ Configuration

### Launcher Parameters
```powershell
.\WindowsAutorunAnalyzer_Launcher.ps1 -Mode auto -OutputPath "C:\reports\analysis.xlsx"
```

**Parameters:**
- `-Mode`: auto, github, local, share
- `-GitHubUrl`: Custom GitHub URL
- `-SharePath`: UNC path to script on share
- `-LocalPath`: Local path to script
- `-OutputPath`: Output file path

### Portable Script Parameters
```powershell
.\WindowsAutorunAnalyzer_Portable.ps1 -OutputPath "C:\reports\analysis.csv"
```

## 🔧 Troubleshooting

### Common Issues

1. **Execution Policy Error**
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

2. **Internet Connectivity Issues**
   - Use local mode: `.\WindowsAutorunAnalyzer_Launcher.ps1 -Mode local`
   - Or use portable version: `.\WindowsAutorunAnalyzer_Portable.ps1`

3. **Share Access Issues**
   - Check network connectivity
   - Verify share path and permissions
   - Use local mode as fallback

4. **Module Installation Issues**
   - Use portable version: `.\WindowsAutorunAnalyzer_Portable.ps1`
   - Or install ImportExcel manually: `Install-Module ImportExcel -Force`

### Error Codes
- `0`: Success
- `1`: Script not found
- `2`: Execution error
- `3`: Network/access error

## 📊 Output Files

The analyzer creates:
- **CSV Report**: Detailed analysis results
- **Summary**: Analysis summary (if using full version)
- **Logs**: Console output with timestamps

## 🚀 Batch File Usage

For simple execution, use the batch file:
```cmd
run_autorun_analyzer.bat
```

This will:
1. Run the launcher in auto-mode
2. Pause for review of results
3. Handle errors gracefully

## 🔒 Security Considerations

- Scripts are signed and verified
- No external dependencies for portable version
- All file operations are logged
- Output files are created in specified directories only

## 📞 Support

For issues or questions:
1. Check the troubleshooting section
2. Verify all requirements are met
3. Test with portable version first
4. Check PowerShell execution logs
