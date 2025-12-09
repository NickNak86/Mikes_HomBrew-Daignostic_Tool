<#
.SYNOPSIS
    Python Helper Module for Telescope Diagnostics
    
.DESCRIPTION
    Provides safe execution and integration of Python telescope communication scripts.
    Handles Python installation detection, script execution, and result parsing.
    
.PARAMETER DeviceIP
    IP address of the HomeBrew device
    
.PARAMETER SerialPort
    Serial port for direct Celestron mount communication
    
.PARAMETER PythonPath
    Path to Python executable (auto-detected if not specified)
    
.PARAMETER TimeoutSeconds
    Timeout for Python script execution in seconds
    
.PARAMETER ScriptName
    Name of the Python script to execute
    
.PARAMETER ScriptArgs
    Arguments to pass to the Python script
    
.EXAMPLE
    $result = Invoke-PythonTelescopeScript -DeviceIP "192.168.1.100" -ScriptName "telescope_comm.py"
#>

function Invoke-PythonTelescopeScript {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$DeviceIP,
        
        [Parameter(Mandatory=$false)]
        [string]$SerialPort,
        
        [Parameter(Mandatory=$false)]
        [string]$PythonPath = "python",
        
        [Parameter(Mandatory=$false)]
        [int]$TimeoutSeconds = 60,
        
        [Parameter(Mandatory=$true)]
        [string]$ScriptName,
        
        [Parameter(Mandatory=$false)]
        [string[]]$ScriptArgs = @(),
        
        [Parameter(Mandatory=$false)]
        [switch]$VerboseOutput
    )
    
    $result = @{
        Success = $false
        ScriptName = $ScriptName
        ExecutionTime = Get-Date
        Duration = $null
        Output = $null
        Error = $null
        ExitCode = $null
        PythonVersion = $null
        JSONOutput = $null
        Warnings = @()
        Recommendations = @()
    }
    
    try {
        $startTime = Get-Date
        
        # Validate Python installation
        $pythonCheck = Test-PythonInstallation -PythonPath $PythonPath
        if (-not $pythonCheck.Success) {
            $result.Error = "Python not available: $($pythonCheck.Error)"
            $result.Recommendations += "Install Python 3.6+ from https://python.org"
            $result.Recommendations += "Ensure Python is in system PATH or specify -PythonPath"
            return $result
        }
        $result.PythonVersion = $pythonCheck.Version
        
        # Build script path
        $scriptPath = Join-Path $PSScriptRoot "..\..\python_scripts" $ScriptName
        if (-not (Test-Path $scriptPath)) {
            $result.Error = "Python script not found: $scriptPath"
            $result.Recommendations += "Verify Python scripts exist in python_scripts directory"
            return $result
        }
        
        # Build command arguments
        $arguments = @()
        
        # Add device-specific arguments
        if ($DeviceIP) {
            $arguments += "--host"
            $arguments += $DeviceIP
        }
        
        if ($SerialPort) {
            $arguments += "--serial"
            $arguments += $SerialPort
        }
        
        # Add custom arguments
        if ($ScriptArgs) {
            $arguments += $ScriptArgs
        }
        
        # Add JSON output flag for structured data
        if (-not ($arguments -contains "--json")) {
            $arguments += "--json"
        }
        
        if ($VerboseOutput) {
            $arguments += "--verbose"
        }
        
        # Execute Python script
        Write-Verbose "Executing: $PythonPath `"$scriptPath`" $($arguments -join ' ')"
        
        $processInfo = New-Object System.Diagnostics.ProcessStartInfo
        $processInfo.FileName = $PythonPath
        $processInfo.Arguments = "`"$scriptPath`" $($arguments -join ' ')"
        $processInfo.RedirectStandardOutput = $true
        $processInfo.RedirectStandardError = $true
        $processInfo.UseShellExecute = $false
        $processInfo.CreateNoWindow = $true
        
        $process = New-Object System.Diagnostics.Process
        $process.StartInfo = $processInfo
        $process.Start() | Out-Null
        
        # Wait for process with timeout
        $waited = $false
        if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
            $process.Kill()
            $result.Error = "Script execution timeout after $TimeoutSeconds seconds"
            $result.Recommendations += "Increase timeout with -TimeoutSeconds parameter"
            $result.Recommendations += "Check device responsiveness and network connectivity"
            $waited = $true
        }
        
        # Get output
        $stdout = $process.StandardOutput.ReadToEnd()
        $stderr = $process.StandardError.ReadToEnd()
        $result.ExitCode = $process.ExitCode
        
        $endTime = Get-Date
        $result.Duration = $endTime - $startTime
        
        # Process results
        if ($process.ExitCode -eq 0) {
            $result.Success = $true
            $result.Output = $stdout
            
            # Try to parse JSON output
            if ($stdout) {
                try {
                    $result.JSONOutput = $stdout | ConvertFrom-Json
                    Write-Verbose "Successfully parsed JSON output"
                } catch {
                    Write-Verbose "Failed to parse JSON output: $_"
                    $result.Warnings += "JSON output parsing failed, raw output available"
                }
            }
        } else {
            $result.Error = $stderr
            if (-not $result.Error) {
                $result.Error = "Script failed with exit code: $($process.ExitCode)"
            }
            
            # Add recommendations based on common errors
            if ($stderr -match "Connection.*refused|Connection.*timeout") {
                $result.Recommendations += "Check HomeBrew device network connectivity"
                $result.Recommendations += "Verify device IP address and telnet port 2000"
            }
            if ($stderr -match "Serial.*not.*available|Port.*not.*found") {
                $result.Recommendations += "Verify Celestron cable connections"
                $result.Recommendations += "Check available COM ports with Python script"
            }
            if ($stderr -match "Python.*not.*found|command.*not.*found") {
                $result.Recommendations += "Install Python 3.6+ from https://python.org"
                $result.Recommendations += "Try alternative Python path: py, python3, or full path"
            }
        }
        
    } catch {
        $result.Error = "Exception during script execution: $($_.Exception.Message)"
        $result.Recommendations += "Verify Python installation and script permissions"
        Write-Error $_.Exception.Message
    }
    
    return $result
}

<#
.SYNOPSIS
    Test Python installation and capabilities
    
.PARAMETER PythonPath
    Path to Python executable to test
    
.EXAMPLE
    $check = Test-PythonInstallation -PythonPath "python"
#>
function Test-PythonInstallation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$PythonPath = "python"
    )
    
    $result = @{
        Success = $false
        Path = $PythonPath
        Version = $null
        Error = $null
        RequiredModules = @{
            serial = $false
            telnetlib = $false
            json = $false
            argparse = $false
            socket = $false
        }
    }
    
    try {
        # Use a temporary directory for all temp files to ensure cleanup
        $tempDir = [System.IO.Path]::GetTempPath()
        $uniqueId = [System.IO.Path]::GetRandomFileName().Replace('.', '')
        $tempStdout = Join-Path $tempDir "python_stdout_$uniqueId.txt"
        $tempStderr = Join-Path $tempDir "python_stderr_$uniqueId.txt"
        $tempModuleTest = Join-Path $tempDir "python_module_test_$uniqueId.py"
        $tempModuleOutput = Join-Path $tempDir "python_modules_$uniqueId.txt"

        # Test Python version
        $versionProcess = Start-Process -FilePath $PythonPath -ArgumentList "--version" -Wait -PassThru -RedirectStandardOutput $tempStdout -RedirectStandardError $tempStderr

        if ($versionProcess.ExitCode -eq 0) {
            $version = (Get-Content $tempStdout | Select-Object -First 1).Trim()
            $result.Version = $version

            # Check if Python 3.6+
            if ($version -match "Python (\d+)\.(\d+)") {
                $major = [int]$matches[1]
                $minor = [int]$matches[2]

                if ($major -eq 3 -and $minor -ge 6) {
                    $result.Success = $true
                } else {
                    $result.Error = "Python 3.6+ required, found: $version"
                }
            } else {
                $result.Error = "Unable to parse Python version: $version"
            }
        } else {
            $result.Error = "Python not found or not executable"
        }

        # Test required modules
        if ($result.Success) {
            $moduleTest = @"
    try:
    import serial
    print("serial: OK")
    except ImportError:
    print("serial: MISSING")

    try:
    import telnetlib
    print("telnetlib: OK")
    except ImportError:
    print("telnetlib: MISSING")

    try:
    import json
    print("json: OK")
    except ImportError:
    print("json: MISSING")

    try:
    import argparse
    print("argparse: OK")
    except ImportError:
    print("argparse: MISSING")

    try:
    import socket
    print("socket: OK")
    except ImportError:
    print("socket: MISSING")
    "@

            $moduleTest | Out-File -FilePath $tempModuleTest -Encoding UTF8

            $moduleProcess = Start-Process -FilePath $PythonPath -ArgumentList $tempModuleTest -Wait -PassThru -RedirectStandardOutput $tempModuleOutput -ErrorAction SilentlyContinue

            if ($moduleProcess -and $moduleProcess.ExitCode -eq 0) {
                $moduleOutput = Get-Content $tempModuleOutput -ErrorAction SilentlyContinue
                foreach ($line in $moduleOutput) {
                    if ($line -match "(\w+): (OK|MISSING)") {
                        $moduleName = $matches[1]
                        $status = $matches[2]
                        $result.RequiredModules[$moduleName] = ($status -eq "OK")
                    }
                }

                # Check if all required modules are available
                $missingModules = @()
                foreach ($module in $result.RequiredModules.Keys) {
                    if (-not $result.RequiredModules[$module]) {
                        $missingModules += $module
                    }
                }

                if ($missingModules.Count -gt 0) {
                    $result.Error = "Missing required Python modules: $($missingModules -join ', ')"
                    $result.Success = $false
                }
            }
        }

    } catch {
        $result.Error = "Exception testing Python installation: $($_.Exception.Message)"
    } finally {
        # Clean up ALL temp files with force flag to ensure deletion
        @($tempStdout, $tempStderr, $tempModuleTest, $tempModuleOutput) | ForEach-Object {
            if ($_ -and (Test-Path $_)) {
                Remove-Item $_ -Force -ErrorAction SilentlyContinue
            }
        }
    }
    
    return $result
}

<#
.SYNOPSIS
    Execute telescope communication tests via Python
    
.PARAMETER DeviceIP
    IP address of the HomeBrew device
    
.PARAMETER SerialPort
    Serial port for Celestron mount communication
    
.PARAMETER PythonPath
    Path to Python executable
    
.EXAMPLE
    $telescopeResult = Invoke-TelescopePythonTests -DeviceIP "192.168.1.100"
#>
function Invoke-TelescopePythonTests {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$DeviceIP,
        
        [Parameter(Mandatory=$false)]
        [string]$SerialPort,
        
        [Parameter(Mandatory=$false)]
        [string]$PythonPath = "python",
        
        [Parameter(Mandatory=$false)]
        [int]$TimeoutSeconds = 90
    )
    
    Write-Verbose "Starting telescope Python tests for device: $DeviceIP"
    
    $results = @{
        telescope_comm = $null
        wifi_bt_gps = $null
        overall_success = $false
        summary = @{}
    }
    
    # Test telescope communication script
    $telescopeArgs = @()
    if ($SerialPort) {
        $telescopeArgs += "--serial"
        $telescopeArgs += $SerialPort
    }
    
    $results.telescope_comm = Invoke-PythonTelescopeScript `
        -DeviceIP $DeviceIP `
        -SerialPort $SerialPort `
        -PythonPath $PythonPath `
        -TimeoutSeconds $TimeoutSeconds `
        -ScriptName "telescope_comm.py" `
        -ScriptArgs $telescopeArgs `
        -VerboseOutput:$PSBoundParameters.ContainsKey('Verbose')
    
    # Test WiFi/BT/GPS script
    $wifiArgs = @()
    $results.wifi_bt_gps = Invoke-PythonTelescopeScript `
        -DeviceIP $DeviceIP `
        -PythonPath $PythonPath `
        -TimeoutSeconds ($TimeoutSeconds - 30) `
        -ScriptName "wifi_bt_gps_test.py" `
        -ScriptArgs $wifiArgs `
        -VerboseOutput:$PSBoundParameters.ContainsKey('Verbose')
    
    # Determine overall success
    $results.overall_success = ($results.telescope_comm.Success -and $results.wifi_bt_gps.Success)
    
    # Create summary
    $results.summary = @{
        python_available = ($results.telescope_comm.PythonVersion -ne $null)
        python_version = $results.telescope_comm.PythonVersion
        telescope_script_success = $results.telescope_comm.Success
        wifi_script_success = $results.wifi_bt_gps.Success
        total_execution_time = [math]::Round((($results.telescope_comm.Duration ?? [TimeSpan]::Zero) + ($results.wifi_bt_gps.Duration ?? [TimeSpan]::Zero)).TotalSeconds, 2)
        warnings = @($results.telescope_comm.Warnings + $results.wifi_bt_gps.Warnings | Select-Object -Unique)
        recommendations = @($results.telescope_comm.Recommendations + $results.wifi_bt_gps.Recommendations | Select-Object -Unique)
    }
    
    return $results
}

<#
.SYNOPSIS
    Parse Python script output and extract key information
    
.PARAMETER PythonResult
    Result object from Invoke-PythonTelescopeScript
    
.PARAMETER OutputType
    Type of output to extract: Summary, Telnet, Serial, WiFi, BT, GPS
    
.EXAMPLE
    $telnetInfo = Get-PythonOutputSummary -PythonResult $result -OutputType "Telnet"
#>
function Get-PythonOutputSummary {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [object]$PythonResult,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("Summary", "Telnet", "Serial", "WiFi", "BT", "GPS", "All")]
        [string]$OutputType = "Summary"
    )
    
    if (-not $PythonResult.Success -or -not $PythonResult.JSONOutput) {
        return @{
            Available = $false
            Error = $PythonResult.Error
            Recommendations = $PythonResult.Recommendations
        }
    }
    
    $jsonData = $PythonResult.JSONOutput
    $summary = @{
        Available = $true
        ScriptName = $PythonResult.ScriptName
        ExecutionTime = $PythonResult.ExecutionTime
        Duration = $PythonResult.Duration
        RawOutput = $PythonResult.Output
    }
    
    # Extract common information
    if ($jsonData.PSObject.Properties.Name -contains "host") {
        $summary.Host = $jsonData.host
    }
    if ($jsonData.PSObject.Properties.Name -contains "port") {
        $summary.Port = $jsonData.port
    }
    if ($jsonData.PSObject.Properties.Name -contains "status") {
        $summary.Status = $jsonData.status
    }
    if ($jsonData.PSObject.Properties.Name -contains "response_time") {
        $summary.ResponseTime = $jsonData.response_time
    }
    
    # Extract telnet-specific information
    if ($OutputType -eq "Telnet" -and $jsonData.telnet) {
        $summary.Telnet = @{
            Connected = $jsonData.telnet.connected
            ResponseTime = $jsonData.telnet.response_time
            Protocol = $jsonData.telnet.protocol
            Commands = $jsonData.telnet.commands_tested
            SuccessRate = $jsonData.telnet.success_rate
        }
    }
    
    # Extract serial-specific information
    if ($OutputType -eq "Serial" -and $jsonData.serial) {
        $summary.Serial = @{
            Available = $jsonData.serial.available
            Port = $jsonData.serial.port
            BaudRate = $jsonData.serial.baud_rate
            Connection = $jsonData.serial.connection_status
            Commands = $jsonData.serial.commands_tested
            SuccessRate = $jsonData.serial.success_rate
        }
    }
    
    # Extract WiFi information
    if ($OutputType -match "WiFi|All" -and $jsonData.wifi) {
        $summary.WiFi = @{
            Status = $jsonData.wifi.status
            SignalStrength = $jsonData.wifi.signal_strength
            SSID = $jsonData.wifi.ssid
            Channel = $jsonData.wifi.channel
            ConnectionType = $jsonData.wifi.connection_type
        }
    }
    
    # Extract Bluetooth information
    if ($OutputType -match "BT|All" -and $jsonData.bluetooth) {
        $summary.Bluetooth = @{
            Status = $jsonData.bluetooth.status
            Discoverable = $jsonData.bluetooth.discoverable
            PairedDevices = $jsonData.bluetooth.paired_devices
            ConnectionType = $jsonData.bluetooth.connection_type
        }
    }
    
    # Extract GPS information
    if ($OutputType -match "GPS|All" -and $jsonData.gps) {
        $summary.GPS = @{
            Status = $jsonData.gps.status
            Satellites = $jsonData.gps.satellites
            Fix = $jsonData.gps.fix
            Location = $jsonData.gps.location
            Accuracy = $jsonData.gps.accuracy
        }
    }
    
    return $summary
}

Export-ModuleMember -Function @(
    'Invoke-PythonTelescopeScript',
    'Test-PythonInstallation', 
    'Invoke-TelescopePythonTests',
    'Get-PythonOutputSummary'
)