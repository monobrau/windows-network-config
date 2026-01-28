# Duo Authentication Proxy Upgrade Helper
# PowerShell GUI Version - SentinelOne Safe
# Version: 1.2
# Compatible with PowerShell 5.1+
# Fixed: Point constructor compatibility for PowerShell 5.x
# Added: Ticket notes templates and Duo extension request button

#Requires -Version 5.1

# Ensure TLS 1.2 is enabled for PowerShell 5.x compatibility
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Configuration Paths
$ConfigPathOld = "C:\Program Files (x86)\Duo Security Authentication Proxy\conf"
$ConfigPathNew = "C:\Program Files\Duo Security Authentication Proxy\conf"
$ConfigFile = "authproxy.cfg"
$DesktopPath = [Environment]::GetFolderPath("Desktop")
$DuoDownloadsURL = "https://dl.duosecurity.com/DuoAccessGateway-2.1.1.msi"

# Centralized Path Arrays (to avoid duplication)
$ProxyManagerPaths = @(
    "C:\Program Files\Duo Security Authentication Proxy\bin\local_proxy_manager-win32-x64\Duo_Authentication_Proxy_Manager.exe",
    "C:\Program Files (x86)\Duo Security Authentication Proxy\bin\local_proxy_manager-win32-x64\Duo_Authentication_Proxy_Manager.exe",
    "C:\Program Files\Duo Security Authentication Proxy\bin\Duo_Authentication_Proxy_Manager.exe",
    "C:\Program Files (x86)\Duo Security Authentication Proxy\bin\Duo_Authentication_Proxy_Manager.exe",
    "C:\Program Files\Duo Security Authentication Proxy\DuoAuthenticationProxyManager.exe",
    "C:\Program Files (x86)\Duo Security Authentication Proxy\DuoAuthenticationProxyManager.exe"
)

$ProxyExePaths = @(
    "C:\Program Files\Duo Security Authentication Proxy\bin\local_proxy_manager-win32-x64\Duo_Authentication_Proxy_Manager.exe",
    "C:\Program Files (x86)\Duo Security Authentication Proxy\bin\local_proxy_manager-win32-x64\Duo_Authentication_Proxy_Manager.exe",
    "C:\Program Files\Duo Security Authentication Proxy\bin\Duo_Authentication_Proxy_Manager.exe",
    "C:\Program Files (x86)\Duo Security Authentication Proxy\bin\Duo_Authentication_Proxy_Manager.exe",
    "C:\Program Files\Duo Security Authentication Proxy\DuoAuthenticationProxyManager.exe",
    "C:\Program Files (x86)\Duo Security Authentication Proxy\DuoAuthenticationProxyManager.exe",
    "C:\Program Files\Duo Security Authentication Proxy\DuoAuthenticationProxy.exe",
    "C:\Program Files (x86)\Duo Security Authentication Proxy\DuoAuthenticationProxy.exe"
)

$ConfigFilePaths = @(
    "C:\Program Files\Duo Security Authentication Proxy\conf\authproxy.cfg",
    "C:\Program Files (x86)\Duo Security Authentication Proxy\conf\authproxy.cfg"
)

$InstallPaths = @(
    "C:\Program Files\Duo Security Authentication Proxy",
    "C:\Program Files (x86)\Duo Security Authentication Proxy"
)

# Function: Open Config Path
function Open-ConfigPath {
    param([string]$Path, [string]$Label)
    
    if (Test-Path $Path) {
        Start-Process explorer.exe -ArgumentList "`"$Path`""
        Show-Notification "Opening $Label config path..."
    } else {
        [System.Windows.Forms.MessageBox]::Show(
            "$Label config path not found:`n$Path",
            "Path Not Found",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        )
    }
}

# Function: Get Active Config Path (helper to avoid duplication)
function Get-ActiveConfigPath {
    if (Test-Path $ConfigPathNew) {
        return $ConfigPathNew
    } elseif (Test-Path $ConfigPathOld) {
        return $ConfigPathOld
    }
    return $null
}

# Function: Open Duo Proxy Manager
function Open-ProxyManager {
    $found = $false
    foreach ($path in $ProxyManagerPaths) {
        # Resolve to absolute path first
        $resolvedPath = $null
        try {
            if (Test-Path $path) {
                $resolvedPath = (Resolve-Path $path -ErrorAction Stop).Path
            }
        } catch {
            continue
        }
        
        # Use System.IO.File.Exists for strict file-only checking (returns false for directories)
        if ($resolvedPath -and [System.IO.File]::Exists($resolvedPath)) {
            # Triple-check it's actually an .exe file and not a directory
            $item = Get-Item $resolvedPath -ErrorAction SilentlyContinue
            if ($item -and -not $item.PSIsContainer -and $item.Extension -eq ".exe" -and $item.Attributes -notmatch "Directory") {
                try {
                    Start-Process -FilePath $resolvedPath -ErrorAction Stop
                    Show-Notification "Opening Duo Proxy Manager..."
                    $found = $true
                    break
                } catch {
                    # If Start-Process fails, continue to next path
                    continue
                }
            }
        }
    }
    
    if (-not $found) {
        [System.Windows.Forms.MessageBox]::Show(
            "Duo Proxy Manager not found.`n`nTried:`n$($ProxyManagerPaths -join "`n")",
            "File Not Found",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        )
    }
}

# Function: Open Duo Downloads (Downloads Installer)
function Open-DuoDownloads {
    Start-Process $DuoDownloadsURL
    Show-Notification "Downloading Duo Proxy installer..."
}

# Function: Open Duo Extension Request Form
function Open-DuoExtensionRequest {
    $ExtensionRequestURL = "https://forms.office.com/Pages/ResponsePage.aspx?id=Yq_hWgWVl0CmmsFVPveEDmQIDgdgnLhBu69G_56G_x1UMDM1T0NUMVdYV0M1Rks0NVRHREtST0hEMC4u"
    Start-Process $ExtensionRequestURL
    Show-Notification "Opening Duo Extension Request form..."
}

# Function: Copy Config Line to Clipboard
function Copy-ConfigLineToClipboard {
    $configLine = "force_message_authenticator=true"
    Set-Clipboard -Value $configLine
    Show-Notification "Copied config line to clipboard: $configLine"
    [System.Console]::Beep(600, 150)
}

# Function: Backup Config File
function Backup-ConfigFile {
    # Use helper function to get active config path
    $configPath = Get-ActiveConfigPath
    
    if (-not $configPath) {
        [System.Windows.Forms.MessageBox]::Show(
            "Config directory not found in either location.`n`nOld: $ConfigPathOld`nNew: $ConfigPathNew",
            "Path Not Found",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        )
        return
    }
    
    $sourceFile = Join-Path $configPath $ConfigFile
    
    if (-not (Test-Path $sourceFile)) {
        [System.Windows.Forms.MessageBox]::Show(
            "Config file not found:`n$sourceFile",
            "File Not Found",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        )
        return
    }
    
    # Create backup filename with date
    $timestamp = Get-Date -Format "yyyyMMddHHmmss"
    $backupName = "authproxy_$timestamp.cfg"
    $backupPath = Join-Path $DesktopPath $backupName
    
    try {
        Copy-Item $sourceFile $backupPath -Force
        Show-Notification "Config backed up to:`n$backupPath"
        [System.Console]::Beep(800, 200)
    } catch {
        [System.Windows.Forms.MessageBox]::Show(
            "Error backing up config:`n$($_.Exception.Message)",
            "Backup Failed",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    }
}

# Function: Open Both Config Paths
function Open-BothConfigPaths {
    $opened = 0
    
    if (Test-Path $ConfigPathOld) {
        Start-Process explorer.exe -ArgumentList "`"$ConfigPathOld`""
        $opened++
    }
    
    if (Test-Path $ConfigPathNew) {
        Start-Process explorer.exe -ArgumentList "`"$ConfigPathNew`""
        $opened++
    }
    
    if ($opened -eq 0) {
        [System.Windows.Forms.MessageBox]::Show(
            "Neither config path found.`n`nOld: $ConfigPathOld`nNew: $ConfigPathNew",
            "Paths Not Found",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        )
    } else {
        Show-Notification "Opened $opened config path(s)..."
    }
}

# Function: Show Notification
function Show-Notification {
    param([string]$Message)
    
    if ($script:NotifyLabel) {
        $script:NotifyLabel.Text = $Message
        $script:NotifyLabel.ForeColor = [System.Drawing.Color]::DarkGreen
        $script:NotifyTimer.Stop()
        $script:NotifyTimer.Start()
    }
}

# Function: Clear Notification
function Clear-Notification {
    if ($script:NotifyLabel) {
        $script:NotifyLabel.Text = "Ready"
        $script:NotifyLabel.ForeColor = [System.Drawing.Color]::Gray
    }
}

# Function: Detect Duo Proxy Installation and Version
function Get-DuoProxyInfo {
    $proxyInfo = @{
        IsInstalled = $false
        Version = $null
        InstallPath = $null
        ServiceStatus = $null
    }
    
    # Check if service exists
    try {
        $service = Get-Service -Name "DuoAuthenticationProxy" -ErrorAction SilentlyContinue
        if ($service) {
            $proxyInfo.IsInstalled = $true
            $proxyInfo.ServiceStatus = $service.Status.ToString()
        }
    } catch {}
    
    # Try to get version from registry
    $regPaths = @(
        "HKLM:\SOFTWARE\Duo Security\Authentication Proxy",
        "HKLM:\SOFTWARE\WOW6432Node\Duo Security\Authentication Proxy"
    )
    
    foreach ($regPath in $regPaths) {
        if (Test-Path $regPath) {
            try {
                $regProps = Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue
                if ($regProps.Version) {
                    $proxyInfo.Version = $regProps.Version
                    if ($regProps.InstallPath) {
                        $proxyInfo.InstallPath = $regProps.InstallPath
                    }
                    break
                }
                if ($regProps.DisplayVersion) {
                    $proxyInfo.Version = $regProps.DisplayVersion
                    if ($regProps.InstallPath) {
                        $proxyInfo.InstallPath = $regProps.InstallPath
                    }
                    break
                }
            } catch {}
        }
    }
    
    # If not in registry, try service executable first (most reliable)
    # Note: Service was already checked above, so reuse $service variable if available
    if (-not $proxyInfo.Version -and $service) {
        try {
            $serviceObj = Get-WmiObject Win32_Service -Filter "Name='DuoAuthenticationProxy'" -ErrorAction SilentlyContinue
            if ($serviceObj -and $serviceObj.PathName) {
                $servicePath = $serviceObj.PathName
                # Extract executable path (handle quoted and unquoted paths, with or without arguments)
                if ($servicePath -match '^"([^"]+)"') {
                    $exePath = $matches[1]
                } elseif ($servicePath -match '^([^\s]+\.exe)') {
                    $exePath = $matches[1]
                } else {
                    # Try splitting by space and taking first part
                    $exePath = ($servicePath -split '\s+')[0]
                }
                
                if ($exePath -and (Test-Path $exePath)) {
                    try {
                        $fileInfo = Get-Item $exePath
                        if ($fileInfo.VersionInfo.FileVersion) {
                            $proxyInfo.Version = $fileInfo.VersionInfo.FileVersion
                            $proxyInfo.InstallPath = Split-Path $exePath -Parent
                            $proxyInfo.IsInstalled = $true
                        } elseif ($fileInfo.VersionInfo.ProductVersion) {
                            $proxyInfo.Version = $fileInfo.VersionInfo.ProductVersion
                            $proxyInfo.InstallPath = Split-Path $exePath -Parent
                            $proxyInfo.IsInstalled = $true
                        }
                    } catch {}
                }
            }
        } catch {}
    }
    
    # If still not found, try standard executable file versions
    if (-not $proxyInfo.Version) {
        foreach ($exePath in $ProxyExePaths) {
            if (Test-Path $exePath) {
                try {
                    $fileInfo = Get-Item $exePath
                    # Try FileVersion first
                    if ($fileInfo.VersionInfo.FileVersion) {
                        $proxyInfo.Version = $fileInfo.VersionInfo.FileVersion
                        $proxyInfo.InstallPath = Split-Path $exePath -Parent
                        $proxyInfo.IsInstalled = $true
                        break
                    }
                    # Try ProductVersion as fallback
                    if (-not $proxyInfo.Version -and $fileInfo.VersionInfo.ProductVersion) {
                        $proxyInfo.Version = $fileInfo.VersionInfo.ProductVersion
                        $proxyInfo.InstallPath = Split-Path $exePath -Parent
                        $proxyInfo.IsInstalled = $true
                        break
                    }
                } catch {}
            }
        }
    }
    
    # Try reading version from config file if still not found
    if (-not $proxyInfo.Version) {
        foreach ($configPath in $ConfigFilePaths) {
            if (Test-Path $configPath) {
                try {
                    $configContent = Get-Content $configPath -Raw
                    # Look for version in config file comments or metadata
                    if ($configContent -match 'version["\s:=]+([0-9]+\.[0-9]+\.[0-9]+)') {
                        $proxyInfo.Version = $matches[1]
                        break
                    }
                } catch {}
            }
        }
    }
    
    # Check install paths to determine if installed
    if (-not $proxyInfo.IsInstalled) {
        foreach ($path in $InstallPaths) {
            if (Test-Path $path) {
                $proxyInfo.IsInstalled = $true
                $proxyInfo.InstallPath = $path
                break
            }
        }
    }
    
    return $proxyInfo
}

# Function: Get Environment Information
function Get-EnvironmentInfo {
    $info = @{}
    
    # Server name
    $info.ServerName = $env:COMPUTERNAME
    
    # OS Version (use WMI for PowerShell 5.x compatibility)
    try {
        $os = Get-WmiObject Win32_OperatingSystem -ErrorAction SilentlyContinue
        if ($os) {
            $info.OSVersion = "$($os.Caption) Build $($os.BuildNumber)"
        } else {
            $info.OSVersion = "Unknown"
        }
    } catch {
        $info.OSVersion = "Unknown"
    }
    
    # Get Duo Proxy info using dedicated function
    $proxyInfo = Get-DuoProxyInfo
    if ($proxyInfo.Version) {
        $info.DuoProxyVersion = $proxyInfo.Version
    } elseif ($proxyInfo.IsInstalled) {
        $info.DuoProxyVersion = "Version unknown"
    } else {
        $info.DuoProxyVersion = "Not installed"
    }
    $info.DuoProxyInstalled = $proxyInfo.IsInstalled
    
    # Determine which config path is in use (use helper function)
    $info.ConfigPath = Get-ActiveConfigPath
    
    # Config file path
    if ($info.ConfigPath) {
        $info.ConfigFilePath = Join-Path $info.ConfigPath $ConfigFile
    } else {
        $info.ConfigFilePath = "Not found"
    }
    
    # Desktop path
    $info.DesktopPath = $DesktopPath
    
    # Current date/time
    $info.CurrentDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $info.CurrentDateShort = Get-Date -Format "yyyy-MM-dd"
    
    return $info
}

# Function: Get Ticket Notes Template
function Get-TicketNotesTemplate {
    param([string]$TemplateName)
    
    # Use temp folder for ticket notes (works when script is executed from memory)
    $notesFile = Join-Path $env:TEMP "DuoProxyUpgrade_TICKET_NOTES.txt"
    
    # Always try to download from GitHub first (ensures latest version)
    try {
        $url = "https://raw.githubusercontent.com/monobrau/windows-network-config/main/duoproxyupdate/TICKET_NOTES.txt"
        $content = (Invoke-WebRequest -Uri $url -UseBasicParsing).Content
        $content | Out-File -FilePath $notesFile -Encoding UTF8 -Force
    } catch {
        # If download fails and file doesn't exist, return null
        if (-not (Test-Path $notesFile)) {
            return $null
        }
    }
    
    if (-not (Test-Path $notesFile)) {
        return $null
    }
    
    $content = Get-Content $notesFile -Raw
    $lines = $content -split "`r?`n"
    
    $result = @()
    $foundHeader = $false
    
    foreach ($line in $lines) {
        # Look for the template header
        if ($line -match $TemplateName -and -not $foundHeader) {
            $foundHeader = $true
            continue
        }
        
        # Start collecting after finding the header
        if ($foundHeader) {
            # Stop at next separator line
            if ($line -match "^═══════════════════════════════════════════════════════════════") {
                if ($result.Count -gt 0) {
                    break
                }
            } else {
                # Preserve empty lines and all content
                $result += $line
            }
        }
    }
    
    if ($result.Count -gt 0) {
        # Join with proper line breaks (Windows uses CRLF)
        $template = ($result -join "`r`n").Trim()
        
        # Populate template with environment information
        $envInfo = Get-EnvironmentInfo
        $template = $template -replace '\{SERVER_NAME\}', $envInfo.ServerName
        $template = $template -replace '\{OS_VERSION\}', $envInfo.OSVersion
        $template = $template -replace '\{DUO_PROXY_VERSION\}', $envInfo.DuoProxyVersion
        $template = $template -replace '\{CONFIG_PATH\}', $(if ($envInfo.ConfigPath) { $envInfo.ConfigPath } else { "Not found" })
        $template = $template -replace '\{CONFIG_FILE_PATH\}', $envInfo.ConfigFilePath
        $template = $template -replace '\{DESKTOP_PATH\}', $envInfo.DesktopPath
        $template = $template -replace '\{CURRENT_DATE\}', $envInfo.CurrentDate
        $template = $template -replace '\{CURRENT_DATE_SHORT\}', $envInfo.CurrentDateShort
        
        return $template
    }
    
    return $null
}

# Function: Copy Ticket Notes to Clipboard
function Copy-TicketNotesToClipboard {
    param([string]$TemplateName)
    
    $template = Get-TicketNotesTemplate -TemplateName $TemplateName
    if ($template) {
        Set-Clipboard -Value $template
        Show-Notification "Copied $TemplateName template to clipboard"
        [System.Console]::Beep(600, 150)
    } else {
        [System.Windows.Forms.MessageBox]::Show(
            "Could not load $TemplateName template.`n`nMake sure TICKET_NOTES.txt is in the same folder as this script.",
            "Template Not Found",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        )
    }
}

# Function: Show Ticket Notes in Popup
function Show-TicketNotesPopup {
    param([string]$TemplateName)
    
    $template = Get-TicketNotesTemplate -TemplateName $TemplateName
    if ($template) {
        $popupForm = New-Object System.Windows.Forms.Form
        $popupForm.Text = "Ticket Notes - $TemplateName"
        $popupForm.Size = New-Object System.Drawing.Size(600, 500)
        $popupForm.StartPosition = "CenterScreen"
        $popupForm.FormBorderStyle = "FixedDialog"
        $popupForm.MaximizeBox = $false
        
        $textBox = New-Object System.Windows.Forms.TextBox
        $textBox.Multiline = $true
        $textBox.ReadOnly = $true
        $textBox.ScrollBars = "Vertical"
        $textBox.Font = New-Object System.Drawing.Font("Consolas", 9)
        $textBox.WordWrap = $true
        $textBox.AcceptsReturn = $true
        $textBox.AcceptsTab = $false
        # Ensure line breaks are preserved
        $textBox.Text = $template -replace "`r`n", "`r`n" -replace "`n", "`r`n"
        $textBox.Dock = [System.Windows.Forms.DockStyle]::Fill
        $popupForm.Controls.Add($textBox)
        
        $copyBtn = New-Object System.Windows.Forms.Button
        $copyBtn.Text = "Copy to Clipboard"
        $copyBtn.Dock = [System.Windows.Forms.DockStyle]::Bottom
        $copyBtn.Height = 35
        $copyBtn.Add_Click({
            Set-Clipboard -Value $template
            Show-Notification "Copied to clipboard"
            [System.Console]::Beep(600, 150)
        })
        $popupForm.Controls.Add($copyBtn)
        
        $popupForm.ShowDialog() | Out-Null
    } else {
        [System.Windows.Forms.MessageBox]::Show(
            "Could not load $TemplateName template.`n`nMake sure TICKET_NOTES.txt is in the same folder as this script.",
            "Template Not Found",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        )
    }
}

# Load Windows Forms
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create Main Form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Duo Proxy Upgrade Helper"
$form.Size = New-Object System.Drawing.Size(400, 885)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.MinimizeBox = $true
$form.TopMost = $true

# Detect Duo Proxy on startup
$startupProxyInfo = Get-DuoProxyInfo

# Title Label
$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = "Duo Authentication Proxy Upgrade Helper"
$titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$titleLabel.Location = New-Object System.Drawing.Point(10, 10)
$titleLabel.Size = New-Object System.Drawing.Size(370, 25)
$titleLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$form.Controls.Add($titleLabel)

# Proxy Detection Label
$proxyInfoLabel = New-Object System.Windows.Forms.Label
if ($startupProxyInfo.IsInstalled) {
    $versionText = if ($startupProxyInfo.Version) { "Version $($startupProxyInfo.Version)" } else { "Version unknown" }
    $statusText = if ($startupProxyInfo.ServiceStatus) { " - Service: $($startupProxyInfo.ServiceStatus)" } else { "" }
    $proxyInfoLabel.Text = "Detected: Duo Proxy installed - $versionText$statusText"
    $proxyInfoLabel.ForeColor = [System.Drawing.Color]::DarkGreen
} else {
    $proxyInfoLabel.Text = "Detected: Duo Proxy not found on this system"
    $proxyInfoLabel.ForeColor = [System.Drawing.Color]::DarkOrange
}
$proxyInfoLabel.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$proxyInfoLabel.Location = New-Object System.Drawing.Point(10, 40)
$proxyInfoLabel.Size = New-Object System.Drawing.Size(370, 18)
$proxyInfoLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$form.Controls.Add($proxyInfoLabel)

# Status Label
$script:NotifyLabel = New-Object System.Windows.Forms.Label
$script:NotifyLabel.Text = "Ready"
$script:NotifyLabel.ForeColor = [System.Drawing.Color]::Gray
$script:NotifyLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$script:NotifyLabel.Location = New-Object System.Drawing.Point(10, 62)
$script:NotifyLabel.Size = New-Object System.Drawing.Size(370, 20)
$script:NotifyLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$form.Controls.Add($script:NotifyLabel)

# Notification Timer
$script:NotifyTimer = New-Object System.Windows.Forms.Timer
$script:NotifyTimer.Interval = 3000
$script:NotifyTimer.Add_Tick({ Clear-Notification })

# Buttons
$buttonY = 90
$buttonHeight = 40
$buttonSpacing = 50

# Button 1: Open Old Config Path
$btnOldPath = New-Object System.Windows.Forms.Button
$btnOldPath.Text = "F1: Open Old Config Path (Pre 5.6.0)"
$btnOldPath.Location = New-Object System.Drawing.Point(20, $buttonY)
$btnOldPath.Size = New-Object System.Drawing.Size(360, $buttonHeight)
$btnOldPath.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$btnOldPath.Add_Click({ Open-ConfigPath -Path $ConfigPathOld -Label "Old" })
$form.Controls.Add($btnOldPath)
$buttonY += $buttonSpacing

# Button 2: Open New Config Path
$btnNewPath = New-Object System.Windows.Forms.Button
$btnNewPath.Text = "F2: Open New Config Path (5.6.0+)"
$btnNewPath.Location = New-Object System.Drawing.Point(20, $buttonY)
$btnNewPath.Size = New-Object System.Drawing.Size(360, $buttonHeight)
$btnNewPath.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$btnNewPath.Add_Click({ Open-ConfigPath -Path $ConfigPathNew -Label "New" })
$form.Controls.Add($btnNewPath)
$buttonY += $buttonSpacing

# Button 3: Open Proxy Manager
$btnProxyManager = New-Object System.Windows.Forms.Button
$btnProxyManager.Text = "F3: Open Duo Proxy Manager"
$btnProxyManager.Location = New-Object System.Drawing.Point(20, $buttonY)
$btnProxyManager.Size = New-Object System.Drawing.Size(360, $buttonHeight)
$btnProxyManager.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$btnProxyManager.Add_Click({ Open-ProxyManager })
$form.Controls.Add($btnProxyManager)
$buttonY += $buttonSpacing

# Button 4: Download Installer
$btnDownloads = New-Object System.Windows.Forms.Button
$btnDownloads.Text = "F4: Download Duo Proxy Installer"
$btnDownloads.Location = New-Object System.Drawing.Point(20, $buttonY)
$btnDownloads.Size = New-Object System.Drawing.Size(360, $buttonHeight)
$btnDownloads.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$btnDownloads.Add_Click({ Open-DuoDownloads })
$form.Controls.Add($btnDownloads)
$buttonY += $buttonSpacing

# Button 5: Backup Config
$btnBackup = New-Object System.Windows.Forms.Button
$btnBackup.Text = "F5: Backup Config File (Auto-detect)"
$btnBackup.Location = New-Object System.Drawing.Point(20, $buttonY)
$btnBackup.Size = New-Object System.Drawing.Size(360, $buttonHeight)
$btnBackup.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$btnBackup.BackColor = [System.Drawing.Color]::LightGreen
$btnBackup.Add_Click({ Backup-ConfigFile })
$form.Controls.Add($btnBackup)
$buttonY += $buttonSpacing

# Button 6: Open Both Paths
$btnBothPaths = New-Object System.Windows.Forms.Button
$btnBothPaths.Text = "F6: Open Both Config Paths"
$btnBothPaths.Location = New-Object System.Drawing.Point(20, $buttonY)
$btnBothPaths.Size = New-Object System.Drawing.Size(360, $buttonHeight)
$btnBothPaths.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$btnBothPaths.Add_Click({ Open-BothConfigPaths })
$form.Controls.Add($btnBothPaths)
$buttonY += $buttonSpacing

# Button 7: Request Duo Extension
$btnExtensionRequest = New-Object System.Windows.Forms.Button
$btnExtensionRequest.Text = "Request Duo Extension (If upgrade impossible)"
$btnExtensionRequest.Location = New-Object System.Drawing.Point(20, $buttonY)
$btnExtensionRequest.Size = New-Object System.Drawing.Size(360, $buttonHeight)
$btnExtensionRequest.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$btnExtensionRequest.BackColor = [System.Drawing.Color]::LightYellow
$btnExtensionRequest.Add_Click({ Open-DuoExtensionRequest })
$form.Controls.Add($btnExtensionRequest)
$buttonY += $buttonSpacing

# Button 8: Copy Config Line
$btnCopyConfig = New-Object System.Windows.Forms.Button
$btnCopyConfig.Text = "Copy Config: force_message_authenticator=true"
$btnCopyConfig.Location = New-Object System.Drawing.Point(20, $buttonY)
$btnCopyConfig.Size = New-Object System.Drawing.Size(360, $buttonHeight)
$btnCopyConfig.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$btnCopyConfig.BackColor = [System.Drawing.Color]::LightBlue
$btnCopyConfig.Add_Click({ Copy-ConfigLineToClipboard })
$form.Controls.Add($btnCopyConfig)
$buttonY += $buttonSpacing

# Separator Label
$separatorLabel = New-Object System.Windows.Forms.Label
$separatorLabel.Text = "----------------------------------------"
$separatorLabel.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$separatorLabel.ForeColor = [System.Drawing.Color]::DarkGray
$separatorLabelY = $buttonY + 5
$separatorLabel.Location = New-Object System.Drawing.Point(20, $separatorLabelY)
$separatorLabel.Size = New-Object System.Drawing.Size(360, 15)
$separatorLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$form.Controls.Add($separatorLabel)
$buttonY += 25

# Ticket Notes Section Label
$notesLabel = New-Object System.Windows.Forms.Label
$notesLabel.Text = "Ticket Notes Templates"
$notesLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$notesLabel.ForeColor = [System.Drawing.Color]::DarkBlue
$notesLabel.Location = New-Object System.Drawing.Point(20, $buttonY)
$notesLabel.Size = New-Object System.Drawing.Size(360, 20)
$notesLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$form.Controls.Add($notesLabel)
$buttonY += 25

# Ticket Notes Buttons (smaller buttons, side by side)
$smallButtonHeight = 30
$smallButtonSpacing = 35
$buttonWidth = 170

# Standard Template - Copy
$btnStandardCopy = New-Object System.Windows.Forms.Button
$btnStandardCopy.Text = "Standard: Copy"
$btnStandardCopy.Location = New-Object System.Drawing.Point(20, $buttonY)
$btnStandardCopy.Size = New-Object System.Drawing.Size($buttonWidth, $smallButtonHeight)
$btnStandardCopy.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$btnStandardCopy.Add_Click({ Copy-TicketNotesToClipboard -TemplateName "DUO PROXY UPGRADE - TICKET NOTES" })
$form.Controls.Add($btnStandardCopy)

# Standard Template - View
$btnStandardView = New-Object System.Windows.Forms.Button
$btnStandardView.Text = "Standard: View"
$btnStandardView.Location = New-Object System.Drawing.Point(210, $buttonY)
$btnStandardView.Size = New-Object System.Drawing.Size($buttonWidth, $smallButtonHeight)
$btnStandardView.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$btnStandardView.Add_Click({ Show-TicketNotesPopup -TemplateName "DUO PROXY UPGRADE - TICKET NOTES" })
$form.Controls.Add($btnStandardView)
$buttonY += $smallButtonSpacing

# Alternative Template - Copy
$btnAltCopy = New-Object System.Windows.Forms.Button
$btnAltCopy.Text = "Alternative: Copy"
$btnAltCopy.Location = New-Object System.Drawing.Point(20, $buttonY)
$btnAltCopy.Size = New-Object System.Drawing.Size($buttonWidth, $smallButtonHeight)
$btnAltCopy.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$btnAltCopy.Add_Click({ Copy-TicketNotesToClipboard -TemplateName "ALTERNATIVE VERSION" })
$form.Controls.Add($btnAltCopy)

# Alternative Template - View
$btnAltView = New-Object System.Windows.Forms.Button
$btnAltView.Text = "Alternative: View"
$btnAltView.Location = New-Object System.Drawing.Point(210, $buttonY)
$btnAltView.Size = New-Object System.Drawing.Size($buttonWidth, $smallButtonHeight)
$btnAltView.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$btnAltView.Add_Click({ Show-TicketNotesPopup -TemplateName "ALTERNATIVE VERSION" })
$form.Controls.Add($btnAltView)
$buttonY += $smallButtonSpacing

# Minimal Template - Copy
$btnMinimalCopy = New-Object System.Windows.Forms.Button
$btnMinimalCopy.Text = "Minimal: Copy"
$btnMinimalCopy.Location = New-Object System.Drawing.Point(20, $buttonY)
$btnMinimalCopy.Size = New-Object System.Drawing.Size($buttonWidth, $smallButtonHeight)
$btnMinimalCopy.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$btnMinimalCopy.Add_Click({ Copy-TicketNotesToClipboard -TemplateName "MINIMAL VERSION" })
$form.Controls.Add($btnMinimalCopy)

# Minimal Template - View
$btnMinimalView = New-Object System.Windows.Forms.Button
$btnMinimalView.Text = "Minimal: View"
$btnMinimalView.Location = New-Object System.Drawing.Point(210, $buttonY)
$btnMinimalView.Size = New-Object System.Drawing.Size($buttonWidth, $smallButtonHeight)
$btnMinimalView.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$btnMinimalView.Add_Click({ Show-TicketNotesPopup -TemplateName "MINIMAL VERSION" })
$form.Controls.Add($btnMinimalView)
$buttonY += $smallButtonSpacing

# Rollback Template - Copy
$btnRollbackCopy = New-Object System.Windows.Forms.Button
$btnRollbackCopy.Text = "Rollback: Copy"
$btnRollbackCopy.Location = New-Object System.Drawing.Point(20, $buttonY)
$btnRollbackCopy.Size = New-Object System.Drawing.Size($buttonWidth, $smallButtonHeight)
$btnRollbackCopy.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$btnRollbackCopy.Add_Click({ Copy-TicketNotesToClipboard -TemplateName "ROLLBACK VERSION" })
$form.Controls.Add($btnRollbackCopy)

# Rollback Template - View
$btnRollbackView = New-Object System.Windows.Forms.Button
$btnRollbackView.Text = "Rollback: View"
$btnRollbackView.Location = New-Object System.Drawing.Point(210, $buttonY)
$btnRollbackView.Size = New-Object System.Drawing.Size($buttonWidth, $smallButtonHeight)
$btnRollbackView.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$btnRollbackView.Add_Click({ Show-TicketNotesPopup -TemplateName "ROLLBACK VERSION" })
$form.Controls.Add($btnRollbackView)
$buttonY += $smallButtonSpacing

# Unsupported OS Template - Copy
$btnUnsupportedCopy = New-Object System.Windows.Forms.Button
$btnUnsupportedCopy.Text = "Unsupported OS: Copy"
$btnUnsupportedCopy.Location = New-Object System.Drawing.Point(20, $buttonY)
$btnUnsupportedCopy.Size = New-Object System.Drawing.Size($buttonWidth, $smallButtonHeight)
$btnUnsupportedCopy.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$btnUnsupportedCopy.BackColor = [System.Drawing.Color]::LightYellow
$btnUnsupportedCopy.Add_Click({ Copy-TicketNotesToClipboard -TemplateName "UNSUPPORTED OS VERSION" })
$form.Controls.Add($btnUnsupportedCopy)

# Unsupported OS Template - View
$btnUnsupportedView = New-Object System.Windows.Forms.Button
$btnUnsupportedView.Text = "Unsupported OS: View"
$btnUnsupportedView.Location = New-Object System.Drawing.Point(210, $buttonY)
$btnUnsupportedView.Size = New-Object System.Drawing.Size($buttonWidth, $smallButtonHeight)
$btnUnsupportedView.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$btnUnsupportedView.BackColor = [System.Drawing.Color]::LightYellow
$btnUnsupportedView.Add_Click({ Show-TicketNotesPopup -TemplateName "UNSUPPORTED OS VERSION" })
$form.Controls.Add($btnUnsupportedView)
$buttonY += $smallButtonSpacing

# Info Label
$infoLabel = New-Object System.Windows.Forms.Label
$infoLabel.Text = "Click buttons above or use keyboard shortcuts`n(Requires form focus for F1-F6 hotkeys)"
$infoLabel.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$infoLabel.ForeColor = [System.Drawing.Color]::DarkGray
$infoLabelY = $buttonY + 10
$infoLabel.Location = New-Object System.Drawing.Point(20, $infoLabelY)
$infoLabel.Size = New-Object System.Drawing.Size(360, 30)
$infoLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$form.Controls.Add($infoLabel)

# Keyboard Shortcuts
$form.Add_KeyDown({
    param($sender, $e)
    switch ($e.KeyCode) {
        "F1" { Open-ConfigPath -Path $ConfigPathOld -Label "Old"; $e.Handled = $true }
        "F2" { Open-ConfigPath -Path $ConfigPathNew -Label "New"; $e.Handled = $true }
        "F3" { Open-ProxyManager; $e.Handled = $true }
        "F4" { Open-DuoDownloads; $e.Handled = $true }
        "F5" { Backup-ConfigFile; $e.Handled = $true }
        "F6" { Open-BothConfigPaths; $e.Handled = $true }
    }
})
$form.KeyPreview = $true

# Show Form
[System.Windows.Forms.Application]::EnableVisualStyles()
$form.Add_Shown({ $form.Activate() })
[System.Windows.Forms.Application]::Run($form)
