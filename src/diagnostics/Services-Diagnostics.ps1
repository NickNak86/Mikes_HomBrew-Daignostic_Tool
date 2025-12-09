#Requires -Version 5.1

<#
.SYNOPSIS
    Services Diagnostic Module
    
.DESCRIPTION
    Checks for required software services like ASCOM Platform and Virtual Serial Ports.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$DeviceIP,
    
    [Parameter(Mandatory=$false)]
    [switch]$VerboseOutput
)

function Write-SvcLog {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] ServicesDiagnostics: $Message"
    Write-Host $logEntry -ForegroundColor $(switch($Level) {
        "INFO" { "Cyan" }
        "SUCCESS" { "Green" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        default { "White" }
    })
}

function Test-ASCOM {
    Write-SvcLog "Checking ASCOM Platform..." "INFO"
    
    $ascomStatus = @{
        'installed' = $false
        'version' = $null
    }
    
    if ($IsWindows) {
        try {
            $ascomKey = Get-ItemProperty -Path "HKLM:\SOFTWARE\ASCOM\Platform" -ErrorAction SilentlyContinue
            if ($ascomKey) {
                $ascomStatus.installed = $true
                $ascomStatus.version = $ascomKey.PlatformVersion
                Write-SvcLog "ASCOM Platform found (Version: $($ascomKey.PlatformVersion))" "SUCCESS"
            } else {
                # Try 64-bit registry
                $ascomKey = Get-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\ASCOM\Platform" -ErrorAction SilentlyContinue
                if ($ascomKey) {
                    $ascomStatus.installed = $true
                    $ascomStatus.version = $ascomKey.PlatformVersion
                     Write-SvcLog "ASCOM Platform found (Version: $($ascomKey.PlatformVersion))" "SUCCESS"
                } else {
                     Write-SvcLog "ASCOM Platform not detected in registry" "WARNING"
                }
            }
        } catch {
            Write-SvcLog "Error checking ASCOM: $($_.Exception.Message)" "WARNING"
        }
    } else {
        Write-SvcLog "Non-Windows OS detected, skipping ASCOM check" "INFO"
    }
    
    return $ascomStatus
}

function Test-VirtualSerialPorts {
    Write-SvcLog "Checking Virtual Serial Port drivers..." "INFO"
    
    $vspStatus = @{
        'found' = $false
        'software' = @()
    }
    
    if ($IsWindows) {
        $drivers = @("com0com", "CNCA0", "VSPE", "Eltima")
        
        # Check installed software roughly via WMI or registry if specific keys known.
        # Simple check: Get-WmiObject Win32_Product (Slow), or check running services/processes
        
        # We'll check for drivers in PnP entity descriptions
        $pnp = Get-WmiObject Win32_PnPEntity | Where-Object { $_.Name -match "Virtual Serial Port" -or $_.Description -match "Virtual Serial Port" }
        
        if ($pnp) {
            $vspStatus.found = $true
            foreach ($p in $pnp) {
                $vspStatus.software += $p.Name
                Write-SvcLog "Found Virtual Serial Port driver: $($p.Name)" "SUCCESS"
            }
        } else {
            Write-SvcLog "No Virtual Serial Port drivers explicitly detected" "INFO"
        }
    }
    
    return $vspStatus
}

function Get-ServicesDiagnosticResults {
    Write-SvcLog "Starting services diagnostic suite..." "INFO"
    
    $results = @{
        'timestamp' = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
        'module' = 'Services'
        'tests' = @{}
        'overall_status' = 'UNKNOWN'
    }
    
    # Test ASCOM
    $results.tests['ascom'] = Test-ASCOM
    
    # Test Virtual Serial Ports
    $results.tests['virtual_serial_ports'] = Test-VirtualSerialPorts
    
    # Determine status
    if ($results.tests['ascom'].installed) {
        $results.overall_status = 'PASS'
    } else {
        # ASCOM is not strictly mandatory for all users, but good for diagnostics
        $results.overall_status = 'WARNING'
    }
    
    return $results
}

# Main execution
try {
    $diagnosticResults = Get-ServicesDiagnosticResults
    return $diagnosticResults
} catch {
    Write-SvcLog "Services diagnostic failed: $($_.Exception.Message)" "ERROR"
    return @{
        'timestamp' = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
        'overall_status' = 'ERROR'
        'error' = $_.Exception.Message
    }
}
