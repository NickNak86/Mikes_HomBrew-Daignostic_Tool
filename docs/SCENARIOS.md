# Diagnostic Scenarios and Use Cases

## Overview

This guide covers real-world telescope diagnostic scenarios, from initial HomeBrew device setup to advanced troubleshooting. Each scenario includes step-by-step procedures, expected outcomes, and troubleshooting guidance.

## Scenario Categories

### 🔧 Setup Scenarios
- **First-time HomeBrew device setup**
- **Network configuration and discovery**
- **Python environment preparation**
- **Celestron mount connection verification**

### 🔍 Troubleshooting Scenarios  
- **Device not responding**
- **Telnet connectivity issues**
- **Serial communication problems**
- **WiFi/BT/GPS module failures**
- **Python script execution errors**

### 📊 Monitoring Scenarios
- **Regular maintenance checks**
- **Performance baseline establishment**
- **Firmware upgrade verification**
- **Long-term health monitoring**

### 🚨 Emergency Scenarios
- **Critical communication failure**
- **Mount control loss**
- **Device firmware corruption**
- **Network isolation incidents**

---

## Setup Scenarios

### Scenario 1: First-time HomeBrew Device Setup

**Context**: New HomeBrew Gen3 PCB device, no previous diagnostic data

**Prerequisites**:
- HomeBrew Gen3 PCB device with power and network connection
- Celestron Evolution telescope mount with serial cable
- Windows 10/11 system with PowerShell 5.1+
- Python 3.6+ installed

#### Step 1: System Preparation

```powershell
# Verify system requirements
.\Run-Diagnostics.ps1 -Module System

# If Python missing, install from python.org
# Verify PowerShell execution policy
Get-ExecutionPolicy
# If Restricted, run:
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**Expected Outcome**: System module reports all requirements met

#### Step 2: Network Discovery

```powershell
# Run network diagnostics to discover device
.\Run-Diagnostics.ps1 -Module Network

# If device not found, scan your network
nmap -sn 192.168.1.0/24

# Or check router DHCP client list for HomeBrew device
# Look for MAC prefix: 00:1A:2B:xx:xx:xx
```

**Expected Outcome**: Device IP identified (e.g., 192.168.1.100)

#### Step 3: Device Connectivity Test

```powershell
# Test basic connectivity to discovered device
ping 192.168.1.100

# Test telnet port accessibility  
telnet 192.168.1.100 2000
```

**Expected Outcome**: Successful ping and telnet connection

#### Step 4: Configuration Update

```powershell
# Update configuration with discovered IP
notepad config/diagnostics.yaml

# Edit device section:
diagnostics:
  device:
    ip: "192.168.1.100"  # Update with your device IP
    serial_port: "COM3"  # Update with your serial port
```

#### Step 5: Full Diagnostic Run

```powershell
# Run complete telescope diagnostic
.\Run-Diagnostics.ps1 -DeviceIP 192.168.1.100

# Review generated reports in output/reports/
```

**Success Criteria**:
- ✓ All 4 core modules (Telescope, Communication, Network, System) pass
- ✓ HTML report generated successfully
- ✓ No critical errors in logs

**Troubleshooting**:
- If device not found: Check network connections and power
- If telnet fails: Verify device IP and port 2000 accessibility
- If Python fails: Install Python 3.6+ from python.org

---

### Scenario 2: Multiple Device Observatory Setup

**Context**: Observatory with multiple HomeBrew devices controlling different telescopes

#### Configuration for Multiple Devices

```yaml
# config/multi_device.yaml
diagnostics:
  device:
    # Will be overridden per device
    timeout_seconds: 45
    
  output:
    filename_prefix: "multi_device_diagnostic"
    include_device_info: true
    
modules:
  network:
    device_discovery_enabled: true
    timeout_per_device: 30
```

#### Device-Specific Diagnostic Scripts

**Script 1: Primary Telescope** (`diagnose_primary.ps1`)
```powershell
$primaryIP = "192.168.1.100"
.\Run-Diagnostics.ps1 -DeviceIP $primaryIP -OutputPrefix "primary_telescope"
```

**Script 2: Secondary Telescope** (`diagnose_secondary.ps1`)
```powershell
$secondaryIP = "192.168.1.101"  
.\Run-Diagnostics.ps1 -DeviceIP $secondaryIP -OutputPrefix "secondary_telescope"
```

**Master Observatory Script** (`observatory_diagnostics.ps1`)
```powershell
$devices = @("192.168.1.100", "192.168.1.101", "192.168.1.102")

foreach ($deviceIP in $devices) {
    Write-Host "Diagnosing device at $deviceIP"
    .\Run-Diagnostics.ps1 -DeviceIP $deviceIP -OutputPrefix "obs_device_$deviceIP"
}

# Generate master report
Get-ChildItem output/reports/obs_device_*.html | 
    ForEach-Object { $_.Name } | 
    Out-File output/reports/observatory_master_report.html
```

---

### Scenario 3: Remote Diagnostic Access

**Context**: Remote telescope control and diagnostic access via VPN or remote desktop

#### Remote Configuration

```powershell
# Configure for remote access
.\Run-Diagnostics.ps1 -DeviceIP 192.168.1.100 -OutputFormat JSON -RemoteAccess

# Results automatically saved to network share
# \\telescope_server\diagnostics\reports\
```

#### Automated Remote Monitoring

```powershell
# PowerShell script for automated remote monitoring
$config = @{
    DeviceIP = "192.168.1.100"
    OutputDir = "\\telescope_server\remote_diagnostics"
    ScheduleInterval = "4h"  # Every 4 hours
}

# Schedule with Windows Task Scheduler
schtasks /create /tn "Telescope Remote Monitor" /tr "powershell.exe -File remote_monitor.ps1" /sc hourly /mo 4
```

---

## Troubleshooting Scenarios

### Scenario 4: Device Not Responding

**Context**: Previously working HomeBrew device suddenly stops responding

#### Initial Assessment

```powershell
# Run system check first
.\Run-Diagnostics.ps1 -Module System

# Check network connectivity
.\Run-Diagnostics.ps1 -Module Network -DeviceIP 192.168.1.100
```

#### Connectivity Investigation

```powershell
# Manual connectivity tests
ping 192.168.1.100

# Check if telnet port is accessible
Test-NetConnection -ComputerName 192.168.1.100 -Port 2000

# Check all common HomeBrew ports
1..2100 | ForEach-Object { 
    $port = $_
    $connection = Test-NetConnection -ComputerName "192.168.1.100" -Port $port -WarningAction SilentlyContinue
    if ($connection.TcpTestSucceeded) {
        Write-Host "Port $port is OPEN"
    }
}
```

#### Device Status Verification

```powershell
# Check device logs
Get-Content output/logs/telescope_diagnostics.log | Select-String "ERROR\|FAIL"

# Review recent reports for patterns
Get-ChildItem output/reports/ -Name | Sort-Object LastWriteTime -Descending | Select-Object -First 5
```

#### Common Causes and Solutions

**Network Issues**:
- **Cause**: Router DHCP changed device IP
- **Solution**: Rescan network, update configuration

**Device Power**:
- **Cause**: Device powered off or power supply issue
- **Solution**: Check device power LED, verify power supply

**Firmware Issues**:
- **Cause**: Device firmware corrupted or outdated
- **Solution**: Device reset, firmware update

---

### Scenario 5: Telnet Connectivity Issues

**Context**: Device responds to ping but telnet on port 2000 fails

#### Telnet-Specific Diagnostics

```powershell
# Detailed telnet testing
.\Run-Diagnostics.ps1 -Module Communication -DeviceIP 192.168.1.100

# Manual telnet testing with timeout
$tcpClient = New-Object System.Net.Sockets.TcpClient
try {
    $tcpClient.Connect("192.168.1.100", 2000)
    Write-Host "Telnet port 2000 is accessible"
    
    # Test protocol handshake
    $stream = $tcpClient.GetStream()
    $writer = New-Object System.IO.StreamWriter($stream)
    $reader = New-Object System.IO.StreamReader($stream)
    
    # Send test command
    $writer.WriteLine("VERSION?`n")
    $writer.Flush()
    
    # Wait for response
    Start-Sleep -Seconds 5
    $response = $reader.ReadLine()
    Write-Host "Device response: $response"
    
} catch {
    Write-Error "Telnet connection failed: $_"
} finally {
    $tcpClient.Close()
}
```

#### Firewall Investigation

```powershell
# Check Windows Firewall rules
Get-NetFirewallRule | Where-Object { 
    $_.DisplayName -like "*telnet*" -or $_.DisplayName -like "*2000*" 
}

# Test with firewall temporarily disabled (for testing only)
# WARNING: Only do this in test environment!
# Disable-NetFirewallRule -DisplayName "All"
```

#### Network Configuration Check

```powershell
# Check network adapter settings
Get-NetAdapter | Where-Object { $_.Status -eq "Up" }

# Test different network paths
Test-NetConnection -ComputerName "192.168.1.100" -Port 2000 -InformationLevel Detailed
```

---

### Scenario 6: Serial Communication Problems

**Context**: Telnet works but serial communication with Celestron mount fails

#### Serial Port Investigation

```powershell
# List available COM ports
python -c "import serial; print([f'{p.device}: {p.description}' for p in serial.tools.list_ports.comports()])"

# Check PowerShell COM port enumeration
Get-WmiObject Win32_SerialPort | Select-Object Name, DeviceID, BaudRate, Status
```

#### Direct Serial Testing

```powershell
# Test serial communication directly
python python_scripts/telescope_comm.py --serial COM3 --baud 9600 --test

# Test different baud rates
python python_scripts/telescope_comm.py --serial COM3 --baud 19200 --test

# Verbose serial testing
python python_scripts/telescope_comm.py --serial COM3 --verbose --test
```

#### Cable and Connection Verification

**Physical Connections**:
- Verify Celestron cable is firmly connected
- Check for loose wires or damaged connectors
- Try different USB-to-serial adapter if using one
- Test cable with known working serial device

**Serial Configuration**:
```yaml
# Test different serial configurations
diagnostics:
  device:
    serial_port: "COM3"
    
modules:
  communication:
    serial_baud_rate: 9600        # Try 19200, 38400
    serial_data_bits: 8           # Try 7
    serial_stop_bits: 1           # Try 2
    serial_parity: "none"         # Try "even", "odd"
```

---

### Scenario 7: WiFi/BT/GPS Module Failures

**Context**: Device networking works but wireless modules not functioning

#### Wireless Module Testing

```powershell
# Run telescope module with wireless focus
.\Run-Diagnostics.ps1 -Module Telescope -DeviceIP 192.168.1.100

# Test wireless modules directly
python python_scripts/wifi_bt_gps_test.py --host 192.168.1.100 --verbose

# Individual module tests
python python_scripts/wifi_bt_gps_test.py --host 192.168.1.100 --wifi-only
python python_scripts/wifi_bt_gps_test.py --host 192.168.1.100 --bluetooth-only  
python python_scripts/wifi_bt_gps_test.py --host 192.168.1.100 --gps-only
```

#### Network Interface Analysis

```powershell
# Check system network interfaces
Get-NetAdapter | Where-Object { $_.PhysicalMediaType -eq "802.11" -or $_.PhysicalMediaType -eq "Bluetooth" }

# Check wireless adapter status
netsh wlan show interfaces

# Test Bluetooth functionality
Get-PnpDevice | Where-Object { $_.FriendlyName -like "*Bluetooth*" }
```

#### HomeBrew Device Wireless Settings

```powershell
# Check device wireless configuration (if accessible via web interface)
# Access device web interface: http://192.168.1.100
# Or via telnet commands:

# Connect to device
telnet 192.168.1.100 2000

# Check wireless status commands (device-specific)
WIFI_STATUS?
BT_STATUS?
GPS_STATUS?
```

---

### Scenario 8: Python Script Execution Errors

**Context**: Python scripts fail to run or produce errors

#### Python Environment Verification

```powershell
# Check Python installation
python --version
py --version

# Verify Python packages
python -c "import serial; print('serial module available')"
python -c "import telnetlib; print('telnetlib module available')" 
python -c "import json; print('json module available')"
python -c "import argparse; print('argparse module available')"
python -c "import socket; print('socket module available')"
```

#### Python Path Configuration

```powershell
# Test different Python paths
.\Run-Diagnostics.ps1 -PythonPath "python" -Module System
.\Run-Diagnostics.ps1 -PythonPath "py" -Module System  
.\Run-Diagnostics.ps1 -PythonPath "C:\Python311\python.exe" -Module System

# Update configuration with working Python path
notepad config/diagnostics.yaml
# Update: diagnostics.python.path: "py"
```

#### Manual Script Testing

```powershell
# Test telescope communication script directly
python python_scripts/telescope_comm.py --help

# Test with verbose output
python python_scripts/telescope_comm.py --host 192.168.1.100 --verbose

# Test WiFi/BT/GPS script directly
python python_scripts/wifi_bt_gps_test.py --help
python python_scripts/wifi_bt_gps_test.py --host 192.168.1.100 --verbose
```

#### Package Installation Issues

```powershell
# Install required packages manually
pip install serial
pip install pyserial  # Alternative package name

# Check Python package installation
pip list | findstr serial
pip list | findstr telnet

# Test package import in Python
python -c "import serial; print(serial.__version__)"
python -c "import telnetlib; print('telnetlib OK')"
```

---

## Monitoring Scenarios

### Scenario 9: Regular Maintenance Checks

**Context**: Scheduled maintenance to ensure optimal telescope performance

#### Weekly Maintenance Routine

```powershell
# Weekly diagnostic script (save as weekly_maintenance.ps1)
$date = Get-Date -Format "yyyy-MM-dd"
Write-Host "Starting weekly telescope maintenance check for $date"

# Run full diagnostics
.\Run-Diagnostics.ps1 -DeviceIP 192.168.1.100 -OutputPrefix "weekly_$date"

# Generate summary report
$reportPath = "output/reports/weekly_$date.html"
if (Test-Path $reportPath) {
    Write-Host "Weekly report generated: $reportPath"
    
    # Check for critical issues
    $content = Get-Content $reportPath -Raw
    if ($content -match "CRITICAL|FAIL") {
        Write-Warning "Critical issues detected in weekly check!"
        # Send email notification or alert
    }
}
```

#### Monthly Performance Baseline

```powershell
# Monthly baseline establishment script
$month = Get-Date -Format "yyyy-MM"
$baselineFile = "output/baselines/monthly_baseline_$month.json"

# Run comprehensive diagnostics
.\Run-Diagnostics.ps1 -DeviceIP 192.168.1.100 -OutputFormat JSON -OutputFile $baselineFile

# Store baseline for comparison
Write-Host "Monthly baseline saved: $baselineFile"
```

#### Performance Trend Analysis

```powershell
# Compare current performance to baseline
$currentReport = "output/reports/telescope_diagnostic_$(Get-Date -Format 'yyyy-MM-dd_HHmmss').json"
$baselineReport = "output/baselines/monthly_baseline_$(Get-Date -Format 'yyyy-MM').json"

if (Test-Path $baselineReport) {
    .\Run-Diagnostics.ps1 -DeviceIP 192.168.1.100 -OutputFile $currentReport -BaselineComparison $baselineReport
}
```

---

### Scenario 10: Firmware Upgrade Verification

**Context**: After HomeBrew device firmware upgrade, verify all functionality

#### Pre-Upgrade Snapshot

```powershell
# Capture pre-upgrade state
$upgradeDate = Get-Date -Format "yyyy-MM-dd_HHmmss"
.\Run-Diagnostics.ps1 -DeviceIP 192.168.1.100 -OutputPrefix "pre_upgrade_$upgradeDate" -OutputFormat All
```

#### Post-Upgrade Verification

```powershell
# Run comprehensive tests after firmware upgrade
.\Run-Diagnostics.ps1 -DeviceIP 192.168.1.100 -OutputPrefix "post_upgrade_$upgradeDate" -OutputFormat All

# Focus on critical functionality
.\Run-Diagnostics.ps1 -DeviceIP 192.168.1.100 -Module Communication
.\Run-Diagnostics.ps1 -DeviceIP 192.168.1.100 -Module Telescope
```

#### Upgrade Success Validation

```powershell
# Compare pre and post upgrade results
$preUpgrade = "output/reports/pre_upgrade_$upgradeDate.json"
$postUpgrade = "output/reports/post_upgrade_$upgradeDate.json"

# Check for regression in key metrics
$preData = Get-Content $preUpgrade | ConvertFrom-Json
$postData = Get-Content $postUpgrade | ConvertFrom-Json

# Compare telescope communication response times
$preResponseTime = $preData.Communication.Results.TelnetConnectivity.ResponseTime
$postResponseTime = $postData.Communication.Results.TelnetConnectivity.ResponseTime

if ($postResponseTime -gt ($preResponseTime * 1.5)) {
    Write-Warning "Communication response time degraded after upgrade!"
}
```

---

### Scenario 11: Long-term Health Monitoring

**Context**: Establish long-term health trends for telescope system

#### Health Metrics Collection

```powershell
# Daily health check script
$date = Get-Date -Format "yyyy-MM-dd"
$healthFile = "output/health/daily_health_$date.json"

# Extract key metrics only
$diagnosticResult = .\Run-Diagnostics.ps1 -DeviceIP 192.168.1.100 -OutputFormat JSON -Quiet

# Extract health metrics
$healthMetrics = @{
    Date = $date
    NetworkLatency = $diagnosticResult.Network.Results.PingTest.ResponseTime
    TelnetAvailability = $diagnosticResult.Communication.Results.TelnetConnectivity.Available
    SerialAvailability = $diagnosticResult.Communication.Results.SerialPort.Available
    WiFiSignalStrength = $diagnosticResult.Telescope.Results.WiFiTest.SignalStrength
    BluetoothStatus = $diagnosticResult.Telescope.Results.BluetoothTest.Status
    GPSStatus = $diagnosticResult.Telescope.Results.GPSTest.Status
    SystemLoad = $diagnosticResult.System.Results.LoadPercentage
}

# Save health metrics
$healthMetrics | ConvertTo-Json -Depth 3 | Out-File $healthFile
```

#### Trend Analysis Script

```powershell
# Monthly trend analysis
$trendScript = {
    param($Month)
    
    $healthFiles = Get-ChildItem "output/health/daily_health_$Month*.json" | Sort-Object Name
    $trendData = @()
    
    foreach ($file in $healthFiles) {
        $data = Get-Content $file.FullName | ConvertFrom-Json
        $trendData += $data
    }
    
    # Calculate trends
    $avgLatency = ($trendData | Measure-Object -Property NetworkLatency -Average).Average
    $avgLoad = ($trendData | Measure-Object -Property SystemLoad -Average).Average
    $wifiStability = ($trendData | Where-Object { $_.WiFiSignalStrength -gt -70 }).Count / $trendData.Count * 100
    
    $trendReport = @{
        Month = $Month
        AverageNetworkLatency = [math]::Round($avgLatency, 2)
        AverageSystemLoad = [math]::Round($avgLoad, 2)
        WiFiStabilityPercent = [math]::Round($wifiStability, 1)
        TotalDays = $trendData.Count
        CriticalEvents = ($trendData | Where-Object { $_.NetworkLatency -gt 100 }).Count
    }
    
    return $trendReport
}

# Generate monthly trend report
$currentMonth = Get-Date -Format "yyyy-MM"
$monthlyTrend = & $trendScript -Month $currentMonth
$monthlyTrend | ConvertTo-Json | Out-File "output/trends/monthly_trend_$currentMonth.json"
```

---

## Emergency Scenarios

### Scenario 12: Critical Communication Failure

**Context**: Complete loss of telescope communication during observation

#### Emergency Diagnostic Protocol

```powershell
# Emergency diagnostic script (save as emergency_diagnostics.ps1)
param(
    [Parameter(Mandatory=$true)]
    [string]$DeviceIP,
    
    [Parameter(Mandatory=$false)]
    [switch]$ForceRestart
)

Write-Host "=== EMERGENCY TELESCOPE DIAGNOSTIC ===" -ForegroundColor Red
Write-Host "Device: $DeviceIP"
Write-Host "Time: $(Get-Date)"
Write-Host ""

# Immediate connectivity test
Write-Host "Testing immediate connectivity..." -ForegroundColor Yellow
$pingResult = Test-Connection -ComputerName $DeviceIP -Count 3 -Quiet

if (-not $pingResult) {
    Write-Host "CRITICAL: Device not responding to ping!" -ForegroundColor Red
    Write-Host "Immediate actions:" -ForegroundColor Yellow
    Write-Host "1. Check device power supply"
    Write-Host "2. Verify network cable connections"
    Write-Host "3. Check router/switch status"
    return
}

# Test critical ports immediately
Write-Host "Testing critical ports..." -ForegroundColor Yellow
$portTest = Test-NetConnection -ComputerName $DeviceIP -Port 2000 -WarningAction SilentlyContinue
if (-not $portTest.TcpTestSucceeded) {
    Write-Host "WARNING: Telnet port 2000 not accessible!" -ForegroundColor Red
}

# Quick diagnostic run
Write-Host "Running emergency diagnostic..." -ForegroundColor Yellow
.\Run-Diagnostics.ps1 -DeviceIP $DeviceIP -Module Communication -OutputPrefix "emergency"

if ($ForceRestart) {
    Write-Host "Forcing device restart (if supported)..." -ForegroundColor Yellow
    # Some devices support restart via telnet
    # telnet commands would be device-specific
}
```

#### Recovery Procedures

**Network Recovery**:
1. Check physical connections
2. Restart network equipment (router, switch)
3. Verify DHCP settings
4. Check for IP conflicts

**Device Recovery**:
1. Power cycle HomeBrew device
2. Check power supply voltage
3. Verify firmware status
4. Factory reset if necessary

**Communication Recovery**:
1. Test with direct serial connection
2. Verify Celestron mount status
3. Check cable connections
4. Try alternative communication methods

---

### Scenario 13: Mount Control Loss

**Context**: Telescope mount stops responding to GoTo commands

#### Mount-Specific Diagnostics

```powershell
# Mount control diagnostic script
param([string]$DeviceIP = "192.168.1.100")

Write-Host "Checking mount control status..." -ForegroundColor Yellow

# Test telescope communication specifically
python python_scripts/telescope_comm.py --host $DeviceIP --mount-test --verbose

# Check mount status via serial (if available)
if (Get-Command python -ErrorAction SilentlyContinue) {
    python python_scripts/telescope_comm.py --serial COM3 --mount-status --verbose
}

# Verify mount mechanical status
Write-Host "Checking mount mechanical status..." -ForegroundColor Yellow
Write-Host "1. Are telescope clutches engaged?"
Write-Host "2. Is mount tracking properly?"
Write-Host "3. Are there any unusual sounds?"
Write-Host "4. Is the mount responding to manual movements?"
```

#### Emergency Mount Procedures

**If Mount Not Responding**:
1. **Stop all GoTo operations immediately**
2. **Check mount power supply**
3. **Verify Celestron cable connections**
4. **Try manual telescope movement**
5. **Check mount alignment status**

**If Mount Moving Erratically**:
1. **Cancel all tracking immediately**
2. **Check for interference or obstruction**
3. **Verify mount firmware version**
4. **Re-initialize mount alignment**

---

### Scenario 14: Network Isolation Incident

**Context**: Telescope system isolated from network, preventing remote access

#### Offline Diagnostic Mode

```powershell
# Offline diagnostic script for network isolation
param(
    [Parameter(Mandatory=$false)]
    [string]$SerialPort = "COM3"
)

Write-Host "=== OFFLINE TELESCOPE DIAGNOSTIC MODE ===" -ForegroundColor Red

# System checks (network-independent)
.\Run-Diagnostics.ps1 -Module System -OfflineMode

# Serial communication test (bypass network)
Write-Host "Testing direct serial communication..." -ForegroundColor Yellow
python python_scripts/telescope_comm.py --serial $SerialPort --offline-test --verbose

# Hardware verification
.\Run-Diagnostics.ps1 -Module Hardware -OfflineMode

# Generate offline report
$offlineReport = "output/reports/offline_diagnostic_$(Get-Date -Format 'yyyy-MM-dd_HHmmss').html"
.\Run-Diagnostics.ps1 -Module System,Hardware -OutputFile $offlineReport -OutputFormat HTML
```

#### Network Recovery Procedures

**Immediate Actions**:
1. Check physical network connections
2. Verify network switch/router status
3. Check for IP address conflicts
4. Test with different network cable

**Alternative Access Methods**:
1. Direct serial communication (bypasses network)
2. USB-to-serial connection
3. Local WiFi hotspot
4. Ethernet crossover cable

---

## Automated Monitoring and Alerts

### Scenario 15: Continuous Monitoring Setup

**Context**: 24/7 observatory monitoring with automated alerts

#### Windows Task Scheduler Setup

```powershell
# Create monitoring tasks
$taskName = "Telescope Monitor"

# Create continuous monitoring task
schtasks /create /tn $taskName /tr "powershell.exe -File telescope_monitor.ps1" /sc minute /mo 5

# Create daily summary task
schtasks /create /tn "Daily Telescope Summary" /tr "powershell.exe -File daily_summary.ps1" /sc daily /st 23:00
```

#### Alert Configuration

```powershell
# Alert thresholds
$alertConfig = @{
    NetworkLatencyThreshold = 100      # milliseconds
    SystemLoadThreshold = 85           # percent
    WiFiSignalThreshold = -80          # dBm
    TemperatureThreshold = 70          # Celsius (if sensor available)
    CriticalFailureThreshold = 3       # consecutive failures
}

# Email alert function
function Send-TelescopeAlert {
    param(
        [string]$AlertType,
        [string]$Message,
        [string]$Severity = "WARNING"
    )
    
    $smtpServer = "smtp.example.com"
    $from = "telescope@observatory.local"
    $to = "admin@observatory.local"
    
    $subject = "[$Severity] Telescope Alert - $AlertType"
    $body = @"
Telescope Alert Details:
Time: $(Get-Date)
Type: $AlertType
Severity: $Severity
Message: $Message
Device: 192.168.1.100
Location: Observatory
"@
    
    Send-MailMessage -SmtpServer $smtpServer -From $from -To $to -Subject $subject -Body $body
}
```

#### Monitoring Script Template

```powershell
# telescope_monitor.ps1
$configPath = "config/monitoring.yaml"
$deviceIP = "192.168.1.100"

try {
    # Run quick health check
    $result = .\Run-Diagnostics.ps1 -DeviceIP $deviceIP -QuickCheck
    
    # Check alerts
    if ($result.Network.Latency -gt 100) {
        Send-TelescopeAlert -AlertType "High Network Latency" -Message "Latency: $($result.Network.Latency)ms"
    }
    
    if ($result.System.Load -gt 85) {
        Send-TelescopeAlert -AlertType "High System Load" -Message "Load: $($result.System.Load)%"
    }
    
    # Log successful check
    $logEntry = "$(Get-Date): Monitoring check completed successfully"
    Add-Content -Path "output/logs/monitoring.log" -Value $logEntry
    
} catch {
    Send-TelescopeAlert -AlertType "Monitoring Failure" -Message "Error: $($_.Exception.Message)" -Severity "CRITICAL"
    Add-Content -Path "output/logs/monitoring.log" -Value "$(Get-Date): ERROR - $($_.Exception.Message)"
}
```

---

## Conclusion

These scenarios provide comprehensive coverage of common telescope diagnostic situations. Each scenario includes:

- **Clear prerequisites and context**
- **Step-by-step procedures**
- **Expected outcomes and success criteria**
- **Detailed troubleshooting guidance**
- **Real-world automation examples**

Choose the scenario that matches your current situation, or use these as templates for developing custom diagnostic procedures for your specific telescope setup.

**🌟 Remember: The best diagnostic scenario is prevention through regular monitoring and maintenance! 🌟**