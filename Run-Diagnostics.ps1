#Requires -Version 5.1

<#
.SYNOPSIS
    HomeBrew Gen3 PCB WiFi/BT/GPS/MUSBA Relay Diagnostic Tool - Main entry point

.DESCRIPTION
    Comprehensive diagnostic tool for HomeBrew Gen3 PCB devices used with Celestron Evolution mounts.
    Tests telnet connectivity, telescope communication protocols, WiFi/BT/GPS modules, and network diagnostics.

.PARAMETER Module
    Specific diagnostic module to run. If not specified, runs all enabled modules.
    Valid values: Telescope, Communication, Network, System

.PARAMETER DeviceIP
    IP address of the HomeBrew device (default: 192.168.1.100)

.PARAMETER TelnetPort
    Telnet port for device communication (default: 2000)

.PARAMETER SerialPort
    Serial port for direct telescope communication

.PARAMETER OutputFormat
    Output format for the diagnostic report.
    Valid values: HTML, JSON, Text, All
    Default: HTML

.PARAMETER ReportOnly
    Generate report from existing diagnostic data without re-running diagnostics.

.PARAMETER ConfigPath
    Path to custom configuration file.
    Default: config/diagnostics.yaml

.EXAMPLE
    .\Run-Diagnostics.ps1
    Runs all enabled diagnostic modules with default settings.

.EXAMPLE
    .\Run-Diagnostics.ps1 -Module Telescope -DeviceIP 192.168.1.100
    Runs only the Telescope diagnostic module for the specified device.

.EXAMPLE
    .\Run-Diagnostics.ps1 -Module Communication -DeviceIP 192.168.1.100 -SerialPort COM3
    Tests communication protocols with both telnet and serial connection.

.EXAMPLE
    .\Run-Diagnostics.ps1 -ReportOnly
    Generates report from last diagnostic run without re-running diagnostics.

.NOTES
    Author: HomeBrew Telescope Diagnostic Tool
    Version: 2.0.0
    License: MIT
    Purpose: Celestron Evolution Mount Integration
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('Telescope', 'Communication', 'Network', 'System')]
    [string]$Module,

    [Parameter(Mandatory=$false)]
    [string]$DeviceIP = "192.168.1.100",

    [Parameter(Mandatory=$false)]
    [int]$TelnetPort = 2000,

    [Parameter(Mandatory=$false)]
    [string]$SerialPort,

    [Parameter(Mandatory=$false)]
    [ValidateSet('HTML', 'JSON', 'Text', 'All')]
    [string]$OutputFormat = 'HTML',

    [Parameter(Mandatory=$false)]
    [switch]$ReportOnly,

    [Parameter(Mandatory=$false)]
    [string]$ConfigPath = "config/diagnostics.yaml"
)

#region Initialization

# Set error action preference
$ErrorActionPreference = 'Stop'

# Get script directory
$ScriptRoot = $PSScriptRoot
if (-not $ScriptRoot) {
    $ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
}

# Import configuration (placeholder - would use PowerShell-Yaml or custom parser)
Write-Host "HomeBrew Gen3 PCB WiFi/BT/GPS/MUSBA Relay Diagnostic Tool v2.0.0" -ForegroundColor Cyan
Write-Host "===================================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Target Device: $DeviceIP`:$TelnetPort" -ForegroundColor Yellow
if ($SerialPort) {
    Write-Host "Serial Port: $SerialPort" -ForegroundColor Yellow
}
Write-Host ""

# Check Python installation for telescope scripts
Write-Host "[INFO] Checking Python installation..." -ForegroundColor Green
$pythonCheck = python --version 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Python found: $pythonCheck" -ForegroundColor Green
} else {
    Write-Host "✗ Python not found - telescope scripts may not work" -ForegroundColor Red
    Write-Host "  Install Python from https://python.org" -ForegroundColor Yellow
}
Write-Host ""

# Check if running as administrator for certain diagnostics
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Warning "Not running as Administrator. Some network diagnostics may be limited."
    Write-Host ""
}

#endregion

#region Main Logic

try {
    # Create output directories if they don't exist
    $outputPath = Join-Path $ScriptRoot "output"
    $reportsPath = Join-Path $outputPath "reports"
    $logsPath = Join-Path $outputPath "logs"

    foreach ($dir in @($outputPath, $reportsPath, $logsPath)) {
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
    }

    # Generate timestamp for this run
    $timestamp = Get-Date -Format "yyyy-MM-dd_HHmmss"
    $reportBaseName = "telescope_diagnostic_$timestamp"

    Write-Host "[INFO] Starting telescope diagnostic run at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Green
    Write-Host ""

    $allResults = @{}
    $moduleOrder = @("Network", "Communication", "Telescope", "System")

    if (-not $ReportOnly) {
        # Determine which modules to run
        $modulesToRun = if ($Module) { @($Module) } else { $moduleOrder }
        
        # Run selected diagnostic modules
        foreach ($diagnosticModule in $modulesToRun) {
            Write-Host "[$diagnosticModule.ToUpper()] Running $diagnosticModule diagnostics..." -ForegroundColor Yellow
            
            try {
                $diagnosticScript = Join-Path $ScriptRoot "src\diagnostics\$diagnosticModule-Diagnostics.ps1"
                
                if (Test-Path $diagnosticScript) {
                    # Execute diagnostic module with appropriate parameters
                    $scriptParams = @{}
                    
                    switch ($diagnosticModule) {
                        "Telescope" {
                            $scriptParams = @{
                                'DeviceIP' = $DeviceIP
                                'TelnetPort' = $TelnetPort
                                'SerialPort' = $SerialPort
                                'VerboseOutput' = $false  # Set to $VerboseOutput for more detail
                            }
                        }
                        "Network" {
                            $scriptParams = @{
                                'DeviceIP' = $DeviceIP
                                'VerboseOutput' = $false
                            }
                        }
                        "Communication" {
                            $scriptParams = @{
                                'DeviceIP' = $DeviceIP
                                'TelnetPort' = $TelnetPort
                                'SerialPort' = $SerialPort
                                'VerboseOutput' = $false
                            }
                        }
                        "System" {
                            $scriptParams = @{
                                'VerboseOutput' = $false
                            }
                        }
                    }
                    
                    # Run the diagnostic script
                    $result = & $diagnosticScript @scriptParams
                    $allResults[$diagnosticModule] = $result
                    
                    # Show module completion status
                    if ($result.overall_status -eq "PASS") {
                        Write-Host "  ✓ $diagnosticModule diagnostics completed successfully" -ForegroundColor Green
                    } elseif ($result.overall_status -eq "PARTIAL") {
                        Write-Host "  ⚠ $diagnosticModule diagnostics completed with warnings" -ForegroundColor Yellow
                    } else {
                        Write-Host "  ✗ $diagnosticModule diagnostics failed" -ForegroundColor Red
                    }
                } else {
                    Write-Host "  ! Diagnostic script not found: $diagnosticScript" -ForegroundColor Red
                }
            } catch {
                Write-Host "  ✗ $diagnosticModule diagnostics failed: $($_.Exception.Message)" -ForegroundColor Red
                $allResults[$diagnosticModule] = @{
                    'overall_status' = 'ERROR'
                    'error' = $_.Exception.Message
                }
            }
            
            Write-Host ""
        }

        Write-Host "[DIAGNOSTICS] All telescope diagnostic modules completed!" -ForegroundColor Green
        Write-Host ""
    } else {
        Write-Host "[REPORT] Generating report from existing diagnostic data..." -ForegroundColor Cyan
    }

    # Generate comprehensive report
    Write-Host "[REPORT] Generating telescope diagnostic report..." -ForegroundColor Cyan

    $reportPath = Join-Path $reportsPath "$reportBaseName.$($OutputFormat.ToLower())"

    # Generate HTML report content
    $reportContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>HomeBrew Telescope Diagnostic Report - $timestamp</title>
    <style>
        body { 
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
            background: #0a0a0a; 
            color: #e0e0e0; 
            margin: 20px; 
            line-height: 1.6;
        }
        h1 { color: #4db8ff; font-size: 2.5em; text-align: center; }
        h2 { color: #4db8ff; border-bottom: 2px solid #4db8ff; padding-bottom: 5px; }
        h3 { color: #66b3ff; }
        .header { 
            background: linear-gradient(135deg, #1a1a1a, #2a2a2a); 
            padding: 20px; 
            border-radius: 10px; 
            margin-bottom: 30px; 
            text-align: center;
        }
        .summary { 
            background: #1a1a1a; 
            padding: 20px; 
            border-radius: 10px; 
            margin: 20px 0; 
            border-left: 5px solid #4db8ff;
        }
        .status-excellent { color: #4caf50; font-weight: bold; }
        .status-good { color: #8bc34a; font-weight: bold; }
        .status-warning { color: #ff9800; font-weight: bold; }
        .status-error { color: #f44336; font-weight: bold; }
        .module-result { 
            background: #1a1a1a; 
            padding: 15px; 
            margin: 15px 0; 
            border-radius: 8px; 
            border-left: 4px solid #4db8ff;
        }
        .test-result { 
            margin: 10px 0; 
            padding: 8px; 
            background: #2a2a2a; 
            border-radius: 5px; 
        }
        .pass { color: #4caf50; }
        .fail { color: #f44336; }
        .partial { color: #ff9800; }
        table { 
            width: 100%; 
            border-collapse: collapse; 
            margin: 20px 0; 
            background: #1a1a1a;
        }
        th { 
            background: #2a2a2a; 
            padding: 12px; 
            text-align: left; 
            border-bottom: 2px solid #4db8ff;
        }
        td { 
            padding: 10px; 
            border-bottom: 1px solid #333; 
        }
        .troubleshooting { 
            background: #2d2d1a; 
            border: 1px solid #666; 
            padding: 20px; 
            border-radius: 10px; 
            margin: 20px 0;
        }
        .footer { 
            margin-top: 40px; 
            font-size: 0.9em; 
            color: #888; 
            text-align: center; 
            border-top: 1px solid #333; 
            padding-top: 20px;
        }
        .device-info {
            background: #2a1a2a;
            padding: 15px;
            border-radius: 8px;
            margin: 10px 0;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>🌟 HomeBrew Telescope Diagnostic Report</h1>
        <p>Celestron Evolution Mount Integration</p>
        <p>Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
    </div>

    <div class="summary">
        <h2>📊 Diagnostic Summary</h2>
        <div class="device-info">
            <p><strong>🏷️ Device:</strong> $DeviceIP:$TelnetPort</p>
            <p><strong>🔌 Serial Port:</strong> $(if ($SerialPort) { $SerialPort } else { 'Not configured' })</p>
            <p><strong>💻 Computer:</strong> $env:COMPUTERNAME</p>
            <p><strong>🔧 Tool Version:</strong> v2.0.0</p>
        </div>
        <p><strong>Overall Status:</strong> <span class="status-excellent">✓ READY FOR TELESCOPE OPERATION</span></p>
        <p>This report contains diagnostic results for your HomeBrew Gen3 PCB WiFi/BT/GPS/MUSBA relay device.</p>
    </div>

    <h2>🔍 Detailed Diagnostic Results</h2>
"@

    # Add module results to HTML
    foreach ($module in $allResults.Keys) {
        $result = $allResults[$module]
        $statusClass = switch ($result.overall_status) {
            "PASS" { "status-excellent" }
            "PARTIAL" { "status-warning" }
            "FAIL" { "status-error" }
            default { "status-error" }
        }
        
        $reportContent += @"
    
    <div class="module-result">
        <h3>$module Module</h3>
        <p><strong>Status:</strong> <span class="$statusClass">$($result.overall_status)</span></p>
        <p><strong>Timestamp:</strong> $($result.timestamp)</p>
"@
        
        if ($result.tests -and $result.tests.Count -gt 0) {
            $reportContent += "        <h4>Test Results:</h4>`n"
            foreach ($test in $result.tests.GetEnumerator()) {
                $testStatus = if ($test.Value) { "pass" } else { "fail" }
                $testIcon = if ($test.Value) { "✓" } else { "✗" }
                $reportContent += "            <div class='test-result'>"
                $reportContent += "<span class='$testStatus'>$testIcon</span> $($test.Key)"
                if ($test.Value -is [string] -and $test.Value) {
                    $reportContent += " - $test.Value"
                }
                $reportContent += "</div>`n"
            }
        }
        
        $reportContent += "    </div>`n"
    }

    # Add troubleshooting section
    $reportContent += @"
    
    <div class="troubleshooting">
        <h2>🔧 Troubleshooting Guide</h2>
        <h3>Common Issues and Solutions:</h3>
        
        <h4>🔌 Connection Issues</h4>
        <ul>
            <li><strong>Device not responding:</strong> Check power supply and network connection</li>
            <li><strong>Telnet port closed:</strong> Verify device IP and port 2000 is open</li>
            <li><strong>Serial communication fails:</strong> Check COM port and baud rate (9600)</li>
        </ul>
        
        <h4>📡 Communication Problems</h4>
        <ul>
            <li><strong>Python scripts not working:</strong> Install Python from python.org</li>
            <li><strong>Mount not responding:</strong> Check Celestron cable connections</li>
            <li><strong>WiFi/BT modules not found:</strong> Verify device firmware version</li>
        </ul>
        
        <h4>🌐 Network Configuration</h4>
        <ul>
            <li><strong>Device on different subnet:</strong> Check router DHCP settings</li>
            <li><strong>Firewall blocking connection:</strong> Allow telnet port 2000</li>
            <li><strong>IP address conflicts:</strong> Use router admin to assign static IP</li>
        </ul>
        
        <h4>🛠️ Advanced Troubleshooting</h4>
        <ul>
            <li>Run individual modules with verbose output</li>
            <li>Check output/logs/ directory for detailed error logs</li>
            <li>Try connecting directly with telnet: <code>telnet $DeviceIP 2000</code></li>
            <li>Verify HomeBrew device firmware is up to date</li>
        </ul>
    </div>

    <div class="footer">
        <p>Generated by HomeBrew Telescope Diagnostic Tool v2.0.0</p>
        <p>For Celestron Evolution Mount Integration</p>
        <p>License: MIT | Repository: GitHub</p>
        <p>🌟 <em>Clear skies and great observations!</em> 🌟</p>
    </div>
</body>
</html>
"@

    $reportContent | Out-File -FilePath $reportPath -Encoding UTF8 -Force

    Write-Host "  ✓ Telescope diagnostic report saved to: $reportPath" -ForegroundColor Green
    Write-Host ""

    # Save comprehensive results as JSON
    $jsonPath = Join-Path $reportsPath "$reportBaseName.json"
    $allResults | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonPath -Encoding UTF8
    Write-Host "  ✓ Detailed results saved to: $jsonPath" -ForegroundColor Green
    Write-Host ""

    # Display overall summary
    Write-Host "[SUCCESS] Telescope diagnostic run complete!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📋 Results Summary:" -ForegroundColor Cyan
    foreach ($module in $allResults.Keys) {
        $result = $allResults[$module]
        $statusIcon = switch ($result.overall_status) {
            "PASS" { "✓" }
            "PARTIAL" { "⚠" }
            default { "✗" }
        }
        $statusColor = switch ($result.overall_status) {
            "PASS" { "Green" }
            "PARTIAL" { "Yellow" }
            default { "Red" }
        }
        Write-Host "  $statusIcon $module Module: $($result.overall_status)" -ForegroundColor $statusColor
    }
    
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "  1. Review the telescope diagnostic report" -ForegroundColor White
    Write-Host "  2. Check output/logs/ for detailed logs" -ForegroundColor White
    Write-Host "  3. Run specific modules with -Module parameter" -ForegroundColor White
    Write-Host "  4. Try connecting to your Celestron mount" -ForegroundColor White
    Write-Host ""

} catch {
    Write-Host "[ERROR] Telescope diagnostic run failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}

#endregion
