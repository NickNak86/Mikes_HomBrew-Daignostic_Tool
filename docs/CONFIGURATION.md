# Configuration Guide

## Overview

The HomeBrew Telescope Diagnostic Tool uses a YAML-based configuration system to customize diagnostic behavior for your specific telescope setup. This guide covers all configuration options and best practices.

## Configuration File Structure

The main configuration file is located at `config/diagnostics.yaml`. The tool automatically creates this file if it doesn't exist, with sensible defaults for HomeBrew devices and Celestron Evolution mounts.

### Default Configuration

```yaml
diagnostics:
  device:
    ip: "192.168.1.100"        # HomeBrew device IP address
    telnet_port: 2000          # HomeBrew telnet port (standard: 2000)
    serial_port: null          # Celestron serial port (null = auto-detect)
    timeout_seconds: 30        # Connection timeout for all operations
    
  python:
    path: "python"             # Python executable path
    timeout_seconds: 60        # Python script execution timeout
    script_timeout: 30         # Individual Python script timeout
    
  output:
    format: "HTML"             # Default: HTML, JSON, Text, All
    directory: "./output"      # Output directory path
    filename_prefix: "telescope_diagnostic"
    include_timestamp: true    # Add timestamp to filenames
    
  logging:
    level: "INFO"              # DEBUG, INFO, WARNING, ERROR
    directory: "./output/logs" # Log file directory
    max_file_size_mb: 50       # Maximum log file size
    max_files: 10              # Maximum number of log files to keep
    
modules:
  telescope:
    python_path: "python"           # Python executable for telescope scripts
    enable_python_scripts: true     # Run Python telescope communication scripts
    telnet_timeout: 15              # Telnet connection timeout (seconds)
    serial_timeout: 10              # Serial connection timeout (seconds)
    command_timeout: 5              # Celestron command response timeout (seconds)
    retry_attempts: 3               # Connection retry attempts
    
  communication:
    telnet_timeout: 15              # Telnet connection timeout
    serial_baud_rate: 9600          # Celestron standard baud rate
    serial_data_bits: 8             # Data bits (usually 8)
    serial_stop_bits: 1             # Stop bits (usually 1)  
    serial_parity: "none"           # Parity: none, even, odd
    command_timeout: 5              # Celestron command response timeout
    protocol_test_timeout: 30       # Protocol handshake timeout
    
  network:
    ping_timeout: 3000              # ICMP ping timeout (milliseconds)
    port_scan_timeout: 1000         # Individual port scan timeout (milliseconds)
    wifi_scan_duration: 10          # WiFi scan duration (seconds)
    network_adapter_timeout: 5000   # Network adapter detection timeout
    dns_lookup_timeout: 5000        # DNS resolution timeout
    
  system:
    python_version_min: "3.6"       # Minimum required Python version
    check_admin_privileges: true    # Verify administrator access
    check_python_packages: true     # Verify required Python packages
    memory_threshold_mb: 500        # Minimum available memory (MB)
    disk_space_threshold_mb: 100    # Minimum free disk space (MB)
    
  # Supporting modules (basic implementations)
  hardware:
    enabled: false                  # Enable basic hardware diagnostics
    usb_scan_enabled: true         # Scan for USB devices
    serial_port_scan: true         # Enumerate available serial ports
    
  performance:
    enabled: false                  # Enable basic performance monitoring
    cpu_threshold_percent: 90       # CPU usage warning threshold
    memory_threshold_percent: 85    # Memory usage warning threshold
    
  services:
    enabled: false                  # Enable basic Windows services check
    critical_services_only: true    # Check only telescope-critical services
    
  security:
    enabled: false                  # Enable basic security checks
    firewall_check: true           # Check firewall rules for telescope ports
    
enabled_modules:
  - "Telescope"           # Core telescope communication testing
  - "Communication"       # Protocol and Celestron command testing  
  - "Network"             # Network connectivity and device discovery
  - "System"              # Python environment and system compatibility
  # - "Hardware"          # Basic hardware capability assessment
  # - "Performance"       # System performance monitoring
  # - "Services"          # Windows services analysis
  # - "Security"          # Security configuration checking
```

## Device Configuration

### HomeBrew Device Settings

#### IP Address Configuration
```yaml
diagnostics:
  device:
    ip: "192.168.1.150"  # Your HomeBrew device IP address
```
**Finding Your Device IP**:
```powershell
# Scan your local network for HomeBrew devices
nmap -sn 192.168.1.0/24

# Check your router's DHCP client list
# Most HomeBrew devices use MAC prefix: 00:1A:2B:xx:xx:xx
```

#### Telnet Port Configuration  
```yaml
diagnostics:
  device:
    telnet_port: 2000     # Standard HomeBrew telnet port
```
**Common HomeBrew Ports**:
- **2000** - Primary telescope communication port
- **2001** - Alternative communication port
- **23** - Standard telnet port (fallback)

#### Serial Port Configuration
```yaml
diagnostics:
  device:
    serial_port: "COM3"   # Direct Celestron mount connection
```
**Finding Available Serial Ports**:
```powershell
# List all available COM ports
python -c "import serial; print([p.device for p in serial.tools.list_ports.comports()])"

# Or use PowerShell
Get-WmiObject Win32_SerialPort | Select-Object Name, DeviceID, BaudRate
```

**Common Serial Configurations**:
- **COM3, COM4** - USB-to-serial adapters
- **COM1, COM2** - Built-in serial ports (older systems)
- **9600 baud** - Celestron Evolution standard
- **38400 baud** - Alternative Celestron baud rate

### Timeout Configuration

```yaml
diagnostics:
  device:
    timeout_seconds: 45        # General connection timeout
    
  communication:
    telnet_timeout: 20         # Telnet connection timeout
    command_timeout: 8         # Celestron command timeout
    protocol_test_timeout: 45  # Full protocol test timeout
    
  network:
    ping_timeout: 5000         # ICMP ping timeout (milliseconds)
    port_scan_timeout: 2000    # Port scan timeout (milliseconds)
```

**Timeout Guidelines**:
- **Device timeout**: 30-60 seconds (HomeBrew devices can be slow)
- **Telnet timeout**: 10-20 seconds (connection establishment)
- **Command timeout**: 3-8 seconds (Celestron command responses)
- **Network timeout**: 3-10 seconds (ping and port scans)

## Python Configuration

### Python Path Configuration

```yaml
diagnostics:
  python:
    path: "py"              # Use Python launcher (Windows)
    # path: "python3"       # Use Python 3 explicitly
    # path: "C:\\Python311\\python.exe"  # Full path
```

**Python Installation Locations**:
- **"py"** - Windows Python launcher (recommended)
- **"python"** - System Python (if in PATH)
- **"python3"** - Explicit Python 3 (Linux/Mac compatibility)
- **Full path** - Specific Python installation

### Python Timeout Settings

```yaml
diagnostics:
  python:
    timeout_seconds: 90      # Overall Python execution timeout
    script_timeout: 45       # Individual script timeout
```

### Required Python Packages

The tool automatically checks for these packages:
- **serial** - Serial communication with Celestron mounts
- **telnetlib** - Telnet connectivity testing  
- **json** - JSON output processing
- **argparse** - Command-line argument parsing
- **socket** - Network connectivity testing

## Module-Specific Configuration

### Telescope Module Settings

```yaml
modules:
  telescope:
    python_path: "py"                    # Python executable for scripts
    enable_python_scripts: true          # Run telescope communication scripts
    telnet_timeout: 15                   # Telnet connection timeout
    serial_timeout: 12                   # Serial connection timeout  
    command_timeout: 6                   # Celestron command timeout
    retry_attempts: 3                    # Connection retry attempts
    firmware_check_enabled: true         # Check device firmware version
    wifi_test_enabled: true              # Test WiFi module functionality
    bluetooth_test_enabled: true         # Test Bluetooth module functionality
    gps_test_enabled: true               # Test GPS module functionality
```

### Communication Module Settings

```yaml
modules:
  communication:
    telnet_timeout: 18                   # Telnet connection timeout
    serial_baud_rate: 9600               # Celestron Evolution standard
    serial_data_bits: 8                  # Data bits (standard 8)
    serial_stop_bits: 1                  # Stop bits (standard 1)
    serial_parity: "none"                # Parity: none, even, odd
    command_timeout: 7                   # Celestron command timeout
    protocol_test_timeout: 40            # Full protocol test timeout
    retry_attempts: 4                    # Command retry attempts
```

**Alternative Celestron Baud Rates**:
- **9600** - Standard Celestron Evolution
- **19200** - Alternative standard rate
- **38400** - High-speed Celestron communication

### Network Module Settings

```yaml
modules:
  network:
    ping_timeout: 4000                   # ICMP ping timeout (milliseconds)
    port_scan_timeout: 1500              # Individual port timeout
    wifi_scan_duration: 12               # WiFi scan duration (seconds)
    network_adapter_timeout: 6000        # Network adapter timeout
    dns_lookup_timeout: 6000             # DNS resolution timeout
    bandwidth_test_enabled: false        # Bandwidth testing (optional)
```

## Output Configuration

### Report Format Settings

```yaml
diagnostics:
  output:
    format: "All"                        # HTML, JSON, Text, All
    directory: "./output"                # Output directory
    filename_prefix: "telescope_diagnostic"
    include_timestamp: true              # Add timestamp to filenames
    compress_reports: false              # Compress HTML reports
    include_charts: true                 # Include visual charts in HTML
```

**Output Format Options**:
- **"HTML"** - Visual report with charts and troubleshooting
- **"JSON"** - Structured data for automation and analysis
- **"Text"** - Console-friendly text summary  
- **"All"** - Generate all three formats

### Logging Configuration

```yaml
diagnostics:
  logging:
    level: "INFO"                        # DEBUG, INFO, WARNING, ERROR
    directory: "./output/logs"           # Log directory
    max_file_size_mb: 100                # Maximum log file size
    max_files: 20                        # Files to keep
    include_timestamp: true              # Timestamp each log entry
    log_module_separation: true          # Separate logs per module
```

**Logging Levels**:
- **"DEBUG"** - Detailed diagnostic information
- **"INFO"** - General operational information  
- **"WARNING"** - Warning conditions
- **"ERROR"** - Error conditions only

## Module Enable/Disable Configuration

### Core Modules (Recommended)

```yaml
enabled_modules:
  - "Telescope"           # Primary telescope communication testing
  - "Communication"       # Protocol and Celestron command testing
  - "Network"             # Network connectivity testing  
  - "System"              # Python environment verification
```

### Supporting Modules (Optional)

```yaml
# Enable basic hardware diagnostics
enabled_modules:
  - "Telescope"
  - "Communication" 
  - "Network"
  - "System"
  - "Hardware"            # Basic hardware capability assessment
  - "Performance"         # System performance monitoring
  - "Services"            # Windows services analysis  
  - "Security"            # Security configuration checking
```

## Environment-Specific Configuration

### Development Environment

```yaml
diagnostics:
  device:
    ip: "192.168.1.50"    # Development HomeBrew device
    
  logging:
    level: "DEBUG"        # Detailed logging for debugging
    
  output:
    format: "All"         # All formats for comprehensive analysis
```

### Production Environment

```yaml
diagnostics:
  device:
    ip: "192.168.1.100"   # Production HomeBrew device
    
  logging:
    level: "WARNING"      # Minimal logging for production
    
  output:
    format: "HTML"        # Quick visual reports
```

### Automated Testing

```yaml
diagnostics:
  device:
    timeout_seconds: 10   # Faster timeouts for testing
    
  logging:
    level: "ERROR"        # Errors only for CI/CD
    
  output:
    format: "JSON"        # Machine-readable for automation
```

## Configuration File Management

### Creating Custom Configuration

1. **Create custom YAML file**:
```yaml
# custom_telescope_config.yaml
diagnostics:
  device:
    ip: "192.168.1.200"   # Custom device IP
    serial_port: "COM5"   # Custom serial port
    
  python:
    path: "C:\\Python311\\python.exe"
    
  output:
    format: "JSON"        # JSON for automation
```

2. **Use custom configuration**:
```powershell
.\Run-Diagnostics.ps1 -ConfigPath custom_telescope_config.yaml
```

### Configuration Validation

The tool validates configuration on startup:

```powershell
# Test configuration validity
.\Run-Diagnostics.ps1 -ConfigValidationOnly

# Preview configuration without running diagnostics
.\Run-Diagnostics.ps1 -ConfigPreviewOnly
```

### Configuration Inheritance

Create base configurations and override specific settings:

**Base Configuration** (`config/base.yaml`):
```yaml
diagnostics:
  device:
    timeout_seconds: 30
    
modules:
  system:
    python_version_min: "3.6"
```

**Override Configuration** (`config/dev.yaml`):
```yaml
diagnostics:
  device:
    ip: "192.168.1.50"
    
  logging:
    level: "DEBUG"
```

## Troubleshooting Configuration Issues

### Common Configuration Problems

**Invalid YAML Syntax**:
```yaml
# ❌ Incorrect
diagnostics:
  device:
    ip: 192.168.1.100   # Should be quoted
    serial_port: COM3   # Should be quoted

# ✅ Correct  
diagnostics:
  device:
    ip: "192.168.1.100"
    serial_port: "COM3"
```

**Missing Required Sections**:
```yaml
# ❌ Missing device section
diagnostics:
  python:
    path: "python"

# ✅ Complete configuration
diagnostics:
  device:
    ip: "192.168.1.100"
  python:
    path: "python"
```

**Invalid Values**:
```yaml
# ❌ Invalid values
diagnostics:
  output:
    format: "XML"       # Only HTML, JSON, Text, All allowed
    
  modules:
    network:
      ping_timeout: -1000  # Must be positive

# ✅ Valid values
diagnostics:
  output:
    format: "HTML"      # Valid format
    
  modules:
    network:
      ping_timeout: 3000  # Valid timeout
```

### Configuration Debug Commands

```powershell
# Show current configuration
.\Run-Diagnostics.ps1 -ShowConfig

# Validate configuration file
.\Run-Diagnostics.ps1 -ConfigPath config/diagnostics.yaml -ValidateOnly

# Debug configuration loading
.\Run-Diagnostics.ps1 -Verbose -ConfigDebug
```

## Advanced Configuration

### Conditional Configuration

Create environment-specific configurations:

**Production** (`config/prod.yaml`):
```yaml
diagnostics:
  output:
    format: "HTML"
    directory: "./prod_reports"
    
  logging:
    level: "WARNING"
    directory: "./prod_logs"
```

**Testing** (`config/test.yaml`):
```yaml
diagnostics:
  output:
    format: "JSON"
    directory: "./test_reports"
    
  logging:
    level: "DEBUG"
    directory: "./test_logs"
    
  device:
    timeout_seconds: 5     # Faster for testing
```

### Multiple Device Configuration

```yaml
# Multi-device telescope observatory setup
devices:
  primary:
    diagnostics:
      device:
        ip: "192.168.1.100"
        telnet_port: 2000
        
  secondary:
    diagnostics:
      device:
        ip: "192.168.1.101"
        telnet_port: 2000
        
  backup:
    diagnostics:
      device:
        ip: "192.168.1.102"  
        telnet_port: 2000
```

### Template Configuration

Use configuration templates for different scenarios:

**Starter Configuration** (`templates/beginner.yaml`):
```yaml
diagnostics:
  device:
    timeout_seconds: 60     # Extra time for beginners
    serial_port: null       # Auto-detect
    
  output:
    format: "HTML"          # Visual reports
    include_charts: true    # Charts for easy understanding
    
  logging:
    level: "INFO"           # Detailed but not overwhelming
```

**Expert Configuration** (`templates/expert.yaml`):
```yaml
diagnostics:
  device:
    timeout_seconds: 15     # Faster for experienced users
    serial_port: "COM3"     # Fixed port
    
  output:
    format: "JSON"          # Data for analysis
    include_charts: false   # Raw data only
    
  logging:
    level: "DEBUG"          # Maximum detail
```

---

**🌟 Properly configured, your telescope diagnostic tool will provide exactly the level of detail and testing you need for your HomeBrew device setup! 🌟**