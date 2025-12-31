function ConvertTo-YtmSong {
    <#
    .SYNOPSIS
        Converts a YouTube Music API song response to a typed object.

    .DESCRIPTION
        Parses the raw API response for a song/track and converts it to a
        PSCustomObject with the YouTubeMusicPS.Song type name.

    .PARAMETER InputObject
        The raw song data from the API response

    .PARAMETER PlaylistId
        Optional playlist ID to include in the output object. Used when parsing
        playlist contents to enable pipeline operations like Remove-YtmPlaylistItem.

    .OUTPUTS
        YouTubeMusicPS.Song
        Custom object with song properties

    .EXAMPLE
        $songs = $response.contents | ForEach-Object { ConvertTo-YtmSong -InputObject $_ }

    .EXAMPLE
        $songs = $response.contents | ForEach-Object { ConvertTo-YtmSong -InputObject $_ -PlaylistId 'PLxxx' }
    #>
    [CmdletBinding()]
    [OutputType('YouTubeMusicPS.Song')]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSCustomObject]$InputObject,

        [Parameter(Mandatory = $false)]
        [string]$PlaylistId
    )

    process {
        # Extract the musicResponsiveListItemRenderer if present
        $data = $InputObject
        if ($InputObject.PSObject.Properties['musicResponsiveListItemRenderer']) {
            $data = $InputObject.musicResponsiveListItemRenderer
        }

        # Extract video ID from playNavigationEndpoint or menu
        $videoId = $null
        if ($data.PSObject.Properties['overlay']) {
            $playButton = $data.overlay.musicItemThumbnailOverlayRenderer.content.musicPlayButtonRenderer
            if ($playButton.PSObject.Properties['playNavigationEndpoint']) {
                $videoId = $playButton.playNavigationEndpoint.watchEndpoint.videoId
            }
        }

        # Extract title from flexColumns
        $title = $null
        if ($data.PSObject.Properties['flexColumns'] -and $data.flexColumns.Count -gt 0) {
            $titleColumn = $data.flexColumns[0].musicResponsiveListItemFlexColumnRenderer
            if ($titleColumn.PSObject.Properties['text'] -and $titleColumn.text.PSObject.Properties['runs']) {
                $title = $titleColumn.text.runs[0].text
            }
        }

        # Extract artist from flexColumns (usually index 1)
        $artist = $null
        $artistId = $null
        if ($data.PSObject.Properties['flexColumns'] -and $data.flexColumns.Count -gt 1) {
            $artistColumn = $data.flexColumns[1].musicResponsiveListItemFlexColumnRenderer
            if ($artistColumn.PSObject.Properties['text'] -and $artistColumn.text.PSObject.Properties['runs']) {
                $artistRuns = $artistColumn.text.runs
                $artist = ($artistRuns | Where-Object { $_.PSObject.Properties['text'] } | ForEach-Object { $_.text }) -join ''
                # Get first artist ID if available
                $firstArtistRun = $artistRuns | Where-Object { $_.PSObject.Properties['navigationEndpoint'] } | Select-Object -First 1
                if ($firstArtistRun) {
                    $artistId = $firstArtistRun.navigationEndpoint.browseEndpoint.browseId
                }
            }
        }

        # Extract album from flexColumns (usually index 2 or 3)
        $album = $null
        $albumId = $null
        foreach ($i in 2..3) {
            if ($data.PSObject.Properties['flexColumns'] -and $data.flexColumns.Count -gt $i) {
                $albumColumn = $data.flexColumns[$i].musicResponsiveListItemFlexColumnRenderer
                if ($albumColumn.PSObject.Properties['text'] -and $albumColumn.text.PSObject.Properties['runs']) {
                    $albumRun = $albumColumn.text.runs | Where-Object {
                        $_.PSObject.Properties['navigationEndpoint'] -and
                        $_.navigationEndpoint.PSObject.Properties['browseEndpoint']
                    } | Select-Object -First 1
                    if ($albumRun) {
                        $pageType = $albumRun.navigationEndpoint.browseEndpoint.browseEndpointContextSupportedConfigs.browseEndpointContextMusicConfig.pageType
                        if ($pageType -eq 'MUSIC_PAGE_TYPE_ALBUM') {
                            $album = $albumRun.text
                            $albumId = $albumRun.navigationEndpoint.browseEndpoint.browseId
                            break
                        }
                    }
                }
            }
        }

        # Extract duration from fixedColumns
        $duration = $null
        $durationSeconds = $null
        if ($data.PSObject.Properties['fixedColumns'] -and $data.fixedColumns.Count -gt 0) {
            $durationColumn = $data.fixedColumns[0].musicResponsiveListItemFixedColumnRenderer
            if ($durationColumn.PSObject.Properties['text']) {
                if ($durationColumn.text.PSObject.Properties['simpleText']) {
                    $duration = $durationColumn.text.simpleText
                }
                elseif ($durationColumn.text.PSObject.Properties['runs']) {
                    $duration = $durationColumn.text.runs[0].text
                }
            }
        }

        # Parse duration to seconds
        if ($duration) {
            $parts = $duration -split ':'
            if ($parts.Count -eq 2) {
                $durationSeconds = [int]$parts[0] * 60 + [int]$parts[1]
            }
            elseif ($parts.Count -eq 3) {
                $durationSeconds = [int]$parts[0] * 3600 + [int]$parts[1] * 60 + [int]$parts[2]
            }
        }

        # Extract thumbnail
        $thumbnailUrl = $null
        if ($data.PSObject.Properties['thumbnail']) {
            $thumbnails = $data.thumbnail.musicThumbnailRenderer.thumbnail.thumbnails
            if ($thumbnails -and $thumbnails.Count -gt 0) {
                # Get the largest thumbnail
                $thumbnailUrl = ($thumbnails | Sort-Object -Property width -Descending | Select-Object -First 1).url
            }
        }

        # Extract like status
        $likeStatus = $null
        if ($data.PSObject.Properties['menu']) {
            $menuItems = $data.menu.menuRenderer.items
            foreach ($item in $menuItems) {
                if ($item.PSObject.Properties['menuServiceItemRenderer']) {
                    $serviceEndpoint = $item.menuServiceItemRenderer.serviceEndpoint
                    if ($serviceEndpoint.PSObject.Properties['likeEndpoint']) {
                        $likeStatus = $serviceEndpoint.likeEndpoint.status
                        break
                    }
                }
            }
        }

        # Extract setVideoId for playlist items (required for removal operations)
        $setVideoId = $null
        if ($data.PSObject.Properties['playlistItemData']) {
            $playlistItemData = $data.playlistItemData
            if ($playlistItemData.PSObject.Properties['playlistSetVideoId']) {
                $setVideoId = $playlistItemData.playlistSetVideoId
            }
        }

        # Return typed object
        [PSCustomObject]@{
            PSTypeName      = 'YouTubeMusicPS.Song'
            VideoId         = $videoId
            SetVideoId      = $setVideoId
            PlaylistId      = if ($PlaylistId) { $PlaylistId } else { $null }
            Title           = $title
            Artist          = $artist
            ArtistId        = $artistId
            Album           = $album
            AlbumId         = $albumId
            Duration        = $duration
            DurationSeconds = $durationSeconds
            ThumbnailUrl    = $thumbnailUrl
            LikeStatus      = $likeStatus
        }
    }
}
