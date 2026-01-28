# Duo Proxy Upgrade Helper - Launcher Script
# Checks for DuoProxyUpgrade.exe, runs it if found, otherwise runs DuoProxyUpgrade.ps1
# Usage: .\Run-DuoProxyUpgrade.ps1 [-Download]

param(
    [switch]$Download
)

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$exePath = Join-Path $scriptPath "DuoProxyUpgrade.exe"
$ps1Path = Join-Path $scriptPath "DuoProxyUpgrade.ps1"

# If Download parameter is specified, download to temp file and execute
if ($Download) {
    # Ensure TLS 1.2 is enabled for PowerShell 5.x compatibility
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    
    # GitHub repository details
    $GitHubUser = "monobrau"
    $GitHubRepo = "windows-network-config"
    $GitHubBranch = "main"
    $SubDirectory = "duoproxyupdate"
    $ScriptFile = "DuoProxyUpgrade.ps1"
    
    # Construct raw GitHub URL
    $GitHubUrl = "https://raw.githubusercontent.com/$GitHubUser/$GitHubRepo/$GitHubBranch/$SubDirectory/$ScriptFile"
    $TempScript = Join-Path $env:TEMP $ScriptFile
    
    Write-Host "Downloading from GitHub..." -ForegroundColor Green
    Write-Host "URL: $GitHubUrl" -ForegroundColor Gray
    
    try {
        # Download script to temp location
        Invoke-WebRequest -Uri $GitHubUrl -OutFile $TempScript -UseBasicParsing -ErrorAction Stop
        Write-Host "Download complete!" -ForegroundColor Green
        Write-Host "Executing script..." -ForegroundColor Yellow
        
        # Execute the downloaded script
        & powershell.exe -ExecutionPolicy Bypass -File $TempScript
    } catch {
        Write-Host "`nERROR: Failed to download or execute script from GitHub" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        Write-Host "Tried URL: $GitHubUrl" -ForegroundColor Yellow
        exit 1
    }
    
    exit 0
}

# Otherwise, launch the GUI
if (Test-Path $exePath) {
    Write-Host "Found DuoProxyUpgrade.exe, running executable..." -ForegroundColor Green
    & $exePath
} elseif (Test-Path $ps1Path) {
    Write-Host "DuoProxyUpgrade.exe not found, running PowerShell script..." -ForegroundColor Yellow
    & powershell.exe -ExecutionPolicy Bypass -File $ps1Path
} else {
    Write-Host "ERROR: Neither DuoProxyUpgrade.exe nor DuoProxyUpgrade.ps1 found in:" -ForegroundColor Red
    Write-Host $scriptPath -ForegroundColor Red
    exit 1
}
