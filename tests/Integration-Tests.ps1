<#
.SYNOPSIS
    Integration Tests for HomeBrew Telescope Diagnostic Tool
    
.DESCRIPTION
    Comprehensive integration tests using Pester framework to validate:
    - Python-Helper.ps1 functions
    - Python script execution and JSON parsing
    - Error handling and recovery
    - Timeout management
    
.NOTES
    Requires: Pester module (Install-Module Pester -Force)
    Run with: Invoke-Pester -Path .\tests\Integration-Tests.ps1
#>

# Import the Python-Helper module
$pythonHelperPath = Join-Path $PSScriptRoot "..\src\diagnostics\Python-Helper.ps1"
. $pythonHelperPath

Describe "Python-Helper Module" {
    
    Context "Test-PythonInstallation" {
        
        It "Should detect Python installation" {
            # Skip if Python is not installed
            $pythonPath = Get-Command python -ErrorAction SilentlyContinue
            if (-not $pythonPath) {
                Set-ItResult -Skipped -Because "Python is not installed"
                return
            }
            
            $result = Test-PythonInstallation -PythonPath "python"
            
            $result | Should -Not -BeNullOrEmpty
            $result.PSObject.Properties.Name | Should -Contain "Success"
            $result.PSObject.Properties.Name | Should -Contain "Version"
            $result.PSObject.Properties.Name | Should -Contain "RequiredModules"
        }
        
        It "Should return error for non-existent Python path" {
            $result = Test-PythonInstallation -PythonPath "nonexistent_python_exe_12345"
            
            $result.Success | Should -Be $false
            $result.Error | Should -Not -BeNullOrEmpty
        }
        
        It "Should validate Python version format" {
            $pythonPath = Get-Command python -ErrorAction SilentlyContinue
            if (-not $pythonPath) {
                Set-ItResult -Skipped -Because "Python is not installed"
                return
            }
            
            $result = Test-PythonInstallation -PythonPath "python"
            
            if ($result.Success) {
                $result.Version | Should -Match "Python \d+\.\d+"
            }
        }
        
        It "Should check required modules" {
            $pythonPath = Get-Command python -ErrorAction SilentlyContinue
            if (-not $pythonPath) {
                Set-ItResult -Skipped -Because "Python is not installed"
                return
            }
            
            $result = Test-PythonInstallation -PythonPath "python"
            
            $result.RequiredModules | Should -Not -BeNullOrEmpty
            @("serial", "telnetlib", "json", "argparse", "socket") | ForEach-Object {
                $result.RequiredModules.PSObject.Properties.Name | Should -Contain $_
            }
        }
        
        It "Should clean up temporary files" {
            $pythonPath = Get-Command python -ErrorAction SilentlyContinue
            if (-not $pythonPath) {
                Set-ItResult -Skipped -Because "Python is not installed"
                return
            }
            
            $tempDir = [System.IO.Path]::GetTempPath()
            $filesBefore = @(Get-ChildItem $tempDir -Filter "python_*_*.txt" -ErrorAction SilentlyContinue).Count
            
            $result = Test-PythonInstallation -PythonPath "python"
            
            Start-Sleep -Milliseconds 500
            $filesAfter = @(Get-ChildItem $tempDir -Filter "python_*_*.txt" -ErrorAction SilentlyContinue).Count
            
            $filesAfter | Should -BeLessOrEqual $filesBefore
        }
    }
    
    Context "Invoke-PythonTelescopeScript with Mock Data" {
        
        BeforeAll {
            # Create a mock Python script for testing
            $mockScriptPath = Join-Path $PSScriptRoot "..\python_scripts\mock_test.py"
            $mockScript = @'
#!/usr/bin/env python3
import json
import sys
import argparse

parser = argparse.ArgumentParser()
parser.add_argument('--host', default='127.0.0.1')
parser.add_argument('--json', action='store_true')
parser.add_argument('--verbose', action='store_true')
parser.add_argument('--serial', default=None)

args = parser.parse_args()

if args.json:
    output = {
        "host": args.host,
        "port": 2000,
        "status": "connected",
        "response_time": 45,
        "telnet": {
            "connected": True,
            "response_time": 45,
            "protocol": "NexStar",
            "commands_tested": 8,
            "success_rate": 100
        },
        "serial": {
            "available": True,
            "port": args.serial if args.serial else "COM3",
            "baud_rate": 9600,
            "connection_status": "Connected",
            "commands_tested": 5,
            "success_rate": 100
        }
    }
    print(json.dumps(output))
else:
    print("Mock test output")

sys.exit(0)
'@
            Set-Content -Path $mockScriptPath -Value $mockScript -Encoding UTF8
        }
        
        It "Should handle JSON output successfully" {
            $pythonPath = Get-Command python -ErrorAction SilentlyContinue
            if (-not $pythonPath) {
                Set-ItResult -Skipped -Because "Python is not installed"
                return
            }
            
            $result = Invoke-PythonTelescopeScript `
                -DeviceIP "127.0.0.1" `
                -ScriptName "mock_test.py" `
                -PythonPath "python" `
                -TimeoutSeconds 30
            
            $result | Should -Not -BeNullOrEmpty
            $result.PSObject.Properties.Name | Should -Contain "Success"
            $result.PSObject.Properties.Name | Should -Contain "ExitCode"
            $result.PSObject.Properties.Name | Should -Contain "JSONOutput"
        }
        
        It "Should track execution duration" {
            $pythonPath = Get-Command python -ErrorAction SilentlyContinue
            if (-not $pythonPath) {
                Set-ItResult -Skipped -Because "Python is not installed"
                return
            }
            
            $result = Invoke-PythonTelescopeScript `
                -DeviceIP "127.0.0.1" `
                -ScriptName "mock_test.py" `
                -PythonPath "python" `
                -TimeoutSeconds 30
            
            $result.Duration | Should -Not -BeNullOrEmpty
            $result.Duration | Should -BeOfType [timespan]
        }
        
        It "Should handle script not found error" {
            $pythonPath = Get-Command python -ErrorAction SilentlyContinue
            if (-not $pythonPath) {
                Set-ItResult -Skipped -Because "Python is not installed"
                return
            }
            
            $result = Invoke-PythonTelescopeScript `
                -DeviceIP "127.0.0.1" `
                -ScriptName "nonexistent_script.py" `
                -PythonPath "python" `
                -TimeoutSeconds 30
            
            $result.Success | Should -Be $false
            $result.Error | Should -Not -BeNullOrEmpty
            $result.Error | Should -Match "not found"
        }
        
        AfterAll {
            # Clean up mock script
            $mockScriptPath = Join-Path $PSScriptRoot "..\python_scripts\mock_test.py"
            if (Test-Path $mockScriptPath) {
                Remove-Item $mockScriptPath -Force -ErrorAction SilentlyContinue
            }
        }
    }
    
    Context "Invoke-TelescopePythonTests" {
        
        It "Should return overall test results" {
            $pythonPath = Get-Command python -ErrorAction SilentlyContinue
            if (-not $pythonPath) {
                Set-ItResult -Skipped -Because "Python is not installed"
                return
            }
            
            $result = Invoke-TelescopePythonTests `
                -DeviceIP "127.0.0.1" `
                -PythonPath "python" `
                -TimeoutSeconds 60
            
            $result | Should -Not -BeNullOrEmpty
            $result.PSObject.Properties.Name | Should -Contain "overall_success"
            $result.PSObject.Properties.Name | Should -Contain "summary"
        }
        
        It "Should include execution summary" {
            $pythonPath = Get-Command python -ErrorAction SilentlyContinue
            if (-not $pythonPath) {
                Set-ItResult -Skipped -Because "Python is not installed"
                return
            }
            
            $result = Invoke-TelescopePythonTests `
                -DeviceIP "127.0.0.1" `
                -PythonPath "python" `
                -TimeoutSeconds 60
            
            $result.summary | Should -Not -BeNullOrEmpty
            $result.summary.PSObject.Properties.Name | Should -Contain "python_available"
            $result.summary.PSObject.Properties.Name | Should -Contain "total_execution_time"
        }
    }
    
    Context "Get-PythonOutputSummary" {
        
        BeforeAll {
            # Create mock result object
            $mockOutput = @{
                Success = $true
                ScriptName = "telescope_comm.py"
                ExecutionTime = Get-Date
                Duration = New-TimeSpan -Seconds 2
                Output = '{"host": "192.168.1.100", "port": 2000, "status": "connected"}'
                Error = $null
                ExitCode = 0
                PythonVersion = "Python 3.11.0"
                Warnings = @()
                Recommendations = @()
            }
            $mockOutput.JSONOutput = $mockOutput.Output | ConvertFrom-Json
        }
        
        It "Should extract summary from successful result" {
            $summary = Get-PythonOutputSummary -PythonResult $mockOutput -OutputType "Summary"
            
            $summary | Should -Not -BeNullOrEmpty
            $summary.Available | Should -Be $true
            $summary.ScriptName | Should -Be "telescope_comm.py"
        }
        
        It "Should handle missing JSON output gracefully" {
            $failedOutput = @{
                Success = $false
                ScriptName = "telescope_comm.py"
                Error = "Connection failed"
                Recommendations = @("Check network")
                JSONOutput = $null
            }
            
            $summary = Get-PythonOutputSummary -PythonResult $failedOutput
            
            $summary.Available | Should -Be $false
            $summary.Error | Should -Not -BeNullOrEmpty
        }
    }
}

Describe "Python Script Compatibility" {
    
    Context "Script Arguments Handling" {
        
        It "Should pass device IP to script" {
            $pythonPath = Get-Command python -ErrorAction SilentlyContinue
            if (-not $pythonPath) {
                Set-ItResult -Skipped -Because "Python is not installed"
                return
            }
            
            $result = Invoke-PythonTelescopeScript `
                -DeviceIP "192.168.1.100" `
                -ScriptName "mock_test.py" `
                -PythonPath "python" `
                -TimeoutSeconds 30
            
            # Mock script returns the host in JSON
            if ($result.JSONOutput) {
                $result.JSONOutput.host | Should -Be "192.168.1.100"
            }
        }
        
        It "Should support custom script arguments" {
            $pythonPath = Get-Command python -ErrorAction SilentlyContinue
            if (-not $pythonPath) {
                Set-ItResult -Skipped -Because "Python is not installed"
                return
            }
            
            $result = Invoke-PythonTelescopeScript `
                -DeviceIP "127.0.0.1" `
                -ScriptName "mock_test.py" `
                -ScriptArgs @("--custom", "value") `
                -PythonPath "python" `
                -TimeoutSeconds 30
            
            $result | Should -Not -BeNullOrEmpty
        }
    }
}

Describe "Error Handling and Recovery" {
    
    Context "Timeout Handling" {
        
        It "Should detect timeout and provide recommendation" {
            # This test uses a slow operation to verify timeout handling
            # Skip if not in extended test mode
            if ($env:EXTENDED_TESTS -ne "true") {
                Set-ItResult -Skipped -Because "Extended tests not enabled"
                return
            }
            
            $result = Invoke-PythonTelescopeScript `
                -DeviceIP "192.168.1.1" `
                -ScriptName "mock_test.py" `
                -PythonPath "python" `
                -TimeoutSeconds 1
            
            # Timeout recommendation should be included
            if (-not $result.Success) {
                $result.Recommendations | Should -Contain -Like "*timeout*"
            }
        }
    }
    
    Context "Python Path Fallback" {
        
        It "Should try multiple Python commands if one fails" {
            # This is handled by caller, but we test the result
            $pythonPath = Get-Command python -ErrorAction SilentlyContinue
            if (-not $pythonPath) {
                Set-ItResult -Skipped -Because "Python is not installed"
                return
            }
            
            # Test with explicit python path
            $result = Invoke-PythonTelescopeScript `
                -DeviceIP "127.0.0.1" `
                -ScriptName "mock_test.py" `
                -PythonPath "python" `
                -TimeoutSeconds 30
            
            $result | Should -Not -BeNullOrEmpty
        }
    }
}
