# HomeBrew Telescope Diagnostic Tool - Implementation Checklist

**Status**: Ready for cto.new AI Agent  
**Branch**: `cto-new-ai-add-diagnostic-modules-yaml-parser-report-tests`  
**Last Updated**: 2025-12-09

---

## 📊 EXECUTIVE SUMMARY

| Component | Status | Effort | Priority |
|-----------|--------|--------|----------|
| Architecture & Framework | ✅ 100% | Done | - |
| YAML Parser | ❌ 0% | 1-2 hrs | 🔴 HIGH |
| Telescope Module | ❌ 5% | 1 hr | 🟡 MEDIUM |
| Network Module | ❌ 5% | 1 hr | 🟡 MEDIUM |
| Communication Module | ❌ 5% | 1.5 hrs | 🟡 MEDIUM |
| System Module | ❌ 5% | 1 hr | 🟡 MEDIUM |
| Pester Test Suite | ❌ 0% | 2-3 hrs | 🟡 MEDIUM |
| Report Tests | ❌ 0% | 1 hr | 🟠 LOW |
| **TOTAL** | **✅ 70%** | **9-11 hrs** | - |

---

## 🎯 TASK 1: YAML PARSER (1-2 hours)

### Location
`src/lib/Yaml-Parser.ps1` (NEW FILE)

### Requirements
- [ ] Create custom YAML parser function
- [ ] Parse `config/diagnostics.yaml`
- [ ] Support nested keys (diagnostics.device.ip)
- [ ] Convert YAML arrays to PowerShell arrays
- [ ] Handle comments and blank lines
- [ ] Merge config with command-line overrides

### Function Signature
```powershell
function Parse-DiagnosticsYaml {
    param([string]$ConfigPath = "config/diagnostics.yaml")
    
    # Returns @{
    #   'diagnostics' = @{...}
    #   'modules' = @{...}
    #   'telescope' = @{...}
    # }
}
```

### Integration Point
In `Run-Diagnostics.ps1` at line ~96:
```powershell
$config = Parse-DiagnosticsYaml -ConfigPath $ConfigPath
```

### Test Cases
- [ ] Parse valid YAML
- [ ] Handle missing config file
- [ ] Override device IP from CLI
- [ ] Override module settings
- [ ] Validate all required keys exist

---

## 🎯 TASK 2: NETWORK-DIAGNOSTICS Module (1 hour)

### Location
`src/diagnostics/Network-Diagnostics.ps1` (IMPLEMENT)

### Required Tests (from config)
- [ ] **Ping Device**: Test connectivity to device IP (192.168.1.100)
- [ ] **Port Test**: Test telnet to device:port (192.168.1.100:2000)
- [ ] **Device Port Alive**: Verify port 2000 is listening
- [ ] **WiFi Status**: Check WiFi adapter status
- [ ] **DNS Resolution**: Test DNS (8.8.8.8, 1.1.1.1, google.com)
- [ ] **Internet Connectivity**: Ping external hosts
- [ ] **Router Connectivity**: Ping router.local
- [ ] **Network Interface**: List active adapters

### Return Structure Example
```powershell
@{
    'overall_status' = 'PASS'
    'timestamp' = (Get-Date -Format 'o')
    'module_name' = 'Network'
    'tests' = @(
        @{ 'name' = 'Ping Device'; 'status' = 'PASS'; 'details' = 'Device at 192.168.1.100 is reachable'; 'duration_ms' = 45 }
        @{ 'name' = 'Telnet Port 2000'; 'status' = 'PASS'; 'details' = 'Port 2000 is responding'; 'duration_ms' = 234 }
    )
    'summary' = @{ 'total_tests' = 8; 'passed' = 8; 'failed' = 0; 'skipped' = 0 }
    'recommendations' = @()
}
```

### Implementation Notes
- Use `Test-NetConnection` for ping and port tests
- Timeout after 2 seconds per test
- Don't fail module if 1-2 tests fail (PARTIAL status)
- Log all results to `output/logs/network_diagnostics.log`

---

## 🎯 TASK 3: COMMUNICATION-DIAGNOSTICS Module (1.5 hours)

### Location
`src/diagnostics/Communication-Diagnostics.ps1` (IMPLEMENT)

### Required Tests
- [ ] **Telnet Connection**: Connect to device via telnet
- [ ] **Echo Command**: Test basic telnet echo
- [ ] **Help Command**: Verify help command response
- [ ] **Info Command**: Test info command
- [ ] **Celestron Mount Status**: Send MS (Mount Status) command
- [ ] **Celestron Get Version**: Send GV command
- [ ] **Celestron Altitude**: Send GA command
- [ ] **Celestron Azimuth**: Send GZ command
- [ ] **WiFi Module**: Send WIFI command
- [ ] **Bluetooth Module**: Send BT command
- [ ] **GPS Module**: Send GPS command
- [ ] **Serial Connection** (if SerialPort param): Test direct serial
- [ ] **Protocol Compliance**: Verify Celestron NexStar format

### Celestron Commands (9600 baud, 8-N-1)
```
Basic:
- echo\r\n
- help\r\n
- info\r\n

Mount Status:
- MS\r\n

Coordinate Queries:
- GA\r\n  (Get Altitude)
- GZ\r\n  (Get Azimuth)
- GV\r\n  (Get Version)
- GM\r\n  (Get UTC Offset)

Wireless:
- WIFI\r\n
- BT\r\n
- GPS\r\n

System:
- VERSION\r\n
- UPTIME\r\n
- STATUS\r\n
```

### Return Structure
```powershell
@{
    'overall_status' = 'PASS|PARTIAL|FAIL'
    'tests' = @(
        @{ 'name' = 'Telnet Connection'; 'status' = 'PASS'; 'details' = 'Connected to 192.168.1.100:2000'; 'duration_ms' = 123 }
        @{ 'name' = 'Echo Command'; 'status' = 'PASS'; 'details' = 'Response: ACK'; 'duration_ms' = 45 }
    )
    'summary' = @{ 'total_tests' = 13; 'passed' = 12; 'failed' = 1; 'skipped' = 0 }
    'protocol_version' = 'NexStar 1.2'
    'device_firmware' = 'v2.1.0'
    'recommendations' = @()
}
```

### Implementation Notes
- Create telnet connection function
- Handle serial port communication if specified
- Parse Celestron responses (often hex/binary)
- Don't fail on optional tests (serial, wireless)
- Timeout: 2 seconds per command
- Log all commands and responses

---

## 🎯 TASK 4: TELESCOPE-DIAGNOSTICS Module (1 hour)

### Location
`src/diagnostics/Telescope-Diagnostics.ps1` (IMPLEMENT)

### Required Tests
- [ ] **Python Installation**: Verify python executable exists
- [ ] **Python Version**: Check Python 3.6+
- [ ] **Telescope Script**: Verify telescope_comm.py exists
- [ ] **WiFi/BT/GPS Script**: Verify wifi_bt_gps_test.py exists
- [ ] **Run Telescope Comm**: Execute `python_scripts/telescope_comm.py --host 192.168.1.100`
- [ ] **Run WiFi/BT/GPS Test**: Execute `python_scripts/wifi_bt_gps_test.py`
- [ ] **Mount Communication**: Test actual mount responses
- [ ] **Wireless Module Status**: Get WiFi/BT/GPS status from device

### Return Structure
```powershell
@{
    'overall_status' = 'PASS|PARTIAL|FAIL'
    'tests' = @(
        @{ 'name' = 'Python Installation'; 'status' = 'PASS'; 'details' = 'Python 3.9.0'; 'duration_ms' = 234 }
        @{ 'name' = 'Telescope Script'; 'status' = 'PASS'; 'details' = 'Script found and executable'; 'duration_ms' = 12 }
        @{ 'name' = 'Mount Communication'; 'status' = 'PASS'; 'details' = 'Mount responding to commands'; 'duration_ms' = 456 }
    )
    'summary' = @{ 'total_tests' = 8; 'passed' = 8; 'failed' = 0; 'skipped' = 0 }
    'mount_info' = @{ 'model' = 'Celestron Evolution'; 'firmware' = 'v5.0.0' }
    'wireless_status' = @{ 'wifi' = 'Connected'; 'bluetooth' = 'Ready'; 'gps' = 'Acquiring' }
    'recommendations' = @()
}
```

### Implementation Notes
- Call Python with proper parameter passing
- Capture stdout and stderr
- Parse Python script output
- Don't fail if Python scripts unavailable (SKIP those tests)
- Device IP from config or parameter
- Timeout: 10 seconds for Python scripts

---

## 🎯 TASK 5: SYSTEM-DIAGNOSTICS Module (1 hour)

### Location
`src/diagnostics/System-Diagnostics.ps1` (IMPLEMENT)

### Required Tests (from config)
- [ ] **Operating System**: Get Windows version
- [ ] **PowerShell Version**: Verify 5.1+
- [ ] **Python Installation**: Check `python --version`
- [ ] **Python Version**: Ensure 3.6+
- [ ] **Ping Utility**: Check if ping.exe available
- [ ] **Telnet Utility**: Check if telnet.exe available
- [ ] **nslookup Utility**: Check DNS query tool
- [ ] **Serial Port Support**: Check if serial port library available
- [ ] **Disk Space**: Verify minimum 1GB free
- [ ] **Firewall Status**: Get Windows Defender Firewall state
- [ ] **Antivirus**: Check Windows Defender antivirus
- [ ] **User Permissions**: Check if running as admin
- [ ] **Registry**: Verify required settings

### Return Structure
```powershell
@{
    'overall_status' = 'PASS|PARTIAL|FAIL'
    'tests' = @(
        @{ 'name' = 'Operating System'; 'status' = 'PASS'; 'details' = 'Windows 11 Pro (Build 22621)'; 'duration_ms' = 45 }
        @{ 'name' = 'Python Installation'; 'status' = 'PASS'; 'details' = 'Python 3.11.0'; 'duration_ms' = 123 }
        @{ 'name' = 'Admin Privileges'; 'status' = 'WARNING'; 'details' = 'Not running as admin - network diagnostics may be limited'; 'duration_ms' = 12 }
    )
    'summary' = @{ 'total_tests' = 13; 'passed' = 12; 'failed' = 0; 'skipped' = 1; 'warnings' = 1 }
    'system_info' = @{
        'os' = 'Windows 11 Pro'
        'build' = '22621'
        'powershell' = '5.1.22621.1778'
        'python' = '3.11.0'
    }
    'recommendations' = @('Run as Administrator for full diagnostics', 'Update Windows Defender definitions')
}
```

### Implementation Notes
- Use WMI for OS info: `Get-CimInstance Win32_OperatingSystem`
- Use WMI for disk space: `Get-CimInstance Win32_LogicalDisk`
- Check firewall: `Get-NetFirewallProfile`
- Check admin: `[Security.Principal.WindowsPrincipal]::new(...).IsInRole(...)`
- All tests should complete quickly (< 100ms each)
- Don't fail module on warnings (use PARTIAL status)

---

## 🎯 TASK 6: PESTER TEST SUITE (2-3 hours)

### Directory
`tests/` (NEW DIRECTORY)

### Files to Create
- [ ] `tests/Telescope-Diagnostics.tests.ps1`
- [ ] `tests/Network-Diagnostics.tests.ps1`
- [ ] `tests/Communication-Diagnostics.tests.ps1`
- [ ] `tests/System-Diagnostics.tests.ps1`
- [ ] `tests/Run-Diagnostics.tests.ps1`
- [ ] `tests/Yaml-Parser.tests.ps1`

### Test Structure Example
```powershell
Describe "Network-Diagnostics" {
    Context "Device Ping Tests" {
        It "Should detect when device is reachable" {
            $result = & $diagnosticScript -DeviceIP "192.168.1.100"
            $result.overall_status | Should -BeIn @('PASS', 'PARTIAL')
        }
        
        It "Should handle unreachable device gracefully" {
            $result = & $diagnosticScript -DeviceIP "192.168.1.200"
            $result.overall_status | Should -Match 'FAIL|PARTIAL'
        }
    }
}
```

### Test Coverage Requirements
- Parameter validation tests
- Mock data for offline testing
- Return structure validation
- Error handling tests
- Edge cases (missing device, timeout, invalid params)
- Status value validation
- Recommendations validation

### Running Tests
```powershell
# Run all tests
Invoke-Pester tests/ -Verbose

# Run specific test file
Invoke-Pester tests/Network-Diagnostics.tests.ps1

# With coverage
Invoke-Pester tests/ -CodeCoverage src/diagnostics/*.ps1
```

---

## 🎯 TASK 7: REPORT GENERATION TESTS (1 hour)

### Location
`tests/Report-Generation.tests.ps1` (NEW FILE)

### Test Cases
- [ ] HTML report generation creates valid file
- [ ] JSON report is valid JSON
- [ ] Text report is readable text
- [ ] Report includes all module results
- [ ] Timestamp is correctly formatted
- [ ] Output directory is created
- [ ] Report file naming convention
- [ ] Report includes summary section
- [ ] Report includes recommendations
- [ ] CSS styling renders correctly

### Expected Outputs
```
output/reports/
├── telescope_diagnostic_2025-12-09_143022.html
├── telescope_diagnostic_2025-12-09_143022.json
└── telescope_diagnostic_2025-12-09_143022.txt
```

---

## 📋 IMPLEMENTATION ORDER (Recommended)

1. **YAML Parser** → Enables configuration-driven execution
2. **Network Module** → Simplest, good test for framework
3. **System Module** → No external dependencies
4. **Communication Module** → Most complex
5. **Telescope Module** → Depends on Python scripts
6. **Pester Tests** → Test all modules
7. **Report Tests** → Final validation

---

## 🔍 QUALITY CHECKLIST

For each implementation:

- [ ] Function has comment-based help
- [ ] Parameters are validated
- [ ] Error handling with try-catch
- [ ] Returns correct structure
- [ ] Logging to output/logs/
- [ ] Handles missing dependencies gracefully
- [ ] No hardcoded values (use config)
- [ ] Timeout protection on network calls
- [ ] Test file exists with 80%+ coverage
- [ ] Documentation updated

---

## ✅ SIGN-OFF CRITERIA

All tasks complete when:

- ✅ YAML parser working
- ✅ All 4 modules return valid structured results
- ✅ Pester tests all passing (>80% coverage)
- ✅ Report generation tests passing
- ✅ `.\Run-Diagnostics.ps1` generates valid reports
- ✅ `Invoke-Pester tests/` all green
- ✅ No external dependencies (except Python for scripts)
- ✅ All modules handle missing device gracefully
- ✅ Logs created in output/logs/
- ✅ Reports created in output/reports/

---

## 📞 Support & Questions

If clarification needed on:
- **Device behavior**: Refer to `docs/TROUBLESHOOTING.md`
- **Protocol details**: Check `python_scripts/telescope_comm.py`
- **Configuration**: See `config/diagnostics.yaml`
- **Expected results**: Review `docs/GETTING_STARTED.md`

---

**Ready to implement!** 🚀
