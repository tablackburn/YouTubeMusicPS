function Remove-YtmStoredCookies {
    <#
    .SYNOPSIS
        Removes stored YouTube Music cookies from the configuration file.

    .DESCRIPTION
        Clears the stored authentication cookies from the configuration file.

    .EXAMPLE
        Remove-YtmStoredCookies
    #>
    # The plural is accurate rather than sloppy: what is stored is the browser cookie
    # jar -- the whole Cookie request header, holding many cookies -- so a singular
    # name would describe something this function never handles. Private helper, so
    # the name is not part of the exported command surface either.
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseSingularNouns',
        '',
        Justification = 'Private helper; the stored value is the whole cookie jar, so the plural is accurate'
    )]
    [CmdletBinding(SupportsShouldProcess)]
    param ()

    if (-not $PSCmdlet.ShouldProcess('YouTubeMusicPS configuration', 'Remove cookies')) {
        return
    }

    $configuration = Get-YtmConfiguration
    $configuration.auth = $null
    Set-YtmConfiguration -Configuration $configuration
}
