# Exchange Transport Rule Manager Launcher
# This script handles module installation and launches the main application

Write-Host "Exchange Transport Rule Manager - MSP Edition" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

# Check and install ExchangeOnlineManagement module
Write-Host "Checking for ExchangeOnlineManagement module..." -ForegroundColor Yellow

try {
    if (!(Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
        Write-Host "ExchangeOnlineManagement module not found. Installing..." -ForegroundColor Yellow
        Install-Module -Name ExchangeOnlineManagement -Force -AllowClobber -Scope CurrentUser
        Write-Host "Module installed successfully." -ForegroundColor Green
    } else {
        Write-Host "ExchangeOnlineManagement module found." -ForegroundColor Green
    }
} catch {
    Write-Host "Error checking/installing module: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Please run as Administrator or install manually:" -ForegroundColor Yellow
    Write-Host "Install-Module -Name ExchangeOnlineManagement -Force -AllowClobber" -ForegroundColor Yellow
    Read-Host "Press Enter to continue anyway"
}

Write-Host ""
Write-Host "Starting Exchange Transport Rule Manager..." -ForegroundColor Green

# Get the directory where this script is located
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Launch the main application
try {
    & "$ScriptDir\ExchangeTransportRuleManager.ps1"
} catch {
    Write-Host "Error launching application: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Full error details:" -ForegroundColor Yellow
    Write-Host $_.Exception.ToString() -ForegroundColor Red
}

Write-Host ""
Write-Host "Application closed." -ForegroundColor Yellow
Read-Host "Press Enter to exit"

