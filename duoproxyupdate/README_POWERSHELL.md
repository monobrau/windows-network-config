# Duo Proxy Upgrade - PowerShell Version

**SentinelOne Safe** - Uses native Windows PowerShell, no compilation needed, won't trigger EDR alerts.

## Quick Start

1. **Transfer** `DuoProxyUpgrade.ps1` to remote server via ScreenConnect
2. **Run** the script:
   ```powershell
   powershell.exe -ExecutionPolicy Bypass -File "DuoProxyUpgrade.ps1"
   ```
3. **Use** the GUI buttons or F1-F6 keyboard shortcuts
4. **Close** window when done

## Why PowerShell?

- ✅ **Native Windows** - No compilation, no external dependencies
- ✅ **SentinelOne Safe** - Won't trigger EDR/antivirus alerts
- ✅ **No Allowlisting** - Works on all client networks
- ✅ **GUI Interface** - Easy to use with buttons
- ✅ **Keyboard Shortcuts** - F1-F6 still work when form has focus

## Features

- **GUI Window** with buttons for all actions
- **F1-F6 Keyboard Shortcuts** (when window has focus)
- **Auto-detection** of config paths (old vs new)
- **Timestamped backups** to Desktop
- **Status notifications** in the window
- **Top-most window** - stays visible during ScreenConnect sessions

## Usage Tips

### For ScreenConnect Sessions:

1. **Transfer** the `.ps1` file via ScreenConnect file transfer
2. **Right-click** → Run with PowerShell (or use command above)
3. **Keep window open** during your upgrade session
4. **Click buttons** or use F1-F6 shortcuts
5. **Close** when finished

### Keyboard Shortcuts (Form must have focus):

- **F1** - Open Old Config Path (Pre 5.6.0)
- **F2** - Open New Config Path (5.6.0+)
- **F3** - Open Duo Proxy Manager
- **F4** - Open Duo Downloads Page
- **F5** - Backup Config File (highlighted in green)
- **F6** - Open Both Config Paths

## Execution Policy

If you get an execution policy error, use:

```powershell
powershell.exe -ExecutionPolicy Bypass -File "DuoProxyUpgrade.ps1"
```

Or set execution policy temporarily:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process
.\DuoProxyUpgrade.ps1
```

## Troubleshooting

**Script won't run?**
- Ensure PowerShell 5.1+ is installed (default on Windows 10/11)
- Use `-ExecutionPolicy Bypass` flag
- Check that file wasn't blocked (right-click → Properties → Unblock)

**Buttons don't work?**
- Make sure the GUI window has focus
- Click inside the window before using keyboard shortcuts

**Paths not found?**
- Script automatically checks both old and new paths
- Verify Duo Proxy is installed on the server

## Advantages

- ✅ No false positives from SentinelOne/EDR
- ✅ No compilation needed - just run the .ps1 script
- ✅ Easy to modify/customize
- ✅ Transparent - admins can review the code
- ✅ Works on all Windows systems with PowerShell 5.1+
