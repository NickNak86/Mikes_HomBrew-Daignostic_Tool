# Getting Started with HomeBrew Telescope Diagnostic Tool

## Installation

### Prerequisites

- **Windows 10 or Windows 11**
- **PowerShell 5.1 or later** (PowerShell 7+ recommended)
- **Python 3.6+** ([Install from python.org](https://python.org))
- **Administrator privileges** (recommended for full diagnostics)
- **Network access** to HomeBrew devices

### Clone the Repository

```powershell
git clone https://github.com/NickNak86/HomeBrew-Telescope-Diagnostic-Tool.git
cd HomeBrew-Telescope-Diagnostic-Tool
```

### Install Python (Required for Telescope Scripts)

```powershell
# Download and install Python from https://python.org
# Make sure to check "Add Python to PATH" during installation

# Verify Python installation
python --version

# If Python is not in PATH, try:
py --version
```

## First Run

### Basic Usage for HomeBrew Device

Run the diagnostic tool with default device settings:

```powershell
.\Run-Diagnostics.ps1
```

This will:
1. Check system requirements (Python, network tools)
2. Test connectivity to HomeBrew device (192.168.1.100:2000)
3. Run telescope communication tests
4. Test WiFi/BT/GPS modules
5. Generate an HTML report in `output/reports/`
6. Create detailed logs in `output/logs/`

### Running as Administrator

For full diagnostic capabilities:

```powershell
# Right-click PowerShell and select "Run as Administrator"
cd path\to\HomeBrew-Telescope-Diagnostic-Tool
.\Run-Diagnostics.ps1
```

## Understanding the Output

### Console Output

The tool displays real-time progress:

```
HomeBrew Gen3 PCB WiFi/BT/GPS/MUSBA Relay Diagnostic Tool v2.0.0
===================================================================

Target Device: 192.168.1.100:2000

[INFO] Checking Python installation...
✓ Python found: Python 3.11.0

[INFO] Starting telescope diagnostic run at 2025-12-09 14:30:45

[NETWORK] Running Network diagnostics...
  ✓ Network diagnostics completed successfully

[COMMUNICATION] Running Communication diagnostics...
  ✓ Communication diagnostics completed successfully

[TELESCOPE] Running Telescope diagnostics...
  ✓ Telescope diagnostics completed successfully

[SYSTEM] Running System diagnostics...
  ✓ System diagnostics completed successfully

[SUCCESS] Telescope diagnostic run complete!
```

### Report Files

Reports are saved to `output/reports/` with timestamps:

- **HTML Report**: `telescope_diagnostic_2025-12-09_143045.html` - Main report with troubleshooting
- **JSON Report**: `telescope_diagnostic_2025-12-09_143045.json` - Detailed data for automation
- **Text Report**: `telescope_diagnostic_2025-12-09_143045.txt` - Console-friendly summary

### Log Files

Detailed logs are saved to `output/logs/`:

- `telescope_diagnostics.log` - Main telescope diagnostic log
- `network_diagnostics.log` - Network connectivity tests
- `communication_diagnostics.log` - Communication protocol tests
- `system_diagnostics.log` - System requirements check

## Common Tasks

### Test Specific Device

```powershell
# Test device at different IP address
.\Run-Diagnostics.ps1 -DeviceIP 192.168.1.150

# Test with custom port
.\Run-Diagnostics.ps1 -DeviceIP 192.168.1.100 -TelnetPort 2001
```

### Test Telescope Communication Only

```powershell
# Run only telescope diagnostics
.\Run-Diagnostics.ps1 -Module Telescope -DeviceIP 192.168.1.100

# Test with serial port connection
.\Run-Diagnostics.ps1 -Module Communication -DeviceIP 192.168.1.100 -SerialPort COM3
```

### Test Network Connectivity Only

```powershell
# Test network diagnostics for specific device
.\Run-Diagnostics.ps1 -Module Network -DeviceIP 192.168.1.100
```

### Change Output Format

```powershell
# Generate JSON report for automation
.\Run-Diagnostics.ps1 -OutputFormat JSON

# Generate all formats
.\Run-Diagnostics.ps1 -OutputFormat All
```

### Generate Report from Existing Data

```powershell
# Re-generate report without re-running diagnostics
.\Run-Diagnostics.ps1 -ReportOnly
```

## HomeBrew Device Setup

### Network Configuration

1. **Connect HomeBrew device to your network**
2. **Find device IP address**:
   ```powershell
   # Scan your local network
   nmap -sn 192.168.1.0/24
   # Or check your router's DHCP client list
   ```
3. **Test connectivity**:
   ```powershell
   ping 192.168.1.100
   telnet 192.168.1.100 2000
   ```

### Celestron Mount Connection

1. **Connect serial cable** from HomeBrew device to Celestron Evolution mount
2. **Verify serial connection**:
   ```powershell
   # List available COM ports
   python -c "import serial; print([p.device for p in serial.tools.list_ports.comports()])"
   ```

## Python Scripts Usage

### Telescope Communication Script

```powershell
# Test telescope communication directly
python python_scripts/telescope_comm.py --host 192.168.1.100 --port 2000

# Test with serial connection
python python_scripts/telescope_comm.py --serial COM3

# Get JSON output for automation
python python_scripts/telescope_comm.py --host 192.168.1.100 --json
```

### WiFi/BT/GPS Testing Script

```powershell
# Test all wireless modules
python python_scripts/wifi_bt_gps_test.py --host 192.168.1.100 --verbose

# Save results to file
python python_scripts/wifi_bt_gps_test.py --host 192.168.1.100 --output my_device_test.json
```

## Customization

### Edit Configuration

Customize telescope diagnostic behavior:

```powershell
notepad config/diagnostics.yaml
```

Key settings:
- `device.ip` - Your HomeBrew device IP address
- `device.telnet_port` - Telnet port (usually 2000)
- `device.serial_port` - Serial port for Celestron connection
- `enabled_modules` - Which diagnostic modules to run
- `output.format` - Default output format
- `logging.level` - Verbosity of logs

## Troubleshooting

### "Scripts are disabled on this system"

Enable script execution:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Python not found

```powershell
# Install Python from https://python.org
# Or try using py launcher
py --version

# Update diagnostic script to use py instead of python
.\Run-Diagnostics.ps1 -PythonPath py
```

### HomeBrew device not responding

1. **Check device power and network connection**
2. **Verify IP address**:
   ```powershell
   ping 192.168.1.100
   ```
3. **Check telnet port**:
   ```powershell
   telnet 192.168.1.100 2000
   ```
4. **Run network diagnostics**:
   ```powershell
   .\Run-Diagnostics.ps1 -Module Network -DeviceIP 192.168.1.100
   ```

### Serial communication fails

1. **Check COM port availability**:
   ```powershell
   python -c "import serial; print([p.device for p in serial.tools.list_ports.comports()])"
   ```
2. **Try different baud rates** (9600, 19200, 38400)
3. **Check Celestron cable connections**

### WiFi/BT/GPS modules not working

1. **Check device firmware version**
2. **Run specific tests**:
   ```powershell
   python python_scripts/wifi_bt_gps_test.py --host 192.168.1.100 --verbose
   ```

### No output/reports generated

Check permissions:
1. Ensure you have write access to the `output/` directory
2. Try running as Administrator
3. Check `output/logs/` for error messages

## Next Steps

1. **Review the [Configuration Guide](CONFIGURATION.md)** for advanced customization
2. **Learn about [individual diagnostic modules](MODULES.md)**
3. **Check [troubleshooting scenarios](TROUBLESHOOTING.md)** for common issues
4. **Integrate with telescope software** for automated monitoring

## Getting Help

- **[Open an issue](https://github.com/NickNak86/HomeBrew-Telescope-Diagnostic-Tool/issues)** on GitHub
- **[Cloudy Nights Forum](https://www.cloudynights.com/forums/)** - Community support
- **Check the [FAQ](FAQ.md)** for common questions

## Hardware Setup Reference

### HomeBrew Gen3 PCB Connections

- **Power**: 12V DC input
- **Network**: Ethernet or WiFi
- **Celestron**: Serial cable to mount
- **USB**: Optional relay control

### Celestron Evolution Mount

- **Communication**: Serial protocol at 9600 baud
- **Commands**: NexStar-compatible
- **Connection**: Via HomeBrew device serial port

---

**🌟 Ready to explore the cosmos with your HomeBrew telescope setup! 🌟**