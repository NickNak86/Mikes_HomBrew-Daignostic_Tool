<#
.SYNOPSIS
    JSON Report Generator
    
.DESCRIPTION
    Generates a JSON report from diagnostic results.
#>

param(
    [Parameter(Mandatory=$true)]
    [hashtable]$Results
)

return $Results | ConvertTo-Json -Depth 10
