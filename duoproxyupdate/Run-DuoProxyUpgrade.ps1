# Duo Proxy Upgrade Helper - Launcher Script
# Checks for DuoProxyUpgrade.exe, runs it if found, otherwise runs DuoProxyUpgrade.ps1

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$exePath = Join-Path $scriptPath "DuoProxyUpgrade.exe"
$ps1Path = Join-Path $scriptPath "DuoProxyUpgrade.ps1"

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
