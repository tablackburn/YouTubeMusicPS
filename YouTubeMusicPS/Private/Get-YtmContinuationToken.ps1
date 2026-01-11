function Get-YtmContinuationToken {
    <#
    .SYNOPSIS
        Extracts a continuation token from a YouTube Music API shelf response.

    .DESCRIPTION
        YouTube Music API uses continuation tokens for pagination. This function
        extracts the nextContinuationData token from a music shelf renderer,
        which can be used to fetch the next page of results.

    .PARAMETER MusicShelf
        The musicShelfRenderer or musicPlaylistShelfRenderer object from an API response.

    .OUTPUTS
        String
        The continuation token if found, otherwise $null.

    .EXAMPLE
        $token = Get-YtmContinuationToken -MusicShelf $musicShelf
        if ($token) {
            $nextPage = Invoke-YtmApi -Endpoint 'browse' -Body $body -ContinuationToken $token
        }
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$MusicShelf
    )

    if ($MusicShelf.PSObject.Properties['continuations']) {
        $continuations = $MusicShelf.continuations
        if ($continuations -and $continuations.Count -gt 0) {
            $continuationItem = $continuations[0]
            if ($continuationItem.PSObject.Properties['nextContinuationData']) {
                return $continuationItem.nextContinuationData.continuation
            }
        }
    }

    return $null
}
