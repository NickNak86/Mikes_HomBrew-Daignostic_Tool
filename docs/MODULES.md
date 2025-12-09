# Diagnostic Modules Reference

## Overview

The HomeBrew Telescope Diagnostic Tool includes 8 specialized diagnostic modules, each focusing on specific aspects of HomeBrew Gen3 PCB device functionality with Celestron Evolution mounts.

## Module Architecture

### Core Telescope Modules

#### 1. Telescope Module (`Telescope-Diagnostics.ps1`)
**Purpose**: Primary telescope communication and module testing

**Functions**:
- `Test-TelescopeCommunication` - Test telnet and serial communication with Celestron mounts
- `Test-WiFiBTGPSModules` - Comprehensive wireless module testing
- `Invoke-PythonTelescopeScripts` - Execute Python scripts for advanced telescope testing
- `Get-TelescopeDeviceInfo` - Retrieve device firmware and status information

**Key Features**:
- Telnet connectivity testing (port 2000)
- Serial communication at 9600 baud (Celestron standard)
- WiFi/BT/GPS module functionality testing
- Python script integration for advanced protocols
- Celestron NexStar command testing

**Usage**:
```powershell
.\Run-Diagnostics.ps1 -Module Telescope -DeviceIP 192.168.1.100
```

**Output Data**:
- Telnet connection status and response times
- Serial port availability and communication test results
- WiFi/BT/GPS module status and signal strength
- Python script execution results
- Device firmware version and capabilities

---

#### 2. Communication Module (`Communication-Diagnostics.ps1`)
**Purpose**: Protocol testing and Celestron command validation

**Functions**:
- `Test-TelnetProtocol` - Test telnet port 2000 connectivity and response
- `Test-SerialCommunication` - Test serial port communication with Celestron mounts
- `Test-CelestronCommands` - Execute standard NexStar protocol commands
- `Test-ProtocolHandshake` - Validate device communication protocols

**Key Features**:
- Telnet protocol compliance testing
- Serial communication at multiple baud rates
- Celestron NexStar command set validation
- Protocol handshake and authentication testing
- Command response time measurements

**Usage**:
```powershell
.\Run-Diagnostics.ps1 -Module Communication -DeviceIP 192.168.1.100 -SerialPort COM3
```

**Output Data**:
- Telnet connection establishment results
- Serial port configuration and test results
- Celestron command response validation
- Protocol timing and reliability metrics
- Communication error rates and statistics

---

#### 3. Network Module (`Network-Diagnostics.ps1`)
**Purpose**: Network connectivity and device discovery

**Functions**:
- `Test-NetworkConnectivity` - Basic network connectivity tests
- `Test-PortConnectivity` - Specific port testing (2000, etc.)
- `Test-WiFiConnectivity` - WiFi network analysis and connection testing
- `Get-NetworkInterfaceInfo` - Network adapter and configuration analysis

**Key Features**:
- ICMP ping testing to HomeBrew devices
- Port connectivity validation (telnet, HTTP, etc.)
- WiFi network scanning and analysis
- Network interface capability testing
- Bandwidth and latency measurements

**Usage**:
```powershell
.\Run-Diagnostics.ps1 -Module Network -DeviceIP 192.168.1.100
```

**Output Data**:
- Network connectivity status and response times
- Port availability and accessibility results
- WiFi network information and signal strength
- Network adapter configuration details
- Connection reliability and error statistics

---

#### 4. System Module (`System-Diagnostics.ps1`)
**Purpose**: Python environment and system compatibility

**Functions**:
- `Test-PythonInstallation` - Verify Python installation and version
- `Test-PythonModules` - Check required Python packages (serial, telnetlib)
- `Get-SystemCompatibility` - System requirements and compatibility analysis
- `Test-AdministratorPrivileges` - Check for required administrator access

**Key Features**:
- Python version validation (3.6+ required)
- Required package verification (serial, telnetlib, json, argparse)
- PowerShell version compatibility checking
- Administrator privilege detection
- System resource availability analysis

**Usage**:
```powershell
.\Run-Diagnostics.ps1 -Module System
```

**Output Data**:
- Python installation status and version
- Required package availability
- System compatibility assessment
- Administrator privilege status
- PowerShell execution environment details

---

### Supporting Modules

#### 5. Hardware Module (`Hardware-Diagnostics.ps1`)
**Purpose**: Basic hardware capability assessment

**Functions**:
- `Get-HardwareInfo` - Basic system hardware information
- `Test-USBPorts` - USB port availability and functionality
- `Test-SerialPorts` - Serial port enumeration and basic testing

**Key Features**:
- System hardware profile generation
- USB device enumeration
- Serial port detection and listing
- Basic connectivity verification

**Status**: Basic implementation - expands based on user requirements

---

#### 6. Performance Module (`Performance-Diagnostics.ps1`)
**Purpose**: System performance and resource monitoring

**Functions**:
- `Get-SystemPerformance` - CPU, memory, and disk usage analysis
- `Test-NetworkPerformance` - Network bandwidth and latency testing
- `Get-ProcessList` - Running process analysis

**Key Features**:
- Real-time system resource monitoring
- Network performance baseline testing
- Process impact assessment
- Performance bottleneck identification

**Status**: Basic implementation - focuses on telescope operation impact

---

#### 7. Services Module (`Services-Diagnostics.ps1`)
**Purpose**: Windows services and dependencies

**Functions**:
- `Get-WindowsServices` - Service status and dependency analysis
- `Test-ServiceDependencies` - Required service availability

**Key Features**:
- Windows service status verification
- Service dependency mapping
- Startup type analysis
- Service impact assessment

**Status**: Basic implementation - minimal telescope impact assessment

---

#### 8. Security Module (`Security-Diagnostics.ps1`)
**Purpose**: Basic security configuration analysis

**Functions**:
- `Get-SecurityStatus` - Basic security configuration assessment
- `Test-FirewallSettings` - Firewall rule analysis for telescope communication

**Key Features**:
- Windows firewall rule verification
- Network security baseline assessment
- Access control evaluation
- Security policy compliance checking

**Status**: Basic implementation - focuses on telescope communication security

---

## Module Configuration

### Configuration File Structure

Edit `config/diagnostics.yaml` to customize module behavior:

```yaml
modules:
  telescope:
    python_path: "python"           # Python executable
    timeout_seconds: 30             # Communication timeout
    retry_attempts: 3               # Connection retry count
    
  communication:
    telnet_timeout: 15              # Telnet connection timeout
    serial_baud_rate: 9600          # Celestron standard baud rate
    command_timeout: 5              # Command response timeout
    
  network:
    ping_timeout: 3000              # Ping timeout (milliseconds)
    port_scan_timeout: 1000         # Port scan timeout
    wifi_scan_duration: 10          # WiFi scan duration (seconds)
    
  system:
    python_version_min: "3.6"       # Minimum Python version
    check_admin_privileges: true    # Verify administrator access
    
enabled_modules:
  - "Telescope"
  - "Communication" 
  - "Network"
  - "System"
  # - "Hardware"
  # - "Performance" 
  # - "Services"
  # - "Security"
```

### Module Execution Order

1. **System Module** - Always runs first (Python requirements)
2. **Network Module** - Connectivity verification
3. **Communication Module** - Protocol testing
4. **Telescope Module** - Advanced telescope testing
5. **Supporting Modules** - Hardware, Performance, Services, Security

### Individual Module Usage

```powershell
# Run specific module only
.\Run-Diagnostics.ps1 -Module Telescope -DeviceIP 192.168.1.100

# Run multiple specific modules  
.\Run-Diagnostics.ps1 -Module Telescope,Communication -DeviceIP 192.168.1.100

# Run with custom configuration
.\Run-Diagnostics.ps1 -Module Network -DeviceIP 192.168.1.100 -ConfigPath custom.yaml

# Generate report from existing data
.\Run-Diagnostics.ps1 -Module Telescope -ReportOnly
```

## Module Output Structure

### Standard Output Format

Each module returns a standardized result object:

```powershell
@{
    ModuleName = "Telescope"
    Status = "Success|Warning|Error"
    ExecutionTime = (Get-Date)
    Duration = [TimeSpan]
    Results = @{
        Tests = @(
            @{
                Name = "Telnet Connectivity"
                Status = "Pass|Fail|Warning"
                Details = "Connection successful"
                Data = @{ /* test-specific data */ }
            }
        )
        Summary = @{
            TotalTests = 8
            Passed = 7
            Failed = 0
            Warnings = 1
        }
        Metadata = @{
            DeviceIP = "192.168.1.100"
            ModuleVersion = "2.0.0"
            ExecutionEnvironment = @{ /* environment info */ }
        }
    }
    Errors = @()  # Array of error messages
    Warnings = @() # Array of warning messages
}
```

### Report Integration

Module results are automatically integrated into:
- **HTML Reports** - Visual status indicators and detailed results
- **JSON Reports** - Structured data for automation and analysis  
- **Text Reports** - Console-friendly summary format
- **Log Files** - Detailed execution logs for troubleshooting

## Error Handling

### Module-Level Error Handling

- **Try/Catch Blocks** - All critical operations wrapped in error handling
- **Graceful Degradation** - Partial failures don't stop entire diagnostic run
- **Detailed Logging** - All errors logged with context and recommendations
- **Recovery Actions** - Automatic retry logic for transient failures

### Common Error Scenarios

1. **Device Not Responding**
   - Module: Network, Communication, Telescope
   - Action: Retry with increased timeout, verify IP address
   - User Guidance: Check device power, network connection

2. **Python Not Available**
   - Module: System, Telescope  
   - Action: Install Python, update PATH, use alternate Python path
   - User Guidance: Install Python 3.6+ from python.org

3. **Serial Port Issues**
   - Module: Communication, Telescope
   - Action: List available ports, try different baud rates
   - User Guidance: Verify cable connections, check COM port numbers

4. **Permission Issues**
   - Module: System, Network
   - Action: Request administrator privileges, check execution policy
   - User Guidance: Run as Administrator, set PowerShell execution policy

## Module Development

### Adding New Tests

Each module follows a consistent pattern:

```powershell
function Test-NewFeature {
    param(
        [string]$DeviceIP,
        [int]$TimeoutSeconds = 30
    )
    
    $result = @{
        Name = "New Feature Test"
        Status = "Pass"
        Details = "Test completed successfully"
        Data = @{}
        ExecutionTime = Get-Date
    }
    
    try {
        # Test implementation
        $testData = Invoke-TestOperation -DeviceIP $DeviceIP -Timeout $TimeoutSeconds
        $result.Data = $testData
        
        # Update status based on results
        if ($testData.Success) {
            $result.Status = "Pass"
            $result.Details = "New feature working correctly"
        } else {
            $result.Status = "Fail" 
            $result.Details = "New feature test failed: $($testData.Error)"
        }
        
    } catch {
        $result.Status = "Error"
        $result.Details = "Test execution failed: $($_.Exception.Message)"
        Write-Error "New feature test failed: $_"
    }
    
    return $result
}
```

### Module Standards

- **Consistent Naming** - Verb-Noun pattern (Test-*, Get-*, Invoke-*)
- **Parameter Validation** - Validate all input parameters
- **Error Handling** - Wrap all operations in try/catch blocks
- **Logging** - Use Write-Verbose for detailed information
- **Return Format** - Consistent result object structure
- **Documentation** - Comment-based help for all functions

---

**🌟 Each module is designed to be independent yet integrate seamlessly into the complete telescope diagnostic workflow! 🌟**