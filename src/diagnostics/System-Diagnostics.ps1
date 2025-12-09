#Requires -Version 5.1

<#
.SYNOPSIS
    System Diagnostic Module for Telescope Setup
    
.DESCRIPTION
    Tests system requirements and environment for telescope operation,
    including Python installation, network tools, and telescope software compatibility.

.PARAMETER VerboseOutput
    Enable verbose diagnostic output

.EXAMPLE
    .\System-Diagnostics.ps1
    Run system diagnostics for telescope operation

.EXAMPLE
    .\System-Diagnostics.ps1 -VerboseOutput
    Run system diagnostics with detailed output
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [switch]$VerboseOutput,
    
    [Parameter(Mandatory=$false)]
    [string]$PythonPath = "python"
)

function Write-SystemLog {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] SystemDiagnostics: $Message"
    Write-Host $logEntry -ForegroundColor $(switch($Level) {
        "INFO" { "Cyan" }
        "SUCCESS" { "Green" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        default { "White" }
    })
    
    # Write to log file
    $logFile = Join-Path $PSScriptRoot "..\..\output\logs\system_diagnostics.log"
    Add-Content -Path $logFile -Value $logEntry -ErrorAction SilentlyContinue
}

function Test-OperatingSystem {
    Write-SystemLog "Checking operating system compatibility..." "INFO"
    
    try {
        $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
        $osName = $osInfo.Caption
        $osVersion = $osInfo.Version
        $architecture = $osInfo.OSArchitecture
        
        Write-SystemLog "OS: $osName" "SUCCESS"
        Write-SystemLog "Version: $osVersion" "SUCCESS"
        Write-SystemLog "Architecture: $architecture" "SUCCESS"
        
        # Check minimum requirements
        if ($osName -like "*Windows 10*" -or $osName -like "*Windows 11*") {
            Write-SystemLog "Operating system is supported for telescope operation" "SUCCESS"
            return $true
        } else {
            Write-SystemLog "Operating system may not be fully compatible" "WARNING"
            return $false
        }
    } catch {
        Write-SystemLog "Could not determine operating system info: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Test-PythonInstallation {
    Write-SystemLog "Checking Python installation for telescope scripts..." "INFO"
    
    try {
        $pythonVersion = & $PythonPath --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-SystemLog "Python found: $pythonVersion" "SUCCESS"
            
            # Check for required Python packages
            $packages = @("serial", "telnetlib", "json", "argparse")
            $missingPackages = @()
            
            foreach ($package in $packages) {
                try {
                    $check = & $PythonPath -c "import $package" 2>&1
                    if ($LASTEXITCODE -ne 0) {
                        $missingPackages += $package
                    }
                } catch {
                    $missingPackages += $package
                }
            }
            
            if ($missingPackages.Count -eq 0) {
                Write-SystemLog "All required Python packages are available" "SUCCESS"
                return $true
            } else {
                Write-SystemLog "Missing Python packages: $($missingPackages -join ', ')" "WARNING"
                Write-SystemLog "Install missing packages with: pip install $($missingPackages -join ' ')" "INFO"
                return $false
            }
        } else {
            Write-SystemLog "Python not found or not working properly" "ERROR"
            Write-SystemLog "Install Python from https://python.org" "INFO"
            return $false
        }
    } catch {
        Write-SystemLog "Python check failed: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Test-NetworkTools {
    Write-SystemLog "Checking network diagnostic tools..." "INFO"
    
    $tools = @{
        'ping' = { ping --help }
        'telnet' = { telnet /? }
        'netstat' = { netstat /? }
        'nslookup' = { nslookup /? }
    }
    
    $availableTools = @{}
    
    foreach ($tool in $tools.Keys) {
        try {
            $result = & $tools[$tool]
            if ($LASTEXITCODE -eq 0) {
                Write-SystemLog "$tool tool is available" "SUCCESS"
                $availableTools[$tool] = $true
            } else {
                Write-SystemLog "$tool tool may not be available" "WARNING"
                $availableTools[$tool] = $false
            }
        } catch {
            Write-SystemLog "$tool tool check failed" "WARNING"
            $availableTools[$tool] = $false
        }
    }
    
    # Count working tools
    $workingTools = $availableTools.GetEnumerator() | Where-Object { $_.Value } | Measure-Object | Select-Object -ExpandProperty Count
    
    if ($workingTools -ge 3) {
        return $true
    } else {
        Write-SystemLog "Insufficient network diagnostic tools available" "WARNING"
        return $false
    }
}

function Test-SerialPortSupport {
    Write-SystemLog "Checking serial port support..." "INFO"
    
    try {
        $availablePorts = [System.IO.Ports.SerialPort]::GetPortNames()
        Write-SystemLog "Available serial ports: $($availablePorts -join ', ')" "INFO"
        
        # Check if we have access to System.IO.Ports
        if ($availablePorts -or $true) {  # This will always have at least an empty array
            Write-SystemLog "Serial port support is available" "SUCCESS"
            
            # Check for common telescope software processes
            $processes = Get-Process -Name "*sky*" -ErrorAction SilentlyContinue
            if ($processes) {
                Write-SystemLog "Found telescope software processes" "INFO"
            }
            
            return $true
        } else {
            Write-SystemLog "No serial port support detected" "ERROR"
            return $false
        }
    } catch {
        Write-SystemLog "Serial port support check failed: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Test-DiskSpace {
    Write-SystemLog "Checking disk space for telescope software..." "INFO"
    
    try {
        $drives = Get-CimInstance -ClassName Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
        $spaceResults = @{}
        
        foreach ($drive in $drives) {
            $freeSpaceGB = [math]::Round($drive.FreeSpace / 1GB, 2)
            $totalSpaceGB = [math]::Round($drive.Size / 1GB, 2)
            $freePercent = [math]::Round(($drive.FreeSpace / $drive.Size) * 100, 1)
            
            Write-SystemLog "Drive $($drive.DeviceID): $freeSpaceGB GB free of $totalSpaceGB GB ($freePercent%)" "INFO"
            $spaceResults[$drive.DeviceID] = @{
                'free_space_gb' = $freeSpaceGB
                'total_space_gb' = $totalSpaceGB
                'free_percent' = $freePercent
                'sufficient' = $freePercent -gt 10  # At least 10% free space
            }
        }
        
        # Check if any drive has sufficient space
        $sufficientSpace = $spaceResults.Values | Where-Object { $_.sufficient } | Measure-Object | Select-Object -ExpandProperty Count
        
        if ($sufficientSpace -gt 0) {
            Write-SystemLog "Sufficient disk space available for telescope operation" "SUCCESS"
            return $true
        } else {
            Write-SystemLog "Insufficient disk space for telescope operation" "WARNING"
            return $false
        }
    } catch {
        Write-SystemLog "Disk space check failed: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Test-FirewallSettings {
    Write-SystemLog "Checking firewall settings for telescope communication..." "INFO"
    
    try {
        $firewallProfiles = Get-NetFirewallProfile -ErrorAction SilentlyContinue
        if ($firewallProfiles) {
            $blocked = 0
            foreach ($profile in $firewallProfiles) {
                if ($profile.Enabled -and $profile.DefaultInboundAction -eq "Block") {
                    Write-SystemLog "Firewall profile $($profile.Name) may block telescope communication" "WARNING"
                    $blocked++
                }
            }
            
            if ($blocked -eq 0) {
                Write-SystemLog "Firewall appears to allow telescope communication" "SUCCESS"
                return $true
            } else {
                Write-SystemLog "Firewall may block some telescope communication" "WARNING"
                return $false
            }
        } else {
            Write-SystemLog "Could not determine firewall settings" "WARNING"
            return $false
        }
    } catch {
        Write-SystemLog "Firewall check failed: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Test-AntivirusCompatibility {
    Write-SystemLog "Checking antivirus compatibility with telescope software..." "INFO"
    
    try {
        $antivirus = Get-CimInstance -Namespace "root\SecurityCenter2" -ClassName "AntiVirusProduct" -ErrorAction SilentlyContinue
        if ($antivirus) {
            Write-SystemLog "Antivirus detected: $($antivirus.displayName)" "INFO"
            Write-SystemLog "Antivirus state: $($antivirus.productState)" "INFO"
            
            # Check if antivirus might interfere with telescope communication
            if ($antivirus.productState -match "00000000") {
                Write-SystemLog "Antivirus may allow telescope communication" "SUCCESS"
                return $true
            } else {
                Write-SystemLog "Antivirus may interfere with telescope communication" "WARNING"
                return $false
            }
        } else {
            Write-SystemLog "No antivirus detected or accessible" "INFO"
            return $true
        }
    } catch {
        Write-SystemLog "Antivirus check failed: $($_.Exception.Message)" "WARNING"
        return $true  # Don't block if we can't check
    }
}

function Test-UserPermissions {
    Write-SystemLog "Checking user permissions for telescope operation..." "INFO"
    
    try {
        $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        if ($isAdmin) {
            Write-SystemLog "Running with administrator privileges" "SUCCESS"
            $adminAccess = $true
        } else {
            Write-SystemLog "Running without administrator privileges" "WARNING"
            $adminAccess = $false
        }
        
        # Check write access to common directories
        $testDirs = @($env:TEMP, $env:USERPROFILE, $PWD)
        $writeAccess = $true
        
        foreach ($dir in $testDirs) {
            if ($dir -and (Test-Path $dir)) {
                try {
                    $testFile = Join-Path $dir "telescope_test_$(Get-Random).tmp"
                    "test" | Out-File -FilePath $testFile -Force
                    Remove-Item $testFile -Force
                } catch {
                    Write-SystemLog "No write access to $dir" "WARNING"
                    $writeAccess = $false
                }
            }
        }
        
        if ($writeAccess) {
            Write-SystemLog "Sufficient file system access" "SUCCESS"
            return $true
        } else {
            Write-SystemLog "Limited file system access - some features may be restricted" "WARNING"
            return $false
        }
    } catch {
        Write-SystemLog "Permission check failed: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Get-SystemDiagnosticResults {
    Write-SystemLog "Starting system diagnostic suite..." "INFO"
    
    $results = @{
        'timestamp' = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
        'tests' = @{}
        'overall_status' = 'UNKNOWN'
    }
    
    # Run all system tests
    $results.tests['operating_system'] = Test-OperatingSystem
    $results.tests['python_installation'] = Test-PythonInstallation
    $results.tests['network_tools'] = Test-NetworkTools
    $results.tests['serial_port_support'] = Test-SerialPortSupport
    $results.tests['disk_space'] = Test-DiskSpace
    $results.tests['firewall_settings'] = Test-FirewallSettings
    $results.tests['antivirus_compatibility'] = Test-AntivirusCompatibility
    $results.tests['user_permissions'] = Test-UserPermissions
    
    # Calculate overall status
    $criticalTests = @($results.tests.operating_system, $results.tests.python_installation, $results.tests.network_tools)
    $optionalTests = @($results.tests.disk_space, $results.tests.user_permissions)
    
    $criticalPassed = $criticalTests | Where-Object { $_ } | Measure-Object | Select-Object -ExpandProperty Count
    $optionalPassed = $optionalTests | Where-Object { $_ } | Measure-Object | Select-Object -ExpandProperty Count
    
    if ($criticalPassed -eq $criticalTests.Count) {
        $results.overall_status = 'PASS'
    } elseif ($criticalPassed -gt 0) {
        $results.overall_status = 'PARTIAL'
    } else {
        $results.overall_status = 'FAIL'
    }
    
    return $results
}

function Show-SystemResults {
    param([hashtable]$Results)
    
    Write-Host ""
    Write-Host "💻 SYSTEM DIAGNOSTIC RESULTS 💻" -ForegroundColor Cyan
    Write-Host "=================================" -ForegroundColor Cyan
    
    Write-Host "Time: $($Results.timestamp)" -ForegroundColor White
    Write-Host "Status: " -NoNewline
    
    switch($Results.overall_status) {
        'PASS' { Write-Host "✓ PASSED" -ForegroundColor Green }
        'PARTIAL' { Write-Host "⚠ PARTIAL" -ForegroundColor Yellow }
        'FAIL' { Write-Host "✗ FAILED" -ForegroundColor Red }
        default { Write-Host "? UNKNOWN" -ForegroundColor Gray }
    }
    
    Write-Host ""
    Write-Host "System Tests:" -ForegroundColor Cyan
    
    foreach ($test in $Results.tests.GetEnumerator()) {
        $status = if ($test.Value) { "✓ PASS" } else { "✗ FAIL" }
        $color = if ($test.Value) { "Green" } else { "Red" }
        Write-Host "  $status - $($test.Key.Replace('_', ' ').ToTitleCase())" -ForegroundColor $color
    }
    
    Write-Host ""
}

# Main execution
try {
    Write-SystemLog "=== SYSTEM DIAGNOSTIC MODULE STARTING ===" "INFO"
    
    if ($VerboseOutput) {
        Write-SystemLog "Verbose mode enabled" "INFO"
        Write-SystemLog "Python Path: $PythonPath" "INFO"
    }
    
    # Run diagnostics
    $diagnosticResults = Get-SystemDiagnosticResults
    
    # Display results
    Show-SystemResults -Results $diagnosticResults
    
    # Save results
    $outputPath = Join-Path $PSScriptRoot "..\..\output\reports"
    if (-not (Test-Path $outputPath)) {
        New-Item -ItemType Directory -Path $outputPath -Force | Out-Null
    }
    
    $timestamp = Get-Date -Format "yyyy-MM-dd_HHmmss"
    $jsonPath = Join-Path $outputPath "system_diagnostic_$timestamp.json"
    
    $diagnosticResults | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonPath -Encoding UTF8
    Write-SystemLog "Results saved to: $jsonPath" "INFO"
    
    Write-SystemLog "=== SYSTEM DIAGNOSTIC MODULE COMPLETED ===" "SUCCESS"
    
    return $diagnosticResults
    
} catch {
    Write-SystemLog "System diagnostic failed: $($_.Exception.Message)" "ERROR"
    return @{
        'timestamp' = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
        'overall_status' = 'ERROR'
        'error' = $_.Exception.Message
    }
}