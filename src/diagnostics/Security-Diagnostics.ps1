#Requires -Version 5.1

<#
.SYNOPSIS
    Security Diagnostic Module
    
.DESCRIPTION
    Basic security checks for the HomeBrew device.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$DeviceIP = "192.168.1.100",
    
    [Parameter(Mandatory=$false)]
    [switch]$VerboseOutput
)

function Write-SecLog {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] SecurityDiagnostics: $Message"
    Write-Host $logEntry -ForegroundColor $(switch($Level) {
        "INFO" { "Cyan" }
        "SUCCESS" { "Green" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        default { "White" }
    })
}

function Test-PortExposure {
    param([string]$IP)
    Write-SecLog "Checking port exposure on $IP..." "INFO"
    
    $criticalPorts = @(2000, 23, 80)
    $results = @{}
    
    foreach ($port in $criticalPorts) {
        try {
            $tcpClient = New-Object System.Net.Sockets.TcpClient
            $connect = $tcpClient.BeginConnect($IP, $port, $null, $null)
            $wait = $connect.AsyncWaitHandle.WaitOne(1000, $false)
            
            if ($wait) {
                $tcpClient.EndConnect($connect)
                $tcpClient.Close()
                Write-SecLog "Port $port is OPEN" "WARNING"
                $results[$port] = "OPEN"
            } else {
                Write-SecLog "Port $port is CLOSED" "SUCCESS"
                $results[$port] = "CLOSED"
            }
        } catch {
             $results[$port] = "CLOSED"
        }
    }
    
    return $results
}

function Get-SecurityDiagnosticResults {
    param([string]$DeviceIP)
    
    Write-SecLog "Starting security diagnostic suite..." "INFO"
    
    $results = @{
        'timestamp' = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
        'module' = 'Security'
        'tests' = @{}
        'overall_status' = 'UNKNOWN'
    }
    
    # Test Port Exposure
    $ports = Test-PortExposure -IP $DeviceIP
    $results.tests['port_exposure'] = $ports
    
    # Logic: It is normal for these ports to be open on the LAN, 
    # but we just report it.
    
    if ($ports[2000] -eq "OPEN") {
        $results.overall_status = 'PASS' # Expected for operation
    } else {
        $results.overall_status = 'WARNING' # Might be blocked
    }
    
    return $results
}

# Main execution
try {
    $diagnosticResults = Get-SecurityDiagnosticResults -DeviceIP $DeviceIP
    return $diagnosticResults
} catch {
    Write-SecLog "Security diagnostic failed: $($_.Exception.Message)" "ERROR"
    return @{
        'timestamp' = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
        'overall_status' = 'ERROR'
        'error' = $_.Exception.Message
    }
}
