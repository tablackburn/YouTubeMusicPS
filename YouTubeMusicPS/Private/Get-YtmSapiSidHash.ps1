function Get-YtmSapiSidHash {
    <#
    .SYNOPSIS
        Calculates the SAPISIDHASH for YouTube Music API authentication.

    .DESCRIPTION
        Generates the SAPISIDHASH authorization header value from the SAPISID cookie.
        This is required for authenticated requests to the YouTube Music API.

        The algorithm is: SHA1("{timestamp} {sapisid} {origin}")
        Returns: "SAPISIDHASH {timestamp}_{hexhash}"

    .PARAMETER SapiSid
        The SAPISID cookie value (from either SAPISID or __Secure-3PAPISID cookie)

    .PARAMETER Origin
        The origin URL. Defaults to https://music.youtube.com

    .OUTPUTS
        String
        The SAPISIDHASH authorization header value

    .NOTES
        Algorithm reverse engineered from: https://stackoverflow.com/a/32065323/5726546

        This uses SHA1 because it is YouTube's required authentication scheme for SAPISIDHASH.
        While SHA1 is considered cryptographically weak for signatures and certificates, it is
        acceptable here as a keyed hash for API authentication where the secret (SAPISID) is
        already known only to the authenticated user.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$SapiSid,

        [Parameter(Mandatory = $false)]
        [string]$Origin = 'https://music.youtube.com'
    )

    # Get current Unix timestamp
    $timestamp = [int64]([DateTimeOffset]::UtcNow.ToUnixTimeSeconds())

    # Build the string to hash: "{timestamp} {sapisid} {origin}"
    $authorizationString = "$timestamp $SapiSid $Origin"

    # Calculate SHA1 hash
    $sha1 = [System.Security.Cryptography.SHA1]::Create()
    try {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($authorizationString)
        $hashBytes = $sha1.ComputeHash($bytes)
        $hexHash = [BitConverter]::ToString($hashBytes).Replace('-', '').ToLower()
    }
    finally {
        $sha1.Dispose()
    }

    # Return in format: "SAPISIDHASH {timestamp}_{hexhash}"
    return "SAPISIDHASH ${timestamp}_${hexHash}"
}
