function Disconnect-YtmAccount {
    <#
    .SYNOPSIS
        Removes stored YouTube Music authentication credentials.

    .DESCRIPTION
        Clears the stored cookies from the configuration file,
        effectively logging out of YouTube Music.

    .EXAMPLE
        Disconnect-YtmAccount

        Removes stored credentials.

    .OUTPUTS
        None
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param ()

    if (-not $PSCmdlet.ShouldProcess('YouTubeMusicPS', 'Remove stored credentials')) {
        return
    }

    Remove-YtmStoredCookies
    Write-Information "Successfully disconnected from YouTube Music." -InformationAction Continue
}
