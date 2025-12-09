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
    body { font-family: 'Segoe UI', Arial, sans-serif; background-color: #0a0a0a; margin: 20px; color: #e0e0e0; }
    .container { max-width: 900px; margin: auto; background: #1a1a1a; padding: 20px; border-radius: 8px; box-shadow: 0 0 20px rgba(0,0,0,0.5); border: 1px solid #333; }
    h1 { color: #4db8ff; border-bottom: 2px solid #4db8ff; padding-bottom: 10px; margin-bottom: 20px; }
    h2 { color: #4db8ff; margin-top: 0; }
    .status-pass { color: #00ff00; font-weight: bold; }
    .status-fail { color: #ff4444; font-weight: bold; }
    .status-warning { color: #ffaa00; font-weight: bold; }
    .status-info { color: #4db8ff; font-weight: bold; }
    .module { margin-bottom: 20px; border: 1px solid #333; padding: 15px; border-radius: 5px; background: #2a2a2a; }
    .test-item { padding: 5px 0; border-bottom: 1px solid #444; }
    .test-key { font-weight: bold; color: #e0e0e0; }
    pre { background: #333; padding: 10px; overflow-x: auto; border-radius: 4px; color: #e0e0e0; }
    ul { list-style-type: none; padding: 0; }
    li { padding: 5px 0; border-bottom: 1px solid #444; }
    p { color: #e0e0e0; line-height: 1.6; }
    a { color: #4db8ff; text-decoration: none; }
    a:hover { text-decoration: underline; }
    .header-info { background: #2a2a2a; padding: 15px; border-radius: 5px; margin-bottom: 20px; border-left: 4px solid #4db8ff; }
    .summary-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px; margin: 20px 0; }
    .summary-card { background: #2a2a2a; padding: 15px; border-radius: 5px; border: 1px solid #333; }
    .summary-card h3 { margin-top: 0; color: #4db8ff; font-size: 14px; text-transform: uppercase; letter-spacing: 1px; }
    .timestamp { color: #888; font-size: 12px; }
</style>
"@

$html = New-Object System.Text.StringBuilder
$null = $html.AppendLine("<!DOCTYPE html><html><head><title>HomeBrew Telescope Diagnostic Report</title>$style</head><body>")
$null = $html.AppendLine("<div class='container'>")

# Header Section
$null = $html.AppendLine("<div class='header-info'>")
$null = $html.AppendLine("<h1>🌟 HomeBrew Telescope Diagnostic Report</h1>")
$null = $html.AppendLine("<p><strong>Device IP:</strong> $($Results.device_ip ?: 'Unknown')</p>")
$null = $html.AppendLine("<p><strong>Generated:</strong> $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>")
$null = $html.AppendLine("<p><strong>Telescope System:</strong> Celestron Evolution with HomeBrew Gen3 PCB</p>")
$null = $html.AppendLine("</div>")

# Summary Grid
$null = $html.AppendLine("<h2>📊 Diagnostic Summary</h2>")
$null = $html.AppendLine("<div class='summary-grid'>")
foreach ($key in $Results.Keys) {
    if ($key -eq 'timestamp' -or $key -eq 'device_ip') { continue }
    $module = $Results[$key]
    $status = $module.overall_status
    $class = "status-warning"
    if ($status -eq "PASS") { $class = "status-pass" }
    elseif ($status -eq "FAIL" -or $status -eq "ERROR") { $class = "status-fail" }
    
    $moduleIcon = switch ($key) {
        "Telescope" { "🔭" }
        "Communication" { "📡" }
        "Network" { "🌐" }
        "System" { "💻" }
        "Hardware" { "🔧" }
        "Performance" { "⚡" }
        "Services" { "⚙️" }
        "Security" { "🔒" }
        default { "📋" }
    }
    
    $null = $html.AppendLine("<div class='summary-card'>")
    $null = $html.AppendLine("<h3>$moduleIcon $key Module</h3>")
    $null = $html.AppendLine("<div class='$class'>$status</div>")
    if ($module.tests) {
        $totalTests = ($module.tests.Keys | Measure-Object).Count
        $passedTests = ($module.tests.Keys | Where-Object { $module.tests[$_].status -eq 'Pass' } | Measure-Object).Count
        $null = $html.AppendLine("<p style='font-size: 12px; margin: 5px 0 0 0; color: #888;'>$passedTests/$totalTests tests passed</p>")
    }
    $null = $html.AppendLine("</div>")
}
$null = $html.AppendLine("</div>")

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
