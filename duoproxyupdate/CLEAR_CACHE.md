# How to Clear Cache for GitHub Script Download

If you're getting an old/cached version of the script, try these methods:

## Method 0: Automated Cache Clearing Script (Easiest - Recommended)

Run the automated cache clearing script directly from GitHub:

**Standard (User-level caches):**
```powershell
powershell.exe -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12;`$f=Join-Path `$env:TEMP Clear-ServerCache.ps1;Remove-Item `$f -ErrorAction SilentlyContinue;Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/monobrau/windows-network-config/main/duoproxyupdate/Clear-ServerCache.ps1' -OutFile `$f -UseBasicParsing;powershell.exe -ExecutionPolicy Bypass -File `$f"
```

**As Administrator (Full cache clearing including DNS and Windows Update):**
```powershell
powershell.exe -ExecutionPolicy Bypass -Command "Start-Process powershell.exe -ArgumentList '-ExecutionPolicy Bypass -Command \"[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12;`$f=Join-Path `$env:TEMP Clear-ServerCache.ps1;Remove-Item `$f -ErrorAction SilentlyContinue;Invoke-WebRequest -Uri ''https://raw.githubusercontent.com/monobrau/windows-network-config/main/duoproxyupdate/Clear-ServerCache.ps1'' -OutFile `$f -UseBasicParsing;powershell.exe -ExecutionPolicy Bypass -File `$f\"' -Verb RunAs"
```

See `CLEAR_CACHE_ONELINER.txt` for more options.

## Method 1: Clear PowerShell Cache (Manual)

Run these commands in PowerShell:

```powershell
# Clear PowerShell command history
Clear-Host
Remove-Item (Get-PSReadlineOption).HistorySavePath -ErrorAction SilentlyContinue

# Clear any cached web requests (if using proxy)
[System.Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
```

## Method 2: Force Fresh Download with Timestamp

Use this command which adds a timestamp to bypass any CDN cache:

```powershell
powershell.exe -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $ts = Get-Date -Format 'yyyyMMddHHmmss'; $url = 'https://raw.githubusercontent.com/monobrau/windows-network-config/main/duoproxyupdate/DuoProxyUpgrade.ps1?t=' + $ts; iex (Invoke-WebRequest -Uri $url -UseBasicParsing).Content"
```

## Method 3: Download to File First (Most Reliable)

Download to a file first, then execute:

```powershell
# Step 1: Download with fresh timestamp
powershell.exe -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $ts = Get-Date -Format 'yyyyMMddHHmmss'; $url = 'https://raw.githubusercontent.com/monobrau/windows-network-config/main/duoproxyupdate/DuoProxyUpgrade.ps1?t=' + $ts; Invoke-WebRequest -Uri $url -OutFile $env:TEMP\DuoProxyUpgrade_Fresh.ps1 -UseBasicParsing"

# Step 2: Execute the downloaded file
powershell.exe -ExecutionPolicy Bypass -File $env:TEMP\DuoProxyUpgrade_Fresh.ps1
```

## Method 4: Clear Windows DNS Cache

If DNS is caching the GitHub domain:

```powershell
# Run as Administrator
ipconfig /flushdns
```

## Method 5: Use Direct Branch Commit Hash (Most Reliable)

Get the latest commit hash and use it in the URL:

```powershell
# Get latest commit hash (run this first)
powershell.exe -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $json = (Invoke-WebRequest -Uri 'https://api.github.com/repos/monobrau/windows-network-config/commits/main' -UseBasicParsing).Content | ConvertFrom-Json; $hash = $json.sha.Substring(0,7); Write-Host \"Latest commit: $hash\""

# Then use the commit hash in URL (replace COMMIT_HASH with actual hash)
powershell.exe -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; iex (Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/monobrau/windows-network-config/COMMIT_HASH/duoproxyupdate/DuoProxyUpgrade.ps1' -UseBasicParsing).Content"
```

## Method 6: Delete Temp Files

Clear any previously downloaded temp files:

```powershell
Remove-Item $env:TEMP\DuoProxyUpgrade*.ps1 -ErrorAction SilentlyContinue
```

## Quick One-Liner with Cache Busting (Recommended)

This command adds a random number to ensure fresh download:

```powershell
powershell.exe -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $rnd = Get-Random; $url = 'https://raw.githubusercontent.com/monobrau/windows-network-config/main/duoproxyupdate/DuoProxyUpgrade.ps1?r=' + $rnd; iex (Invoke-WebRequest -Uri $url -UseBasicParsing).Content"
```

## Verify You Have the Latest Version

Check the version in the script header:

```powershell
powershell.exe -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $content = (Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/monobrau/windows-network-config/main/duoproxyupdate/DuoProxyUpgrade.ps1' -UseBasicParsing).Content; ($content -split \"`n\")[0..5]"
```

Look for `Version: 1.1` in the output to confirm you have the latest version.
