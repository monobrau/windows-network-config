#requires -version 7.0
# Exchange Online Transport Rule Manager for MSPs
# Multi-tenant GUI tool for managing transport rules with focus on anti-spoofing and anti-spam
# Optimized for PowerShell 7+
# Author: MSP Admin Tool
# Date: September 2025

using namespace System.Windows.Forms
using namespace System.Drawing

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Import required modules
try {
    Import-Module ExchangeOnlineManagement -ErrorAction Stop
} catch {
    [System.Windows.Forms.MessageBox]::Show("ExchangeOnlineManagement module is required. Please install it using: Install-Module -Name ExchangeOnlineManagement", "Module Missing", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    exit
}

# Global variables
$global:CurrentTenant = $null
$global:ConnectedTenant = $null
$global:LogFile = "c:\dev\ExchangeTransportRuleManager\Logs\TransportRuleManager_$(Get-Date -Format 'yyyyMMdd').log"

# Ensure log directory exists
$logDir = Split-Path $global:LogFile -Parent
if (!(Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force
}

# Logging function
function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO",
        [string]$Tenant = $global:ConnectedTenant
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] [$Tenant] $Message"
    Add-Content -Path $global:LogFile -Value $logEntry
    Write-Host $logEntry
}

# Pre-built templates for anti-spoofing and anti-spam rules
$global:RuleTemplates = @{
    "Block External Spoofing - CEO" = @{
        Name = "Block External CEO Spoofing"
        Description = "Blocks external emails impersonating CEO display name"
        Conditions = @{
            FromScope = "NotInOrganization"
            SenderDisplayNameMatchesPatterns = @("*CEO*", "*Chief Executive*")
        }
        Actions = @{
            RejectMessageReasonText = "External email impersonating internal executive blocked"
        }
        PowerShellCode = @"
New-TransportRule -Name "Block External CEO Spoofing" ``
    -FromScope NotInOrganization ``
    -SenderDisplayNameMatchesPatterns "*CEO*","*Chief Executive*" ``
    -RejectMessageReasonText "External email impersonating internal executive blocked" ``
    -Comments "Blocks external emails attempting to impersonate CEO"
"@
    }
    
    "Block Domain Spoofing" = @{
        Name = "Block Domain Spoofing"
        Description = "Blocks external emails using internal domain"
        Conditions = @{
            FromScope = "NotInOrganization"
            SenderDomainIs = "@YOURDOMAIN.COM"
        }
        Actions = @{
            RejectMessageReasonText = "External email using internal domain blocked"
        }
        PowerShellCode = @"
New-TransportRule -Name "Block Domain Spoofing" ``
    -FromScope NotInOrganization ``
    -SenderDomainIs "@YOURDOMAIN.COM" ``
    -RejectMessageReasonText "External email using internal domain blocked" ``
    -Comments "Blocks external emails spoofing internal domain"
"@
    }
    
    "Quarantine Suspicious Attachments" = @{
        Name = "Quarantine Suspicious Attachments"
        Description = "Quarantines emails with potentially dangerous attachments"
        Conditions = @{
            AttachmentExtensionMatchesWords = @("exe", "scr", "bat", "cmd", "pif", "vbs", "js")
        }
        Actions = @{
            Quarantine = $true
        }
        PowerShellCode = @"
New-TransportRule -Name "Quarantine Suspicious Attachments" ``
    -AttachmentExtensionMatchesWords "exe","scr","bat","cmd","pif","vbs","js" ``
    -Quarantine $true ``
    -Comments "Quarantines emails with potentially dangerous file extensions"
"@
    }
    
    "External Warning Banner" = @{
        Name = "External Email Warning"
        Description = "Adds warning banner to external emails"
        Conditions = @{
            FromScope = "NotInOrganization"
        }
        Actions = @{
            PrependSubject = "[EXTERNAL] "
            ApplyHtmlDisclaimerText = "<div style='background-color:#ffeb9c;border:1px solid #9c6500;color:#9c6500;padding:10px;margin:10px 0;'><strong>CAUTION:</strong> This email originated from outside the organization. Do not click links or open attachments unless you recognize the sender and know the content is safe.</div>"
        }
        PowerShellCode = @"
New-TransportRule -Name "External Email Warning" ``
    -FromScope NotInOrganization ``
    -PrependSubject "[EXTERNAL] " ``
    -ApplyHtmlDisclaimerText "<div style='background-color:#ffeb9c;border:1px solid #9c6500;color:#9c6500;padding:10px;margin:10px 0;'><strong>CAUTION:</strong> This email originated from outside the organization. Do not click links or open attachments unless you recognize the sender and know the content is safe.</div>" ``
    -ApplyHtmlDisclaimerLocation Prepend ``
    -Comments "Adds external email warning banner"
"@
    }
}

# Create main form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Exchange Transport Rule Manager - MSP Edition"
$form.Size = New-Object System.Drawing.Size(1200, 800)
$form.StartPosition = "CenterScreen"
$form.MaximizeBox = $true
$form.FormBorderStyle = "Sizable"

# Create menu strip
$menuStrip = New-Object System.Windows.Forms.MenuStrip
$form.MainMenuStrip = $menuStrip

# File menu
$fileMenu = New-Object System.Windows.Forms.ToolStripMenuItem
$fileMenu.Text = "&File"
$menuStrip.Items.Add($fileMenu) | Out-Null

$connectMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
$connectMenuItem.Text = "&Connect to Tenant"
$connectMenuItem.Add_Click({
    Connect-ToTenant
})
$fileMenu.DropDownItems.Add($connectMenuItem) | Out-Null

$disconnectMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
$disconnectMenuItem.Text = "&Disconnect"
$disconnectMenuItem.Add_Click({
    Disconnect-FromTenant
})
$fileMenu.DropDownItems.Add($disconnectMenuItem) | Out-Null

$fileMenu.DropDownItems.Add("-") | Out-Null

$exitMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
$exitMenuItem.Text = "E&xit"
$exitMenuItem.Add_Click({
    $form.Close()
})
$fileMenu.DropDownItems.Add($exitMenuItem) | Out-Null

# Tools menu
$toolsMenu = New-Object System.Windows.Forms.ToolStripMenuItem
$toolsMenu.Text = "&Tools"
$menuStrip.Items.Add($toolsMenu) | Out-Null

$refreshMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
$refreshMenuItem.Text = "&Refresh Rules"
$refreshMenuItem.Add_Click({
    Refresh-TransportRules
})
$toolsMenu.DropDownItems.Add($refreshMenuItem) | Out-Null

$form.Controls.Add($menuStrip)

# Status bar
$statusStrip = New-Object System.Windows.Forms.StatusStrip
$statusLabel = New-Object System.Windows.Forms.ToolStripStatusLabel
$statusLabel.Text = "Not Connected"
$statusStrip.Items.Add($statusLabel) | Out-Null
$form.Controls.Add($statusStrip)

# Main panel
$mainPanel = New-Object System.Windows.Forms.Panel
$mainPanel.Dock = "Fill"
$mainPanel.Padding = New-Object System.Windows.Forms.Padding(10)
$form.Controls.Add($mainPanel)

# Connection panel
$connectionPanel = New-Object GroupBox
$connectionPanel.Text = "Microsoft 365 Connection"
$connectionPanel.Size = New-Object Size(1160, 60)
$connectionPanel.Location = New-Object Point(10, 10)
$mainPanel.Controls.Add($connectionPanel)

$connectButton = New-Object Button
$connectButton.Text = "Connect to Microsoft 365"
$connectButton.Location = New-Object Point(20, 25)
$connectButton.Size = New-Object Size(150, 25)
$connectButton.Add_Click({
    Connect-ToTenant
})
$connectionPanel.Controls.Add($connectButton)

$disconnectButton = New-Object Button
$disconnectButton.Text = "Disconnect"
$disconnectButton.Location = New-Object Point(180, 25)
$disconnectButton.Size = New-Object Size(80, 25)
$disconnectButton.Enabled = $false
$disconnectButton.Add_Click({
    Disconnect-FromTenant
})
$connectionPanel.Controls.Add($disconnectButton)

$connectionStatusLabel = New-Object Label
$connectionStatusLabel.Text = "Status: Not Connected"
$connectionStatusLabel.Location = New-Object Point(280, 28)
$connectionStatusLabel.Size = New-Object Size(400, 20)
$connectionStatusLabel.ForeColor = [Color]::Red
$connectionPanel.Controls.Add($connectionStatusLabel)

# Tab control for main functionality
$tabControl = New-Object TabControl
$tabControl.Location = New-Object Point(10, 80)
$tabControl.Size = New-Object Size(1160, 640)
$mainPanel.Controls.Add($tabControl)

# Rules Management Tab
$rulesTab = New-Object System.Windows.Forms.TabPage
$rulesTab.Text = "Transport Rules"
$tabControl.TabPages.Add($rulesTab) | Out-Null

# Rules list
$rulesListView = New-Object System.Windows.Forms.ListView
$rulesListView.View = "Details"
$rulesListView.FullRowSelect = $true
$rulesListView.GridLines = $true
$rulesListView.Location = New-Object System.Drawing.Point(10, 50)
$rulesListView.Size = New-Object System.Drawing.Size(800, 400)

$rulesListView.Columns.Add("Name", 200) | Out-Null
$rulesListView.Columns.Add("State", 80) | Out-Null
$rulesListView.Columns.Add("Priority", 60) | Out-Null
$rulesListView.Columns.Add("Description", 300) | Out-Null
$rulesListView.Columns.Add("Comments", 200) | Out-Null

$rulesTab.Controls.Add($rulesListView)

# Rules management buttons
$refreshRulesButton = New-Object System.Windows.Forms.Button
$refreshRulesButton.Text = "Refresh Rules"
$refreshRulesButton.Location = New-Object System.Drawing.Point(10, 10)
$refreshRulesButton.Size = New-Object System.Drawing.Size(100, 30)
$refreshRulesButton.Add_Click({
    Refresh-TransportRules
})
$rulesTab.Controls.Add($refreshRulesButton)

$deleteRuleButton = New-Object System.Windows.Forms.Button
$deleteRuleButton.Text = "Delete Selected"
$deleteRuleButton.Location = New-Object System.Drawing.Point(120, 10)
$deleteRuleButton.Size = New-Object System.Drawing.Size(100, 30)
$deleteRuleButton.Add_Click({
    Delete-SelectedRule
})
$rulesTab.Controls.Add($deleteRuleButton)

$enableRuleButton = New-Object Button
$enableRuleButton.Text = "Enable/Disable"
$enableRuleButton.Location = New-Object Point(230, 10)
$enableRuleButton.Size = New-Object Size(100, 30)
$enableRuleButton.Add_Click({
    Toggle-RuleState
})
$rulesTab.Controls.Add($enableRuleButton)

$editRuleButton = New-Object Button
$editRuleButton.Text = "Edit Rule"
$editRuleButton.Location = New-Object Point(340, 10)
$editRuleButton.Size = New-Object Size(80, 30)
$editRuleButton.Add_Click({
    Edit-SelectedRule
})
$rulesTab.Controls.Add($editRuleButton)

# Rule details panel
$ruleDetailsPanel = New-Object System.Windows.Forms.GroupBox
$ruleDetailsPanel.Text = "Rule Details"
$ruleDetailsPanel.Location = New-Object System.Drawing.Point(820, 10)
$ruleDetailsPanel.Size = New-Object System.Drawing.Size(320, 440)
$rulesTab.Controls.Add($ruleDetailsPanel)

$ruleDetailsTextBox = New-Object System.Windows.Forms.TextBox
$ruleDetailsTextBox.Multiline = $true
$ruleDetailsTextBox.ScrollBars = "Vertical"
$ruleDetailsTextBox.ReadOnly = $true
$ruleDetailsTextBox.Location = New-Object System.Drawing.Point(10, 20)
$ruleDetailsTextBox.Size = New-Object System.Drawing.Size(300, 410)
$ruleDetailsPanel.Controls.Add($ruleDetailsTextBox)

# Templates Tab
$templatesTab = New-Object System.Windows.Forms.TabPage
$templatesTab.Text = "Rule Templates"
$tabControl.TabPages.Add($templatesTab) | Out-Null

# Template selection
$templateLabel = New-Object System.Windows.Forms.Label
$templateLabel.Text = "Select Template:"
$templateLabel.Location = New-Object System.Drawing.Point(10, 15)
$templateLabel.Size = New-Object System.Drawing.Size(100, 20)
$templatesTab.Controls.Add($templateLabel)

$templateComboBox = New-Object System.Windows.Forms.ComboBox
$templateComboBox.DropDownStyle = "DropDownList"
$templateComboBox.Location = New-Object System.Drawing.Point(120, 13)
$templateComboBox.Size = New-Object System.Drawing.Size(300, 20)
foreach ($template in $global:RuleTemplates.Keys) {
    $templateComboBox.Items.Add($template) | Out-Null
}
$templateComboBox.Add_SelectedIndexChanged({
    Show-TemplateDetails
})
$templatesTab.Controls.Add($templateComboBox)

$deployTemplateButton = New-Object System.Windows.Forms.Button
$deployTemplateButton.Text = "Deploy Template"
$deployTemplateButton.Location = New-Object System.Drawing.Point(430, 11)
$deployTemplateButton.Size = New-Object System.Drawing.Size(120, 25)
$deployTemplateButton.Add_Click({
    Deploy-Template
})
$templatesTab.Controls.Add($deployTemplateButton)

# Template details
$templateDetailsPanel = New-Object System.Windows.Forms.GroupBox
$templateDetailsPanel.Text = "Template Details"
$templateDetailsPanel.Location = New-Object System.Drawing.Point(10, 50)
$templateDetailsPanel.Size = New-Object System.Drawing.Size(560, 300)
$templatesTab.Controls.Add($templateDetailsPanel)

$templateDetailsTextBox = New-Object System.Windows.Forms.TextBox
$templateDetailsTextBox.Multiline = $true
$templateDetailsTextBox.ScrollBars = "Vertical"
$templateDetailsTextBox.ReadOnly = $true
$templateDetailsTextBox.Location = New-Object System.Drawing.Point(10, 20)
$templateDetailsTextBox.Size = New-Object System.Drawing.Size(540, 270)
$templateDetailsPanel.Controls.Add($templateDetailsTextBox)

# Template PowerShell code
$templateCodePanel = New-Object System.Windows.Forms.GroupBox
$templateCodePanel.Text = "PowerShell Code (Editable)"
$templateCodePanel.Location = New-Object System.Drawing.Point(580, 50)
$templateCodePanel.Size = New-Object System.Drawing.Size(560, 300)
$templatesTab.Controls.Add($templateCodePanel)

$templateCodeTextBox = New-Object System.Windows.Forms.TextBox
$templateCodeTextBox.Multiline = $true
$templateCodeTextBox.ScrollBars = "Vertical"
$templateCodeTextBox.Location = New-Object System.Drawing.Point(10, 20)
$templateCodeTextBox.Size = New-Object System.Drawing.Size(540, 270)
$templateCodeTextBox.Font = New-Object System.Drawing.Font("Consolas", 9)
$templateCodePanel.Controls.Add($templateCodeTextBox)

# Custom PowerShell Tab
$customTab = New-Object System.Windows.Forms.TabPage
$customTab.Text = "Custom PowerShell"
$tabControl.TabPages.Add($customTab) | Out-Null

$customLabel = New-Object System.Windows.Forms.Label
$customLabel.Text = "Paste or type PowerShell commands for transport rule creation:"
$customLabel.Location = New-Object System.Drawing.Point(10, 10)
$customLabel.Size = New-Object System.Drawing.Size(400, 20)
$customTab.Controls.Add($customLabel)

$customCodeTextBox = New-Object System.Windows.Forms.TextBox
$customCodeTextBox.Multiline = $true
$customCodeTextBox.ScrollBars = "Both"
$customCodeTextBox.Location = New-Object System.Drawing.Point(10, 40)
$customCodeTextBox.Size = New-Object System.Drawing.Size(1130, 400)
$customCodeTextBox.Font = New-Object System.Drawing.Font("Consolas", 9)
$customTab.Controls.Add($customCodeTextBox)

$executeCustomButton = New-Object System.Windows.Forms.Button
$executeCustomButton.Text = "Execute PowerShell"
$executeCustomButton.Location = New-Object System.Drawing.Point(10, 450)
$executeCustomButton.Size = New-Object System.Drawing.Size(150, 30)
$executeCustomButton.Add_Click({
    Execute-CustomPowerShell
})
$customTab.Controls.Add($executeCustomButton)

$validateCustomButton = New-Object System.Windows.Forms.Button
$validateCustomButton.Text = "Validate Syntax"
$validateCustomButton.Location = New-Object System.Drawing.Point(170, 450)
$validateCustomButton.Size = New-Object System.Drawing.Size(120, 30)
$validateCustomButton.Add_Click({
    Validate-CustomPowerShell
})
$customTab.Controls.Add($validateCustomButton)

# Output area for custom PowerShell
$customOutputTextBox = New-Object System.Windows.Forms.TextBox
$customOutputTextBox.Multiline = $true
$customOutputTextBox.ScrollBars = "Both"
$customOutputTextBox.ReadOnly = $true
$customOutputTextBox.Location = New-Object System.Drawing.Point(10, 490)
$customOutputTextBox.Size = New-Object System.Drawing.Size(1130, 100)
$customOutputTextBox.Font = New-Object System.Drawing.Font("Consolas", 8)
$customTab.Controls.Add($customOutputTextBox)

# Message Trace Tab
$traceTab = New-Object TabPage
$traceTab.Text = "Message Trace"
$tabControl.TabPages.Add($traceTab) | Out-Null

# Date range selection
$dateRangePanel = New-Object GroupBox
$dateRangePanel.Text = "Date Range Selection"
$dateRangePanel.Location = New-Object Point(10, 10)
$dateRangePanel.Size = New-Object Size(1120, 80)
$traceTab.Controls.Add($dateRangePanel)

$startDateLabel = New-Object Label
$startDateLabel.Text = "Start Date:"
$startDateLabel.Location = New-Object Point(10, 25)
$startDateLabel.Size = New-Object Size(70, 20)
$dateRangePanel.Controls.Add($startDateLabel)

$startDatePicker = New-Object DateTimePicker
$startDatePicker.Location = New-Object Point(85, 23)
$startDatePicker.Size = New-Object Size(120, 20)
$startDatePicker.Value = (Get-Date).AddDays(-10)
$dateRangePanel.Controls.Add($startDatePicker)

$endDateLabel = New-Object Label
$endDateLabel.Text = "End Date:"
$endDateLabel.Location = New-Object Point(220, 25)
$endDateLabel.Size = New-Object Size(60, 20)
$dateRangePanel.Controls.Add($endDateLabel)

$endDatePicker = New-Object DateTimePicker
$endDatePicker.Location = New-Object Point(285, 23)
$endDatePicker.Size = New-Object Size(120, 20)
$endDatePicker.Value = Get-Date
$dateRangePanel.Controls.Add($endDatePicker)

# Domain filtering
$senderDomainLabel = New-Object Label
$senderDomainLabel.Text = "Sender Domain:"
$senderDomainLabel.Location = New-Object Point(420, 25)
$senderDomainLabel.Size = New-Object Size(90, 20)
$dateRangePanel.Controls.Add($senderDomainLabel)

$senderDomainTextBox = New-Object TextBox
$senderDomainTextBox.Location = New-Object Point(515, 23)
$senderDomainTextBox.Size = New-Object Size(150, 20)
$senderDomainTextBox.Text = "yourdomain.com"
$senderDomainTextBox.ForeColor = [Color]::Gray
$senderDomainTextBox.Add_GotFocus({
    if ($senderDomainTextBox.Text -eq "yourdomain.com") {
        $senderDomainTextBox.Text = ""
        $senderDomainTextBox.ForeColor = [Color]::Black
    }
})
$senderDomainTextBox.Add_LostFocus({
    if ([string]::IsNullOrWhiteSpace($senderDomainTextBox.Text)) {
        $senderDomainTextBox.Text = "yourdomain.com"
        $senderDomainTextBox.ForeColor = [Color]::Gray
    }
})
$dateRangePanel.Controls.Add($senderDomainTextBox)

$recipientDomainLabel = New-Object Label
$recipientDomainLabel.Text = "Recipient Domain:"
$recipientDomainLabel.Location = New-Object Point(680, 25)
$recipientDomainLabel.Size = New-Object Size(100, 20)
$dateRangePanel.Controls.Add($recipientDomainLabel)

$recipientDomainTextBox = New-Object TextBox
$recipientDomainTextBox.Location = New-Object Point(785, 23)
$recipientDomainTextBox.Size = New-Object Size(150, 20)
$recipientDomainTextBox.Text = "yourdomain.com"
$recipientDomainTextBox.ForeColor = [Color]::Gray
$recipientDomainTextBox.Add_GotFocus({
    if ($recipientDomainTextBox.Text -eq "yourdomain.com") {
        $recipientDomainTextBox.Text = ""
        $recipientDomainTextBox.ForeColor = [Color]::Black
    }
})
$recipientDomainTextBox.Add_LostFocus({
    if ([string]::IsNullOrWhiteSpace($recipientDomainTextBox.Text)) {
        $recipientDomainTextBox.Text = "yourdomain.com"
        $recipientDomainTextBox.ForeColor = [Color]::Gray
    }
})
$dateRangePanel.Controls.Add($recipientDomainTextBox)

# Search and export buttons
$searchTraceButton = New-Object Button
$searchTraceButton.Text = "Search Messages"
$searchTraceButton.Location = New-Object Point(950, 21)
$searchTraceButton.Size = New-Object Size(100, 25)
$searchTraceButton.Add_Click({
    Search-MessageTrace
})
$dateRangePanel.Controls.Add($searchTraceButton)

# Quick search buttons
$quickSearchPanel = New-Object GroupBox
$quickSearchPanel.Text = "Quick Searches (Anti-Spoofing Focus)"
$quickSearchPanel.Location = New-Object Point(10, 100)
$quickSearchPanel.Size = New-Object Size(1120, 60)
$traceTab.Controls.Add($quickSearchPanel)

$spoofingButton = New-Object Button
$spoofingButton.Text = "Find Domain Spoofing"
$spoofingButton.Location = New-Object Point(10, 25)
$spoofingButton.Size = New-Object Size(130, 25)
$spoofingButton.Add_Click({
    Search-DomainSpoofing
})
$quickSearchPanel.Controls.Add($spoofingButton)

$internalButton = New-Object Button
$internalButton.Text = "Internal to Internal"
$internalButton.Location = New-Object Point(150, 25)
$internalButton.Size = New-Object Size(120, 25)
$internalButton.Add_Click({
    Search-InternalToInternal
})
$quickSearchPanel.Controls.Add($internalButton)

# Domain selection for internal searches
$domainLabel = New-Object Label
$domainLabel.Text = "Domain:"
$domainLabel.Location = New-Object Point(540, 28)
$domainLabel.Size = New-Object Size(50, 20)
$quickSearchPanel.Controls.Add($domainLabel)

$domainComboBox = New-Object ComboBox
$domainComboBox.DropDownStyle = "DropDownList"
$domainComboBox.Location = New-Object Point(595, 26)
$domainComboBox.Size = New-Object Size(180, 20)
$domainComboBox.Items.Add("Auto-detect public domain") | Out-Null
$quickSearchPanel.Controls.Add($domainComboBox)

$suspiciousButton = New-Object Button
$suspiciousButton.Text = "Suspicious Patterns"
$suspiciousButton.Location = New-Object Point(280, 25)
$suspiciousButton.Size = New-Object Size(120, 25)
$suspiciousButton.Add_Click({
    Search-SuspiciousPatterns
})
$quickSearchPanel.Controls.Add($suspiciousButton)

$loadMoreButton = New-Object Button
$loadMoreButton.Text = "Load More Results"
$loadMoreButton.Location = New-Object Point(410, 25)
$loadMoreButton.Size = New-Object Size(120, 25)
$loadMoreButton.Enabled = $false
$loadMoreButton.Add_Click({
    Load-MoreResults
})
$quickSearchPanel.Controls.Add($loadMoreButton)

$exportCsvButton = New-Object Button
$exportCsvButton.Text = "Export to CSV"
$exportCsvButton.Location = New-Object Point(950, 25)
$exportCsvButton.Size = New-Object Size(100, 25)
$exportCsvButton.Enabled = $false
$exportCsvButton.Add_Click({
    Export-MessageTraceToCsv
})
$quickSearchPanel.Controls.Add($exportCsvButton)

# Results display
$traceResultsPanel = New-Object GroupBox
$traceResultsPanel.Text = "Message Trace Results"
$traceResultsPanel.Location = New-Object Point(10, 170)
$traceResultsPanel.Size = New-Object Size(1120, 400)
$traceTab.Controls.Add($traceResultsPanel)

$traceResultsListView = New-Object ListView
$traceResultsListView.View = "Details"
$traceResultsListView.FullRowSelect = $true
$traceResultsListView.GridLines = $true
$traceResultsListView.Location = New-Object Point(10, 20)
$traceResultsListView.Size = New-Object Size(1100, 370)

$traceResultsListView.Columns.Add("Date/Time", 130) | Out-Null
$traceResultsListView.Columns.Add("Sender", 200) | Out-Null
$traceResultsListView.Columns.Add("Recipient", 200) | Out-Null
$traceResultsListView.Columns.Add("Subject", 250) | Out-Null
$traceResultsListView.Columns.Add("Status", 80) | Out-Null
$traceResultsListView.Columns.Add("Size", 60) | Out-Null
$traceResultsListView.Columns.Add("Message ID", 180) | Out-Null

$traceResultsPanel.Controls.Add($traceResultsListView)

# Status label for trace operations
$traceStatusLabel = New-Object Label
$traceStatusLabel.Text = "Ready to search message traces"
$traceStatusLabel.Location = New-Object Point(20, 580)
$traceStatusLabel.Size = New-Object Size(600, 20)
$traceStatusLabel.ForeColor = [Color]::Blue
$traceTab.Controls.Add($traceStatusLabel)

# Global variables to store current trace results and search state
$global:CurrentTraceResults = @()
$global:CurrentSearchParams = @{}
$global:CurrentSearchType = ""
$global:HasMoreResults = $false
$global:NextPage = 1
$global:LastRecipientAddress = $null
$global:CurrentSearchDomains = @()

# Logs Tab
$logsTab = New-Object TabPage
$logsTab.Text = "Logs"
$tabControl.TabPages.Add($logsTab) | Out-Null

$logsTextBox = New-Object System.Windows.Forms.TextBox
$logsTextBox.Multiline = $true
$logsTextBox.ScrollBars = "Both"
$logsTextBox.ReadOnly = $true
$logsTextBox.Location = New-Object System.Drawing.Point(10, 40)
$logsTextBox.Size = New-Object System.Drawing.Size(1130, 540)
$logsTextBox.Font = New-Object System.Drawing.Font("Consolas", 8)
$logsTab.Controls.Add($logsTextBox)

$refreshLogsButton = New-Object System.Windows.Forms.Button
$refreshLogsButton.Text = "Refresh Logs"
$refreshLogsButton.Location = New-Object System.Drawing.Point(10, 10)
$refreshLogsButton.Size = New-Object System.Drawing.Size(100, 25)
$refreshLogsButton.Add_Click({
    Refresh-Logs
})
$logsTab.Controls.Add($refreshLogsButton)

$clearLogsButton = New-Object System.Windows.Forms.Button
$clearLogsButton.Text = "Clear Logs"
$clearLogsButton.Location = New-Object System.Drawing.Point(120, 10)
$clearLogsButton.Size = New-Object System.Drawing.Size(80, 25)
$clearLogsButton.Add_Click({
    Clear-Logs
})
$logsTab.Controls.Add($clearLogsButton)

# Event handlers for rules list
$rulesListView.Add_SelectedIndexChanged({
    Show-RuleDetails
})

# Functions
function Connect-ToTenant {
    try {
        Write-Log "Attempting to connect to Microsoft 365..."
        $connectionStatusLabel.Text = "Status: Opening browser for authentication..."
        $connectionStatusLabel.ForeColor = [Color]::Orange
        $form.Refresh()
        
        # Connect without specifying organization - let user choose in browser
        Connect-ExchangeOnline -ShowBanner:$false -UseRPSSession:$false
        
        # Get the connected tenant information
        $connectionInfo = Get-ConnectionInformation
        if ($connectionInfo) {
            $global:ConnectedTenant = $connectionInfo.TenantId
            $tenantName = $connectionInfo.Name ?? $connectionInfo.TenantId
            
            $connectionStatusLabel.Text = "Status: Connected to $tenantName"
            $connectionStatusLabel.ForeColor = [Color]::Green
            $statusLabel.Text = "Connected to: $tenantName"
            
            Write-Log "Successfully connected to tenant: $tenantName"
        } else {
            $global:ConnectedTenant = "Microsoft 365"
            $connectionStatusLabel.Text = "Status: Connected to Microsoft 365"
            $connectionStatusLabel.ForeColor = [Color]::Green
            $statusLabel.Text = "Connected to Microsoft 365"
            
            Write-Log "Successfully connected to Microsoft 365"
        }
        
        $connectButton.Enabled = $false
        $disconnectButton.Enabled = $true
        
        # Populate domain dropdown for internal searches
        Populate-DomainDropdown
        
        Refresh-TransportRules
        
    } catch {
        Write-Log "Failed to connect to Microsoft 365. Error: $($_.Exception.Message)" "ERROR"
        $connectionStatusLabel.Text = "Status: Connection Failed"
        $connectionStatusLabel.ForeColor = [Color]::Red
        
        # Reset UI state on connection failure
        $connectButton.Enabled = $true
        $disconnectButton.Enabled = $false
        
        [MessageBox]::Show("Failed to connect: $($_.Exception.Message)", "Connection Error", [MessageBoxButtons]::OK, [MessageBoxIcon]::Error)
    }
}

function Disconnect-FromTenant {
    try {
        Write-Log "Disconnecting from tenant: $global:ConnectedTenant"
        Disconnect-ExchangeOnline -Confirm:$false
        
        $global:ConnectedTenant = $null
        $connectionStatusLabel.Text = "Status: Not Connected"
        $connectionStatusLabel.ForeColor = [Color]::Red
        $statusLabel.Text = "Not Connected"
        
        $connectButton.Enabled = $true
        $disconnectButton.Enabled = $false
        
        $rulesListView.Items.Clear()
        $ruleDetailsTextBox.Clear()
        
        Write-Log "Successfully disconnected from tenant"
        
    } catch {
        Write-Log "Error during disconnect: $($_.Exception.Message)" "ERROR"
        [MessageBox]::Show("Error during disconnect: $($_.Exception.Message)", "Disconnect Error", [MessageBoxButtons]::OK, [MessageBoxIcon]::Warning)
    }
}

function Refresh-TransportRules {
    if ([string]::IsNullOrEmpty($global:ConnectedTenant)) {
        [MessageBox]::Show("Please connect to Microsoft 365 first.", "Not Connected", [MessageBoxButtons]::OK, [MessageBoxIcon]::Warning)
        return
    }
    
    try {
        Write-Log "Refreshing transport rules for tenant: $global:ConnectedTenant"
        $rulesListView.Items.Clear()
        
        $rules = Get-TransportRule | Sort-Object Priority
        
        foreach ($rule in $rules) {
            $ruleName = if ($rule.Name) { $rule.Name } else { "Unnamed Rule" }
            $ruleState = if ($rule.State) { $rule.State } else { "Unknown" }
            $rulePriority = if ($rule.Priority) { $rule.Priority.ToString() } else { "0" }
            $ruleDescription = if ($rule.Description) { $rule.Description } else { "" }
            $ruleComments = if ($rule.Comments) { $rule.Comments } else { "" }
            
            $item = New-Object ListViewItem($ruleName)
            $item.SubItems.Add($ruleState) | Out-Null
            $item.SubItems.Add($rulePriority) | Out-Null
            $item.SubItems.Add($ruleDescription) | Out-Null
            $item.SubItems.Add($ruleComments) | Out-Null
            $item.Tag = $rule
            $rulesListView.Items.Add($item) | Out-Null
        }
        
        Write-Log "Successfully refreshed $($rules.Count) transport rules"
        
    } catch {
        Write-Log "Failed to refresh transport rules: $($_.Exception.Message)" "ERROR"
        [MessageBox]::Show("Failed to refresh transport rules: $($_.Exception.Message)", "Refresh Error", [MessageBoxButtons]::OK, [MessageBoxIcon]::Error)
    }
}

function Show-RuleDetails {
    if ($rulesListView.SelectedItems.Count -eq 0) {
        $ruleDetailsTextBox.Clear()
        return
    }
    
    $selectedRule = $rulesListView.SelectedItems[0].Tag
    
    $details = @"
Name: $($selectedRule.Name)
State: $($selectedRule.State)
Priority: $($selectedRule.Priority)
Description: $($selectedRule.Description)
Comments: $($selectedRule.Comments)

Conditions:
$($selectedRule.Conditions | Out-String)

Actions:
$($selectedRule.Actions | Out-String)

Exceptions:
$($selectedRule.Exceptions | Out-String)
"@
    
    $ruleDetailsTextBox.Text = $details
}

function Delete-SelectedRule {
    if ($rulesListView.SelectedItems.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Please select a rule to delete.", "No Selection", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        return
    }
    
    $selectedRule = $rulesListView.SelectedItems[0].Tag
    $result = [System.Windows.Forms.MessageBox]::Show("Are you sure you want to delete the rule '$($selectedRule.Name)'?", "Confirm Deletion", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
    
    if ($result -eq "Yes") {
        try {
            Write-Log "Deleting transport rule: $($selectedRule.Name)"
            Remove-TransportRule -Identity $selectedRule.Name -Confirm:$false
            Write-Log "Successfully deleted transport rule: $($selectedRule.Name)"
            Refresh-TransportRules
        } catch {
            Write-Log "Failed to delete transport rule: $($selectedRule.Name). Error: $($_.Exception.Message)" "ERROR"
            [System.Windows.Forms.MessageBox]::Show("Failed to delete rule: $($_.Exception.Message)", "Delete Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    }
}

function Toggle-RuleState {
    if ($rulesListView.SelectedItems.Count -eq 0) {
        [MessageBox]::Show("Please select a rule to enable/disable.", "No Selection", [MessageBoxButtons]::OK, [MessageBoxIcon]::Information)
        return
    }
    
    $selectedRule = $rulesListView.SelectedItems[0].Tag
    $newState = if ($selectedRule.State -eq "Enabled") { "Disabled" } else { "Enabled" }
    
    try {
        Write-Log "Changing rule state: $($selectedRule.Name) from $($selectedRule.State) to $newState"
        Set-TransportRule -Identity $selectedRule.Name -Enabled ($newState -eq "Enabled")
        Write-Log "Successfully changed rule state: $($selectedRule.Name) to $newState"
        Refresh-TransportRules
    } catch {
        Write-Log "Failed to change rule state: $($selectedRule.Name). Error: $($_.Exception.Message)" "ERROR"
        [MessageBox]::Show("Failed to change rule state: $($_.Exception.Message)", "State Change Error", [MessageBoxButtons]::OK, [MessageBoxIcon]::Error)
    }
}

function Edit-SelectedRule {
    if ($rulesListView.SelectedItems.Count -eq 0) {
        [MessageBox]::Show("Please select a rule to edit.", "No Selection", [MessageBoxButtons]::OK, [MessageBoxIcon]::Information)
        return
    }
    
    $selectedRule = $rulesListView.SelectedItems[0].Tag
    Show-RuleEditor $selectedRule
}

function Show-RuleEditor {
    param($rule)
    
    # Create rule editor form
    $editorForm = New-Object Form
    $editorForm.Text = "Edit Transport Rule: $($rule.Name)"
    $editorForm.Size = New-Object Size(800, 600)
    $editorForm.StartPosition = "CenterParent"
    $editorForm.FormBorderStyle = "FixedDialog"
    $editorForm.MaximizeBox = $false
    $editorForm.MinimizeBox = $false
    
    # Create tab control for different sections
    $editorTabControl = New-Object TabControl
    $editorTabControl.Location = New-Object Point(10, 10)
    $editorTabControl.Size = New-Object Size(760, 500)
    $editorForm.Controls.Add($editorTabControl)
    
    # Basic Properties Tab
    $basicTab = New-Object TabPage
    $basicTab.Text = "Basic Properties"
    $editorTabControl.TabPages.Add($basicTab) | Out-Null
    
    # Rule Name
    $nameLabel = New-Object Label
    $nameLabel.Text = "Rule Name:"
    $nameLabel.Location = New-Object Point(10, 20)
    $nameLabel.Size = New-Object Size(100, 20)
    $basicTab.Controls.Add($nameLabel)
    
    $nameTextBox = New-Object TextBox
    $nameTextBox.Text = $rule.Name
    $nameTextBox.Location = New-Object Point(120, 18)
    $nameTextBox.Size = New-Object Size(300, 20)
    $basicTab.Controls.Add($nameTextBox)
    
    # Description
    $descLabel = New-Object Label
    $descLabel.Text = "Description:"
    $descLabel.Location = New-Object Point(10, 50)
    $descLabel.Size = New-Object Size(100, 20)
    $basicTab.Controls.Add($descLabel)
    
    $descTextBox = New-Object TextBox
    $descTextBox.Text = $rule.Description ?? ""
    $descTextBox.Location = New-Object Point(120, 48)
    $descTextBox.Size = New-Object Size(300, 20)
    $basicTab.Controls.Add($descTextBox)
    
    # Comments
    $commentsLabel = New-Object Label
    $commentsLabel.Text = "Comments:"
    $commentsLabel.Location = New-Object Point(10, 80)
    $commentsLabel.Size = New-Object Size(100, 20)
    $basicTab.Controls.Add($commentsLabel)
    
    $commentsTextBox = New-Object TextBox
    $commentsTextBox.Text = $rule.Comments ?? ""
    $commentsTextBox.Location = New-Object Point(120, 78)
    $commentsTextBox.Size = New-Object Size(300, 20)
    $basicTab.Controls.Add($commentsTextBox)
    
    # Priority
    $priorityLabel = New-Object Label
    $priorityLabel.Text = "Priority:"
    $priorityLabel.Location = New-Object Point(10, 110)
    $priorityLabel.Size = New-Object Size(100, 20)
    $basicTab.Controls.Add($priorityLabel)
    
    $priorityTextBox = New-Object TextBox
    $priorityTextBox.Text = $rule.Priority?.ToString() ?? "0"
    $priorityTextBox.Location = New-Object Point(120, 108)
    $priorityTextBox.Size = New-Object Size(100, 20)
    $basicTab.Controls.Add($priorityTextBox)
    
    # Enabled checkbox
    $enabledCheckBox = New-Object CheckBox
    $enabledCheckBox.Text = "Rule Enabled"
    $enabledCheckBox.Checked = ($rule.State -eq "Enabled")
    $enabledCheckBox.Location = New-Object Point(120, 140)
    $enabledCheckBox.Size = New-Object Size(150, 20)
    $basicTab.Controls.Add($enabledCheckBox)
    
    # PowerShell Code Tab
    $codeTab = New-Object TabPage
    $codeTab.Text = "PowerShell Code"
    $editorTabControl.TabPages.Add($codeTab) | Out-Null
    
    $codeLabel = New-Object Label
    $codeLabel.Text = "Generated PowerShell code for this rule (read-only):"
    $codeLabel.Location = New-Object Point(10, 10)
    $codeLabel.Size = New-Object Size(400, 20)
    $codeTab.Controls.Add($codeLabel)
    
    $codeTextBox = New-Object TextBox
    $codeTextBox.Multiline = $true
    $codeTextBox.ScrollBars = "Both"
    $codeTextBox.ReadOnly = $true
    $codeTextBox.Location = New-Object Point(10, 40)
    $codeTextBox.Size = New-Object Size(720, 400)
    $codeTextBox.Font = New-Object Font("Consolas", 9)
    $codeTab.Controls.Add($codeTextBox)
    
    # Generate PowerShell code for the current rule
    $codeTextBox.Text = Generate-RuleCode $rule
    
    # Conditions Tab
    $conditionsTab = New-Object TabPage
    $conditionsTab.Text = "Conditions"
    $editorTabControl.TabPages.Add($conditionsTab) | Out-Null
    
    $conditionsLabel = New-Object Label
    $conditionsLabel.Text = "Rule Conditions:"
    $conditionsLabel.Location = New-Object Point(10, 10)
    $conditionsLabel.Size = New-Object Size(200, 20)
    $conditionsTab.Controls.Add($conditionsLabel)
    
    $conditionsTextBox = New-Object TextBox
    $conditionsTextBox.Multiline = $true
    $conditionsTextBox.ScrollBars = "Both"
    $conditionsTextBox.ReadOnly = $true
    $conditionsTextBox.Location = New-Object Point(10, 40)
    $conditionsTextBox.Size = New-Object Size(720, 180)
    $conditionsTextBox.Text = ($rule.Conditions | Out-String)
    $conditionsTab.Controls.Add($conditionsTextBox)
    
    # Actions Tab
    $actionsTab = New-Object TabPage
    $actionsTab.Text = "Actions"
    $editorTabControl.TabPages.Add($actionsTab) | Out-Null
    
    $actionsLabel = New-Object Label
    $actionsLabel.Text = "Rule Actions:"
    $actionsLabel.Location = New-Object Point(10, 10)
    $actionsLabel.Size = New-Object Size(200, 20)
    $actionsTab.Controls.Add($actionsLabel)
    
    $actionsTextBox = New-Object TextBox
    $actionsTextBox.Multiline = $true
    $actionsTextBox.ScrollBars = "Both"
    $actionsTextBox.ReadOnly = $true
    $actionsTextBox.Location = New-Object Point(10, 40)
    $actionsTextBox.Size = New-Object Size(720, 180)
    $actionsTextBox.Text = ($rule.Actions | Out-String)
    $actionsTab.Controls.Add($actionsTextBox)
    
    # Buttons
    $saveButton = New-Object Button
    $saveButton.Text = "Save Changes"
    $saveButton.Location = New-Object Point(600, 520)
    $saveButton.Size = New-Object Size(100, 30)
    $saveButton.Add_Click({
        Save-RuleChanges $rule $nameTextBox.Text $descTextBox.Text $commentsTextBox.Text $priorityTextBox.Text $enabledCheckBox.Checked $editorForm
    })
    $editorForm.Controls.Add($saveButton)
    
    $cancelButton = New-Object Button
    $cancelButton.Text = "Cancel"
    $cancelButton.Location = New-Object Point(710, 520)
    $cancelButton.Size = New-Object Size(60, 30)
    $cancelButton.Add_Click({
        $editorForm.Close()
    })
    $editorForm.Controls.Add($cancelButton)
    
    # Show the dialog
    $editorForm.ShowDialog() | Out-Null
}

function Generate-RuleCode {
    param($rule)
    
    $code = @"
# PowerShell code to recreate this transport rule
Set-TransportRule -Identity "$($rule.Name)" ``
    -Name "$($rule.Name)" ``
    -Description "$($rule.Description ?? "")" ``
    -Comments "$($rule.Comments ?? "")" ``
    -Priority $($rule.Priority ?? 0) ``
    -Enabled `$$($rule.State -eq "Enabled" ? "true" : "false")

# Full rule details:
# Conditions: $($rule.Conditions | Out-String)
# Actions: $($rule.Actions | Out-String)
# Exceptions: $($rule.Exceptions | Out-String)
"@
    
    return $code
}

function Save-RuleChanges {
    param($originalRule, $newName, $newDescription, $newComments, $newPriority, $enabled, $form)
    
    try {
        Write-Log "Updating transport rule: $($originalRule.Name)"
        
        $parameters = @{
            Identity = $originalRule.Name
            Name = $newName
            Description = $newDescription
            Comments = $newComments
            Priority = [int]$newPriority
            Enabled = $enabled
        }
        
        Set-TransportRule @parameters
        
        Write-Log "Successfully updated transport rule: $newName"
        [MessageBox]::Show("Rule updated successfully!", "Success", [MessageBoxButtons]::OK, [MessageBoxIcon]::Information)
        
        $form.Close()
        Refresh-TransportRules
        
    } catch {
        Write-Log "Failed to update transport rule: $($originalRule.Name). Error: $($_.Exception.Message)" "ERROR"
        [MessageBox]::Show("Failed to update rule: $($_.Exception.Message)", "Update Error", [MessageBoxButtons]::OK, [MessageBoxIcon]::Error)
    }
}

function Show-TemplateDetails {
    if ($templateComboBox.SelectedItem -eq $null) {
        return
    }
    
    $selectedTemplate = $global:RuleTemplates[$templateComboBox.SelectedItem.ToString()]
    
    $details = @"
Name: $($selectedTemplate.Name)
Description: $($selectedTemplate.Description)

Conditions:
$($selectedTemplate.Conditions | Out-String)

Actions:
$($selectedTemplate.Actions | Out-String)
"@
    
    $templateDetailsTextBox.Text = $details
    $templateCodeTextBox.Text = $selectedTemplate.PowerShellCode
}

function Deploy-Template {
    if ($templateComboBox.SelectedItem -eq $null) {
        [System.Windows.Forms.MessageBox]::Show("Please select a template to deploy.", "No Selection", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        return
    }
    
    if ([string]::IsNullOrEmpty($global:ConnectedTenant)) {
        [System.Windows.Forms.MessageBox]::Show("Please connect to a tenant first.", "Not Connected", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        return
    }
    
    $templateName = $templateComboBox.SelectedItem.ToString()
    $code = $templateCodeTextBox.Text
    
    try {
        Write-Log "Deploying template: $templateName"
        $scriptBlock = [ScriptBlock]::Create($code)
        Invoke-Command -ScriptBlock $scriptBlock
        Write-Log "Successfully deployed template: $templateName"
        [System.Windows.Forms.MessageBox]::Show("Template deployed successfully!", "Success", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        Refresh-TransportRules
    } catch {
        Write-Log "Failed to deploy template: $templateName. Error: $($_.Exception.Message)" "ERROR"
        [System.Windows.Forms.MessageBox]::Show("Failed to deploy template: $($_.Exception.Message)", "Deployment Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

function Execute-CustomPowerShell {
    if ([string]::IsNullOrEmpty($global:ConnectedTenant)) {
        [System.Windows.Forms.MessageBox]::Show("Please connect to a tenant first.", "Not Connected", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        return
    }
    
    $code = $customCodeTextBox.Text.Trim()
    if ([string]::IsNullOrEmpty($code)) {
        [System.Windows.Forms.MessageBox]::Show("Please enter PowerShell code to execute.", "No Code", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        return
    }
    
    try {
        Write-Log "Executing custom PowerShell code"
        $customOutputTextBox.Text = "Executing..."
        $form.Refresh()
        
        $scriptBlock = [ScriptBlock]::Create($code)
        $output = Invoke-Command -ScriptBlock $scriptBlock | Out-String
        
        $customOutputTextBox.Text = "Execution completed successfully:`r`n`r`n$output"
        Write-Log "Successfully executed custom PowerShell code"
        Refresh-TransportRules
    } catch {
        $errorMsg = $_.Exception.Message
        $customOutputTextBox.Text = "Execution failed:`r`n`r`n$errorMsg"
        Write-Log "Failed to execute custom PowerShell code: $errorMsg" "ERROR"
    }
}

function Validate-CustomPowerShell {
    $code = $customCodeTextBox.Text.Trim()
    if ([string]::IsNullOrEmpty($code)) {
        [System.Windows.Forms.MessageBox]::Show("Please enter PowerShell code to validate.", "No Code", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        return
    }
    
    try {
        $scriptBlock = [ScriptBlock]::Create($code)
        $customOutputTextBox.Text = "Syntax validation passed. Code appears to be valid PowerShell."
        Write-Log "PowerShell syntax validation passed"
    } catch {
        $customOutputTextBox.Text = "Syntax validation failed:`r`n`r`n$($_.Exception.Message)"
        Write-Log "PowerShell syntax validation failed: $($_.Exception.Message)" "WARNING"
    }
}

function Refresh-Logs {
    if (Test-Path $global:LogFile) {
        $logsTextBox.Text = Get-Content $global:LogFile -Raw
        $logsTextBox.SelectionStart = $logsTextBox.Text.Length
        $logsTextBox.ScrollToCaret()
    } else {
        $logsTextBox.Text = "No log file found."
    }
}

function Clear-Logs {
    $result = [System.Windows.Forms.MessageBox]::Show("Are you sure you want to clear the logs?", "Confirm Clear", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
    if ($result -eq "Yes") {
        if (Test-Path $global:LogFile) {
            Clear-Content $global:LogFile
        }
        $logsTextBox.Clear()
        Write-Log "Logs cleared by user"
    }
}

function Populate-DomainDropdown {
    try {
        Write-Log "Populating domain dropdown with accepted domains"
        
        # Clear existing items except the auto-detect option
        $domainComboBox.Items.Clear()
        $domainComboBox.Items.Add("Auto-detect public domain") | Out-Null
        $domainComboBox.Items.Add("All domains") | Out-Null
        
        # Get accepted domains
        $acceptedDomains = Get-AcceptedDomain | Select-Object -ExpandProperty DomainName | Sort-Object
        
        # Separate public domains from Microsoft domains
        $publicDomains = $acceptedDomains | Where-Object { $_ -notlike "*.onmicrosoft.com" -and $_ -notlike "*.mail.onmicrosoft.com" }
        $microsoftDomains = $acceptedDomains | Where-Object { $_ -like "*.onmicrosoft.com" -or $_ -like "*.mail.onmicrosoft.com" }
        
        # Add public domains first
        foreach ($domain in $publicDomains) {
            $domainComboBox.Items.Add("$domain (Public)") | Out-Null
        }
        
        # Add Microsoft domains
        foreach ($domain in $microsoftDomains) {
            $domainComboBox.Items.Add("$domain (Microsoft)") | Out-Null
        }
        
        # Select auto-detect by default
        $domainComboBox.SelectedIndex = 0
        
        Write-Log "Added $($publicDomains.Count) public domains and $($microsoftDomains.Count) Microsoft domains to dropdown"
        
    } catch {
        Write-Log "Failed to populate domain dropdown: $($_.Exception.Message)" "ERROR"
    }
}

# Message Trace Functions
function Search-MessageTrace {
    if ([string]::IsNullOrEmpty($global:ConnectedTenant)) {
        [MessageBox]::Show("Please connect to Microsoft 365 first.", "Not Connected", [MessageBoxButtons]::OK, [MessageBoxIcon]::Warning)
        return
    }
    
    $startDate = $startDatePicker.Value
    $endDate = $endDatePicker.Value
    $senderDomain = if ($senderDomainTextBox.Text -ne "yourdomain.com") { $senderDomainTextBox.Text } else { $null }
    $recipientDomain = if ($recipientDomainTextBox.Text -ne "yourdomain.com") { $recipientDomainTextBox.Text } else { $null }
    
    if ($endDate -lt $startDate) {
        [MessageBox]::Show("End date must be after start date.", "Invalid Date Range", [MessageBoxButtons]::OK, [MessageBoxIcon]::Warning)
        return
    }
    
    $daysDiff = ($endDate - $startDate).Days
    if ($daysDiff -gt 10) {
        $result = [MessageBox]::Show("Date range is more than 10 days. This may take a long time and return many results. Continue?", "Large Date Range", [MessageBoxButtons]::YesNo, [MessageBoxIcon]::Question)
        if ($result -eq "No") { return }
    }
    
    try {
        $traceStatusLabel.Text = "Searching message traces..."
        $traceStatusLabel.ForeColor = [Color]::Orange
        $form.Refresh()
        
        Write-Log "Starting message trace search from $startDate to $endDate"
        
        $searchParams = @{
            StartDate = $startDate
            EndDate = $endDate
        }
        
        if ($senderDomain) {
            $searchParams.SenderAddress = "*@$senderDomain"
            Write-Log "Filtering by sender domain: $senderDomain"
        }
        
        if ($recipientDomain) {
            $searchParams.RecipientAddress = "*@$recipientDomain"
            Write-Log "Filtering by recipient domain: $recipientDomain"
        }
        
        # Store search parameters for potential "Load More" operations
        $global:CurrentSearchParams = $searchParams.Clone()
        $global:CurrentSearchType = "Custom"
        $global:NextPage = 1
        
        # Get first batch of messages
        $resultSize = 5000
        Write-Log "Retrieving message traces (first batch of up to $resultSize)..."
        
        $messages = Get-MessageTraceV2 @searchParams -ResultSize $resultSize
        $global:HasMoreResults = ($messages.Count -eq $resultSize)
        $global:LastRecipientAddress = if ($messages.Count -gt 0) { $messages[-1].RecipientAddress } else { $null }
        
        if ($messages) {
            Write-Log "Retrieved $($messages.Count) messages"
            $messages = $messages | Sort-Object Received -Descending
            
            Display-MessageTraceResults $messages
            $global:CurrentTraceResults = $messages
            $global:NextPage = 2
            
            $statusText = "Found $($messages.Count) messages"
            if ($global:HasMoreResults) {
                $statusText += " (More available - click 'Load More Results')"
            }
            $traceStatusLabel.Text = $statusText
            $traceStatusLabel.ForeColor = [Color]::Green
            
            $exportCsvButton.Enabled = $true
            $loadMoreButton.Enabled = $global:HasMoreResults
            
            Write-Log "Message trace search completed. Found $($messages.Count) messages. More available: $($global:HasMoreResults)"
        } else {
            $traceStatusLabel.Text = "No messages found"
            $traceStatusLabel.ForeColor = [Color]::Orange
            $exportCsvButton.Enabled = $false
            $loadMoreButton.Enabled = $false
        }
        
    } catch {
        $traceStatusLabel.Text = "Search failed: $($_.Exception.Message)"
        $traceStatusLabel.ForeColor = [Color]::Red
        Write-Log "Message trace search failed: $($_.Exception.Message)" "ERROR"
        [MessageBox]::Show("Message trace search failed: $($_.Exception.Message)", "Search Error", [MessageBoxButtons]::OK, [MessageBoxIcon]::Error)
    }
}

function Search-DomainSpoofing {
    if ([string]::IsNullOrEmpty($global:ConnectedTenant)) {
        [MessageBox]::Show("Please connect to Microsoft 365 first.", "Not Connected", [MessageBoxButtons]::OK, [MessageBoxIcon]::Warning)
        return
    }
    
    # Get the organization's accepted domains
    try {
        $acceptedDomains = Get-AcceptedDomain | Select-Object -ExpandProperty DomainName
        
        if ($acceptedDomains.Count -eq 0) {
            [MessageBox]::Show("No accepted domains found. Please check your connection.", "No Domains", [MessageBoxButtons]::OK, [MessageBoxIcon]::Warning)
            return
        }
        
        # Use the first accepted domain as default, or let user specify
        $primaryDomain = $acceptedDomains[0]
        
        $traceStatusLabel.Text = "Searching for domain spoofing attempts..."
        $traceStatusLabel.ForeColor = [Color]::Orange
        $form.Refresh()
        
        Write-Log "Searching for domain spoofing using domain: $primaryDomain"
        
        # Store search parameters for potential "Load More" operations
        $searchParams = @{
            StartDate = (Get-Date).AddDays(-10)
            EndDate = (Get-Date)
            SenderAddress = "*@$primaryDomain"
        }
        
        $global:CurrentSearchParams = $searchParams.Clone()
        $global:CurrentSearchType = "Spoofing"
        $global:NextPage = 1
        
        # Get first batch of messages
        $resultSize = 5000
        $allMessages = Get-MessageTraceV2 @searchParams -ResultSize $resultSize
        $global:HasMoreResults = ($allMessages.Count -eq $resultSize)
        $global:LastRecipientAddress = if ($allMessages.Count -gt 0) { $allMessages[-1].RecipientAddress } else { $null }
        $global:NextPage = 2
        
        # Filter for external IPs (potential spoofing)
        $messages = $allMessages | 
                   Where-Object { $_.FromIP -notlike "10.*" -and $_.FromIP -notlike "192.168.*" -and $_.FromIP -notlike "172.16.*" -and $_.FromIP -ne $null } |
                   Sort-Object Received -Descending
        
        Display-MessageTraceResults $messages
        $global:CurrentTraceResults = $messages
        
        $statusText = "Found $($messages.Count) potential spoofing attempts"
        if ($global:HasMoreResults) {
            $statusText += " (More data available - click 'Load More Results')"
        }
        $traceStatusLabel.Text = $statusText
        $traceStatusLabel.ForeColor = if ($messages.Count -gt 0) { [Color]::Red } else { [Color]::Green }
        $exportCsvButton.Enabled = ($messages.Count -gt 0)
        $loadMoreButton.Enabled = $global:HasMoreResults
        
        Write-Log "Domain spoofing search completed. Found $($messages.Count) potential attempts. More available: $($global:HasMoreResults)"
        
        if ($messages.Count -gt 0) {
            [MessageBox]::Show("Found $($messages.Count) potential domain spoofing attempts! Review the results carefully.", "Potential Spoofing Detected", [MessageBoxButtons]::OK, [MessageBoxIcon]::Warning)
        }
        
    } catch {
        $traceStatusLabel.Text = "Spoofing search failed: $($_.Exception.Message)"
        $traceStatusLabel.ForeColor = [Color]::Red
        Write-Log "Domain spoofing search failed: $($_.Exception.Message)" "ERROR"
        [MessageBox]::Show("Domain spoofing search failed: $($_.Exception.Message)", "Search Error", [MessageBoxButtons]::OK, [MessageBoxIcon]::Error)
    }
}

function Search-InternalToInternal {
    if ([string]::IsNullOrEmpty($global:ConnectedTenant)) {
        [MessageBox]::Show("Please connect to Microsoft 365 first.", "Not Connected", [MessageBoxButtons]::OK, [MessageBoxIcon]::Warning)
        return
    }
    
    try {
        # Determine which domain(s) to search based on dropdown selection
        $selectedDomain = $domainComboBox.SelectedItem?.ToString()
        $searchDomains = @()
        
        if ($selectedDomain -eq "Auto-detect public domain" -or [string]::IsNullOrEmpty($selectedDomain)) {
            # Auto-detect logic (original behavior)
            $acceptedDomains = Get-AcceptedDomain | Select-Object -ExpandProperty DomainName
            $publicDomain = $acceptedDomains | Where-Object { $_ -notlike "*.onmicrosoft.com" -and $_ -notlike "*.mail.onmicrosoft.com" } | Select-Object -First 1
            $primaryDomain = if ($publicDomain) { $publicDomain } else { $acceptedDomains[0] }
            $searchDomains = @($primaryDomain)
            Write-Log "Auto-detected domain for internal search: $primaryDomain"
        } elseif ($selectedDomain -eq "All domains") {
            # Search all domains
            $acceptedDomains = Get-AcceptedDomain | Select-Object -ExpandProperty DomainName
            $searchDomains = $acceptedDomains
            $primaryDomain = "All Domains"
            Write-Log "Searching all domains: $($acceptedDomains -join ', ')"
        } else {
            # Extract domain name from dropdown selection (remove " (Public)" or " (Microsoft)" suffix)
            $primaryDomain = $selectedDomain -replace " \(Public\)$", "" -replace " \(Microsoft\)$", ""
            $searchDomains = @($primaryDomain)
            Write-Log "Using selected domain for internal search: $primaryDomain"
        }
        
        $traceStatusLabel.Text = "Searching internal to internal messages..."
        $traceStatusLabel.ForeColor = [Color]::Orange
        $form.Refresh()
        
        Write-Log "Searching for internal to internal messages for: $primaryDomain"
        
        # Store search parameters for potential "Load More" operations
        $searchParams = @{
            StartDate = (Get-Date).AddDays(-10)
            EndDate = (Get-Date)
        }
        
        # For single domain, add specific sender/recipient filters
        if ($searchDomains.Count -eq 1 -and $primaryDomain -ne "All Domains") {
            $searchParams.SenderAddress = "*@$primaryDomain"
            $searchParams.RecipientAddress = "*@$primaryDomain"
        }
        
        # Store the domains for filtering
        $global:CurrentSearchDomains = $searchDomains
        
        $global:CurrentSearchParams = $searchParams.Clone()
        $global:CurrentSearchType = "Internal"
        $global:NextPage = 1
        
        # Get first batch of messages
        $resultSize = 5000
        $allMessages = Get-MessageTraceV2 @searchParams -ResultSize $resultSize
        $global:HasMoreResults = ($allMessages.Count -eq $resultSize)
        $global:LastRecipientAddress = if ($allMessages.Count -gt 0) { $allMessages[-1].RecipientAddress } else { $null }
        $global:NextPage = 2
        
        # Filter for ONLY real user-to-user emails, excluding ALL system messages
        $messages = $allMessages | 
                   Where-Object { 
                       # Check if sender and recipient are in the target domains
                       ($global:CurrentSearchDomains | Where-Object { $_.SenderAddress -like "*@$_" }).Count -gt 0 -and
                       ($global:CurrentSearchDomains | Where-Object { $_.RecipientAddress -like "*@$_" }).Count -gt 0 -and
                       $_.SenderAddress -ne $null -and
                       $_.SenderAddress -ne "" -and
                       $_.RecipientAddress -ne $null -and
                       $_.RecipientAddress -ne "" -and
                       # Exclude ALL Microsoft system messages and mailboxes
                       $_.Subject -notlike "*HierarchySync*" -and
                       $_.Subject -notlike "*SystemMailbox*" -and
                       $_.Subject -notlike "*Microsoft Exchange*" -and
                       $_.Subject -notlike "*ExchangeOnline*" -and
                       $_.Subject -notlike "*Office365*" -and
                       $_.Subject -notlike "*AutoDiscover*" -and
                       $_.Subject -notlike "*DirectorySync*" -and
                       $_.Subject -notlike "*IncrementalSync*" -and
                       # Exclude system sender addresses
                       $_.SenderAddress -notlike "*SystemMailbox*" -and
                       $_.SenderAddress -notlike "*MicrosoftExchange*" -and
                       $_.SenderAddress -notlike "*WeekendStaffPFMailbox*" -and
                       $_.SenderAddress -notlike "*PFMailbox*" -and
                       $_.SenderAddress -notlike "*HealthMailbox*" -and
                       $_.SenderAddress -notlike "*DiscoverySearchMailbox*" -and
                       $_.SenderAddress -notlike "*FederatedEmail*" -and
                       $_.SenderAddress -notlike "*Migration*" -and
                       # Exclude system recipient addresses  
                       $_.RecipientAddress -notlike "*SystemMailbox*" -and
                       $_.RecipientAddress -notlike "*MicrosoftExchange*" -and
                       $_.RecipientAddress -notlike "*WeekendStaffPFMailbox*" -and
                       $_.RecipientAddress -notlike "*PFMailbox*" -and
                       $_.RecipientAddress -notlike "*HealthMailbox*" -and
                       $_.RecipientAddress -notlike "*DiscoverySearchMailbox*" -and
                       $_.RecipientAddress -notlike "*FederatedEmail*" -and
                       $_.RecipientAddress -notlike "*Migration*" -and
                       # Only include messages that look like real user addresses (no system UUIDs)
                       $_.SenderAddress -notmatch ".*[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}.*" -and
                       $_.RecipientAddress -notmatch ".*[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}.*"
                   } |
                   Sort-Object Received -Descending
        
        Display-MessageTraceResults $messages
        $global:CurrentTraceResults = $messages
        
        $statusText = "Found $($messages.Count) internal messages for domain: $primaryDomain"
        if ($global:HasMoreResults) {
            $statusText += " (More available)"
        }
        $traceStatusLabel.Text = $statusText
        $traceStatusLabel.ForeColor = [Color]::Blue
        $exportCsvButton.Enabled = ($messages.Count -gt 0)
        $loadMoreButton.Enabled = $global:HasMoreResults
        
        Write-Log "Internal to internal search completed. Found $($messages.Count) messages. More available: $($global:HasMoreResults)"
        
    } catch {
        $traceStatusLabel.Text = "Internal search failed: $($_.Exception.Message)"
        $traceStatusLabel.ForeColor = [Color]::Red
        Write-Log "Internal to internal search failed: $($_.Exception.Message)" "ERROR"
        [MessageBox]::Show("Internal to internal search failed: $($_.Exception.Message)", "Search Error", [MessageBoxButtons]::OK, [MessageBoxIcon]::Error)
    }
}

function Search-SuspiciousPatterns {
    if ([string]::IsNullOrEmpty($global:ConnectedTenant)) {
        [MessageBox]::Show("Please connect to Microsoft 365 first.", "Not Connected", [MessageBoxButtons]::OK, [MessageBoxIcon]::Warning)
        return
    }
    
    try {
        $traceStatusLabel.Text = "Searching for suspicious patterns..."
        $traceStatusLabel.ForeColor = [Color]::Orange
        $form.Refresh()
        
        Write-Log "Searching for suspicious message patterns"
        
        # Search for messages with suspicious patterns
        $suspiciousPatterns = @(
            "*urgent*", "*immediate*", "*action required*", "*verify*", "*suspend*", 
            "*click here*", "*update*", "*confirm*", "*security*", "*account*"
        )
        
        $allMessages = @()
        
        foreach ($pattern in $suspiciousPatterns) {
            $messages = Get-MessageTraceV2 -StartDate (Get-Date).AddDays(-7) -EndDate (Get-Date) | 
                       Where-Object { $_.Subject -like $pattern }
            $allMessages += $messages
        }
        
        # Remove duplicates and sort
        $uniqueMessages = $allMessages | Sort-Object MessageTraceId -Unique | Sort-Object Received -Descending
        
        Display-MessageTraceResults $uniqueMessages
        $global:CurrentTraceResults = $uniqueMessages
        
        $traceStatusLabel.Text = "Found $($uniqueMessages.Count) messages with suspicious patterns"
        $traceStatusLabel.ForeColor = if ($uniqueMessages.Count -gt 0) { [Color]::Orange } else { [Color]::Green }
        $exportCsvButton.Enabled = ($uniqueMessages.Count -gt 0)
        
        Write-Log "Suspicious patterns search completed. Found $($uniqueMessages.Count) messages"
        
    } catch {
        $traceStatusLabel.Text = "Suspicious search failed: $($_.Exception.Message)"
        $traceStatusLabel.ForeColor = [Color]::Red
        Write-Log "Suspicious patterns search failed: $($_.Exception.Message)" "ERROR"
        [MessageBox]::Show("Suspicious patterns search failed: $($_.Exception.Message)", "Search Error", [MessageBoxButtons]::OK, [MessageBoxIcon]::Error)
    }
}

function Display-MessageTraceResults {
    param($messages)
    
    $traceResultsListView.Items.Clear()
    
    foreach ($message in $messages) {
        $dateTime = if ($message.Received) { $message.Received.ToString("yyyy-MM-dd HH:mm") } else { "" }
        $sender = $message.SenderAddress ?? ""
        $recipient = $message.RecipientAddress ?? ""
        $subject = $message.Subject ?? ""
        $status = $message.Status ?? ""
        $size = if ($message.Size) { "$($message.Size) KB" } else { "" }
        $messageId = $message.MessageId ?? ""
        
        $item = New-Object ListViewItem($dateTime)
        $item.SubItems.Add($sender) | Out-Null
        $item.SubItems.Add($recipient) | Out-Null
        $item.SubItems.Add($subject) | Out-Null
        $item.SubItems.Add($status) | Out-Null
        $item.SubItems.Add($size) | Out-Null
        $item.SubItems.Add($messageId) | Out-Null
        $item.Tag = $message
        
        # Color code based on potential risk
        if ($sender -like "*@*" -and $recipient -like "*@*") {
            $senderDomain = $sender.Split("@")[1]
            $recipientDomain = $recipient.Split("@")[1]
            
            # Highlight potential spoofing in red
            if ($senderDomain -eq $recipientDomain -and $message.FromIP -notlike "10.*" -and $message.FromIP -notlike "192.168.*") {
                $item.BackColor = [Color]::LightPink
            }
            # Highlight external to internal in yellow
            elseif ($senderDomain -ne $recipientDomain) {
                $item.BackColor = [Color]::LightYellow
            }
        }
        
        $traceResultsListView.Items.Add($item) | Out-Null
    }
}

function Load-MoreResults {
    if ([string]::IsNullOrEmpty($global:ConnectedTenant)) {
        [MessageBox]::Show("Please connect to Microsoft 365 first.", "Not Connected", [MessageBoxButtons]::OK, [MessageBoxIcon]::Warning)
        return
    }
    
    if (-not $global:HasMoreResults) {
        [MessageBox]::Show("No more results available.", "No More Data", [MessageBoxButtons]::OK, [MessageBoxIcon]::Information)
        return
    }
    
    try {
        $traceStatusLabel.Text = "Loading more results..."
        $traceStatusLabel.ForeColor = [Color]::Orange
        $form.Refresh()
        
        Write-Log "Loading more results - Page $($global:NextPage) for $($global:CurrentSearchType) search"
        
        # Get next batch of messages using StartingRecipientAddress for pagination
        $resultSize = 5000
        $searchParamsWithPagination = $global:CurrentSearchParams.Clone()
        if ($global:LastRecipientAddress) {
            $searchParamsWithPagination.StartingRecipientAddress = $global:LastRecipientAddress
        }
        $newMessages = Get-MessageTraceV2 @searchParamsWithPagination -ResultSize $resultSize
        
        if ($newMessages) {
            # Apply filtering based on search type
            switch ($global:CurrentSearchType) {
                "Spoofing" {
                    $filteredMessages = $newMessages | 
                        Where-Object { $_.FromIP -notlike "10.*" -and $_.FromIP -notlike "192.168.*" -and $_.FromIP -notlike "172.16.*" -and $_.FromIP -ne $null }
                }
                "Internal" {
                    $acceptedDomains = Get-AcceptedDomain | Select-Object -ExpandProperty DomainName
                    # Find the public domain (not .onmicrosoft.com)
                    $publicDomain = $acceptedDomains | Where-Object { $_ -notlike "*.onmicrosoft.com" -and $_ -notlike "*.mail.onmicrosoft.com" } | Select-Object -First 1
                    $primaryDomain = if ($publicDomain) { $publicDomain } else { $acceptedDomains[0] }
                    $filteredMessages = $newMessages | 
                        Where-Object { 
                            $_.SenderAddress -like "*@$primaryDomain" -and 
                            $_.RecipientAddress -like "*@$primaryDomain" -and
                            $_.SenderAddress -ne $null -and
                            $_.SenderAddress -ne "" -and
                            $_.RecipientAddress -ne $null -and
                            $_.RecipientAddress -ne "" -and
                            # Exclude ALL Microsoft system messages and mailboxes
                            $_.Subject -notlike "*HierarchySync*" -and
                            $_.Subject -notlike "*SystemMailbox*" -and
                            $_.Subject -notlike "*Microsoft Exchange*" -and
                            $_.Subject -notlike "*ExchangeOnline*" -and
                            $_.Subject -notlike "*Office365*" -and
                            $_.Subject -notlike "*AutoDiscover*" -and
                            $_.Subject -notlike "*DirectorySync*" -and
                            $_.Subject -notlike "*IncrementalSync*" -and
                            # Exclude system sender addresses
                            $_.SenderAddress -notlike "*SystemMailbox*" -and
                            $_.SenderAddress -notlike "*MicrosoftExchange*" -and
                            $_.SenderAddress -notlike "*WeekendStaffPFMailbox*" -and
                            $_.SenderAddress -notlike "*PFMailbox*" -and
                            $_.SenderAddress -notlike "*HealthMailbox*" -and
                            $_.SenderAddress -notlike "*DiscoverySearchMailbox*" -and
                            $_.SenderAddress -notlike "*FederatedEmail*" -and
                            $_.SenderAddress -notlike "*Migration*" -and
                            # Exclude system recipient addresses  
                            $_.RecipientAddress -notlike "*SystemMailbox*" -and
                            $_.RecipientAddress -notlike "*MicrosoftExchange*" -and
                            $_.RecipientAddress -notlike "*WeekendStaffPFMailbox*" -and
                            $_.RecipientAddress -notlike "*PFMailbox*" -and
                            $_.RecipientAddress -notlike "*HealthMailbox*" -and
                            $_.RecipientAddress -notlike "*DiscoverySearchMailbox*" -and
                            $_.RecipientAddress -notlike "*FederatedEmail*" -and
                            $_.RecipientAddress -notlike "*Migration*" -and
                            # Only include messages that look like real user addresses (no system UUIDs)
                            $_.SenderAddress -notmatch ".*[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}.*" -and
                            $_.RecipientAddress -notmatch ".*[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}.*"
                        }
                }
                default {
                    $filteredMessages = $newMessages
                }
            }
            
            # Add to existing results
            $global:CurrentTraceResults += $filteredMessages | Sort-Object Received -Descending
            
            # Update pagination state
            $global:HasMoreResults = ($newMessages.Count -eq $resultSize)
            $global:LastRecipientAddress = if ($newMessages.Count -gt 0) { $newMessages[-1].RecipientAddress } else { $null }
            $global:NextPage++
            
            # Refresh display with all results
            Display-MessageTraceResults $global:CurrentTraceResults
            
            $statusText = "Total: $($global:CurrentTraceResults.Count) messages (added $($filteredMessages.Count) new)"
            if ($global:HasMoreResults) {
                $statusText += " - More available"
            }
            $traceStatusLabel.Text = $statusText
            $traceStatusLabel.ForeColor = [Color]::Green
            
            $loadMoreButton.Enabled = $global:HasMoreResults
            $exportCsvButton.Enabled = ($global:CurrentTraceResults.Count -gt 0)
            
            Write-Log "Loaded $($filteredMessages.Count) additional messages. Total: $($global:CurrentTraceResults.Count). More available: $($global:HasMoreResults)"
            
        } else {
            $global:HasMoreResults = $false
            $loadMoreButton.Enabled = $false
            $traceStatusLabel.Text = "No additional results found"
            $traceStatusLabel.ForeColor = [Color]::Orange
            Write-Log "No additional messages found"
        }
        
    } catch {
        $traceStatusLabel.Text = "Failed to load more results: $($_.Exception.Message)"
        $traceStatusLabel.ForeColor = [Color]::Red
        Write-Log "Failed to load more results: $($_.Exception.Message)" "ERROR"
        [MessageBox]::Show("Failed to load more results: $($_.Exception.Message)", "Load Error", [MessageBoxButtons]::OK, [MessageBoxIcon]::Error)
    }
}

function Export-MessageTraceToCsv {
    if ($global:CurrentTraceResults.Count -eq 0) {
        [MessageBox]::Show("No message trace results to export.", "No Data", [MessageBoxButtons]::OK, [MessageBoxIcon]::Information)
        return
    }
    
    try {
        $saveDialog = New-Object SaveFileDialog
        $saveDialog.Filter = "CSV Files (*.csv)|*.csv|All Files (*.*)|*.*"
        $saveDialog.FileName = "MessageTrace_$(Get-Date -Format 'yyyyMMdd_HHmm').csv"
        $saveDialog.InitialDirectory = "c:\dev\ExchangeTransportRuleManager\"
        
        if ($saveDialog.ShowDialog() -eq "OK") {
            # Include ALL standard message trace fields that would be in a normal export
            $csvData = $global:CurrentTraceResults | Select-Object @(
                @{Name="Organization";Expression={$_.Organization}},
                @{Name="MessageId";Expression={$_.MessageId}},
                @{Name="Received";Expression={$_.Received}},
                @{Name="SenderAddress";Expression={$_.SenderAddress}},
                @{Name="RecipientAddress";Expression={$_.RecipientAddress}},
                @{Name="Subject";Expression={$_.Subject}},
                @{Name="Status";Expression={$_.Status}},
                @{Name="ToIP";Expression={$_.ToIP}},
                @{Name="FromIP";Expression={$_.FromIP}},
                @{Name="Size";Expression={$_.Size}},
                @{Name="MessageTraceId";Expression={$_.MessageTraceId}},
                @{Name="StartDate";Expression={$_.StartDate}},
                @{Name="EndDate";Expression={$_.EndDate}},
                @{Name="Index";Expression={$_.Index}},
                # Additional fields that may be present
                @{Name="Direction";Expression={$_.Direction}},
                @{Name="OriginalClientIP";Expression={$_.OriginalClientIP}},
                @{Name="ClientIP";Expression={$_.ClientIP}},
                @{Name="ServerIP";Expression={$_.ServerIP}},
                @{Name="ConnectorId";Expression={$_.ConnectorId}},
                @{Name="Source";Expression={$_.Source}},
                @{Name="EventType";Expression={$_.EventType}},
                @{Name="Detail";Expression={$_.Detail}},
                @{Name="Data";Expression={$_.Data}},
                @{Name="TransportTrafficType";Expression={$_.TransportTrafficType}},
                @{Name="TenantId";Expression={$_.TenantId}},
                @{Name="OriginalServerIp";Expression={$_.OriginalServerIp}},
                @{Name="Directionality";Expression={$_.Directionality}}
            )
            
            $csvData | Export-Csv -Path $saveDialog.FileName -NoTypeInformation
            
            Write-Log "Exported $($global:CurrentTraceResults.Count) message trace results to: $($saveDialog.FileName)"
            [MessageBox]::Show("Successfully exported $($global:CurrentTraceResults.Count) results to:`n$($saveDialog.FileName)", "Export Complete", [MessageBoxButtons]::OK, [MessageBoxIcon]::Information)
        }
        
    } catch {
        Write-Log "Failed to export message trace results: $($_.Exception.Message)" "ERROR"
        [MessageBox]::Show("Failed to export results: $($_.Exception.Message)", "Export Error", [MessageBoxButtons]::OK, [MessageBoxIcon]::Error)
    }
}

# Initialize logs display
Refresh-Logs

# Show the form
Write-Log "Exchange Transport Rule Manager started"
[Application]::Run($form)
