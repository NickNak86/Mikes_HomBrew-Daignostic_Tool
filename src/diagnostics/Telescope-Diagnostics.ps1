#Requires -Version 5.1

# Import Python Helper module for advanced telescope testing
$pythonHelperPath = Join-Path $PSScriptRoot "Python-Helper.ps1"
if (Test-Path $pythonHelperPath) {
    . $pythonHelperPath
}

<#
.SYNOPSIS
    Telescope Mount Diagnostic Module
    
.DESCRIPTION
    Diagnoses HomeBrew Gen3 PCB WiFi/BT/GPS/MUSBA relay devices for Celestron Evolution mounts.
    Tests telnet connectivity, serial communication, and mount communication protocols.
    Integrates Python scripts for advanced Celestron protocol testing.

.PARAMETER DeviceIP
    IP address of the HomeBrew device
    
.PARAMETER TelnetPort
    Telnet port for device communication (default: 2000)
    
.PARAMETER SerialPort
    Serial port for direct mount communication
    
.PARAMETER VerboseOutput
    Enable verbose diagnostic output

.EXAMPLE
    .\Telescope-Diagnostics.ps1 -DeviceIP 192.168.1.100
    Run telescope diagnostics for device at 192.168.1.100

.EXAMPLE
    .\Telescope-Diagnostics.ps1 -DeviceIP 192.168.1.100 -VerboseOutput
    Run telescope diagnostics with verbose output

.NOTES
    Author: HomeBrew Diagnostic Tool
    Version: 2.0.0
    Purpose: Celestron Evolution Mount Integration
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$DeviceIP = "192.168.1.100",
    
    [Parameter(Mandatory=$false)]
    [int]$TelnetPort = 2000,
    
    [Parameter(Mandatory=$false)]
    [string]$SerialPort,
    
    [Parameter(Mandatory=$false)]
    [switch]$VerboseOutput,
    
    [Parameter(Mandatory=$false)]
    [string]$PythonPath = "python"
)

function Write-TelescopeLog {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] TelescopeDiagnostics: $Message"
    Write-Host $logEntry -ForegroundColor $(switch($Level) {
        "INFO" { "Cyan" }
        "SUCCESS" { "Green" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        default { "White" }
    })
    
    # Write to log file if configured
    $logFile = Join-Path $PSScriptRoot "..\..\output\logs\telescope_diagnostics.log"
    Add-Content -Path $logFile -Value $logEntry -ErrorAction SilentlyContinue
}

function Test-PythonEnvironment {
    Write-TelescopeLog "Checking Python environment..." "INFO"
    
    # Use the comprehensive Python Helper function
    $pythonCheck = Test-PythonInstallation -PythonPath $PythonPath
    
    if ($pythonCheck.Success) {
        Write-TelescopeLog "Python found: $($pythonCheck.Version)" "SUCCESS"
        $availableModules = ($pythonCheck.RequiredModules.Keys | Where-Object { $pythonCheck.RequiredModules[$_] }) -join ', '
        Write-TelescopeLog "Required modules available: $availableModules" "INFO"
        
        # Log missing modules as warnings
        $missingModules = ($pythonCheck.RequiredModules.Keys | Where-Object { -not $pythonCheck.RequiredModules[$_] })
        if ($missingModules.Count -gt 0) {
            Write-TelescopeLog "Missing required modules: $($missingModules -join ', ')" "WARNING"
        }
        
        return $true
    } else {
        Write-TelescopeLog "Python check failed: $($pythonCheck.Error)" "ERROR"
        return $false
    }
}

function Test-TelnetConnectivity {
    param([string]$Host, [int]$Port = 2000)
    
    Write-TelescopeLog "Testing telnet connectivity to $Host`:$Port..." "INFO"
    
    try {
        # Test basic network connectivity first
        $ping = Test-Connection -ComputerName $Host -Count 2 -Quiet
        if (-not $ping) {
            Write-TelescopeLog "Cannot ping $Host - device may be offline" "ERROR"
            return $false
        }
        
        # Test telnet port
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $connect = $tcpClient.BeginConnect($Host, $Port, $null, $null)
        $wait = $connect.AsyncWaitHandle.WaitOne(5000, $false)
        
        if ($wait) {
            $tcpClient.EndConnect($connect)
            $tcpClient.Close()
            Write-TelescopeLog "Telnet port $Port is open and accessible" "SUCCESS"
            return $true
        } else {
            Write-TelescopeLog "Telnet port $Port is not accessible (timeout)" "ERROR"
            return $false
        }
    } catch {
        Write-TelescopeLog "Telnet connectivity test failed: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Test-SerialConnectivity {
    param([string]$Port)
    
    Write-TelescopeLog "Testing serial connectivity on $Port..." "INFO"
    
    try {
        # Check if port exists
        $ports = [System.IO.Ports.SerialPort]::GetPortNames()
        if ($Port -notin $ports) {
            Write-TelescopeLog "Serial port $Port not found" "ERROR"
            return $false
        }
        
        # Try to open the port briefly
        $serial = New-Object System.IO.Ports.SerialPort
        $serial.PortName = $Port
        $serial.BaudRate = 9600
        $serial.Open()
        
        if ($serial.IsOpen) {
            $serial.Close()
            Write-TelescopeLog "Serial port $Port is accessible" "SUCCESS"
            return $true
        } else {
            Write-TelescopeLog "Could not open serial port $Port" "ERROR"
            return $false
        }
    } catch {
        Write-TelescopeLog "Serial connectivity test failed: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Test-PythonTelescopeScript {
    param([string]$DeviceIP, [int]$Port, [string]$SerialPort)
    
    Write-TelescopeLog "Running Python telescope communication test..." "INFO"
    
    $scriptPath = Join-Path $PSScriptRoot "..\..\python_scripts\telescope_comm.py"
    if (-not (Test-Path $scriptPath)) {
        Write-TelescopeLog "Python telescope script not found at $scriptPath" "ERROR"
        return $false
    }
    
    try {
        $arguments = @()
        if ($DeviceIP) {
            $arguments += "--host"
            $arguments += $DeviceIP
        }
        $arguments += "--port"
        $arguments += $Port.ToString()
        if ($SerialPort) {
            $arguments += "--serial"
            $arguments += $SerialPort
        }
        $arguments += "--test"
        $arguments += "--json"
        
        Write-TelescopeLog "Executing: $PythonPath `"$scriptPath`" $($arguments -join ' ')" "INFO"
        
        $process = Start-Process -FilePath $PythonPath -ArgumentList $arguments -Wait -PassThru -RedirectStandardOutput "$env:TEMP\python_stdout.log" -RedirectStandardError "$env:TEMP\python_stderr.log"
        
        if ($process.ExitCode -eq 0) {
            $output = Get-Content "$env:TEMP\python_stdout.log" -ErrorAction SilentlyContinue
            if ($output) {
                $results = $output | ConvertFrom-Json -ErrorAction SilentlyContinue
                if ($results) {
                    Write-TelescopeLog "Python telescope communication successful" "SUCCESS"
                    
                    if ($VerboseOutput) {
                        Write-TelescopeLog "Telescope communication results:" "INFO"
                        $results | ConvertTo-Json -Depth 3 | Write-Host -ForegroundColor Yellow
                    }
                    
                    return $true
                }
            }
        } else {
            $errorOutput = Get-Content "$env:TEMP\python_stderr.log" -ErrorAction SilentlyContinue
            Write-TelescopeLog "Python telescope communication failed: $errorOutput" "ERROR"
            return $false
        }
    } catch {
        Write-TelescopeLog "Python telescope script execution failed: $($_.Exception.Message)" "ERROR"
        return $false
    } finally {
        # Cleanup temp files
        Remove-Item "$env:TEMP\python_stdout.log" -ErrorAction SilentlyContinue
        Remove-Item "$env:TEMP\python_stderr.log" -ErrorAction SilentlyContinue
    }
    
    return $false
}

function Test-WiFiBTGPSScript {
    param([string]$DeviceIP, [int]$Port)
    
    Write-TelescopeLog "Running Python WiFi/BT/GPS module test..." "INFO"
    
    $scriptPath = Join-Path $PSScriptRoot "..\..\python_scripts\wifi_bt_gps_test.py"
    if (-not (Test-Path $scriptPath)) {
        Write-TelescopeLog "Python WiFi/BT/GPS script not found at $scriptPath" "ERROR"
        return $false
    }
    
    try {
        $arguments = @()
        $arguments += "--host"
        $arguments += $DeviceIP
        $arguments += "--port"
        $arguments += $Port.ToString()
        $arguments += "--verbose"
        
        Write-TelescopeLog "Executing: $PythonPath `"$scriptPath`" $($arguments -join ' ')" "INFO"
        
        $process = Start-Process -FilePath $PythonPath -ArgumentList $arguments -Wait -PassThru -RedirectStandardOutput "$env:TEMP\wifi_test_stdout.log" -RedirectStandardError "$env:TEMP\wifi_test_stderr.log"
        
        if ($process.ExitCode -eq 0) {
            $output = Get-Content "$env:TEMP\wifi_test_stdout.log" -ErrorAction SilentlyContinue
            if ($output) {
                Write-TelescopeLog "Python WiFi/BT/GPS test completed successfully" "SUCCESS"
                
                if ($VerboseOutput) {
                    Write-TelescopeLog "WiFi/BT/GPS test results:" "INFO"
                    Write-Host $output -ForegroundColor Yellow
                }
                
                return $true
            }
        } else {
            $errorOutput = Get-Content "$env:TEMP\wifi_test_stderr.log" -ErrorAction SilentlyContinue
            Write-TelescopeLog "Python WiFi/BT/GPS test failed: $errorOutput" "ERROR"
            return $false
        }
    } catch {
        Write-TelescopeLog "Python WiFi/BT/GPS script execution failed: $($_.Exception.Message)" "ERROR"
        return $false
    } finally {
        # Cleanup temp files
        Remove-Item "$env:TEMP\wifi_test_stdout.log" -ErrorAction SilentlyContinue
        Remove-Item "$env:TEMP\wifi_test_stderr.log" -ErrorAction SilentlyContinue
    }
    
    return $false
}

function Get-TelescopeDiagnosticResults {
    param([string]$DeviceIP, [int]$Port, [string]$SerialPort)
    
    Write-TelescopeLog "Starting telescope diagnostic suite..." "INFO"
    
    $results = @{
        'timestamp' = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
        'device_ip' = $DeviceIP
        'telnet_port' = $Port
        'serial_port' = $SerialPort
        'tests' = @{}
        'overall_status' = 'UNKNOWN'
    }
    
    # Test Python environment
    $results.tests['python_environment'] = Test-PythonEnvironment
    
    # Test telnet connectivity
    $results.tests['telnet_connectivity'] = Test-TelnetConnectivity -Host $DeviceIP -Port $Port
    
    # Test serial connectivity if port specified
    if ($SerialPort) {
        $results.tests['serial_connectivity'] = Test-SerialConnectivity -Port $SerialPort
    }
    
    # Test telescope communication using Python Helper
    Write-TelescopeLog "Running integrated Python telescope tests..." "INFO"
    $pythonTestResults = Invoke-TelescopePythonTests -DeviceIP $DeviceIP -SerialPort $SerialPort -PythonPath $PythonPath
    
    $results.tests['telescope_communication'] = $pythonTestResults.overall_success
    $results.tests['wifi_bt_gps_modules'] = $pythonTestResults.wifi_bt_gps.Success
    
    # Store detailed Python results for reporting
    $results.python_integration = @{
        telescope_script = $pythonTestResults.telescope_comm
        wifi_script = $pythonTestResults.wifi_bt_gps
        overall_success = $pythonTestResults.overall_success
        python_version = $pythonTestResults.summary.python_version
        execution_time = $pythonTestResults.summary.total_execution_time
        warnings = $pythonTestResults.summary.warnings
        recommendations = $pythonTestResults.summary.recommendations
    }
    
    # Calculate overall status
    $failedTests = $results.tests.GetEnumerator() | Where-Object { -not $_.Value }
    if ($failedTests.Count -eq 0) {
        $results.overall_status = 'PASS'
    } elseif ($failedTests.Count -lt $results.tests.Count) {
        $results.overall_status = 'PARTIAL'
    } else {
        $results.overall_status = 'FAIL'
    }
    
    return $results
}

function Show-TelescopeResults {
    param([hashtable]$Results)
    
    Write-Host ""
    Write-Host "🌟 TELESCOPE DIAGNOSTIC RESULTS 🌟" -ForegroundColor Cyan
    Write-Host "=====================================" -ForegroundColor Cyan
    
    Write-Host "Device: $($Results.device_ip):$($Results.telnet_port)" -ForegroundColor White
    Write-Host "Time: $($Results.timestamp)" -ForegroundColor White
    Write-Host "Status: " -NoNewline
    
    switch($Results.overall_status) {
        'PASS' { Write-Host "✓ PASSED" -ForegroundColor Green }
        'PARTIAL' { Write-Host "⚠ PARTIAL" -ForegroundColor Yellow }
        'FAIL' { Write-Host "✗ FAILED" -ForegroundColor Red }
        default { Write-Host "? UNKNOWN" -ForegroundColor Gray }
    }
    
    Write-Host ""
    Write-Host "Test Results:" -ForegroundColor Cyan
    
    foreach ($test in $Results.tests.GetEnumerator()) {
        $status = if ($test.Value) { "✓ PASS" } else { "✗ FAIL" }
        $color = if ($test.Value) { "Green" } else { "Red" }
        Write-Host "  $status - $($test.Key)" -ForegroundColor $color
    }
    
    Write-Host ""
}

# Main execution
try {
    Write-TelescopeLog "=== TELESCOPE DIAGNOSTIC MODULE STARTING ===" "INFO"
    
    if ($VerboseOutput) {
        Write-TelescopeLog "Verbose mode enabled" "INFO"
        Write-TelescopeLog "Device IP: $DeviceIP" "INFO"
        Write-TelescopeLog "Telnet Port: $TelnetPort" "INFO"
        if ($SerialPort) { Write-TelescopeLog "Serial Port: $SerialPort" "INFO" }
        Write-TelescopeLog "Python Path: $PythonPath" "INFO"
    }
    
    # Run diagnostics
    $diagnosticResults = Get-TelescopeDiagnosticResults -DeviceIP $DeviceIP -Port $TelnetPort -SerialPort $SerialPort
    
    # Display results
    Show-TelescopeResults -Results $diagnosticResults
    
    # Save results
    $outputPath = Join-Path $PSScriptRoot "..\..\output\reports"
    if (-not (Test-Path $outputPath)) {
        New-Item -ItemType Directory -Path $outputPath -Force | Out-Null
    }
    
    $timestamp = Get-Date -Format "yyyy-MM-dd_HHmmss"
    $jsonPath = Join-Path $outputPath "telescope_diagnostic_$timestamp.json"
    
    $diagnosticResults | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonPath -Encoding UTF8
    Write-TelescopeLog "Results saved to: $jsonPath" "INFO"
    
    Write-TelescopeLog "=== TELESCOPE DIAGNOSTIC MODULE COMPLETED ===" "SUCCESS"
    
    # Return results for calling script
    return $diagnosticResults
    
} catch {
    Write-TelescopeLog "Telescope diagnostic failed: $($_.Exception.Message)" "ERROR"
    Write-TelescopeLog $_.ScriptStackTrace -ErrorAction SilentlyContinue
    
    return @{
        'timestamp' = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
        'device_ip' = $DeviceIP
        'overall_status' = 'ERROR'
        'error' = $_.Exception.Message
    }
}