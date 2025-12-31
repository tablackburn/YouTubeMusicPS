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
