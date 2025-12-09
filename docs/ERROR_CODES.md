# Error Codes and Troubleshooting Guide

This document provides a comprehensive reference for error codes and common issues encountered when running the HomeBrew Telescope Diagnostic Tool.

## Exit Codes

### Success Codes
- **0**: All diagnostics completed successfully
  - All tests passed
  - Device is fully functional
  - No critical issues detected

### Python Script Exit Codes
- **0**: Script executed successfully
  - Connection established
  - Data collected
  - JSON output generated

- **1**: Script execution failed
  - Connection could not be established
  - Device not accessible
  - Communication error

- **2**: Python environment error
  - Python not installed
  - Required modules missing
  - Unsupported Python version

- **3**: Invalid arguments
  - Required parameters missing
  - Invalid IP address or port
  - Malformed command

- **127**: Command not found
  - Python executable not in PATH
  - Script file not found
  - Invalid script path

## PowerShell Error Codes

### Test-PythonInstallation Exit Codes
- **0**: Python found and valid
  - Python 3.6+ detected
  - All required modules available
  - Ready for script execution

- **1**: Python not found
  - Install from: https://python.org
  - Ensure Python is in system PATH
  - Check Python installation

- **2**: Python version incompatible
  - Python 3.6+ required
  - Current version too old
  - Upgrade Python to version 3.6 or later

- **3**: Required modules missing
  - Missing: serial, telnetlib, json, argparse, socket
  - Install with: `pip install pyserial`
  - See GETTING_STARTED.md for full setup

## Common Error Messages and Solutions

### Device Connection Errors

#### "Connection refused" or "Connection timeout"
**Cause**: HomeBrew device not accessible at specified IP/port

**Solutions**:
1. Verify device IP address is correct
   ```powershell
   ping 192.168.1.100
   ```

2. Check network connectivity
   - Confirm device is powered on
   - Check network cable connection
   - Verify same network as diagnostic tool

3. Confirm port 2000 is accessible
   ```powershell
   Test-NetConnection -ComputerName 192.168.1.100 -Port 2000
   ```

4. Update device IP in configuration
   ```yaml
   diagnostics:
     device:
       ip: "192.168.1.100"
   ```

#### "Serial port not found" or "Port not available"
**Cause**: Serial port doesn't exist or is in use

**Solutions**:
1. List available serial ports
   ```powershell
   [System.IO.Ports.SerialPort]::GetPortNames()
   ```

2. Check if port is in use by another application
   - Close any other serial communication software
   - Restart the port device

3. Verify USB-to-serial adapter is connected
   - Check device manager for COM ports
   - Install adapter drivers if necessary

4. Specify correct serial port
   ```powershell
   .\Run-Diagnostics.ps1 -SerialPort COM3
   ```

### Python Errors

#### "Python not found or not executable"
**Cause**: Python is not installed or not in PATH

**Solutions**:
1. Install Python 3.6+
   - Download from: https://python.org
   - Add Python to PATH during installation
   - Verify with: `python --version`

2. Specify Python path explicitly
   ```yaml
   modules:
     telescope:
       python_path: "C:\\Python311\\python.exe"
   ```

3. Try alternative Python commands
   ```powershell
   python --version
   python3 --version
   py --version
   ```

#### "Missing required Python modules: serial, telnetlib, json, argparse, socket"
**Cause**: One or more Python packages not installed

**Solutions**:
1. Install all required packages
   ```bash
   pip install pyserial
   ```
   
2. Verify installation
   ```bash
   python -m pip list
   ```

3. Install from requirements (if available)
   ```bash
   pip install -r requirements.txt
   ```

#### "Script failed with exit code: 1"
**Cause**: Python script encountered an error during execution

**Solutions**:
1. Run script with verbose output
   ```powershell
   .\Run-Diagnostics.ps1 -Verbose
   ```

2. Run Python script directly for detailed error
   ```bash
   python python_scripts/telescope_comm.py --host 192.168.1.100 --json
   ```

3. Check script logs for error details

### Network Errors

#### "Ping Connectivity: FAIL"
**Cause**: Device is not responding to network requests

**Solutions**:
1. Check device power and network connection
2. Verify device IP address
3. Verify firewall settings allow ICMP
4. Check router/network connectivity

#### "Port 2000 Accessibility: FAIL"
**Cause**: Telnet port is blocked or device not listening

**Solutions**:
1. Verify device is running and configured
2. Check firewall rules
3. Confirm port 2000 is not blocked
4. Test from command line:
   ```powershell
   Test-NetConnection -ComputerName 192.168.1.100 -Port 2000 -Verbose
   ```

#### "WiFi Network Scan: FAIL"
**Cause**: Device WiFi module not responding or disabled

**Solutions**:
1. Verify WiFi module is enabled on device
2. Check device logs for WiFi errors
3. Restart device WiFi module
4. Verify antenna connections

### Timeout Errors

#### "Script execution timeout after X seconds"
**Cause**: Python script took longer than timeout value

**Solutions**:
1. Increase timeout value
   ```powershell
   .\Run-Diagnostics.ps1 -TimeoutSeconds 120
   ```

2. Update in configuration
   ```yaml
   diagnostics:
     python:
       timeout_seconds: 120
   ```

3. Check device performance
   - Device may be slow or busy
   - Check CPU usage on HomeBrew device
   - Reduce network congestion

4. Reduce number of tests
   - Run individual modules instead of all
   - Disable non-critical tests

### File and Permission Errors

#### "Access Denied" or "Permission Denied"
**Cause**: Insufficient permissions to run diagnostic tool

**Solutions**:
1. Run PowerShell as Administrator
2. Check file permissions on scripts
3. Verify UAC is set appropriately
4. Disable execution policy restriction (if safe)
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

#### "Output directory not found"
**Cause**: Report directory doesn't exist or path is invalid

**Solutions**:
1. Create output directory
   ```powershell
   New-Item -ItemType Directory -Path ".\output" -Force
   ```

2. Update configuration with valid path
   ```yaml
   diagnostics:
     output:
       directory: "./output"
   ```

3. Verify path exists before running
   ```powershell
   Test-Path ".\output"
   ```

## Troubleshooting Flowchart

```
Is device accessible via ping?
├─ YES → Is port 2000 open?
│        ├─ YES → Is Python installed?
│        │        ├─ YES → Are required modules available?
│        │        │        ├─ YES → Device is ready (check test results)
│        │        │        └─ NO  → Install missing modules (pip install)
│        │        └─ NO  → Install Python 3.6+
│        └─ NO  → Check firewall/network security
└─ NO  → Check device power and network connection
```

## Quick Diagnostic Steps

If you encounter errors, follow these steps:

1. **Verify Device**: Is device powered on and accessible?
   ```powershell
   ping 192.168.1.100
   ```

2. **Check Network**: Is port 2000 open?
   ```powershell
   Test-NetConnection -ComputerName 192.168.1.100 -Port 2000
   ```

3. **Verify Python**: Is Python installed with required modules?
   ```powershell
   python --version
   python -m pip list
   ```

4. **Run with Verbose**: Get more detailed error information
   ```powershell
   .\Run-Diagnostics.ps1 -Verbose
   ```

5. **Check Logs**: Review detailed logs in output/logs/
   ```powershell
   Get-Content .\output\logs\system_diagnostics.log
   ```

## Common Exit Code Reference

| Code | Meaning | Action |
|------|---------|--------|
| 0 | Success | No action needed |
| 1 | Device/Connection Error | Check device connectivity |
| 2 | Python Error | Install/update Python |
| 3 | Invalid Arguments | Check command parameters |
| 127 | Command Not Found | Check PATH and file locations |
| Timeout | Script Too Slow | Increase timeout or check device |

## Getting Help

If you still encounter issues:

1. **Enable Verbose Logging**
   ```powershell
   .\Run-Diagnostics.ps1 -Verbose
   ```

2. **Check Log Files**
   - Located in: `./output/logs/`
   - Each module has its own log file

3. **Review Documentation**
   - GETTING_STARTED.md - Initial setup
   - TROUBLESHOOTING.md - Known issues
   - MODULES.md - Module reference

4. **Verify Configuration**
   - Check: `config/diagnostics.yaml`
   - Ensure all paths are correct
   - Verify IP addresses and ports

5. **Run Single Module**
   ```powershell
   .\Run-Diagnostics.ps1 -Module Network
   ```

## Recovery Procedures

### Reset to Default Configuration
```powershell
# Backup current config
Copy-Item config\diagnostics.yaml config\diagnostics.yaml.backup

# Edit to default values
# Or copy from default template
```

### Clear Temporary Files
```powershell
# Remove temp files
Remove-Item $env:TEMP\python_*.txt -Force -ErrorAction SilentlyContinue
```

### Restart Services
```powershell
# Restart network service (if applicable)
Restart-Service -Name "Your Service Name" -Force

# Restart device
# Power cycle the HomeBrew device
```

---

**Last Updated**: 2025-12-09
**Tool Version**: 2.0.0
**Compatibility**: Windows 10/11, PowerShell 5.1+, Python 3.6+
