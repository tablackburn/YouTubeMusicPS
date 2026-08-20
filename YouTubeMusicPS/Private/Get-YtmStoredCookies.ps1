function Get-YtmStoredCookies {
    <#
    .SYNOPSIS
        Retrieves stored YouTube Music cookies.

    .DESCRIPTION
        Gets the stored authentication cookies from the configuration file.
        Returns null if no cookies are stored.

    .OUTPUTS
        PSCustomObject
        Object containing:
        - SapiSid: The SAPISID cookie value
        - Cookies: The full cookie string for HTTP requests

    .EXAMPLE
        $cookies = Get-YtmStoredCookies
        if ($cookies) {
            $authorization = Get-YtmSapiSidHash -SapiSid $cookies.SapiSid
        }
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
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param ()

    $configuration = Get-YtmConfiguration

    if (-not $configuration.auth) {
        return $null
    }

    if (-not $configuration.auth.sapiSid -or -not $configuration.auth.cookies) {
        return $null
    }

    return [PSCustomObject]@{
        SapiSid = $configuration.auth.sapiSid
        Cookies = $configuration.auth.cookies
    }
}
