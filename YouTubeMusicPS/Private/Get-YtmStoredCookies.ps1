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
