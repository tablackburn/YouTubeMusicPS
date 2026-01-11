function ConvertTo-YtmPlaylist {
    <#
    .SYNOPSIS
        Converts a YouTube Music API playlist response to a typed object.

    .DESCRIPTION
        Parses the raw API response for a playlist from the library and converts it to a
        PSCustomObject with the YouTubeMusicPS.Playlist type name.

    .PARAMETER InputObject
        The raw playlist data from the API response (musicTwoRowItemRenderer)

    .OUTPUTS
        YouTubeMusicPS.Playlist
        Custom object with playlist properties

    .EXAMPLE
        $playlists = $response.contents | ForEach-Object { ConvertTo-YtmPlaylist -InputObject $_ }
    #>
    [CmdletBinding()]
    [OutputType('YouTubeMusicPS.Playlist')]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSCustomObject]$InputObject
    )

    process {
        # Extract the musicTwoRowItemRenderer if present
        $data = $InputObject
        if ($InputObject.PSObject.Properties['musicTwoRowItemRenderer']) {
            $data = $InputObject.musicTwoRowItemRenderer
        }

        # Extract playlist ID from navigationEndpoint
        $playlistId = $null
        if ($data.PSObject.Properties['navigationEndpoint']) {
            $browseEndpoint = $data.navigationEndpoint.browseEndpoint
            if ($browseEndpoint -and $browseEndpoint.PSObject.Properties['browseId']) {
                $playlistId = $browseEndpoint.browseId
                # Remove 'VL' prefix if present (used for browse requests)
                if ($playlistId -and $playlistId.StartsWith('VL')) {
                    $playlistId = $playlistId.Substring(2)
                }
            }
        }

        # Extract title from title.runs
        $name = $null
        if ($data.PSObject.Properties['title'] -and $data.title.PSObject.Properties['runs']) {
            $name = ($data.title.runs | ForEach-Object { $_.text }) -join ''
        }

        # Extract track count from subtitle
        $trackCount = $null
        if ($data.PSObject.Properties['subtitle'] -and $data.subtitle.PSObject.Properties['runs']) {
            $subtitleText = ($data.subtitle.runs | ForEach-Object { $_.text }) -join ''
            # Parse "X songs" or "X song" pattern
            if ($subtitleText -match '(\d+)\s+songs?') {
                try {
                    $trackCount = [int]$Matches[1]
                }
                catch {
                    Write-Verbose "Could not parse track count from '$subtitleText': $($_.Exception.Message)"
                    $trackCount = $null
                }
            }
        }

        # Extract thumbnail URL
        $thumbnailUrl = $null
        if ($data.PSObject.Properties['thumbnailRenderer']) {
            $thumbnails = $data.thumbnailRenderer.musicThumbnailRenderer.thumbnail.thumbnails
            if ($thumbnails -and $thumbnails.Count -gt 0) {
                # Get the largest thumbnail
                $thumbnailUrl = ($thumbnails | Sort-Object -Property width -Descending | Select-Object -First 1).url
            }
        }

        # Return typed object
        [PSCustomObject]@{
            PSTypeName   = 'YouTubeMusicPS.Playlist'
            Name         = $name
            PlaylistId   = $playlistId
            TrackCount   = $trackCount
            ThumbnailUrl = $thumbnailUrl
        }
    }
}
