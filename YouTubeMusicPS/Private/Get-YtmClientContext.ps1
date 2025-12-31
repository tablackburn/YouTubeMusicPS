function Get-YtmClientContext {
    <#
    .SYNOPSIS
        Builds the client context for YouTube Music API requests.

    .DESCRIPTION
        Creates the context object required for all YouTube Music API calls.
        Includes client name, version, language, and location settings.

    .PARAMETER Language
        The language code for the request. Defaults to 'en'.

    .PARAMETER Location
        The country code for the request. Defaults to 'US'.

    .OUTPUTS
        Hashtable
        The context object for API requests

    .EXAMPLE
        $context = Get-YtmClientContext
        $body = @{ browseId = 'FEmusic_liked_videos'; context = $context.context }
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$Language = 'en',

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$Location = 'US'
    )

    # Use a stable client version
    $clientVersion = '1.20241127.01.00'

    return @{
        context = @{
            client = @{
                clientName    = 'WEB_REMIX'
                clientVersion = $clientVersion
                hl            = $Language
                gl            = $Location
            }
        }
    }
}
