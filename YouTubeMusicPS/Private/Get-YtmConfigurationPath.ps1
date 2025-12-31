function Get-YtmConfigurationPath {
    <#
    .SYNOPSIS
        Gets the configuration file path for YouTubeMusicPS.

    .DESCRIPTION
        Determines the best location for the configuration file with fallback options.
        Prefers OneDrive-synced location for cross-machine sync on Windows.
        Uses ~/.config/YouTubeMusicPS on Linux/macOS.

    .OUTPUTS
        String
        Returns the full path to the configuration file
    #>
    [CmdletBinding()]
    param ()

    $runningOnWindows = $PSVersionTable.PSVersion.Major -lt 6 -or $IsWindows

    if ($runningOnWindows) {
        # Try OneDrive location first (syncs across machines)
        if ($env:OneDrive) {
            $configurationDirectory = Join-Path $env:OneDrive 'Documents\YouTubeMusicPS'
            $configurationPath = Join-Path $configurationDirectory 'config.json'

            # Test if OneDrive location is writable
            try {
                # Create directory if needed (Force handles race condition)
                $null = New-Item -Path $configurationDirectory -ItemType Directory -Force -ErrorAction Stop

                # Test write access
                $testFile = Join-Path $configurationDirectory '.test'
                [IO.File]::WriteAllText($testFile, 'test')
                Remove-Item $testFile -Force
                return $configurationPath
            }
            catch [System.IO.IOException] {
                Write-Debug "OneDrive path not accessible (IOException), using fallback"
            }
            catch {
                Write-Debug "OneDrive path not accessible ($($_.Exception.GetType().Name)), using fallback"
            }
        }

        # Fallback to user Documents
        if ($env:USERPROFILE) {
            $configurationDirectory = Join-Path $env:USERPROFILE 'Documents\YouTubeMusicPS'
            $configurationPath = Join-Path $configurationDirectory 'config.json'

            try {
                # Create directory if needed (Force handles race condition)
                $null = New-Item -Path $configurationDirectory -ItemType Directory -Force -ErrorAction Stop
                return $configurationPath
            }
            catch {
                # Documents not accessible, use LocalAppData as last resort
                if ($env:LOCALAPPDATA) {
                    $configurationDirectory = Join-Path $env:LOCALAPPDATA 'YouTubeMusicPS'
                    # Create directory if needed (Force handles race condition)
                    $null = New-Item -Path $configurationDirectory -ItemType Directory -Force -ErrorAction Stop
                    return Join-Path $configurationDirectory 'config.json'
                }
            }
        }
    }

    # Linux/macOS: use ~/.config/YouTubeMusicPS
    $homeDir = $env:HOME
    if (-not $homeDir) {
        $homeDir = [Environment]::GetFolderPath('UserProfile')
    }

    $configurationDirectory = Join-Path $homeDir '.config/YouTubeMusicPS'
    $configurationPath = Join-Path $configurationDirectory 'config.json'

    # Create directory if needed
    $null = New-Item -Path $configurationDirectory -ItemType Directory -Force -ErrorAction SilentlyContinue

    return $configurationPath
}
