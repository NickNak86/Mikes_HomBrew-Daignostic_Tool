#Requires -Version 5.1

<#
.SYNOPSIS
    Communication Diagnostic Module for Telescope Mount
    
.DESCRIPTION
    Tests telnet and serial communication protocols for Celestron Evolution mounts
    and HomeBrew Gen3 PCB WiFi/BT/GPS/MUSBA relay devices.

.PARAMETER DeviceIP
    IP address of the HomeBrew device
    
.PARAMETER TelnetPort
    Telnet port (default: 2000)
    
.PARAMETER SerialPort
    Serial port for direct mount communication
    
.EXAMPLE
    .\Communication-Diagnostics.ps1 -DeviceIP 192.168.1.100
    Test communication protocols for device at 192.168.1.100
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
    [switch]$VerboseOutput
)

function Write-CommLog {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] CommunicationDiagnostics: $Message"
    Write-Host $logEntry -ForegroundColor $(switch($Level) {
        "INFO" { "Cyan" }
        "SUCCESS" { "Green" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        default { "White" }
    })
    
    # Write to log file
    $logFile = Join-Path $PSScriptRoot "..\..\output\logs\communication_diagnostics.log"
    Add-Content -Path $logFile -Value $logEntry -ErrorAction SilentlyContinue
}

function Test-TelnetConnection {
    param([string]$Host, [int]$Port)
    
    Write-CommLog "Testing telnet connection to $Host`:$Port..." "INFO"
    
    try {
        # Create telnet connection test
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $connect = $tcpClient.BeginConnect($Host, $Port, $null, $null)
        $wait = $connect.AsyncWaitHandle.WaitOne(5000, $false)
        
        if ($wait) {
            $tcpClient.EndConnect($connect)
            
            # Test if it's actually a telnet service (port 23) or custom service (port 2000)
            if ($Port -eq 23) {
                # Try to read telnet greeting
                $stream = $tcpClient.GetStream()
                $reader = New-Object System.IO.StreamReader($stream)
                $writer = New-Object System.IO.StreamWriter($stream)
                $writer.AutoFlush = $true
                
                # Try to read any welcome message
                Start-Sleep -Milliseconds 500
                if ($stream.DataAvailable) {
                    $greeting = $reader.ReadLine()
                    Write-CommLog "Telnet greeting received: $greeting" "SUCCESS"
                }
                
                # Test basic telnet commands
                $writer.WriteLine("echo test")
                Start-Sleep -Milliseconds 1000
                $response = $reader.ReadLine()
                
                if ($response) {
                    Write-CommLog "Telnet echo test successful: $response" "SUCCESS"
                }
                
                $reader.Close()
                $writer.Close()
            }
            
            $tcpClient.Close()
            Write-CommLog "Telnet connection successful" "SUCCESS"
            return $true
        } else {
            Write-CommLog "Telnet connection timeout" "ERROR"
            $tcpClient.Close()
            return $false
        }
    } catch {
        Write-CommLog "Telnet connection failed: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Test-SerialCommunication {
    param([string]$Port)
    
    Write-CommLog "Testing serial communication on $Port..." "INFO"
    
    try {
        # Check if port exists
        $availablePorts = [System.IO.Ports.SerialPort]::GetPortNames()
        if ($Port -notin $availablePorts) {
            Write-CommLog "Serial port $Port not found. Available ports: $($availablePorts -join ', ')" "ERROR"
            return $false
        }
        
        # Test serial port communication
        $serial = New-Object System.IO.Ports.SerialPort
        $serial.PortName = $Port
        $serial.BaudRate = 9600
        $serial.DataBits = 8
        $serial.Parity = "None"
        $serial.StopBits = "One"
        $serial.Handshake = "None"
        $serial.ReadTimeout = 2000
        $serial.WriteTimeout = 2000
        $serial.NewLine = "`r`n"
        
        $serial.Open()
        
        if ($serial.IsOpen) {
            Write-CommLog "Serial port $Port opened successfully" "SUCCESS"
            
            # Test Celestron mount commands
            $testCommands = @("MS", "GV", "GA", "GZ")  # Mount Status, Get Version, Get Altitude, Get Azimuth
            
            foreach ($cmd in $testCommands) {
                try {
                    Write-CommLog "Testing Celestron command: $cmd" "INFO"
                    $serial.WriteLine($cmd)
                    Start-Sleep -Milliseconds 500
                    
                    $response = $serial.ReadLine()
                    if ($response) {
                        Write-CommLog "Command '$cmd' response: $response" "SUCCESS"
                    } else {
                        Write-CommLog "No response to command '$cmd'" "WARNING"
                    }
                } catch {
                    Write-CommLog "Command '$cmd' failed: $($_.Exception.Message)" "WARNING"
                }
            }
            
            $serial.Close()
            Write-CommLog "Serial communication test completed" "SUCCESS"
            return $true
        } else {
            Write-CommLog "Could not open serial port $Port" "ERROR"
            return $false
        }
    } catch {
        Write-CommLog "Serial communication test failed: $($_.Exception.Message)" "ERROR"
        if ($serial -and $serial.IsOpen) {
            $serial.Close()
        }
        return $false
    }
}

function Test-CelestronProtocol {
    param([string]$Host, [int]$Port)
    
    Write-CommLog "Testing Celestron protocol communication..." "INFO"
    
    try {
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $connect = $tcpClient.BeginConnect($Host, $Port, $null, $null)
        $wait = $connect.AsyncWaitHandle.WaitOne(5000, $false)
        
        if ($wait) {
            $tcpClient.EndConnect($connect)
            $stream = $tcpClient.GetStream()
            $reader = New-Object System.IO.StreamReader($stream)
            $writer = New-Object System.IO.StreamWriter($stream)
            $writer.AutoFlush = $true
            
            # Test Celestron commands
            $testCommands = @("MS", "GV", "GA", "GZ", "echo")  # Mount Status, Get Version, etc.
            
            $protocolResults = @{}
            
            foreach ($cmd in $testCommands) {
                try {
                    Write-CommLog "Sending Celestron command: $cmd" "INFO"
                    $writer.WriteLine($cmd)
                    Start-Sleep -Milliseconds 1000
                    
                    if ($stream.DataAvailable) {
                        $response = $reader.ReadLine()
                        if ($response) {
                            Write-CommLog "Command '$cmd' response: $response" "SUCCESS"
                            $protocolResults[$cmd] = $response
                        } else {
                            Write-CommLog "Command '$cmd' no response" "WARNING"
                            $protocolResults[$cmd] = "No response"
                        }
                    } else {
                        Write-CommLog "Command '$cmd' timeout" "WARNING"
                        $protocolResults[$cmd] = "Timeout"
                    }
                } catch {
                    Write-CommLog "Command '$cmd' failed: $($_.Exception.Message)" "WARNING"
                    $protocolResults[$cmd] = "Error: $($_.Exception.Message)"
                }
            }
            
            $reader.Close()
            $writer.Close()
            $tcpClient.Close()
            
            Write-CommLog "Celestron protocol test completed" "SUCCESS"
            return $protocolResults
        } else {
            Write-CommLog "Celestron protocol test - connection failed" "ERROR"
            $tcpClient.Close()
            return @{}
        }
    } catch {
        Write-CommLog "Celestron protocol test failed: $($_.Exception.Message)" "ERROR"
        return @{}
    }
}

function Test-ProtocolCommands {
    Write-CommLog "Testing various protocol commands..." "INFO"
    
    # Common Celestron and HomeBrew commands to test
    $protocolCommands = @{
        'basic' = @("echo", "help", "info")
        'mount' = @("MS", "GV", "GA", "GZ", "GM")  # Mount Status, Get Version, Alt, Az, UTC Offset
        'wireless' = @("WIFI", "BT", "GPS")
        'system' = @("VERSION", "UPTIME", "STATUS")
    }
    
    $commandResults = @{}
    
    foreach ($category in $protocolCommands.Keys) {
        Write-CommLog "Testing $category commands..." "INFO"
        $categoryResults = @()
        
        foreach ($cmd in $protocolCommands[$category]) {
            # Placeholder for actual command testing
            # In a real implementation, this would send the command and capture response
            $categoryResults += @{
                'command' = $cmd
                'status' = 'Not Tested'
                'response' = 'N/A'
            }
        }
        
        $commandResults[$category] = $categoryResults
    }
    
    return $commandResults
}

function Get-CommunicationDiagnosticResults {
    param([string]$DeviceIP, [int]$Port, [string]$SerialPort)
    
    Write-CommLog "Starting communication diagnostic suite..." "INFO"
    
    $results = @{
        'timestamp' = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
        'device_ip' = $DeviceIP
        'telnet_port' = $Port
        'serial_port' = $SerialPort
        'tests' = @{}
        'overall_status' = 'UNKNOWN'
    }
    
    # Test telnet connection
    $results.tests['telnet_connection'] = Test-TelnetConnection -Host $DeviceIP -Port $Port
    
    # Test serial communication if port specified
    if ($SerialPort) {
        $results.tests['serial_communication'] = Test-SerialCommunication -Port $SerialPort
    }
    
    # Test Celestron protocol
    $results.tests['celestron_protocol'] = Test-CelestronProtocol -Host $DeviceIP -Port $Port
    
    # Test protocol commands
    $results.tests['protocol_commands'] = Test-ProtocolCommands
    
    # Calculate overall status
    $essentialTests = @($results.tests.telnet_connection)
    if ($SerialPort) {
        $essentialTests += $results.tests.serial_communication
    }
    
    $passedTests = $essentialTests | Where-Object { $_ -eq $true }
    
    if ($passedTests.Count -eq $essentialTests.Count) {
        $results.overall_status = 'PASS'
    } elseif ($passedTests.Count -gt 0) {
        $results.overall_status = 'PARTIAL'
    } else {
        $results.overall_status = 'FAIL'
    }
    
    return $results
}

function Show-CommunicationResults {
    param([hashtable]$Results)
    
    Write-Host ""
    Write-Host "📡 COMMUNICATION DIAGNOSTIC RESULTS 📡" -ForegroundColor Cyan
    Write-Host "=======================================" -ForegroundColor Cyan
    
    Write-Host "Device: $($Results.device_ip):$($Results.telnet_port)" -ForegroundColor White
    if ($Results.serial_port) {
        Write-Host "Serial: $($Results.serial_port)" -ForegroundColor White
    }
    Write-Host "Time: $($Results.timestamp)" -ForegroundColor White
    Write-Host "Status: " -NoNewline
    
    switch($Results.overall_status) {
        'PASS' { Write-Host "✓ PASSED" -ForegroundColor Green }
        'PARTIAL' { Write-Host "⚠ PARTIAL" -ForegroundColor Yellow }
        'FAIL' { Write-Host "✗ FAILED" -ForegroundColor Red }
        default { Write-Host "? UNKNOWN" -ForegroundColor Gray }
    }
    
    Write-Host ""
    Write-Host "Communication Tests:" -ForegroundColor Cyan
    
    # Telnet Connection
    $telnetStatus = if ($Results.tests.telnet_connection) { "✓ PASS" } else { "✗ FAIL" }
    $telnetColor = if ($Results.tests.telnet_connection) { "Green" } else { "Red" }
    Write-Host "  $telnetStatus - Telnet Connection" -ForegroundColor $telnetColor
    
    # Serial Communication
    if ($Results.serial_port) {
        $serialStatus = if ($Results.tests.serial_communication) { "✓ PASS" } else { "✗ FAIL" }
        $serialColor = if ($Results.tests.serial_communication) { "Green" } else { "Red" }
        Write-Host "  $serialStatus - Serial Communication ($($Results.serial_port))" -ForegroundColor $serialColor
    }
    
    # Celestron Protocol
    $protocolStatus = if ($Results.tests.celestron_protocol.Count -gt 0) { "✓ PASS" } else { "✗ FAIL" }
    $protocolColor = if ($Results.tests.celestron_protocol.Count -gt 0) { "Green" } else { "Red" }
    Write-Host "  $protocolStatus - Celestron Protocol" -ForegroundColor $protocolColor
    
    Write-Host ""
}

# Main execution
try {
    Write-CommLog "=== COMMUNICATION DIAGNOSTIC MODULE STARTING ===" "INFO"
    
    if ($VerboseOutput) {
        Write-CommLog "Verbose mode enabled" "INFO"
        Write-CommLog "Device IP: $DeviceIP" "INFO"
        Write-CommLog "Telnet Port: $TelnetPort" "INFO"
        if ($SerialPort) { Write-CommLog "Serial Port: $SerialPort" "INFO" }
    }
    
    # Run diagnostics
    $diagnosticResults = Get-CommunicationDiagnosticResults -DeviceIP $DeviceIP -Port $TelnetPort -SerialPort $SerialPort
    
    # Display results
    Show-CommunicationResults -Results $diagnosticResults
    
    # Save results
    $outputPath = Join-Path $PSScriptRoot "..\..\output\reports"
    if (-not (Test-Path $outputPath)) {
        New-Item -ItemType Directory -Path $outputPath -Force | Out-Null
    }
    
    $timestamp = Get-Date -Format "yyyy-MM-dd_HHmmss"
    $jsonPath = Join-Path $outputPath "communication_diagnostic_$timestamp.json"
    
    $diagnosticResults | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonPath -Encoding UTF8
    Write-CommLog "Results saved to: $jsonPath" "INFO"
    
    Write-CommLog "=== COMMUNICATION DIAGNOSTIC MODULE COMPLETED ===" "SUCCESS"
    
    return $diagnosticResults
    
} catch {
    Write-CommLog "Communication diagnostic failed: $($_.Exception.Message)" "ERROR"
    return @{
        'timestamp' = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
        'device_ip' = $DeviceIP
        'overall_status' = 'ERROR'
        'error' = $_.Exception.Message
    }
}