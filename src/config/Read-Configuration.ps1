#Requires -Version 5.1

<#
.SYNOPSIS
    Configuration Reader for HomeBrew Diagnostic Tool
    
.DESCRIPTION
    Reads and parses the YAML configuration file for the diagnostic tool.
    Uses a simple parser to avoid dependencies on external modules.
    
.OUTPUTS
    Hashtable containing the configuration settings
    
.EXAMPLE
    $config = .\Read-Configuration.ps1
    Write-Host "Device IP: $($config.diagnostics.device.ip)"
#>

[CmdletBinding()]
param(
    [string]$ConfigPath = "$PSScriptRoot/../../config/diagnostics.yaml"
)

function Parse-SimpleYaml {
    param([string]$Path)
    
    if (-not (Test-Path $Path)) {
        Write-Warning "Configuration file not found at $Path. Using defaults."
        return $null
    }
    
    $content = Get-Content -Path $Path -Raw
    $lines = $content -split "`r?`n"
    
    $config = @{}
    $currentPath = @()
    $lastIndent = -1
    
    foreach ($line in $lines) {
        # Skip comments and empty lines
        if ($line -match "^\s*#" -or [string]::IsNullOrWhiteSpace($line)) { continue }
        
        # Determine indentation
        $indent = 0
        if ($line -match "^(\s+)") {
            $indent = $matches[1].Length
        }
        
        # Parse key-value or key-object
        if ($line -match "^(\s*)([\w\-_]+):\s*(.*)$") {
            $key = $matches[2]
            $value = $matches[3].Trim()
            
            # Adjust current path based on indentation
            if ($indent -gt $lastIndent) {
                # Child of previous
            } elseif ($indent -eq $lastIndent) {
                # Sibling, pop last
                if ($currentPath.Count -gt 0) { $null = $currentPath.RemoveAt($currentPath.Count - 1) }
            } else {
                # Parent, pop until level matches (approximate for simple cases)
                # Since we don't track exact indent levels in a stack, we'll just pop
                # This simple parser assumes 2-space indentation standard
                $levelsToPop = ($lastIndent - $indent) / 2 + 1
                for ($i = 0; $i -lt $levelsToPop; $i++) {
                    if ($currentPath.Count -gt 0) { $null = $currentPath.RemoveAt($currentPath.Count - 1) }
                }
            }
            
            # Add to config structure
            $currentRef = $config
            foreach ($pathPart in $currentPath) {
                if (-not $currentRef.ContainsKey($pathPart)) {
                    $currentRef[$pathPart] = @{}
                }
                $currentRef = $currentRef[$pathPart]
            }
            
            # Handle values
            if ($value -eq "") {
                # It's a parent key
                $currentRef[$key] = @{}
                $currentPath.Add($key)
                $lastIndent = $indent
            } else {
                # Leaf node
                # Remove inline comments
                if ($value -match "^(.*?)\s+#") { $value = $matches[1] }
                
                # Parse value types
                if ($value -eq "true") { $value = $true }
                elseif ($value -eq "false") { $value = $false }
                elseif ($value -eq "null") { $value = $null }
                elseif ($value -match "^['`"](.*)['`"]$") { $value = $matches[1] } # Strip quotes
                elseif ($value -as [double]) { $value = $value -as [double] } # Numbers
                
                # Handle lists (very basic support)
                if ($currentRef.ContainsKey($key) -and $currentRef[$key] -is [System.Collections.ArrayList]) {
                    # Already a list?
                } else {
                    $currentRef[$key] = $value
                }
            }
        } elseif ($line -match "^(\s*)-\s+(.*)$") {
            # List item
            $val = $matches[2].Trim()
            if ($val -match "^['`"](.*)['`"]$") { $val = $matches[1] }
            
            # Add to the parent list
            # We need to find the parent object which should be the last one in currentPath
            $parentKey = $currentPath[$currentPath.Count - 1]
            
            # Navigate to parent's parent
            $listParent = $config
            for ($i = 0; $i -lt $currentPath.Count - 1; $i++) {
                $listParent = $listParent[$currentPath[$i]]
            }
            
            if (-not ($listParent[$parentKey] -is [System.Collections.ArrayList])) {
                $listParent[$parentKey] = New-Object System.Collections.ArrayList
            }
            $null = $listParent[$parentKey].Add($val)
        }
    }
    
    return $config
}

# Return default config if parsing fails or returns null
$config = Parse-SimpleYaml -Path $ConfigPath

if (-not $config) {
    # Default fallback
    $config = @{
        'diagnostics' = @{
            'device' = @{
                'ip' = "192.168.1.100"
            }
        }
    }
}

return $config
