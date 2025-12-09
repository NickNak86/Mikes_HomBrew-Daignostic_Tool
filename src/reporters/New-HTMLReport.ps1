<#
.SYNOPSIS
    HTML Report Generator
    
.DESCRIPTION
    Generates a rich HTML report from diagnostic results.
#>

param(
    [Parameter(Mandatory=$true)]
    [hashtable]$Results
)

$style = @"
<style>
    body { font-family: Arial, sans-serif; background-color: #f4f4f4; margin: 20px; }
    .container { max-width: 900px; margin: auto; background: white; padding: 20px; border-radius: 8px; box-shadow: 0 0 10px rgba(0,0,0,0.1); }
    h1 { color: #333; border-bottom: 2px solid #0078d4; padding-bottom: 10px; }
    .status-pass { color: green; font-weight: bold; }
    .status-fail { color: red; font-weight: bold; }
    .status-warning { color: orange; font-weight: bold; }
    .module { margin-bottom: 20px; border: 1px solid #ddd; padding: 15px; border-radius: 5px; }
    .module h2 { margin-top: 0; }
    .test-item { padding: 5px 0; border-bottom: 1px solid #eee; }
    .test-key { font-weight: bold; }
    pre { background: #eee; padding: 10px; overflow-x: auto; }
</style>
"@

$html = New-Object System.Text.StringBuilder
$null = $html.AppendLine("<!DOCTYPE html><html><head><title>Diagnostic Report</title>$style</head><body>")
$null = $html.AppendLine("<div class='container'>")
$null = $html.AppendLine("<h1>HomeBrew Diagnostic Report</h1>")
$null = $html.AppendLine("<p><strong>Date:</strong> $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>")

# Summary Section
$null = $html.AppendLine("<h2>Summary</h2>")
$null = $html.AppendLine("<ul>")
foreach ($key in $Results.Keys) {
    if ($key -eq 'timestamp' -or $key -eq 'device_ip') { continue }
    $status = $Results[$key].overall_status
    $class = "status-warning"
    if ($status -eq "PASS") { $class = "status-pass" }
    elseif ($status -eq "FAIL" -or $status -eq "ERROR") { $class = "status-fail" }
    
    $null = $html.AppendLine("<li><strong>$key:</strong> <span class='$class'>$status</span></li>")
}
$null = $html.AppendLine("</ul>")

# Detail Section
foreach ($key in $Results.Keys) {
    if ($key -eq 'timestamp' -or $key -eq 'device_ip') { continue }
    
    $module = $Results[$key]
    $null = $html.AppendLine("<div class='module'>")
    $null = $html.AppendLine("<h2>Module: $key</h2>")
    
    if ($module.tests) {
        foreach ($testName in $module.tests.Keys) {
            $val = $module.tests[$testName]
            $null = $html.AppendLine("<div class='test-item'>")
            $null = $html.AppendLine("<span class='test-key'>$testName:</span>")
            
            if ($val -is [hashtable] -or $val -is [PSCustomObject]) {
                $json = $val | ConvertTo-Json -Depth 2 -Compress
                $null = $html.AppendLine("<pre>$json</pre>")
            } else {
                $null = $html.AppendLine("<span>$val</span>")
            }
            $null = $html.AppendLine("</div>")
        }
    }
    
    if ($module.error) {
        $null = $html.AppendLine("<div class='test-item status-fail'><strong>Error:</strong> $($module.error)</div>")
    }
    
    $null = $html.AppendLine("</div>")
}

$null = $html.AppendLine("</div></body></html>")

return $html.ToString()
