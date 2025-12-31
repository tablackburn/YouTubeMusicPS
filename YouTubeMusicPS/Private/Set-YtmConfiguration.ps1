function Set-YtmConfiguration {
    <#
    .SYNOPSIS
        Writes the YouTubeMusicPS configuration file.

    .DESCRIPTION
        Saves the configuration to the JSON config file.
        Creates the file if it doesn't exist.

    .PARAMETER Configuration
        The configuration object to save

    .EXAMPLE
        $configuration = Get-YtmConfiguration
        $configuration.auth = [PSCustomObject]@{ cookies = 'SAPISID=xxx' }
        Set-YtmConfiguration -Configuration $configuration
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [PSCustomObject]
        $Configuration
    )

    $configurationPath = Get-YtmConfigurationPath

    if (-not $PSCmdlet.ShouldProcess($configurationPath, 'Write configuration')) {
        return
    }

    try {
        # Validate required properties
        if (-not $Configuration.PSObject.Properties['version']) {
            throw "Configuration missing 'version' property"
        }

        # Convert to JSON with proper formatting
        $json = $Configuration | ConvertTo-Json -Depth 10 -ErrorAction Stop

        # Ensure directory exists
        $configurationDirectory = Split-Path $configurationPath -Parent
        if (-not (Test-Path $configurationDirectory)) {
            New-Item -Path $configurationDirectory -ItemType Directory -Force -ErrorAction Stop | Out-Null
        }

        # Write file with UTF-8 encoding (no BOM)
        [IO.File]::WriteAllText($configurationPath, $json, [System.Text.UTF8Encoding]::new($false))
    }
    catch {
        throw "Failed to write configuration: $($_.Exception.Message)"
    }
}
