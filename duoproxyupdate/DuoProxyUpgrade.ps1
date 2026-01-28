# Duo Authentication Proxy Upgrade Helper
# PowerShell GUI Version - SentinelOne Safe
# Version: 1.0

#Requires -Version 5.1

# Configuration Paths
$ConfigPathOld = "C:\Program Files (x86)\Duo Security Authentication Proxy\conf"
$ConfigPathNew = "C:\Program Files\Duo Security Authentication Proxy\conf"
$ConfigFile = "authproxy.cfg"
$DesktopPath = [Environment]::GetFolderPath("Desktop")
$DuoDownloadsURL = "https://duo.com/docs/checksums"
$ProxyManagerExe = "C:\Program Files\Duo Security Authentication Proxy\DuoAuthenticationProxyManager.exe"

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

# Function: Open Duo Proxy Manager
function Open-ProxyManager {
    $paths = @(
        "C:\Program Files\Duo Security Authentication Proxy\DuoAuthenticationProxyManager.exe",
        "C:\Program Files (x86)\Duo Security Authentication Proxy\DuoAuthenticationProxyManager.exe"
    )
    
    $found = $false
    foreach ($path in $paths) {
        if (Test-Path $path) {
            Start-Process $path
            Show-Notification "Opening Duo Proxy Manager..."
            $found = $true
            break
        }
    }
    
    if (-not $found) {
        [System.Windows.Forms.MessageBox]::Show(
            "Duo Proxy Manager not found.`n`nTried:`n$($paths -join "`n")",
            "File Not Found",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        )
    }
}

# Function: Open Duo Downloads
function Open-DuoDownloads {
    Start-Process $DuoDownloadsURL
    Show-Notification "Opening Duo Downloads page..."
}

# Function: Backup Config File
function Backup-ConfigFile {
    # Try new path first (5.6.0+), then old path
    $configPath = $null
    
    if (Test-Path $ConfigPathNew) {
        $configPath = $ConfigPathNew
    } elseif (Test-Path $ConfigPathOld) {
        $configPath = $ConfigPathOld
    } else {
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

# Load Windows Forms
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create Main Form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Duo Proxy Upgrade Helper"
$form.Size = New-Object System.Drawing.Size(400, 500)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.MinimizeBox = $true
$form.TopMost = $true

# Title Label
$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = "Duo Authentication Proxy Upgrade Helper"
$titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$titleLabel.Location = New-Object System.Drawing.Point(10, 10)
$titleLabel.Size = New-Object System.Drawing.Size(370, 25)
$titleLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$form.Controls.Add($titleLabel)

# Status Label
$script:NotifyLabel = New-Object System.Windows.Forms.Label
$script:NotifyLabel.Text = "Ready"
$script:NotifyLabel.ForeColor = [System.Drawing.Color]::Gray
$script:NotifyLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$script:NotifyLabel.Location = New-Object System.Drawing.Point(10, 40)
$script:NotifyLabel.Size = New-Object System.Drawing.Size(370, 20)
$script:NotifyLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$form.Controls.Add($script:NotifyLabel)

# Notification Timer
$script:NotifyTimer = New-Object System.Windows.Forms.Timer
$script:NotifyTimer.Interval = 3000
$script:NotifyTimer.Add_Tick({ Clear-Notification })

# Buttons
$buttonY = 75
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

# Button 4: Open Duo Downloads
$btnDownloads = New-Object System.Windows.Forms.Button
$btnDownloads.Text = "F4: Open Duo Downloads Page"
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

# Info Label
$infoLabel = New-Object System.Windows.Forms.Label
$infoLabel.Text = "Click buttons above or use keyboard shortcuts`n(Requires form focus for F1-F6)"
$infoLabel.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$infoLabel.ForeColor = [System.Drawing.Color]::DarkGray
$infoLabel.Location = New-Object System.Drawing.Point(20, $buttonY + 10)
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
