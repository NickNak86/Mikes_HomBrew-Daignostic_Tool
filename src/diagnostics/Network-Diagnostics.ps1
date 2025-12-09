#Requires -Version 5.1

<#
.SYNOPSIS
    Network Diagnostic Module for HomeBrew Device
    
.DESCRIPTION
    Tests network connectivity, WiFi status, and communication protocols
    specific to HomeBrew Gen3 PCB WiFi/BT/GPS/MUSBA relay devices.

.PARAMETER DeviceIP
    IP address of the HomeBrew device
    
.PARAMETER NetworkRange
    Network range to scan (default: 192.168.1.0/24)

.EXAMPLE
    .\Network-Diagnostics.ps1 -DeviceIP 192.168.1.100
    Test network connectivity for HomeBrew device
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$DeviceIP = "192.168.1.100",
    
    [Parameter(Mandatory=$false)]
    [string]$NetworkRange = "192.168.1.0/24",
    
    [Parameter(Mandatory=$false)]
    [switch]$VerboseOutput
)

function Write-NetworkLog {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] NetworkDiagnostics: $Message"
    Write-Host $logEntry -ForegroundColor $(switch($Level) {
        "INFO" { "Cyan" }
        "SUCCESS" { "Green" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        default { "White" }
    })
    
    # Write to log file
    $logFile = Join-Path $PSScriptRoot "..\..\output\logs\network_diagnostics.log"
    Add-Content -Path $logFile -Value $logEntry -ErrorAction SilentlyContinue
}

function Test-DevicePing {
    param([string]$IP)
    Write-NetworkLog "Testing ping to device $IP..." "INFO"
    
    try {
        $ping = Test-Connection -ComputerName $IP -Count 3 -Quiet
        if ($ping) {
            Write-NetworkLog "Device $IP is reachable via ping" "SUCCESS"
            return $true
        } else {
            Write-NetworkLog "Device $IP is not reachable via ping" "WARNING"
            return $false
        }
    } catch {
        Write-NetworkLog "Ping test failed: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Test-CommonPorts {
    param([string]$IP)
    Write-NetworkLog "Testing common ports on $IP..." "INFO"
    
    $commonPorts = @(2000, 23, 80, 443, 8080)  # Telnet, HTTP, HTTPS
    $portResults = @{}
    
    foreach ($port in $commonPorts) {
        try {
            $tcpClient = New-Object System.Net.Sockets.TcpClient
            $connect = $tcpClient.BeginConnect($IP, $port, $null, $null)
            $wait = $connect.AsyncWaitHandle.WaitOne(3000, $false)
            
            if ($wait) {
                $tcpClient.EndConnect($connect)
                $tcpClient.Close()
                Write-NetworkLog "Port $port is open" "SUCCESS"
                $portResults[$port] = $true
            } else {
                Write-NetworkLog "Port $port is closed/filtered" "INFO"
                $portResults[$port] = $false
            }
        } catch {
            Write-NetworkLog "Port $port test failed: $($_.Exception.Message)" "WARNING"
            $portResults[$port] = $false
        }
    }
    
    return $portResults
}

function Test-WiFiConnectivity {
    Write-NetworkLog "Testing WiFi connectivity..." "INFO"
    
    try {
        # Get WiFi adapter status
        $wifiAdapters = Get-NetAdapter | Where-Object { $_.PhysicalMediaType -eq "802.11" -and $_.Status -eq "Up" }
        
        if ($wifiAdapters) {
            Write-NetworkLog "Found $($wifiAdapters.Count) active WiFi adapter(s)" "SUCCESS"
            
            $wifiResults = @()
            foreach ($adapter in $wifiAdapters) {
                $wifiInfo = [ordered]@{
                    'name' = $adapter.Name
                    'interface_description' = $adapter.InterfaceDescription
                    'status' = $adapter.Status
                    'speed' = $adapter.LinkSpeed
                    'media_type' = $adapter.MediaType
                }
                $wifiResults += $wifiInfo
            }
            
            if ($VerboseOutput) {
                Write-NetworkLog "WiFi Adapter Details:" "INFO"
                $wifiResults | Format-List | Out-String | Write-Host -ForegroundColor Yellow
            }
            
            return $wifiResults
        } else {
            Write-NetworkLog "No active WiFi adapters found" "WARNING"
            return @()
        }
    } catch {
        Write-NetworkLog "WiFi connectivity test failed: $($_.Exception.Message)" "ERROR"
        return @()
    }
}

function Test-NetworkInterfaces {
    Write-NetworkLog "Testing all network interfaces..." "INFO"
    
    try {
        $interfaces = Get-NetAdapter | Sort-Object Name
        $interfaceResults = @()
        
        foreach ($iface in $interfaces) {
            $ifaceInfo = [ordered]@{
                'name' = $iface.Name
                'interface_description' = $iface.InterfaceDescription
                'status' = $iface.Status
                'speed' = $iface.LinkSpeed
                'physical_address' = $iface.MacAddress
                'media_type' = $iface.MediaType
                'physical_media_type' = $iface.PhysicalMediaType
            }
            
            # Get IP configuration if available
            $ipConfig = Get-NetIPAddress -InterfaceIndex $iface.InterfaceIndex -ErrorAction SilentlyContinue
            if ($ipConfig) {
                $ifaceInfo['ip_address'] = $ipConfig.IPAddress
                $ifaceInfo['subnet_mask'] = $ipConfig.PrefixLength
            }
            
            $interfaceResults += $ifaceInfo
            
            $statusIcon = if ($iface.Status -eq "Up") { "✓" } else { "✗" }
            Write-NetworkLog "  $statusIcon $($iface.Name) - $($iface.Status)" $(if ($iface.Status -eq "Up") { "SUCCESS" } else { "WARNING" })
        }
        
        return $interfaceResults
    } catch {
        Write-NetworkLog "Network interfaces test failed: $($_.Exception.Message)" "ERROR"
        return @()
    }
}

function Test-DNSResolution {
    Write-NetworkLog "Testing DNS resolution..." "INFO"
    
    $dnsTests = @{
        'localhost' = $false
        'google.com' = $false
        'github.com' = $false
    }
    
    foreach ($hostname in $dnsTests.Keys) {
        try {
            $ip = Resolve-DnsName -Name $hostname -ErrorAction Stop
            if ($ip) {
                Write-NetworkLog "DNS resolution successful: $hostname -> $ip" "SUCCESS"
                $dnsTests[$hostname] = $true
            }
        } catch {
            Write-NetworkLog "DNS resolution failed: $hostname" "WARNING"
        }
    }
    
    return $dnsTests
}

function Test-InternetConnectivity {
    Write-NetworkLog "Testing internet connectivity..." "INFO"
    
    $internetTargets = @("8.8.8.8", "1.1.1.1", "google.com")
    $connectivityResults = @{}
    
    foreach ($target in $internetTargets) {
        try {
            $ping = Test-Connection -ComputerName $target -Count 2 -Quiet
            $connectivityResults[$target] = $ping
            if ($ping) {
                Write-NetworkLog "Internet connectivity OK: $target" "SUCCESS"
            } else {
                Write-NetworkLog "Internet connectivity failed: $target" "WARNING"
            }
        } catch {
            Write-NetworkLog "Internet connectivity test failed for $target: $($_.Exception.Message)" "WARNING"
            $connectivityResults[$target] = $false
        }
    }
    
    return $connectivityResults
}

function Get-NetworkDiagnosticResults {
    param([string]$DeviceIP, [string]$NetworkRange)
    
    Write-NetworkLog "Starting network diagnostic suite..." "INFO"
    
    $results = @{
        'timestamp' = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
        'device_ip' = $DeviceIP
        'network_range' = $NetworkRange
        'tests' = @{}
        'overall_status' = 'UNKNOWN'
    }
    
    # Test device ping
    $results.tests['device_ping'] = Test-DevicePing -IP $DeviceIP
    
    # Test device ports
    $results.tests['device_ports'] = Test-CommonPorts -IP $DeviceIP
    
    # Test WiFi connectivity
    $results.tests['wifi_connectivity'] = Test-WiFiConnectivity
    
    # Test network interfaces
    $results.tests['network_interfaces'] = Test-NetworkInterfaces
    
    # Test DNS resolution
    $results.tests['dns_resolution'] = Test-DNSResolution
    
    # Test internet connectivity
    $results.tests['internet_connectivity'] = Test-InternetConnectivity
    
    # Calculate overall status
    $criticalTests = @($results.tests['device_ping'], $results.tests['device_ports'])
    if ($results.tests['device_ports'][2000]) {
        $overallPass = $results.tests['device_ping'] -and $results.tests['wifi_connectivity'].Count -gt 0
    } else {
        $overallPass = $results.tests['device_ping'] -and $results.tests['internet_connectivity'].GetEnumerator() | Where-Object { $_.Value } | Measure-Object | Select-Object -ExpandProperty Count
    }
    
    if ($overallPass) {
        $results.overall_status = 'PASS'
    } else {
        $results.overall_status = 'PARTIAL'
    }
    
    return $results
}

function Show-NetworkResults {
    param([hashtable]$Results)
    
    Write-Host ""
    Write-Host "🌐 NETWORK DIAGNOSTIC RESULTS 🌐" -ForegroundColor Cyan
    Write-Host "===================================" -ForegroundColor Cyan
    
    Write-Host "Target Device: $($Results.device_ip)" -ForegroundColor White
    Write-Host "Network Range: $($Results.network_range)" -ForegroundColor White
    Write-Host "Time: $($Results.timestamp)" -ForegroundColor White
    Write-Host "Status: " -NoNewline
    
    switch($Results.overall_status) {
        'PASS' { Write-Host "✓ PASSED" -ForegroundColor Green }
        'PARTIAL' { Write-Host "⚠ PARTIAL" -ForegroundColor Yellow }
        'FAIL' { Write-Host "✗ FAILED" -ForegroundColor Red }
        default { Write-Host "? UNKNOWN" -ForegroundColor Gray }
    }
    
    Write-Host ""
    Write-Host "Network Tests:" -ForegroundColor Cyan
    
    # Device Ping
    $pingStatus = if ($Results.tests.device_ping) { "✓ PASS" } else { "✗ FAIL" }
    $pingColor = if ($Results.tests.device_ping) { "Green" } else { "Red" }
    Write-Host "  $pingStatus - Device Ping ($($Results.device_ip))" -ForegroundColor $pingColor
    
    # Port Tests
    $openPorts = $Results.tests.device_ports.GetEnumerator() | Where-Object { $_.Value } | Select-Object -ExpandProperty Key
    if ($openPorts) {
        Write-Host "  ✓ PASS - Device Ports: $(($openPorts -join ', '))" -ForegroundColor Green
    } else {
        Write-Host "  ✗ FAIL - Device Ports: None accessible" -ForegroundColor Red
    }
    
    # WiFi
    $wifiCount = $Results.tests.wifi_connectivity.Count
    if ($wifiCount -gt 0) {
        Write-Host "  ✓ PASS - WiFi Adapters: $wifiCount active" -ForegroundColor Green
    } else {
        Write-Host "  ✗ FAIL - WiFi Adapters: None active" -ForegroundColor Red
    }
    
    # Internet
    $internetCount = ($Results.tests.internet_connectivity.GetEnumerator() | Where-Object { $_.Value } | Measure-Object).Count
    if ($internetCount -gt 0) {
        Write-Host "  ✓ PASS - Internet Connectivity: $internetCount/$($Results.tests.internet_connectivity.Count) targets" -ForegroundColor Green
    } else {
        Write-Host "  ✗ FAIL - Internet Connectivity: No targets reachable" -ForegroundColor Red
    }
    
    Write-Host ""
}

# Main execution
try {
    Write-NetworkLog "=== NETWORK DIAGNOSTIC MODULE STARTING ===" "INFO"
    
    if ($VerboseOutput) {
        Write-NetworkLog "Verbose mode enabled" "INFO"
        Write-NetworkLog "Device IP: $DeviceIP" "INFO"
        Write-NetworkLog "Network Range: $NetworkRange" "INFO"
    }
    
    # Run diagnostics
    $diagnosticResults = Get-NetworkDiagnosticResults -DeviceIP $DeviceIP -NetworkRange $NetworkRange
    
    # Display results
    Show-NetworkResults -Results $diagnosticResults
    
    # Save results
    $outputPath = Join-Path $PSScriptRoot "..\..\output\reports"
    if (-not (Test-Path $outputPath)) {
        New-Item -ItemType Directory -Path $outputPath -Force | Out-Null
    }
    
    $timestamp = Get-Date -Format "yyyy-MM-dd_HHmmss"
    $jsonPath = Join-Path $outputPath "network_diagnostic_$timestamp.json"
    
    $diagnosticResults | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonPath -Encoding UTF8
    Write-NetworkLog "Results saved to: $jsonPath" "INFO"
    
    Write-NetworkLog "=== NETWORK DIAGNOSTIC MODULE COMPLETED ===" "SUCCESS"
    
    return $diagnosticResults
    
} catch {
    Write-NetworkLog "Network diagnostic failed: $($_.Exception.Message)" "ERROR"
    return @{
        'timestamp' = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
        'device_ip' = $DeviceIP
        'overall_status' = 'ERROR'
        'error' = $_.Exception.Message
    }
}