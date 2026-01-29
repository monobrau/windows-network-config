# Troubleshooting Duo Proxy Version Detection

## Issue
You're seeing "Installed (version unknown - check Duo Proxy Manager)" instead of the actual version or "Version unknown".

**Note:** This issue occurs on the **target server** (e.g., ZCS-MAIN) where Duo Proxy is installed, not on your local machine.

## Solution

### Step 1: Clear PowerShell Cache on Target Server
When connected to the target server (e.g., via ScreenConnect), clear PowerShell cache:

```powershell
# Clear PowerShell module cache
Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Windows\PowerShell\CommandAnalysis\*" -Recurse -Force -ErrorAction SilentlyContinue

# Clear temp files (where script may be cached)
Remove-Item -Path "$env:TEMP\DuoProxyUpgrade*.ps1" -Force -ErrorAction SilentlyContinue

# Clear any cached web requests
[System.Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
```

### Step 2: Use Cache-Busting One-Liner
Use this command to ensure you get the latest version:

```powershell
powershell.exe -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12;`$f=Join-Path `$env:TEMP DuoProxyUpgrade.ps1;Remove-Item `$f -ErrorAction SilentlyContinue;Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/monobrau/windows-network-config/main/duoproxyupdate/DuoProxyUpgrade.ps1' -OutFile `$f -UseBasicParsing;powershell.exe -ExecutionPolicy Bypass -File `$f"
```

### Step 3: Run Diagnostic Script on Target Server
If version detection still fails on the target server, run the diagnostic script:

```powershell
# Download and run diagnostic (run this on the target server)
powershell.exe -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12;iex((Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/monobrau/windows-network-config/main/duoproxyupdate/Diagnose-DuoVersion.ps1' -UseBasicParsing).Content)"
```

The diagnostic will show:
- Whether the service exists
- Service executable path and version info
- Registry entries
- Standard executable paths
- Install directories

**Important:** Run this diagnostic on the server where Duo Proxy is installed (e.g., ZCS-MAIN), not on your local machine.

### Step 4: Share Diagnostic Output
If version detection still fails after clearing cache, share the diagnostic output from the target server so we can improve the detection logic.

## Expected Behavior
After clearing cache on the target server and using the latest version, you should see:
- **If version found**: "Version X.X.X" (e.g., "Version 5.6.0")
- **If installed but version unknown**: "Version unknown"
- **If not installed**: "Not installed"

The ticket notes will show:
- `Upgrade Duo Authentication Proxy on ZCS-MAIN from version 5.6.0 to latest version.` (if version found)
- `Upgrade Duo Authentication Proxy on ZCS-MAIN from version Version unknown to latest version.` (if installed but version unknown)

## Quick Fix for Immediate Use
If you need to use the script right now on a server and want to ensure you get the latest version:

1. **Connect to target server** (e.g., ZCS-MAIN via ScreenConnect)
2. **Run this command** (includes timestamp cache-busting):
   ```powershell
   powershell.exe -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12;`$f=Join-Path `$env:TEMP DuoProxyUpgrade.ps1;Remove-Item `$f -ErrorAction SilentlyContinue;Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/monobrau/windows-network-config/main/duoproxyupdate/DuoProxyUpgrade.ps1' -OutFile `$f -UseBasicParsing;powershell.exe -ExecutionPolicy Bypass -File `$f"
   ```

This ensures you get a fresh download every time, bypassing any cache issues.
