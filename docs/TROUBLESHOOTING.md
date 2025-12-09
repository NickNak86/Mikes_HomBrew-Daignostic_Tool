# HomeBrew Telescope Diagnostic Tool - Troubleshooting Guide

## Common Issues and Solutions

### Connection Issues

#### Device Not Responding
**Symptoms:**
- Device doesn't show up in network scans
- Telnet connection fails
- Ping timeouts

**Solutions:**
1. **Check Power Supply**
   - Verify HomeBrew device is powered on (12V DC)
   - Check power LED status indicators
   - Try different power adapter

2. **Network Configuration**
   - Ensure device is on same subnet
   - Check router DHCP client list
   - Try assigning static IP address

3. **Test Connectivity**
   ```powershell
   # Basic network test
   ping 192.168.1.100
   
   # Port test
   Test-NetConnection -ComputerName 192.168.1.100 -Port 2000
   
   # Full network diagnostic
   .\Run-Diagnostics.ps1 -Module Network -DeviceIP 192.168.1.100
   ```

#### Telnet Port Issues
**Symptoms:**
- Port 2000 not accessible
- Connection refused errors
- Timeout errors

**Solutions:**
1. **Verify Port Settings**
   - Check device configuration for correct port
   - Try alternative ports (23, 2001, 2002)
   - Verify firewall settings

2. **Test Different Connection Methods**
   ```powershell
   # Manual telnet test
   telnet 192.168.1.100 2000
   
   # Test with Python script
   python python_scripts/telescope_comm.py --host 192.168.1.100 --port 2000
   ```

### Python Script Issues

#### Python Not Found
**Symptoms:**
- "python is not recognized" errors
- Python scripts fail to execute

**Solutions:**
1. **Install Python**
   - Download from [python.org](https://python.org)
   - **Important**: Check "Add Python to PATH" during installation
   - Restart PowerShell after installation

2. **Alternative Python Launcher**
   ```powershell
   # Try py launcher instead of python
   py --version
   
   # Update diagnostic script to use py
   .\Run-Diagnostics.ps1 -PythonPath py
   ```

3. **Verify Python Installation**
   ```powershell
   # Check Python availability
   python --version
   py --version
   
   # Check PATH environment variable
   $env:PATH -split ';' | Where-Object { $_ -like "*Python*" }
   ```

#### Python Module Import Errors
**Symptoms:**
- "ModuleNotFoundError" for serial, telnetlib, etc.
- Script execution fails partway through

**Solutions:**
1. **Install Required Packages**
   ```powershell
   # Install via pip
   pip install pyserial
   
   # Or use Python launcher
   py -m pip install pyserial
   ```

2. **Test Individual Modules**
   ```powershell
   # Test Python installation
   python -c "import serial; print('Serial module OK')"
   python -c "import telnetlib; print('Telnet module OK')"
   python -c "import json; print('JSON module OK')"
   ```

### Serial Communication Issues

#### No Serial Port Detected
**Symptoms:**
- COM port not found
- Serial connection tests fail

**Solutions:**
1. **Check Available Ports**
   ```powershell
   # List all available COM ports
   python -c "import serial; import serial.tools.list_ports; [print(p.device) for p in serial.tools.list_ports.comports()]"
   ```

2. **Install USB-to-Serial Drivers**
   - Download drivers for your USB-to-serial adapter
   - Common chip types: CP2102, CH340, FTDI
   - Check Device Manager for device recognition

3. **Manual Port Specification**
   ```powershell
   # Test with specific port
   .\Run-Diagnostics.ps1 -SerialPort COM5 -DeviceIP 192.168.1.100
   
   # Test Python script directly
   python python_scripts/telescope_comm.py --serial COM5
   ```

#### Mount Not Responding
**Symptoms:**
- Celestron commands time out
- No response to basic commands
- Mount status unavailable

**Solutions:**
1. **Check Celestron Cable**
   - Verify serial cable connections
   - Check cable continuity with multimeter
   - Try different serial cable

2. **Verify Mount Settings**
   - Ensure mount is powered on
   - Check mount hand controller connections
   - Try manual mount controls

3. **Test Protocol Communication**
   ```powershell
   # Run communication diagnostics
   .\Run-Diagnostics.ps1 -Module Communication -SerialPort COM3
   
   # Test direct Python script
   python python_scripts/telescope_comm.py --serial COM3 --test
   ```

### WiFi/BT/GPS Module Issues

#### WiFi Module Not Working
**Symptoms:**
- WiFi scan returns no results
- WiFi connection fails
- Internet connectivity test fails

**Solutions:**
1. **Check Module Status**
   ```powershell
   # Run WiFi/BT/GPS test script
   python python_scripts/wifi_bt_gps_test.py --host 192.168.1.100 --verbose
   ```

2. **Verify Network Configuration**
   - Check WiFi router settings
   - Ensure HomeBrew device WiFi is enabled
   - Try different WiFi network

3. **Check Firmware**
   - Verify HomeBrew device firmware version
   - Update firmware if needed
   - Reset WiFi settings to defaults

#### Bluetooth Issues
**Symptoms:**
- BT scan returns no devices
- Pairing fails
- BT connection unstable

**Solutions:**
1. **Enable BT on Device**
   - Check HomeBrew device BT enable switch
   - Verify BT module power status
   - Try BT reset procedure

2. **Test BT Communication**
   ```powershell
   # Run BT-specific tests
   python python_scripts/wifi_bt_gps_test.py --host 192.168.1.100 --verbose | Select-String "BT"
   ```

#### GPS Module Problems
**Symptoms:**
- No GPS coordinates
- Satellite count zero
- GPS time sync fails

**Solutions:**
1. **Outdoor Testing Required**
   - GPS requires clear sky view
   - Test outdoors or near windows
   - Allow time for satellite acquisition

2. **Verify GPS Module**
   ```powershell
   # Test GPS functionality
   python python_scripts/wifi_bt_gps_test.py --host 192.168.1.100 --verbose | Select-String "GPS"
   ```

### System Compatibility Issues

#### PowerShell Execution Policy
**Symptoms:**
- "cannot be loaded because running scripts is disabled"
- ExecutionPolicy errors

**Solutions:**
```powershell
# Allow script execution for current user
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Or for current session only
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
```

#### Firewall Blocking
**Symptoms:**
- Network tests fail behind firewall
- Communication timeouts
- Access denied errors

**Solutions:**
1. **Windows Firewall**
   ```powershell
   # Add exception for PowerShell
   New-NetFirewallRule -DisplayName "HomeBrew Diagnostic" -Direction Inbound -Program "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -Action Allow
   ```

2. **Corporate Firewall**
   - Contact IT for port 2000 access
   - Use internal IP ranges in config
   - Disable external connectivity checks

#### Antivirus Interference
**Symptoms:**
- Script execution blocked
- Files quarantined
- False positive alerts

**Solutions:**
1. **Add Exceptions**
   - Add HomeBrew diagnostic folder to antivirus exclusions
   - Whitelist Python executable
   - Allow PowerShell script execution

2. **Temporarily Disable**
   - Test with antivirus temporarily disabled
   - Re-enable after successful testing

### Performance Issues

#### Slow Network Response
**Symptoms:**
- Diagnostic tests take too long
- Connection timeouts
- High latency

**Solutions:**
1. **Network Optimization**
   - Check network congestion
   - Verify cable connections
   - Try wired instead of WiFi connection

2. **Adjust Timeout Settings**
   ```powershell
   # Modify config/diagnostics.yaml
   # Increase connection timeouts
   telescope:
     homebrew:
       connection_timeout: 10
   ```

#### High CPU Usage
**Symptoms:**
- PowerShell uses high CPU
- System becomes unresponsive
- Fan noise increases

**Solutions:**
1. **Run Individual Modules**
   ```powershell
   # Test one module at a time
   .\Run-Diagnostics.ps1 -Module Network
   ```

2. **Reduce Verbosity**
   ```powershell
   # Run with minimal output
   .\Run-Diagnostics.ps1 -Module Network -VerboseOutput:$false
   ```

### Report Generation Issues

#### No Reports Created
**Symptoms:**
- No output in output/ directory
- Permission errors
- File system issues

**Solutions:**
1. **Check Permissions**
   ```powershell
   # Verify write access
   Test-Path output -PathType Container
   Get-Acl output
   
   # Try running as Administrator
   ```

2. **Manual Directory Creation**
   ```powershell
   # Create directories manually
   mkdir output\reports
   mkdir output\logs
   
   # Set permissions
   icacls output /grant Users:F /T
   ```

#### HTML Report Won't Open
**Symptoms:**
- Report file created but browser won't display
- Formatting issues
- JavaScript errors

**Solutions:**
1. **Check File Encoding**
   - Ensure UTF-8 encoding
   - Try different browser
   - Check for corrupted files

2. **Alternative Formats**
   ```powershell
   # Generate JSON instead
   .\Run-Diagnostics.ps1 -OutputFormat JSON
   
   # Generate Text report
   .\Run-Diagnostics.ps1 -OutputFormat Text
   ```

### Advanced Troubleshooting

#### Enable Debug Logging
```powershell
# Edit config/diagnostics.yaml
logging:
  level: DEBUG

# Run with verbose output
.\Run-Diagnostics.ps1 -VerboseOutput
```

#### Check System Logs
```powershell
# Review diagnostic logs
Get-Content output\logs\telescope_diagnostics.log -Wait

# Check Windows Event Logs
Get-EventLog -LogName Application -Newest 10
```

#### Network Packet Capture
```powershell
# Install Wireshark for detailed network analysis
# Or use built-in tools
Test-NetConnection -ComputerName 192.168.1.100 -Port 2000 -InformationLevel Detailed
```

### Getting Additional Help

#### GitHub Issues
- Create detailed issue reports
- Include log files
- Specify environment details
- Attach diagnostic reports

#### Community Support
- **Cloudy Nights Forum**: Equipment-specific discussions
- **Telescope Community**: User experiences and solutions
- **Reddit r/telescope**: Community troubleshooting

#### Information to Include
1. **System Information**
   ```powershell
   $PSVersionTable
   Get-ComputerInfo
   python --version
   ```

2. **Network Configuration**
   ```powershell
   ipconfig /all
   route print
   ```

3. **Diagnostic Results**
   - Latest diagnostic report
   - Log files from output/logs/
   - Error messages from console

---

## Quick Reference

### Basic Diagnostic Commands
```powershell
# Full system test
.\Run-Diagnostics.ps1

# Test specific device
.\Run-Diagnostics.ps1 -DeviceIP 192.168.1.100 -SerialPort COM3

# Run individual modules
.\Run-Diagnostics.ps1 -Module Network
.\Run-Diagnostics.ps1 -Module Communication
.\Run-Diagnostics.ps1 -Module Telescope
```

### Python Script Commands
```powershell
# Test telescope communication
python python_scripts/telescope_comm.py --host 192.168.1.100 --json

# Test WiFi/BT/GPS modules
python python_scripts/wifi_bt_gps_test.py --host 192.168.1.100 --verbose
```

### Network Testing
```powershell
# Basic connectivity
ping 192.168.1.100
telnet 192.168.1.100 2000

# PowerShell network test
Test-NetConnection -ComputerName 192.168.1.100 -Port 2000
```

---

**🌟 Remember: The cosmos is worth the troubleshooting! Clear skies and happy debugging! 🌟**