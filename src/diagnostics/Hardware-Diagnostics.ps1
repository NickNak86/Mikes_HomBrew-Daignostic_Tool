#Requires -Version 5.1

<#
.SYNOPSIS
    Hardware Diagnostic Module
    
.DESCRIPTION
    Checks local hardware interfaces (Serial) and queries remote device hardware status.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$DeviceIP,
    
    [Parameter(Mandatory=$false)]
    [switch]$VerboseOutput
)

function Write-HwLog {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] HardwareDiagnostics: $Message"
    Write-Host $logEntry -ForegroundColor $(switch($Level) {
        "INFO" { "Cyan" }
        "SUCCESS" { "Green" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        default { "White" }
    })
}

function Test-SerialPorts {
    Write-HwLog "Enumerating local serial ports..." "INFO"
    
    try {
        $ports = [System.IO.Ports.SerialPort]::GetPortNames()
        $result = @{
            'available_ports' = $ports
            'count' = $ports.Count
        }
        
        if ($ports.Count -gt 0) {
            Write-HwLog "Found serial ports: $($ports -join ', ')" "SUCCESS"
            
            # Check for specific driver types if possible (Windows only usually)
            if ($IsWindows) {
                $pnp = Get-WmiObject Win32_PnPEntity | Where-Object { $_.Name -match "COM\d+" }
                $result['details'] = @()
                foreach ($p in $pnp) {
                    $info = @{
                        'name' = $p.Name
                        'description' = $p.Description
                        'manufacturer' = $p.Manufacturer
                    }
                    $result['details'] += $info
                    Write-HwLog "  $($p.Name): $($p.Description)" "INFO"
                    
                    if ($p.Description -match "Prolific|FTDI") {
                         Write-HwLog "  Found telescope-compatible adapter: $($p.Description)" "SUCCESS"
                    }
                }
            }
        } else {
            Write-HwLog "No serial ports found" "WARNING"
        }
        
        return $result
    } catch {
        Write-HwLog "Serial port enumeration failed: $($_.Exception.Message)" "ERROR"
        return @{ 'error' = $_.Exception.Message }
    }
}

function Get-HardwareDiagnosticResults {
    param([string]$DeviceIP)
    
    Write-HwLog "Starting hardware diagnostic suite..." "INFO"
    
    $results = @{
        'timestamp' = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
        'module' = 'Hardware'
        'tests' = @{}
        'overall_status' = 'UNKNOWN'
    }
    
    # Test local serial ports
    $serialResults = Test-SerialPorts
    $results.tests['serial_ports'] = $serialResults
    
    # Determine status
    if ($serialResults.count -gt 0) {
        $results.overall_status = 'PASS'
    } else {
        $results.overall_status = 'WARNING'
    }
    
    return $results
}

# Main execution
try {
    $diagnosticResults = Get-HardwareDiagnosticResults -DeviceIP $DeviceIP
    return $diagnosticResults
} catch {
    Write-HwLog "Hardware diagnostic failed: $($_.Exception.Message)" "ERROR"
    return @{
        'timestamp' = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
        'overall_status' = 'ERROR'
        'error' = $_.Exception.Message
    }
}
