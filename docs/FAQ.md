# Frequently Asked Questions

## General Questions

### What is the HomeBrew Telescope Diagnostic Tool?

The HomeBrew Telescope Diagnostic Tool is a comprehensive diagnostic system specifically designed for **HomeBrew Gen3 PCB WiFi/BT/GPS/MUSBA relay devices** used with **Celestron Evolution telescope mounts**. It provides automated testing, troubleshooting, and reporting capabilities to ensure optimal telescope operation.

### Who should use this tool?

- **Telescope enthusiasts** using HomeBrew devices with Celestron mounts
- **Observatory operators** managing multiple telescope setups
- **Telescope service technicians** troubleshooting HomeBrew devices
- **HomeBrew device owners** experiencing connectivity or performance issues

### What makes this tool different from general diagnostic tools?

This tool is **telescope-specific**, focusing on:
- **Celestron Evolution mount communication protocols**
- **HomeBrew device telnet port 2000 connectivity**
- **Serial communication at 9600 baud (Celestron standard)**
- **WiFi/BT/GPS module testing specific to HomeBrew hardware**
- **Python scripts for advanced telescope protocol testing**

---

## Installation and Setup

### What are the system requirements?

- **Windows 10/11** with PowerShell 5.1 or later
- **Python 3.6+** ([Download from python.org](https://python.org))
- **Network access** to HomeBrew devices
- **Administrator privileges** (recommended for full diagnostics)
- **1GB free disk space** for reports and logs

### Do I need to install Python?

**Yes, Python is required** for the advanced telescope communication features. Install Python 3.6+ from [python.org](https://python.org) and ensure you check "Add Python to PATH" during installation.

### Why am I getting "Scripts are disabled on this system"?

PowerShell has security restrictions on script execution. Run this command:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### How do I find my HomeBrew device IP address?

**Method 1: Network Scan**
```powershell
# Scan your local network
nmap -sn 192.168.1.0/24

# Look for HomeBrew devices (MAC prefix: 00:1A:2B:xx:xx:xx)
```

**Method 2: Router Check**
- Access your router's admin interface
- Check DHCP client list for HomeBrew device
- Look for MAC prefix: `00:1A:2B`

**Method 3: Run Diagnostic Tool**
```powershell
# The Network module will discover your device automatically
.\Run-Diagnostics.ps1 -Module Network
```

---

## Device Configuration

### What is the default HomeBrew device IP address?

The default is **192.168.1.100:2000**, but your device may have a different IP address. Use the discovery methods above to find it.

### What telnet port should I use?

**Port 2000** is the standard HomeBrew telnet port for telescope communication. Some devices may use alternative ports like 2001 or 23.

### How do I configure the serial port for Celestron connection?

**Automatic Detection:**
```powershell
# List available COM ports
python -c "import serial; print([p.device for p in serial.tools.list_ports.comports()])"
```

**Manual Configuration:**
```yaml
# Edit config/diagnostics.yaml
diagnostics:
  device:
    serial_port: "COM3"  # Replace with your port
```

### What baud rate should I use for Celestron communication?

**9600 baud** is the standard Celestron Evolution baud rate. The tool also supports 19200 and 38400 baud as alternatives.

---

## Python Integration

### Why are Python scripts failing?

**Common Python Issues:**

1. **Python not in PATH:**
   ```powershell
   # Try different Python commands
   python --version
   py --version
   python3 --version
   ```

2. **Missing required packages:**
   ```powershell
   # Install required packages
   pip install serial
   pip install pyserial
   ```

3. **Python version too old:**
   - Requires Python 3.6 or later
   - Download latest Python from python.org

### How do I specify a different Python path?

```powershell
# Use command line parameter
.\Run-Diagnostics.ps1 -PythonPath "C:\Python311\python.exe"

# Or edit config/diagnostics.yaml
diagnostics:
  python:
    path: "C:\Python311\python.exe"
```

### What Python packages are required?

- **serial** - Serial communication with Celestron mounts
- **telnetlib** - Telnet connectivity testing
- **json** - JSON output processing
- **argparse** - Command-line argument parsing
- **socket** - Network connectivity testing

---

## Communication Issues

### Device not responding to ping

**Troubleshooting Steps:**

1. **Check device power:**
   - Verify power LED is on
   - Check power supply voltage

2. **Verify network connection:**
   ```powershell
   # Test network connectivity
   ping 192.168.1.100
   
   # Check specific port
   Test-NetConnection -ComputerName 192.168.1.100 -Port 2000
   ```

3. **Check network configuration:**
   - Ensure device and computer are on same network
   - Check for IP address conflicts
   - Verify subnet mask compatibility

### Telnet connection fails

**Common Telnet Issues:**

1. **Firewall blocking port 2000:**
   ```powershell
   # Check firewall rules
   Get-NetFirewallRule | Where-Object { $_.DisplayName -like "*2000*" }
   ```

2. **Wrong IP address:**
   - Use network discovery to find correct IP
   - Check router DHCP client list

3. **Device not configured for telnet:**
   - Verify device firmware supports telnet
   - Check device configuration settings

### Serial communication not working

**Serial Troubleshooting:**

1. **Verify COM port:**
   ```powershell
   # List available ports
   python -c "import serial; print([p.device for p in serial.tools.list_ports.comports()])"
   ```

2. **Check cable connections:**
   - Ensure Celestron cable is firmly connected
   - Try different USB-to-serial adapter
   - Test cable with another serial device

3. **Try different baud rates:**
   ```powershell
   # Test 9600 baud (standard)
   python python_scripts/telescope_comm.py --serial COM3 --baud 9600
   
   # Test 19200 baud (alternative)
   python python_scripts/telescope_comm.py --serial COM3 --baud 19200
   ```

---

## WiFi/BT/GPS Issues

### WiFi module not working

**WiFi Troubleshooting:**

1. **Check device WiFi status:**
   ```powershell
   # Test WiFi module specifically
   python python_scripts/wifi_bt_gps_test.py --host 192.168.1.100 --wifi-only
   ```

2. **Verify network settings:**
   - Check device WiFi configuration
   - Verify network credentials
   - Test with known working WiFi network

3. **Check wireless interference:**
   - Look for competing networks on same channel
   - Check for electronic interference
   - Verify antenna connections

### Bluetooth module issues

**Bluetooth Troubleshooting:**

1. **Verify Bluetooth capability:**
   ```powershell
   # Test Bluetooth module
   python python_scripts/wifi_bt_gps_test.py --host 192.168.1.100 --bluetooth-only
   ```

2. **Check system Bluetooth:**
   ```powershell
   # Check Windows Bluetooth services
   Get-PnpDevice | Where-Object { $_.FriendlyName -like "*Bluetooth*" }
   ```

3. **Test pairing:**
   - Try pairing device with computer
   - Check Bluetooth PIN settings
   - Verify device is discoverable

### GPS module not functioning

**GPS Troubleshooting:**

1. **Check GPS signal:**
   ```powershell
   # Test GPS module
   python python_scripts/wifi_bt_gps_test.py --host 192.168.1.100 --gps-only
   ```

2. **Verify location:**
   - Ensure clear sky view (no obstructions)
   - Check GPS antenna connection
   - Wait for GPS fix (can take several minutes)

3. **Test GPS externally:**
   - Use smartphone GPS to verify location services
   - Check if GPS works with other software

---

## Reporting and Output

### Where are the reports saved?

Reports are saved to the `output/` directory:
```
output/
├── reports/
│   ├── telescope_diagnostic_2025-12-09_143022.html
│   ├── telescope_diagnostic_2025-12-09_143022.json
│   └── telescope_diagnostic_2025-12-09_143022.txt
└── logs/
    ├── telescope_diagnostics.log
    ├── network_diagnostics.log
    └── communication_diagnostics.log
```

### How do I change the report format?

```powershell
# HTML report (default)
.\Run-Diagnostics.ps1 -OutputFormat HTML

# JSON report for automation
.\Run-Diagnostics.ps1 -OutputFormat JSON

# Text report for console
.\Run-Diagnostics.ps1 -OutputFormat Text

# All formats
.\Run-Diagnostics.ps1 -OutputFormat All
```

### What do the HTML report colors mean?

- **Green**: Tests passed successfully
- **Yellow**: Warnings or minor issues
- **Red**: Critical failures or errors
- **Blue**: Informational messages
- **Gray**: Skipped or not applicable tests

### How do I interpret the JSON output?

The JSON output provides structured data for automation:

```json
{
  "Telescope": {
    "Results": {
      "TelnetConnectivity": {
        "Status": "Pass",
        "ResponseTime": 45
      }
    }
  }
}
```

---

## Advanced Usage

### Can I run individual modules only?

```powershell
# Run only telescope diagnostics
.\Run-Diagnostics.ps1 -Module Telescope -DeviceIP 192.168.1.100

# Run specific modules
.\Run-Diagnostics.ps1 -Module Telescope,Communication -DeviceIP 192.168.1.100
```

### How do I use custom configuration?

```powershell
# Use custom configuration file
.\Run-Diagnostics.ps1 -ConfigPath custom_config.yaml

# Create custom configuration
notepad config/my_telescope.yaml
```

### Can I automate this tool?

Yes, the tool supports automation:

```powershell
# Scheduled execution
schtasks /create /tn "Telescope Monitor" /tr "powershell.exe -File telescope_monitor.ps1" /sc hourly

# Automated monitoring script
$deviceIP = "192.168.1.100"
$result = .\Run-Diagnostics.ps1 -DeviceIP $deviceIP -OutputFormat JSON
if ($result.Telescope.Status -eq "Fail") {
    Send-MailMessage -To "admin@example.com" -Subject "Telescope Alert" -Body "Device $deviceIP has issues"
}
```

### How do I compare diagnostic results over time?

```powershell
# Generate baseline
.\Run-Diagnostics.ps1 -DeviceIP 192.168.1.100 -OutputFormat JSON -BaselineFile baseline.json

# Later comparison
.\Run-Diagnostics.ps1 -DeviceIP 192.168.1.100 -BaselineComparison baseline.json
```

---

## Error Messages

### "Python installation not found"

**Solutions:**
1. Install Python 3.6+ from python.org
2. Add Python to system PATH
3. Specify Python path explicitly:
   ```powershell
   .\Run-Diagnostics.ps1 -PythonPath "C:\Python311\python.exe"
   ```

### "Device IP address not reachable"

**Solutions:**
1. Verify device IP address:
   ```powershell
   ping 192.168.1.100
   ```
2. Check network connectivity
3. Use network discovery:
   ```powershell
   .\Run-Diagnostics.ps1 -Module Network
   ```

### "Serial port not available"

**Solutions:**
1. Check available ports:
   ```powershell
   python -c "import serial; print([p.device for p in serial.tools.list_ports.comports()])"
   ```
2. Verify Celestron cable connection
3. Try different COM port numbers
4. Install USB-to-serial drivers if needed

### "Telnet connection timeout"

**Solutions:**
1. Check if device supports telnet on port 2000
2. Verify firewall settings allow port 2000
3. Try alternative ports (2001, 23)
4. Check device network configuration

### "Permission denied"

**Solutions:**
1. Run PowerShell as Administrator
2. Check PowerShell execution policy:
   ```powershell
   Get-ExecutionPolicy
   Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```
3. Verify file/folder permissions

---

## Hardware Compatibility

### What HomeBrew devices are supported?

- **HomeBrew Gen3 PCB** WiFi/BT/GPS/MUSBA relay devices
- Devices with **telnet port 2000** support
- **Firmware v2.x+** recommended

### What Celestron mounts are supported?

- **Celestron Evolution** series mounts
- **Celestron NexStar** compatible mounts
- Mounts supporting **9600 baud serial communication**

### Can I use this with other telescope mounts?

The tool is optimized for Celestron protocols, but may work with:
- **Meade LX200** compatible mounts (with protocol adjustments)
- **SynScan** mounts (with configuration changes)
- **Other mounts** using similar serial protocols

### What about USB-to-serial adapters?

**Supported USB-to-serial adapters:**
- **Prolific PL2303** based adapters
- **FTDI FT232** based adapters  
- **CH340/CH341** based adapters
- **Most standard USB-to-serial adapters**

**Driver Requirements:**
- Install drivers from adapter manufacturer's website
- Windows should automatically detect most adapters

---

## Performance and Optimization

### The diagnostic is running slowly

**Optimization Tips:**

1. **Increase timeouts for slow networks:**
   ```yaml
   diagnostics:
     device:
       timeout_seconds: 60
   ```

2. **Disable unnecessary modules:**
   ```yaml
   enabled_modules:
     - "Telescope"
     - "Communication"
     - "Network"
   ```

3. **Use faster network connection:**
   - Ethernet instead of WiFi when possible
   - Ensure stable network connection

### How often should I run diagnostics?

**Recommended Schedule:**
- **Daily**: Quick health check during observations
- **Weekly**: Full diagnostic run for maintenance
- **Monthly**: Comprehensive baseline establishment
- **After firmware updates**: Complete verification

### Can I run this during telescope operation?

**Yes, but with considerations:**
- **Non-invasive**: Tool doesn't interfere with telescope operation
- **Network impact**: Minimal network traffic generated
- **Mount communication**: Doesn't disrupt active GoTo commands
- **Recommendation**: Run during setup or maintenance windows

---

## Troubleshooting Resources

### Where can I get additional help?

- **GitHub Issues**: [Report bugs and feature requests](https://github.com/NickNak86/HomeBrew-Telescope-Diagnostic-Tool/issues)
- **Cloudy Nights Forum**: [Community support and discussion](https://www.cloudynights.com/forums/)
- **Email Support**: Check documentation for contact information

### How do I collect diagnostic information for support?

```powershell
# Generate comprehensive support package
.\Run-Diagnostics.ps1 -DeviceIP 192.168.1.100 -OutputFormat All -SupportPackage

# This creates:
# - Full diagnostic report
# - System information
# - Configuration files
# - Log files
# - All in a zip file for easy sharing
```

### What information should I include when reporting issues?

1. **HomeBrew device model and firmware version**
2. **Celestron mount model and firmware version**
3. **Windows version and PowerShell version**
4. **Python version and installation method**
5. **Network configuration (IP ranges, subnet masks)**
6. **Error messages and log file excerpts**
7. **Steps to reproduce the issue**

---

## Best Practices

### Regular Maintenance

1. **Weekly health checks** during telescope setup
2. **Monthly comprehensive diagnostics** for baseline comparison
3. **Firmware update verification** after HomeBrew device updates
4. **Cable connection inspection** during regular maintenance

### Documentation

1. **Save baseline reports** for performance comparison
2. **Document configuration changes** for troubleshooting
3. **Keep firmware version history** for regression tracking
4. **Maintain network diagram** for complex setups

### Backup and Recovery

1. **Backup configuration files** before making changes
2. **Save diagnostic reports** for trend analysis
3. **Document custom scripts** and modifications
4. **Keep recovery procedures** easily accessible

---

**🌟 Still have questions? Check the [Getting Started Guide](GETTING_STARTED.md), [Configuration Guide](CONFIGURATION.md), or [Troubleshooting Guide](TROUBLESHOOTING.md) for more detailed information! 🌟**