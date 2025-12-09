<#
.SYNOPSIS
    Text Report Generator
    
.DESCRIPTION
    Generates a plain text report from diagnostic results.
#>

param(
    [Parameter(Mandatory=$true)]
    [hashtable]$Results
)

$sb = New-Object System.Text.StringBuilder

$null = $sb.AppendLine("==================================================")
$null = $sb.AppendLine("       HOMEBREW TELESCOPE DIAGNOSTIC REPORT       ")
$null = $sb.AppendLine("==================================================")
$null = $sb.AppendLine("Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
$null = $sb.AppendLine("")

foreach ($key in $Results.Keys) {
    if ($key -eq 'timestamp' -or $key -eq 'device_ip') { continue }
    
    $moduleResult = $Results[$key]
    $moduleName = $key.ToUpper()
    $status = $moduleResult.overall_status
    
    $null = $sb.AppendLine("[$moduleName] Status: $status")
    
    if ($moduleResult.tests) {
        foreach ($testName in $moduleResult.tests.Keys) {
            $testVal = $moduleResult.tests[$testName]
            # Simple string representation
            if ($testVal -is [hashtable]) {
                $testStr = $testVal | Out-String
                $null = $sb.AppendLine("  - $testName: ")
                $null = $sb.AppendLine($testStr.Trim())
            } else {
                $null = $sb.AppendLine("  - $testName: $testVal")
            }
        }
    }
    $null = $sb.AppendLine("--------------------------------------------------")
}

return $sb.ToString()
