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
    [ValidateSet('Telescope', 'Communication', 'Network', 'System', 'Hardware', 'Performance', 'Services', 'Security')]
    [string]$Module,

    [Parameter(Mandatory=$false)]
    [string]$DeviceIP,

    [Parameter(Mandatory=$false)]
    [int]$TelnetPort,

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

# Import configuration
Write-Host "HomeBrew Gen3 PCB WiFi/BT/GPS/MUSBA Relay Diagnostic Tool v2.0.0" -ForegroundColor Cyan
Write-Host "===================================================================" -ForegroundColor Cyan
Write-Host ""

# Load Configuration
$configScript = Join-Path $ScriptRoot "src/config/Read-Configuration.ps1"
if (Test-Path $configScript) {
    $Config = & $configScript -ConfigPath (Join-Path $ScriptRoot $ConfigPath)
} else {
    Write-Warning "Configuration loader not found. Using defaults."
    $Config = @{ 'diagnostics' = @{ 'device' = @{ 'ip' = "192.168.1.100"; 'telnet_port' = 2000 } } }
}

# Apply defaults from config if not provided
if (-not $DeviceIP) { $DeviceIP = $Config.diagnostics.device.ip }
if (-not $TelnetPort) { $TelnetPort = $Config.diagnostics.device.telnet_port }
if (-not $SerialPort -and $Config.diagnostics.device.serial_port) { $SerialPort = $Config.diagnostics.device.serial_port }

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

    $allResults = @{
        'timestamp' = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
        'device_ip' = $DeviceIP
    }
    
    $moduleOrder = @("System", "Network", "Hardware", "Performance", "Services", "Security", "Communication", "Telescope")

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
                    
                    # Common parameters
                    if ($diagnosticModule -ne "System") {
                         $scriptParams['DeviceIP'] = $DeviceIP
                    }
                    $scriptParams['VerboseOutput'] = $false
                    
                    # Module specific parameters
                    switch ($diagnosticModule) {
                        "Telescope" {
                            $scriptParams['TelnetPort'] = $TelnetPort
                            $scriptParams['SerialPort'] = $SerialPort
                        }
                        "Communication" {
                            $scriptParams['TelnetPort'] = $TelnetPort
                            $scriptParams['SerialPort'] = $SerialPort
                        }
                    }
                    
                    # Run the diagnostic script
                    $result = & $diagnosticScript @scriptParams
                    $allResults[$diagnosticModule] = $result
                    
                    # Show module completion status
                    if ($result.overall_status -eq "PASS") {
                        Write-Host "  ✓ $diagnosticModule diagnostics completed successfully" -ForegroundColor Green
                    } elseif ($result.overall_status -eq "PARTIAL" -or $result.overall_status -eq "WARNING") {
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

    # Generate HTML Report
    if ($OutputFormat -eq 'HTML' -or $OutputFormat -eq 'All') {
        $htmlReporter = Join-Path $ScriptRoot "src/reporters/New-HTMLReport.ps1"
        if (Test-Path $htmlReporter) {
            $htmlContent = & $htmlReporter -Results $allResults
            $reportPath = Join-Path $reportsPath "$reportBaseName.html"
            $htmlContent | Out-File -FilePath $reportPath -Encoding UTF8 -Force
            Write-Host "  ✓ HTML Report saved to: $reportPath" -ForegroundColor Green
        }
    }

    # Generate JSON Report
    if ($OutputFormat -eq 'JSON' -or $OutputFormat -eq 'All') {
        $jsonReporter = Join-Path $ScriptRoot "src/reporters/New-JSONReport.ps1"
        if (Test-Path $jsonReporter) {
            $jsonContent = & $jsonReporter -Results $allResults
            $reportPath = Join-Path $reportsPath "$reportBaseName.json"
            $jsonContent | Out-File -FilePath $reportPath -Encoding UTF8 -Force
            Write-Host "  ✓ JSON Report saved to: $reportPath" -ForegroundColor Green
        }
    }
    
    # Generate Text Report
    if ($OutputFormat -eq 'Text' -or $OutputFormat -eq 'All') {
        $textReporter = Join-Path $ScriptRoot "src/reporters/New-TextReport.ps1"
        if (Test-Path $textReporter) {
            $textContent = & $textReporter -Results $allResults
            $reportPath = Join-Path $reportsPath "$reportBaseName.txt"
            $textContent | Out-File -FilePath $reportPath -Encoding UTF8 -Force
            Write-Host "  ✓ Text Report saved to: $reportPath" -ForegroundColor Green
        }
    }
    
    Write-Host ""
    
    # Display overall summary
    Write-Host "[SUCCESS] Telescope diagnostic run complete!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📋 Results Summary:" -ForegroundColor Cyan
    foreach ($module in $allResults.Keys) {
        if ($module -eq 'timestamp' -or $module -eq 'device_ip') { continue }
        $result = $allResults[$module]
        $statusIcon = switch ($result.overall_status) {
            "PASS" { "✓" }
            "PARTIAL" { "⚠" }
            "WARNING" { "⚠" }
            default { "✗" }
        }
        $statusColor = switch ($result.overall_status) {
            "PASS" { "Green" }
            "PARTIAL" { "Yellow" }
            "WARNING" { "Yellow" }
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
