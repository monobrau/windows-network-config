# Duo Proxy Upgrade Helper

PowerShell GUI tool providing quick shortcuts for Duo Authentication Proxy upgrade tasks.

## Quick Start

1. **Transfer** `DuoProxyUpgrade.ps1` to remote server via ScreenConnect
2. **Run** the script:
   ```powershell
   powershell.exe -ExecutionPolicy Bypass -File "DuoProxyUpgrade.ps1"
   ```
3. **Use** the GUI buttons or F1-F6 keyboard shortcuts
4. **Close** window when done

See `README_POWERSHELL.md` for detailed PowerShell version documentation.

## Features

- **GUI Window** with buttons for all actions
- **F1-F6 Keyboard Shortcuts** (when window has focus)
- **Auto-detection** of config paths (old vs new Duo Proxy versions)
- **Timestamped backups** to Desktop
- **Status notifications** in the window
- **Top-most window** - stays visible during ScreenConnect sessions
- **SentinelOne Safe** - Native Windows PowerShell, won't trigger EDR alerts

## Hotkeys

| Key | Action |
|-----|--------|
| **F1** | Open Old Config Path (Pre 5.6.0)<br>`C:\Program Files (x86)\Duo Security Authentication Proxy\conf` |
| **F2** | Open New Config Path (5.6.0+)<br>`C:\Program Files\Duo Security Authentication Proxy\conf` |
| **F3** | Open Duo Proxy Manager |
| **F4** | Open Duo Downloads/Checksums Page |
| **F5** | Backup Config File (Auto-detects path)<br>Copies `authproxy.cfg` to Desktop with timestamp |
| **F6** | Open Both Config Paths (for version detection) |

**Note**: Hotkeys only work when the GUI window has focus. Click inside the window before using shortcuts.

## Usage Tips

1. **Before upgrade**: Press F5 to backup config, F3 to check current version
2. **During upgrade**: Press F4 to open downloads page
3. **After upgrade**: Press F5 again to verify backup, F3 to validate new version

## Configuration Paths

The script automatically detects which path exists:

- **Old (Pre 5.6.0)**: `C:\Program Files (x86)\Duo Security Authentication Proxy\conf`
- **New (5.6.0+)**: `C:\Program Files\Duo Security Authentication Proxy\conf`
- **Config File**: `authproxy.cfg`

## Troubleshooting

- **Hotkeys not working**: Ensure GUI window has focus (click inside it)
- **Paths not found**: Verify Duo Proxy installation location matches script paths
- **Script won't run**: Use `-ExecutionPolicy Bypass` flag or right-click → Run with PowerShell
- **Execution Policy Error**: Use `powershell.exe -ExecutionPolicy Bypass -File "DuoProxyUpgrade.ps1"`

## Advantages

- ✅ **No false positives** from SentinelOne/EDR
- ✅ **No compilation needed** - just run the .ps1 script
- ✅ **Easy to modify/customize** - plain text PowerShell
- ✅ **Transparent** - admins can review the code
- ✅ **Works on all Windows systems** with PowerShell 5.1+
