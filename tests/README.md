# HomeBrew Telescope Diagnostic Tool - Tests

This directory contains integration tests and mock device simulators for validating the diagnostic tool without requiring actual hardware.

## Test Structure

```
tests/
├── Integration-Tests.ps1        # Pester integration tests for Python-Helper module
├── Mock-TelescopeDevice.ps1     # Mock HomeBrew Gen3 PCB device simulator
└── README.md                     # This file
```

## Running Tests

### Prerequisites

1. **Install Pester Framework** (if not already installed)
   ```powershell
   Install-Module Pester -Force -SkipPublisherCheck
   ```

2. **Python Environment** (for integration tests)
   ```bash
   python --version  # Python 3.6+
   pip install pyserial
   ```

### Run All Integration Tests

```powershell
# From the project root
Invoke-Pester -Path .\tests\Integration-Tests.ps1 -Verbose

# Or run from tests directory
cd tests
Invoke-Pester -Path .\Integration-Tests.ps1 -Verbose
```

### Run Specific Test Suite

```powershell
# Run only Python-Helper tests
Invoke-Pester -Path .\tests\Integration-Tests.ps1 -TestName "Python-Helper*" -Verbose

# Run only error handling tests
Invoke-Pester -Path .\tests\Integration-Tests.ps1 -TestName "*Error*" -Verbose
```

### Run Extended Tests

Some tests are skipped by default. To enable extended testing:

```powershell
# Enable extended tests environment variable
$env:EXTENDED_TESTS = "true"

# Run tests with extended tests enabled
Invoke-Pester -Path .\tests\Integration-Tests.ps1 -Verbose
```

## Mock Device Simulator

The Mock-TelescopeDevice.ps1 script simulates a HomeBrew Gen3 PCB device on port 2000 for testing without real hardware.

### Starting the Mock Device

```powershell
# Start with default settings (port 2000)
.\tests\Mock-TelescopeDevice.ps1

# Start with custom port and verbose logging
.\tests\Mock-TelescopeDevice.ps1 -Port 2000 -Verbose

# Start in background
Start-Job -FilePath .\tests\Mock-TelescopeDevice.ps1 -ArgumentList 2000, $true
```

### Testing Against Mock Device

Once the mock device is running, you can test the diagnostic tool:

```powershell
# In another PowerShell window
.\Run-Diagnostics.ps1 -DeviceIP 127.0.0.1 -Verbose

# Or run specific modules
.\Run-Diagnostics.ps1 -DeviceIP 127.0.0.1 -Module Network
.\Run-Diagnostics.ps1 -DeviceIP 127.0.0.1 -Module Communication
.\Run-Diagnostics.ps1 -DeviceIP 127.0.0.1 -Module Telescope
```

### Mock Device Features

The mock device supports:

**Celestron Commands:**
- `MS` - Mount Status
- `GV` - Get Version
- `GA` - Get Altitude
- `GZ` - Get Azimuth
- `GC` - Get Date
- `GL` - Get Time
- `e` - Echo

**WiFi Module Commands:**
- `WIFISTATUS` - Device WiFi status (JSON)
- `WIFISCAN` - Scan available networks (JSON)
- `WIFICONNECT` - Connect to network
- `PING <IP>` - Ping network address

**Bluetooth Module Commands:**
- `BTSTATUS` - Bluetooth status (JSON)
- `BTSCAN` - Scan for Bluetooth devices (JSON)
- `BTPAIR` - Enter pairing mode

**GPS Module Commands:**
- `GPSSTATUS` - GPS status (JSON)
- `GPSCOORDS` - Get GPS coordinates (JSON)
- `GPSSAT` - Get satellite information (JSON)
- `GPSTIME` - Get GPS time sync info (JSON)

**USB Relay Commands:**
- `USBSTATUS` - USB relay status (JSON)
- `USBRELAY ON` - Turn relay on
- `USBRELAY OFF` - Turn relay off

**System Commands:**
- `VERSION` - Device version
- `UPTIME` - Device uptime
- `TEMPERATURE` - Device temperatures (JSON)
- `MEMORY` - Device memory status (JSON)

### Stopping the Mock Device

Press `Ctrl+C` to stop the mock device server.

## Integration Test Coverage

### Python-Helper Module Tests

- **Test-PythonInstallation**
  - Python installation detection
  - Error handling for missing Python
  - Python version validation
  - Required module checking
  - Temporary file cleanup

- **Invoke-PythonTelescopeScript**
  - JSON output parsing
  - Execution duration tracking
  - Script not found error handling
  - Custom script arguments

- **Invoke-TelescopePythonTests**
  - Overall test result structure
  - Execution summary generation

- **Get-PythonOutputSummary**
  - Summary extraction from results
  - Error handling for failed scripts
  - JSON output parsing

### Script Compatibility Tests

- Device IP argument passing
- Custom script arguments support

### Error Handling Tests

- Timeout detection and recovery
- Python path fallback
- Error recommendations

## Test Results

Test results are displayed in the console with a summary:

```
Tests Run: 15
Passed: 15
Failed: 0
Skipped: 2
Duration: 3.45s
```

Failed tests will show detailed error information to help with debugging.

## Continuous Integration

To integrate these tests into CI/CD:

```yaml
# Example GitHub Actions workflow
- name: Run Tests
  run: |
    Install-Module Pester -Force -SkipPublisherCheck
    Invoke-Pester -Path ./tests/Integration-Tests.ps1 -OutputFormat NUnitXml -OutputFile test-results.xml
    
- name: Publish Results
  uses: dorny/test-reporter@v1
  if: always()
  with:
    name: Test Results
    path: test-results.xml
    reporter: java-junit
```

## Troubleshooting Tests

### "Pester module not found"
Install Pester:
```powershell
Install-Module Pester -Force -SkipPublisherCheck
```

### "Python not found" in tests
Install Python and ensure it's in PATH:
```powershell
python --version
pip install pyserial
```

### Tests timing out
Some tests may timeout if the system is slow:
```powershell
# Run tests without timeout
Invoke-Pester -Path .\tests\Integration-Tests.ps1 -Verbose -TimeoutSec 0
```

### Mock device already using port
If port 2000 is already in use:
```powershell
# Find process using port
Get-NetTCPConnection -LocalPort 2000

# Or use different port
.\tests\Mock-TelescopeDevice.ps1 -Port 2001
```

## Adding New Tests

To add new tests:

1. Open `Integration-Tests.ps1`
2. Add test within a `Context` block
3. Use descriptive test names
4. Include comments explaining test purpose
5. Use proper assertions with `Should` statements

Example:
```powershell
It "Should handle specific scenario" {
    $result = Test-Something
    $result | Should -Not -BeNullOrEmpty
    $result.Property | Should -Be "ExpectedValue"
}
```

## Performance Considerations

- Integration tests may take 30-60 seconds to complete
- Mock device starts a background job for each client
- Multiple simultaneous connections are supported
- Tests skip if prerequisites are not met (not marked as failures)

## Documentation

See related documentation:
- [GETTING_STARTED.md](../docs/GETTING_STARTED.md) - Tool setup
- [ERROR_CODES.md](../docs/ERROR_CODES.md) - Error reference
- [MODULES.md](../docs/MODULES.md) - Module documentation
- [TROUBLESHOOTING.md](../docs/TROUBLESHOOTING.md) - Troubleshooting guide

---

**Last Updated**: 2025-12-09
**Tool Version**: 2.0.0
