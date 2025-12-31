function Get-YtmConfiguration {
    <#
    .SYNOPSIS
        Reads the YouTubeMusicPS configuration file.

    .DESCRIPTION
        Loads and validates the configuration from the JSON config file.
        Returns a default empty config if file doesn't exist.

    .OUTPUTS
        PSCustomObject
        Returns the configuration object with version and authentication data
    #>
    [CmdletBinding()]
    param ()

    $configurationPath = Get-YtmConfigurationPath

    if (-not (Test-Path $configurationPath)) {
        # Return default empty config
        return [PSCustomObject]@{
            version = '1.0'
            auth    = $null
        }
    }

    try {
        $content = Get-Content -Path $configurationPath -Raw -ErrorAction Stop
        $configuration = $content | ConvertFrom-Json -ErrorAction Stop

        # Validate schema
        if (-not $configuration.PSObject.Properties['version']) {
            throw "Configuration missing 'version' property"
        }

        return $configuration
    }
    catch {
        throw "Failed to read configuration: $($_.Exception.Message)"
    }
}
