function Set-YtmStoredCookies {
    <#
    .SYNOPSIS
        Stores YouTube Music cookies in the configuration file.

    .DESCRIPTION
        Saves the SAPISID and full cookie string to the configuration file
        for use in authenticated API requests.

    .PARAMETER SapiSid
        The SAPISID cookie value (extracted from SAPISID or __Secure-3PAPISID)

    .PARAMETER Cookies
        The full cookie string for HTTP requests

    .EXAMPLE
        Set-YtmStoredCookies -SapiSid 'abc123' -Cookies 'SAPISID=abc123; SSID=xyz789'
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
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$SapiSid,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Cookies
    )

    if (-not $PSCmdlet.ShouldProcess('YouTubeMusicPS configuration', 'Store cookies')) {
        return
    }

    $configuration = Get-YtmConfiguration

    $configuration.auth = [PSCustomObject]@{
        sapiSid = $SapiSid
        cookies = $Cookies
    }

    Set-YtmConfiguration -Configuration $configuration
}
