# Getting Started with Mike's HomeBrew Diagnostic Tool

## Installation

### Prerequisites

- Windows 10 or Windows 11
- PowerShell 5.1 or later (PowerShell 7+ recommended)
- Administrator privileges (optional, but recommended for full diagnostics)

### Clone the Repository

```powershell
git clone https://github.com/NickNak86/Mikes_HomBrew-Daignostic_Tool.git
cd Mikes_HomBrew-Daignostic_Tool
```

## First Run

### Basic Usage

Run the diagnostic tool with default settings:

```powershell
.\Run-Diagnostics.ps1
```

This will:
1. Run all enabled diagnostic modules
2. Generate an HTML report in `output/reports/`
3. Create logs in `output/logs/`
4. Display a summary in the console

### Running as Administrator

For full diagnostic capabilities:

```powershell
# Right-click PowerShell and select "Run as Administrator"
cd path\to\Mikes_HomBrew-Daignostic_Tool
.\Run-Diagnostics.ps1
```

## Understanding the Output

### Console Output

The tool displays real-time progress:

```
Mike's HomeBrew Diagnostic Tool v1.0.0
=======================================

[INFO] Starting diagnostic run at 2025-12-08 18:30:45

[SYSTEM] Running system diagnostics...
  ✓ OS Version checked
  ✓ System uptime recorded
  ✓ Windows Update status verified

[HARDWARE] Running hardware diagnostics...
  ✓ CPU information collected
  ✓ Memory status analyzed
  ✓ Disk space checked

[SUCCESS] Diagnostic run complete!
```

### Report Files

Reports are saved to `output/reports/` with timestamps:

- **HTML Report**: `diagnostic_2025-12-08_183045.html` - Open in browser
- **JSON Report**: `diagnostic_2025-12-08_183045.json` - For automation
- **Text Report**: `diagnostic_2025-12-08_183045.txt` - Console-friendly

### Log Files

Detailed logs are saved to `output/logs/`:

- `diagnostic_2025-12-08.log` - Daily log file with all diagnostic details

## Common Tasks

### Run Specific Module Only

```powershell
# Run only hardware diagnostics
.\Run-Diagnostics.ps1 -Module Hardware

# Run only network diagnostics
.\Run-Diagnostics.ps1 -Module Network
```

### Change Output Format

```powershell
# Generate JSON report
.\Run-Diagnostics.ps1 -OutputFormat JSON

# Generate all formats (HTML, JSON, Text)
.\Run-Diagnostics.ps1 -OutputFormat All
```

### Generate Report from Existing Data

```powershell
# Re-generate report without re-running diagnostics
.\Run-Diagnostics.ps1 -ReportOnly
```

## Customization

### Edit Configuration

Customize which diagnostics run and how they behave:

```powershell
notepad config/diagnostics.yaml
```

Key settings:
- `enabled_modules` - Which diagnostic modules to run
- `output.format` - Default output format
- `logging.level` - Verbosity of logs (DEBUG, INFO, WARNING, ERROR)
- Module-specific thresholds and settings

## Troubleshooting

### "Scripts are disabled on this system"

Enable script execution:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### No output/reports generated

Check permissions:
1. Ensure you have write access to the `output/` directory
2. Try running as Administrator
3. Check `output/logs/` for error messages

### Network diagnostics failing

If behind a corporate firewall:
1. Edit `config/diagnostics.yaml`
2. Adjust `ping_targets` to internal addresses
3. Disable external connectivity checks if needed

## Next Steps

1. Review the [Configuration Guide](CONFIGURATION.md) for advanced customization
2. Learn about [individual diagnostic modules](MODULES.md)
3. Set up [scheduled diagnostics](SCHEDULING.md) for continuous monitoring
4. Integrate with [WOPR or other monitoring systems](INTEGRATION.md)

## Getting Help

- [Open an issue](https://github.com/NickNak86/Mikes_HomBrew-Daignostic_Tool/issues) on GitHub
- Check the [FAQ](FAQ.md)
- Review [common diagnostic scenarios](SCENARIOS.md)

---

**Happy diagnosing!** 🔍💻
