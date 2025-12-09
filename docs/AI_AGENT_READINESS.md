# AI Agent Readiness Guide

## Overview
This document serves as a comprehensive guide for AI agents to implement the remaining components of the HomeBrew Diagnostic Tool. It outlines the project structure, coding standards, and specific requirements for each module.

## Project Status
The project is approximately 60% complete. Foundation, documentation, and prototype scripts are in place. The core diagnostic modules, configuration parser, and reporting tools need to be implemented.

## Implementation Checklist

### 1. Configuration Management
- [ ] **src/config/Read-Configuration.ps1**: Parse `config/diagnostics.yaml` and return a hashtable.

### 2. Diagnostic Modules
- [ ] **src/diagnostics/System-Diagnostics.ps1**: Check local system prerequisites (Python, PowerShell version, Admin rights).
- [ ] **src/diagnostics/Hardware-Diagnostics.ps1**: Diagnose hardware status of the HomeBrew device (if possible via telemetry) or local hardware (serial ports).
- [ ] **src/diagnostics/Network-Diagnostics.ps1**: (Existing) Verify connectivity, ports, WiFi. Update if needed.
- [ ] **src/diagnostics/Performance-Diagnostics.ps1**: Measure latency, throughput to the device.
- [ ] **src/diagnostics/Services-Diagnostics.ps1**: Check status of related services (e.g. ASCOM, virtual serial ports).
- [ ] **src/diagnostics/Security-Diagnostics.ps1**: Basic security checks (default credentials check, open ports audit).

### 3. Reporting
- [ ] **src/reporters/New-HTMLReport.ps1**: Generate a rich HTML report from results.
- [ ] **src/reporters/New-JSONReport.ps1**: Save raw results as JSON.
- [ ] **src/reporters/New-TextReport.ps1**: Generate a summary text report for console/logs.

## Module Requirements

### Common Pattern
All diagnostic modules must:
- Accept parameters (e.g., `DeviceIP`).
- Return a standardized Hashtable result.
- Log activities to console/file.
- Handle errors gracefully.
- Follow the pattern: `Input -> Test -> Log -> Return Result`.

### Expected Output Format
```powershell
@{
    'timestamp' = "yyyy-MM-dd HH:mm:ss"
    'module' = "ModuleName"
    'status' = "PASS|FAIL|WARNING"
    'tests' = @{
        'test_name' = @{
            'status' = "PASS|FAIL"
            'message' = "Details"
            'data' = ...
        }
    }
}
```

## Detailed Module Specifications

### System-Diagnostics.ps1
- Check PowerShell version ($PSVersionTable).
- Check if Python is installed (`python --version`).
- Check if running as Administrator.
- Check required PowerShell modules (e.g. NetTCPIP).

### Hardware-Diagnostics.ps1
- Enumerate Serial Ports (`[System.IO.Ports.SerialPort]::GetPortNames()`).
- specific check for prolific/FTDI drivers if possible.
- If device connection exists, query device hardware stats (voltage, uptime) if protocol supports it.

### Performance-Diagnostics.ps1
- Ping latency statistics (min/max/avg).
- Data transfer rate test (if applicable, e.g. download a small file or echo test).

### Services-Diagnostics.ps1
- Check for ASCOM platform presence.
- Check for specific virtual serial port software (e.g. com0com).

### Security-Diagnostics.ps1
- Check if critical ports (2000, 23) are open.
- Warn if default ports are exposed to public internet (check public IP vs local IP).

### Read-Configuration.ps1
- Use `PowerShell-Yaml` or simple parsing if module not available.
- Validate config structure.
- Return default config if file missing.

## Reporting Tools
- **New-HTMLReport.ps1**:
  - Accept the aggregated results object.
  - Use a template string with placeholders.
  - Color-code results (Green/Red).
  - Include a troubleshooting section based on failures.

## Integration
- The main script `Run-Diagnostics.ps1` will orchestrate these modules.
- It will load config, run selected modules, aggregate results, and call reporters.

## Quick Start for AI Agents
1. Read this guide.
2. Implement `Read-Configuration.ps1` first.
3. Implement one diagnostic module at a time.
4. Implement reporters.
5. Verify integration with `Run-Diagnostics.ps1` (mocking if necessary).
