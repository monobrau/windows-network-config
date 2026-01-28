# Clear Server Cache
# Clears various caches that may interfere with script downloads and execution
# Run as Administrator for full functionality

#Requires -Version 5.1

# Ensure TLS 1.2 is enabled
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Write-Host "`n=== Server Cache Cleaner ===" -ForegroundColor Cyan
Write-Host ""

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "WARNING: Not running as Administrator. Some operations may require elevation." -ForegroundColor Yellow
    Write-Host ""
}

# Function: Clear PowerShell History
function Clear-PowerShellHistory {
    Write-Host "Clearing PowerShell command history..." -ForegroundColor Yellow
    try {
        $historyPath = (Get-PSReadlineOption).HistorySavePath
        if (Test-Path $historyPath) {
            Remove-Item $historyPath -Force -ErrorAction SilentlyContinue
            Write-Host "  PowerShell history cleared." -ForegroundColor Green
        } else {
            Write-Host "  No PowerShell history file found." -ForegroundColor Gray
        }
    } catch {
        Write-Host "  Could not clear PowerShell history: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Function: Clear Temp Files
function Clear-TempFiles {
    Write-Host "Clearing temporary files..." -ForegroundColor Yellow
    try {
        $tempFiles = @(
            "$env:TEMP\DuoProxyUpgrade*.ps1",
            "$env:TEMP\*DuoProxy*.ps1",
            "$env:TEMP\*Duo*.ps1"
        )
        
        $cleared = 0
        foreach ($pattern in $tempFiles) {
            $files = Get-ChildItem -Path $pattern -ErrorAction SilentlyContinue
            foreach ($file in $files) {
                try {
                    Remove-Item $file.FullName -Force -ErrorAction SilentlyContinue
                    $cleared++
                } catch {
                    # Ignore locked files
                }
            }
        }
        
        if ($cleared -gt 0) {
            Write-Host "  Cleared $cleared temporary file(s)." -ForegroundColor Green
        } else {
            Write-Host "  No temporary files found to clear." -ForegroundColor Gray
        }
    } catch {
        Write-Host "  Could not clear temp files: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Function: Clear DNS Cache
function Clear-DNSCache {
    if (-not $isAdmin) {
        Write-Host "Skipping DNS cache flush (requires Administrator privileges)..." -ForegroundColor Yellow
        return
    }
    
    Write-Host "Flushing DNS cache..." -ForegroundColor Yellow
    try {
        ipconfig /flushdns 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  DNS cache flushed successfully." -ForegroundColor Green
        } else {
            Write-Host "  DNS cache flush returned error code: $LASTEXITCODE" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "  Could not flush DNS cache: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Function: Clear .NET Web Cache
function Clear-DotNetWebCache {
    Write-Host "Clearing .NET web request cache..." -ForegroundColor Yellow
    try {
        # Force fresh TLS negotiation
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Write-Host "  .NET web cache cleared." -ForegroundColor Green
    } catch {
        Write-Host "  Could not clear .NET web cache: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Function: Clear PowerShell Module Cache
function Clear-PowerShellModuleCache {
    Write-Host "Clearing PowerShell module cache..." -ForegroundColor Yellow
    try {
        # Clear module cache locations
        $modulePaths = @(
            "$env:USERPROFILE\Documents\WindowsPowerShell\Modules",
            "$env:ProgramFiles\WindowsPowerShell\Modules",
            "$env:ProgramFiles(x86)\WindowsPowerShell\Modules"
        )
        
        $cleared = 0
        foreach ($path in $modulePaths) {
            if (Test-Path $path) {
                # Only clear cache metadata, not actual modules
                $cacheFiles = Get-ChildItem -Path $path -Recurse -Filter "*.cache" -ErrorAction SilentlyContinue
                foreach ($file in $cacheFiles) {
                    try {
                        Remove-Item $file.FullName -Force -ErrorAction SilentlyContinue
                        $cleared++
                    } catch {
                        # Ignore locked files
                    }
                }
            }
        }
        
        if ($cleared -gt 0) {
            Write-Host "  Cleared $cleared PowerShell module cache file(s)." -ForegroundColor Green
        } else {
            Write-Host "  No PowerShell module cache files found." -ForegroundColor Gray
        }
    } catch {
        Write-Host "  Could not clear PowerShell module cache: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Function: Clear Internet Explorer Cache (if exists)
function Clear-IECache {
    if (-not $isAdmin) {
        Write-Host "Skipping IE cache clear (requires Administrator privileges)..." -ForegroundColor Yellow
        return
    }
    
    Write-Host "Clearing Internet Explorer cache..." -ForegroundColor Yellow
    try {
        RunDll32.exe InetCpl.cpl,ClearMyTracksByProcess 8
        Write-Host "  IE cache cleared." -ForegroundColor Green
    } catch {
        Write-Host "  Could not clear IE cache: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Function: Clear Windows Update Cache (if Admin)
function Clear-WindowsUpdateCache {
    if (-not $isAdmin) {
        Write-Host "Skipping Windows Update cache clear (requires Administrator privileges)..." -ForegroundColor Yellow
        return
    }
    
    Write-Host "Clearing Windows Update cache..." -ForegroundColor Yellow
    try {
        Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
        
        $updateCache = "$env:SystemRoot\SoftwareDistribution\Download"
        if (Test-Path $updateCache) {
            $items = Get-ChildItem -Path $updateCache -ErrorAction SilentlyContinue
            $count = $items.Count
            Remove-Item -Path "$updateCache\*" -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "  Windows Update cache cleared ($count items)." -ForegroundColor Green
        }
        
        Start-Service -Name wuauserv -ErrorAction SilentlyContinue
    } catch {
        Write-Host "  Could not clear Windows Update cache: $($_.Exception.Message)" -ForegroundColor Red
        try {
            Start-Service -Name wuauserv -ErrorAction SilentlyContinue
        } catch {
            # Ignore service start errors
        }
    }
}

# Main execution
Write-Host "Starting cache cleanup operations...`n" -ForegroundColor Cyan

Clear-PowerShellHistory
Clear-TempFiles
Clear-DNSCache
Clear-DotNetWebCache
Clear-PowerShellModuleCache
Clear-IECache
Clear-WindowsUpdateCache

Write-Host "`n=== Cache Cleanup Complete ===" -ForegroundColor Green
Write-Host ""
Write-Host "If you were trying to download a fresh script version, try running your download command again." -ForegroundColor Yellow
Write-Host ""
