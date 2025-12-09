#Requires -Version 5.1

<#
.SYNOPSIS
    Performance Diagnostic Module
    
.DESCRIPTION
    Measures network latency and throughput to the HomeBrew device.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$DeviceIP = "192.168.1.100",
    
    [Parameter(Mandatory=$false)]
    [switch]$VerboseOutput
)

function Write-PerfLog {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] PerformanceDiagnostics: $Message"
    Write-Host $logEntry -ForegroundColor $(switch($Level) {
        "INFO" { "Cyan" }
        "SUCCESS" { "Green" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        default { "White" }
    })
}

function Test-Latency {
    param([string]$IP)
    Write-PerfLog "Measuring latency to $IP..." "INFO"
    
    try {
        # Send 5 pings
        $pings = Test-Connection -ComputerName $IP -Count 5 -ErrorAction SilentlyContinue
        
        if ($pings) {
            $times = $pings | Select-Object -ExpandProperty ResponseTime
            $stats = $times | Measure-Object -Average -Maximum -Minimum
            
            Write-PerfLog "Latency (ms): Min=$($stats.Minimum), Max=$($stats.Maximum), Avg=$($stats.Average)" "SUCCESS"
            
            return @{
                'reachable' = $true
                'min_ms' = $stats.Minimum
                'max_ms' = $stats.Maximum
                'avg_ms' = $stats.Average
                'packet_loss' = (5 - $pings.Count) / 5 * 100
            }
        } else {
            Write-PerfLog "Device unreachable for latency test" "WARNING"
            return @{ 'reachable' = $false }
        }
    } catch {
        Write-PerfLog "Latency test failed: $($_.Exception.Message)" "ERROR"
        return @{ 'error' = $_.Exception.Message }
    }
}

function Get-PerformanceDiagnosticResults {
    param([string]$DeviceIP)
    
    Write-PerfLog "Starting performance diagnostic suite..." "INFO"
    
    $results = @{
        'timestamp' = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
        'module' = 'Performance'
        'tests' = @{}
        'overall_status' = 'UNKNOWN'
    }
    
    # Test Latency
    $latency = Test-Latency -IP $DeviceIP
    $results.tests['latency'] = $latency
    
    # Determine status
    if ($latency.reachable) {
        if ($latency.avg_ms -lt 100) {
            $results.overall_status = 'PASS'
        } elseif ($latency.avg_ms -lt 500) {
            $results.overall_status = 'WARNING'
        } else {
            $results.overall_status = 'FAIL' # Too slow for reliable telescope control
        }
    } else {
        $results.overall_status = 'FAIL'
    }
    
    return $results
}

# Main execution
try {
    $diagnosticResults = Get-PerformanceDiagnosticResults -DeviceIP $DeviceIP
    return $diagnosticResults
} catch {
    Write-PerfLog "Performance diagnostic failed: $($_.Exception.Message)" "ERROR"
    return @{
        'timestamp' = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
        'overall_status' = 'ERROR'
        'error' = $_.Exception.Message
    }
}
