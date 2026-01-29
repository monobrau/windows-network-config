# Diagnostic script to help identify why Duo Proxy version detection is failing
Write-Host "=== Duo Proxy Version Detection Diagnostic ===" -ForegroundColor Cyan
Write-Host ""

# Check if service exists
Write-Host "1. Checking DuoAuthenticationProxy service..." -ForegroundColor Yellow
$service = Get-Service -Name "DuoAuthenticationProxy" -ErrorAction SilentlyContinue
if ($service) {
    Write-Host "   ✓ Service found: $($service.Status)" -ForegroundColor Green
    Write-Host "   Service Name: $($service.Name)" -ForegroundColor Gray
    Write-Host "   Display Name: $($service.DisplayName)" -ForegroundColor Gray
    
    # Get service path
    $serviceObj = Get-WmiObject Win32_Service -Filter "Name='DuoAuthenticationProxy'" -ErrorAction SilentlyContinue
    if ($serviceObj -and $serviceObj.PathName) {
        Write-Host "   Service PathName: $($serviceObj.PathName)" -ForegroundColor Gray
        
        # Try to extract executable path
        $servicePath = $serviceObj.PathName
        if ($servicePath -match '^"([^"]+)"') {
            $exePath = $matches[1]
        } elseif ($servicePath -match '^([^\s]+\.exe)') {
            $exePath = $matches[1]
        } else {
            $exePath = ($servicePath -split '\s+')[0]
        }
        Write-Host "   Extracted EXE Path: $exePath" -ForegroundColor Gray
        
        if ($exePath -and (Test-Path $exePath)) {
            Write-Host "   ✓ Executable exists" -ForegroundColor Green
            $fileInfo = Get-Item $exePath
            Write-Host "   FileVersion: $($fileInfo.VersionInfo.FileVersion)" -ForegroundColor Gray
            Write-Host "   ProductVersion: $($fileInfo.VersionInfo.ProductVersion)" -ForegroundColor Gray
            if ($fileInfo.VersionInfo.FileVersion) {
                Write-Host "   ✓ Version found: $($fileInfo.VersionInfo.FileVersion)" -ForegroundColor Green
            } elseif ($fileInfo.VersionInfo.ProductVersion) {
                Write-Host "   ✓ Version found (ProductVersion): $($fileInfo.VersionInfo.ProductVersion)" -ForegroundColor Green
            } else {
                Write-Host "   ✗ No version info in executable" -ForegroundColor Red
            }
        } else {
            Write-Host "   ✗ Executable not found at extracted path" -ForegroundColor Red
        }
    } else {
        Write-Host "   ✗ Could not get service PathName" -ForegroundColor Red
    }
} else {
    Write-Host "   ✗ Service not found" -ForegroundColor Red
}

Write-Host ""

# Check registry
Write-Host "2. Checking registry..." -ForegroundColor Yellow
$regPaths = @(
    "HKLM:\SOFTWARE\Duo Security\Authentication Proxy",
    "HKLM:\SOFTWARE\WOW6432Node\Duo Security\Authentication Proxy"
)

$regFound = $false
foreach ($regPath in $regPaths) {
    if (Test-Path $regPath) {
        Write-Host "   ✓ Registry path found: $regPath" -ForegroundColor Green
        $regFound = $true
        try {
            $regProps = Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue
            Write-Host "   Version: $($regProps.Version)" -ForegroundColor Gray
            Write-Host "   DisplayVersion: $($regProps.DisplayVersion)" -ForegroundColor Gray
            Write-Host "   InstallPath: $($regProps.InstallPath)" -ForegroundColor Gray
            if ($regProps.Version) {
                Write-Host "   ✓ Version found in registry: $($regProps.Version)" -ForegroundColor Green
            } elseif ($regProps.DisplayVersion) {
                Write-Host "   ✓ Version found (DisplayVersion): $($regProps.DisplayVersion)" -ForegroundColor Green
            }
        } catch {
            Write-Host "   ✗ Error reading registry: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}
if (-not $regFound) {
    Write-Host "   ✗ No registry entries found" -ForegroundColor Red
}

Write-Host ""

# Check standard executable paths
Write-Host "3. Checking standard executable paths..." -ForegroundColor Yellow
$exePaths = @(
    "C:\Program Files\Duo Security Authentication Proxy\DuoAuthenticationProxyManager.exe",
    "C:\Program Files (x86)\Duo Security Authentication Proxy\DuoAuthenticationProxyManager.exe",
    "C:\Program Files\Duo Security Authentication Proxy\DuoAuthenticationProxy.exe",
    "C:\Program Files (x86)\Duo Security Authentication Proxy\DuoAuthenticationProxy.exe"
)

$exeFound = $false
foreach ($exePath in $exePaths) {
    if (Test-Path $exePath) {
        Write-Host "   ✓ Found: $exePath" -ForegroundColor Green
        $exeFound = $true
        try {
            $fileInfo = Get-Item $exePath
            Write-Host "      FileVersion: $($fileInfo.VersionInfo.FileVersion)" -ForegroundColor Gray
            Write-Host "      ProductVersion: $($fileInfo.VersionInfo.ProductVersion)" -ForegroundColor Gray
            if ($fileInfo.VersionInfo.FileVersion) {
                Write-Host "      ✓ Version: $($fileInfo.VersionInfo.FileVersion)" -ForegroundColor Green
            } elseif ($fileInfo.VersionInfo.ProductVersion) {
                Write-Host "      ✓ Version (ProductVersion): $($fileInfo.VersionInfo.ProductVersion)" -ForegroundColor Green
            }
        } catch {
            Write-Host "      ✗ Error reading file: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}
if (-not $exeFound) {
    Write-Host "   ✗ No executables found in standard paths" -ForegroundColor Red
}

Write-Host ""

# Check install directories
Write-Host "4. Checking install directories..." -ForegroundColor Yellow
$installPaths = @(
    "C:\Program Files\Duo Security Authentication Proxy",
    "C:\Program Files (x86)\Duo Security Authentication Proxy"
)

$dirFound = $false
foreach ($path in $installPaths) {
    if (Test-Path $path) {
        Write-Host "   ✓ Install directory found: $path" -ForegroundColor Green
        $dirFound = $true
    }
}
if (-not $dirFound) {
    Write-Host "   ✗ No install directories found" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== Diagnostic Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "If version was not detected, please share the output above." -ForegroundColor Yellow
