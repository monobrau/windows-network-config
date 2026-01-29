# Exchange Transport Rule Manager - MSP Edition

A PowerShell-based GUI application designed for MSPs to manage Exchange Online transport rules across multiple client tenants, with a focus on anti-spoofing and anti-spam protection.

## Features

- **Multi-Tenant Support**: Connect to different client tenants using Entra account selector
- **Transport Rule Management**: Create, modify, delete, and toggle transport rules
- **Pre-built Templates**: Ready-to-use anti-spoofing and anti-spam rule templates
- **Custom PowerShell**: Execute custom PowerShell code for advanced rule creation
- **Comprehensive Logging**: Track all operations with detailed logs for MSP compliance
- **User-Friendly GUI**: Windows Forms-based interface for easy navigation

## Requirements

- Windows PowerShell 5.1 or PowerShell 7+
- ExchangeOnlineManagement module (auto-installed if missing)
- Appropriate Exchange Online permissions for target tenants

## Installation

1. Download or clone the files to `c:\dev\ExchangeTransportRuleManager\`
2. Run `Launch.bat` to start the application (will auto-install required modules)

Alternatively, run directly:
```powershell
.\ExchangeTransportRuleManager.ps1
```

## Usage

### Connecting to a Tenant
1. Enter the tenant domain (e.g., `contoso.onmicrosoft.com`)
2. Click "Connect" - this will use the Entra account selector for authentication
3. Once connected, the interface will enable rule management features

### Managing Transport Rules
- **View Rules**: All transport rules are displayed with name, state, priority, and description
- **Rule Details**: Click on any rule to view detailed configuration
- **Delete Rules**: Select a rule and click "Delete Selected"
- **Enable/Disable**: Toggle rule state with "Enable/Disable" button

### Using Templates
The application includes several pre-built templates:

1. **Block External Spoofing - CEO**: Blocks external emails impersonating CEO display names
2. **Block Domain Spoofing**: Prevents external emails using your internal domain
3. **Quarantine Suspicious Attachments**: Quarantines emails with dangerous file extensions
4. **External Warning Banner**: Adds warning banners to external emails

To deploy a template:
1. Select from the dropdown on the "Rule Templates" tab
2. Review and edit the PowerShell code if needed
3. Click "Deploy Template"

### Custom PowerShell
Use the "Custom PowerShell" tab to:
- Paste existing PowerShell transport rule code
- Write custom rules from scratch
- Validate syntax before execution
- Execute and see results

### Logging
All operations are logged to `c:\dev\ExchangeTransportRuleManager\Logs\` with:
- Timestamp
- Log level (INFO, WARNING, ERROR)
- Tenant information
- Action details

## Template Examples

### Block CEO Spoofing
```powershell
New-TransportRule -Name "Block External CEO Spoofing" `
    -FromScope NotInOrganization `
    -SenderDisplayNameMatchesPatterns "*CEO*","*Chief Executive*" `
    -RejectMessageReasonText "External email impersonating internal executive blocked" `
    -Comments "Blocks external emails attempting to impersonate CEO"
```

### External Email Warning
```powershell
New-TransportRule -Name "External Email Warning" `
    -FromScope NotInOrganization `
    -PrependSubject "[EXTERNAL] " `
    -ApplyHtmlDisclaimerText "<div style='background-color:#ffeb9c;border:1px solid #9c6500;color:#9c6500;padding:10px;margin:10px 0;'><strong>CAUTION:</strong> This email originated from outside the organization. Do not click links or open attachments unless you recognize the sender and know the content is safe.</div>" `
    -ApplyHtmlDisclaimerLocation Prepend `
    -Comments "Adds external email warning banner"
```

## Security Considerations

- Always review rules before deployment
- Test rules in a non-production environment first
- Monitor rule effectiveness through Exchange Online reports
- Keep logs for compliance and audit purposes

## Troubleshooting

### Connection Issues
- Ensure you have appropriate permissions in the target tenant
- Check if MFA is properly configured
- Verify the tenant domain is correct

### Module Issues
- Run as Administrator if module installation fails
- Manually install: `Install-Module -Name ExchangeOnlineManagement -Force`

### Rule Deployment Issues
- Check PowerShell syntax in custom code
- Verify rule names don't conflict with existing rules
- Ensure all required parameters are provided

## Support

This tool is designed for MSP administrators with Exchange Online experience. Ensure you understand the impact of transport rules before deployment.

## Version History

- v1.0: Initial release with core functionality
- Multi-tenant support
- Pre-built templates
- Custom PowerShell execution
- Comprehensive logging
