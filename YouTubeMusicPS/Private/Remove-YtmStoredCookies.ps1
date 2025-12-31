function Remove-YtmStoredCookies {
    <#
    .SYNOPSIS
        Removes stored YouTube Music cookies from the configuration file.

    .DESCRIPTION
        Clears the stored authentication cookies from the configuration file.

    .EXAMPLE
        Remove-YtmStoredCookies
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param ()

    if (-not $PSCmdlet.ShouldProcess('YouTubeMusicPS configuration', 'Remove cookies')) {
        return
    }

    $configuration = Get-YtmConfiguration
    $configuration.auth = $null
    Set-YtmConfiguration -Configuration $configuration
}
