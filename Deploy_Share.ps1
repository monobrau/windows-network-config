# LAN Share Deployment Script
# Copies and runs the Windows Autorun Analyzer from a network share

param(
    [string]$SharePath = "\\server\share\WindowsAutorunAnalyzer_Portable.ps1",
    [string]$LocalPath = "C:\dev\WindowsAutorunAnalyzer_Portable.ps1",
    [string]$OutputPath = "C:\dev\AutorunAnalysis_$(Get-Date -Format 'yyyyMMdd_HHmmss').xlsx"
)

Write-Host "LAN Share Deployment Mode" -ForegroundColor Cyan
Write-Host "Copying from: $SharePath" -ForegroundColor Yellow

try {
    # Check if share is accessible
    if (Test-Path $SharePath) {
        # Copy the script
        Copy-Item -Path $SharePath -Destination $LocalPath -Force
        Write-Host "Script copied successfully" -ForegroundColor Green
        
        # Execute the script
        & $LocalPath -OutputPath $OutputPath
        Write-Host "Analysis completed successfully" -ForegroundColor Green
        
    } else {
        Write-Host "Share not accessible: $SharePath" -ForegroundColor Red
        Write-Host "Please check:" -ForegroundColor Yellow
        Write-Host "1. Network connectivity" -ForegroundColor Yellow
        Write-Host "2. Share path is correct" -ForegroundColor Yellow
        Write-Host "3. You have access permissions" -ForegroundColor Yellow
    }
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}
