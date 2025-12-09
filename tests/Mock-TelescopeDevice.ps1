<#
.SYNOPSIS
    Mock HomeBrew Gen3 PCB Telescope Device Simulator
    
.DESCRIPTION
    Simulates a HomeBrew Gen3 PCB device on port 2000 for testing diagnostic scripts
    without requiring actual hardware. Responds to Celestron NexStar protocol commands
    and provides realistic device behavior.
    
.PARAMETER Port
    TCP port to listen on (default: 2000)
    
.PARAMETER Verbose
    Enable verbose logging
    
.EXAMPLE
    .\Mock-TelescopeDevice.ps1 -Port 2000 -Verbose
    
.NOTES
    Stop the server by pressing Ctrl+C
#>

param(
    [int]$Port = 2000,
    [switch]$Verbose
)

$script:stopServer = $false
$script:clientCount = 0

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    if ($Verbose -or $Level -eq "ERROR") {
        Write-Host $logMessage
    }
}

function Handle-Command {
    param(
        [string]$Command,
        [System.Net.Sockets.NetworkStream]$Stream,
        [System.IO.StreamWriter]$Writer
    )
    
    $command = $command.Trim()
    Write-Log "Received command: '$command'" "DEBUG"
    
    $response = switch -Wildcard ($command) {
        # Connection/Status commands
        "MS" { "Idle#" }
        "GV*" { "HomeBrew Gen3 PCB v2.1.0#" }
        "VERSION?" { "#02.100#" }
        "VERSION" { "HomeBrew Gen3 PCB v2.1.0#" }
        
        # Position commands
        "GA" { "+89:59:60#" }
        "GZ" { "+000:00:00#" }
        "GA#" { "+45:30:15#" }
        "GZ#" { "+180:15:45#" }
        
        # Status commands
        "WIFISTATUS" { 
            @{
                status = "Connected"
                ssid = "Observatory_Network"
                signal_strength = -45
                ip_address = "192.168.1.100"
                mac_address = "AA:BB:CC:DD:EE:FF"
            } | ConvertTo-Json
        }
        
        "BTSTATUS" {
            @{
                status = "Active"
                discoverable = $true
                paired_devices = @("Phone", "Tablet")
                connection_type = "BLE"
            } | ConvertTo-Json
        }
        
        "GPSSTATUS" {
            @{
                status = "Active"
                fix_type = "3D Fix"
                satellites = 8
                hdop = 1.2
                latitude = 40.7128
                longitude = -74.0060
                altitude = 100
                accuracy = 3
            } | ConvertTo-Json
        }
        
        # WiFi commands
        "WIFISCAN" {
            @(
                @{ ssid = "Observatory_Network"; signal = -45; security = "WPA2"; channel = 6 }
                @{ ssid = "Guest_Network"; signal = -65; security = "WPA2"; channel = 11 }
                @{ ssid = "OpenNetwork"; signal = -78; security = "Open"; channel = 1 }
            ) | ConvertTo-Json
        }
        
        "WIFICONNECT" { "Connected to Observatory_Network#" }
        "PING 8.8.8.8" { "Response from 8.8.8.8: bytes=32 time=25ms TTL=119#" }
        "PING 192.168.1.1" { "Response from 192.168.1.1: bytes=32 time=2ms TTL=64#" }
        
        # Bluetooth commands
        "BTSCAN" {
            @{
                devices = @(
                    @{ name = "Samsung Phone"; address = "11:22:33:44:55:66"; signal = -35 }
                    @{ name = "iPad"; address = "AA:BB:CC:DD:EE:FF"; signal = -50 }
                )
                scan_time = "5 seconds"
            } | ConvertTo-Json
        }
        
        "BTPAIR" { "Pairing mode enabled. Waiting for device...#" }
        
        # GPS commands
        "GPSCOORDS" {
            @{
                latitude = 40.7128
                longitude = -74.0060
                altitude = 100
                accuracy = 3
            } | ConvertTo-Json
        }
        
        "GPSSAT" {
            @{
                satellites_total = 12
                satellites_used = 8
                satellite_ids = @(2, 5, 7, 12, 15, 19, 24, 27)
                signal_strengths = @(45, 42, 41, 40, 39, 38, 37, 36)
            } | ConvertTo-Json
        }
        
        "GPSTIME" {
            @{
                utc_time = (Get-Date -AsUTC).ToString("o")
                local_time = (Get-Date).ToString("o")
                time_sync = "GPS synced"
            } | ConvertTo-Json
        }
        
        # USB Relay commands
        "USBSTATUS" { @{ status = "Active"; relay_count = 1; relay1 = "OFF" } | ConvertTo-Json }
        "USBRELAY ON" { "Relay 1 turned ON#" }
        "USBRELAY OFF" { "Relay 1 turned OFF#" }
        
        # Device info commands
        "UPTIME" { "Device uptime: 45 days, 12 hours, 30 minutes#" }
        "TEMPERATURE" { @{ cpu_temp = 62.5; board_temp = 45.3 } | ConvertTo-Json }
        "MEMORY" {
            @{
                total_memory = "2 GB"
                used_memory = "512 MB"
                free_memory = "1.5 GB"
                memory_usage_percent = 25.6
            } | ConvertTo-Json
        }
        
        # Celestron commands
        "e" { "#" }
        "GC#" { (Get-Date).ToString("hh/MM/yyyy#") }
        "GL#" { (Get-Date).ToString("HH:MM:SS#") }
        
        # Echo test
        "echo test" { "test" }
        
        # Default response
        default {
            Write-Log "Unknown command: $command" "WARN"
            "Unknown command#"
        }
    }
    
    Write-Log "Sending response: $response"
    $Writer.WriteLine($response)
    $Writer.Flush()
}

function Start-MockDeviceServer {
    Write-Log "Starting mock HomeBrew device simulator on port $Port"
    
    $listener = New-Object System.Net.Sockets.TcpListener([System.Net.IPAddress]::Any, $Port)
    
    try {
        $listener.Start()
        Write-Log "Server listening on port $Port"
        Write-Host "Mock Device Server started. Press Ctrl+C to stop."
        Write-Host "Simulating HomeBrew Gen3 PCB at 192.168.1.100:$Port"
        Write-Host ""
        
        # Accept connections in a loop
        while (-not $script:stopServer) {
            if ($listener.Pending()) {
                $client = $listener.AcceptTcpClient()
                $script:clientCount++
                $clientId = $script:clientCount
                
                Write-Log "Client #$clientId connected from $($client.Client.RemoteEndPoint)"
                
                $stream = $client.GetStream()
                $reader = New-Object System.IO.StreamReader($stream)
                $writer = New-Object System.IO.StreamWriter($stream)
                $writer.AutoFlush = $true
                
                # Send banner
                $banner = "HomeBrew Gen3 PCB v2.1.0 - Ready`r`n"
                $writer.WriteLine($banner)
                
                # Handle client in background job to allow multiple simultaneous connections
                $clientBlock = {
                    param($Client, $Reader, $Writer, $ClientId, $Verbose)
                    
                    function Write-Log {
                        param([string]$Message, [string]$Level = "INFO")
                        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
                        $logMessage = "[$timestamp] [Client #$ClientId] [$Level] $Message"
                        if ($Verbose -or $Level -eq "ERROR") {
                            Write-Host $logMessage
                        }
                    }
                    
                    try {
                        while ($Client.Connected) {
                            $line = $Reader.ReadLine()
                            if ($null -eq $line) {
                                break
                            }
                            
                            # Handle command
                            $command = $line.Trim()
                            if ([string]::IsNullOrWhiteSpace($command)) {
                                continue
                            }
                            
                            Write-Log "Received: $command"
                            
                            $response = switch -Wildcard ($command) {
                                "MS" { "Idle#" }
                                "GV*" { "HomeBrew Gen3 PCB v2.1.0#" }
                                "VERSION?" { "#02.100#" }
                                "VERSION" { "HomeBrew Gen3 PCB v2.1.0#" }
                                "GA" { "+89:59:60#" }
                                "GZ" { "+000:00:00#" }
                                "GA#" { "+45:30:15#" }
                                "GZ#" { "+180:15:45#" }
                                "WIFISTATUS" { @{ status = "Connected"; ssid = "Observatory_Network"; signal_strength = -45 } | ConvertTo-Json }
                                "BTSTATUS" { @{ status = "Active"; discoverable = $true; paired_devices = 2 } | ConvertTo-Json }
                                "GPSSTATUS" { @{ status = "Active"; fix_type = "3D Fix"; satellites = 8 } | ConvertTo-Json }
                                "WIFISCAN" { @( @{ ssid = "Observatory_Network"; signal = -45 } ) | ConvertTo-Json }
                                "BTSCAN" { @{ devices = @( @{ name = "Phone" } ) } | ConvertTo-Json }
                                "GPSCOORDS" { @{ latitude = 40.7128; longitude = -74.0060; altitude = 100 } | ConvertTo-Json }
                                "GPSSAT" { @{ satellites_used = 8; signal_strengths = @(45, 42, 41, 40, 39, 38, 37, 36) } | ConvertTo-Json }
                                "USBSTATUS" { @{ status = "Active"; relay1 = "OFF" } | ConvertTo-Json }
                                "USBRELAY ON" { "Relay 1 turned ON#" }
                                "USBRELAY OFF" { "Relay 1 turned OFF#" }
                                "UPTIME" { "Device uptime: 45 days, 12 hours, 30 minutes#" }
                                "TEMPERATURE" { @{ cpu_temp = 62.5; board_temp = 45.3 } | ConvertTo-Json }
                                "MEMORY" { @{ used_memory = "512 MB"; free_memory = "1.5 GB" } | ConvertTo-Json }
                                "echo test" { "test" }
                                default { "Unknown command#" }
                            }
                            
                            Write-Log "Sending: $response"
                            $Writer.WriteLine($response)
                        }
                    } catch {
                        Write-Log "Error: $($_.Exception.Message)" "ERROR"
                    } finally {
                        $Client.Close()
                        Write-Log "Client disconnected"
                    }
                }
                
                # Start background job for this client
                $job = Start-Job -ScriptBlock $clientBlock -ArgumentList $client, $reader, $writer, $clientId, $Verbose
            }
            
            Start-Sleep -Milliseconds 100
        }
    } catch {
        Write-Log "Server error: $($_.Exception.Message)" "ERROR"
    } finally {
        if ($listener) {
            $listener.Stop()
            $listener.Dispose()
        }
        
        # Clean up all background jobs
        Get-Job | Stop-Job -Force
        Get-Job | Remove-Job -Force
        
        Write-Log "Server stopped"
    }
}

# Setup Ctrl+C handler
$null = Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action {
    $script:stopServer = $true
}

# Start the server
Start-MockDeviceServer
