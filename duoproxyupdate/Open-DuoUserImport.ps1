# Open Duo User Import Page
# Opens the Duo User Import page in the default web browser

#Requires -Version 5.1

# Configuration
$DuoUserImportURL = "https://www.duo.com/admin/users/import"

# Open URL in default browser
Write-Host "Opening Duo User Import page..." -ForegroundColor Green
Start-Process $DuoUserImportURL
