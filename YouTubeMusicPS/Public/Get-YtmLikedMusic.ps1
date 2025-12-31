function Get-YtmLikedMusic {
    <#
    .SYNOPSIS
        Retrieves your liked songs from YouTube Music.

    .DESCRIPTION
        Gets the list of songs you have liked (thumbs up) on YouTube Music.
        Requires authentication via Connect-YtmAccount first.
        Supports pagination to retrieve your entire library.

    .PARAMETER Limit
        Maximum number of songs to retrieve. Default is 0 which retrieves all songs.

    .EXAMPLE
        Get-YtmLikedMusic

        Gets all liked songs.

    .EXAMPLE
        Get-YtmLikedMusic -Limit 50

        Gets up to 50 liked songs.

    .EXAMPLE
        Get-YtmLikedMusic | Select-Object Title, Artist, Album

        Gets liked songs and displays selected properties.

    .EXAMPLE
        Get-YtmLikedMusic | Export-Csv -Path liked_songs.csv

        Exports all liked songs to a CSV file.

    .OUTPUTS
        YouTubeMusicPS.Song

        Objects with properties:
        - VideoId: YouTube video identifier
        - Title: Song title
        - Artist: Artist name(s)
        - ArtistId: Artist channel ID
        - Album: Album name (if available)
        - AlbumId: Album browse ID
        - Duration: Duration as string (e.g., "3:45")
        - DurationSeconds: Duration in seconds
        - ThumbnailUrl: URL to thumbnail image
        - LikeStatus: Current like status
    #>
    [CmdletBinding()]
    [OutputType('YouTubeMusicPS.Song')]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateRange(0, [int]::MaxValue)]
        [int]$Limit = 0
    )

    # Check authentication
    $cookies = Get-YtmStoredCookies
    if (-not $cookies) {
        throw 'Not authenticated. Please run Connect-YtmAccount first.'
    }

    Write-Verbose "Fetching liked music from YouTube Music..."

    # Make the initial API request
    $body = @{
        browseId = 'FEmusic_liked_videos'
    }

    try {
        $response = Invoke-YtmApi -Endpoint 'browse' -Body $body
    }
    catch {
        throw "Failed to retrieve liked music: $($_.Exception.Message)"
    }

    # Helper function to find the music shelf in the response
    function Find-MusicShelf {
        param ($Response)

        $musicShelf = $null

        if ($Response.PSObject.Properties['contents']) {
            $tabs = $Response.contents.singleColumnBrowseResultsRenderer.tabs
            if ($tabs) {
                foreach ($tab in $tabs) {
                    $tabRenderer = $tab.tabRenderer
                    if ($tabRenderer.PSObject.Properties['content']) {
                        $sectionList = $tabRenderer.content.sectionListRenderer
                        if ($sectionList.PSObject.Properties['contents']) {
                            foreach ($section in $sectionList.contents) {
                                if ($section.PSObject.Properties['itemSectionRenderer']) {
                                    $itemSection = $section.itemSectionRenderer
                                    if ($itemSection.PSObject.Properties['contents']) {
                                        foreach ($item in $itemSection.contents) {
                                            if ($item.PSObject.Properties['musicShelfRenderer']) {
                                                $musicShelf = $item.musicShelfRenderer
                                                break
                                            }
                                        }
                                    }
                                }
                                elseif ($section.PSObject.Properties['musicShelfRenderer']) {
                                    $musicShelf = $section.musicShelfRenderer
                                    break
                                }
                            }
                        }
                    }
                }
            }
        }

        return $musicShelf
    }

    # Helper function to extract continuation token
    function Get-ContinuationToken {
        param ($MusicShelf)

        if ($MusicShelf.PSObject.Properties['continuations']) {
            $continuations = $MusicShelf.continuations
            if ($continuations -and $continuations.Count -gt 0) {
                $contData = $continuations[0]
                if ($contData.PSObject.Properties['nextContinuationData']) {
                    return $contData.nextContinuationData.continuation
                }
            }
        }
        return $null
    }

    # Find the music shelf in the initial response
    $musicShelf = Find-MusicShelf -Response $response

    if (-not $musicShelf -or -not $musicShelf.PSObject.Properties['contents']) {
        Write-Warning "No liked songs found or unable to parse response."
        return
    }

    $totalCount = 0
    $shouldContinue = $true

    # Process initial batch - check for random mix entry to skip
    $contents = $musicShelf.contents
    $startIndex = 0
    if ($contents.Count -gt 1) {
        $firstItem = $contents[0]
        if ($firstItem.PSObject.Properties['musicResponsiveListItemRenderer']) {
            $renderer = $firstItem.musicResponsiveListItemRenderer
            if (-not $renderer.PSObject.Properties['overlay']) {
                $startIndex = 1
                Write-Verbose "Skipping random mix entry"
            }
        }
    }

    # Output initial songs
    for ($i = $startIndex; $i -lt $contents.Count; $i++) {
        if ($Limit -gt 0 -and $totalCount -ge $Limit) {
            $shouldContinue = $false
            break
        }

        $song = ConvertTo-YtmSong -InputObject $contents[$i]
        if ($song.VideoId -and $song.Title) {
            $song  # Output to pipeline
            $totalCount++
        }
    }

    # Get continuation token for pagination
    $continuationToken = Get-ContinuationToken -MusicShelf $musicShelf

    # Continue fetching while we have a token and haven't hit the limit
    $pageNumber = 1
    while ($shouldContinue -and $continuationToken) {
        $pageNumber++
        Write-Verbose "Fetching more songs (retrieved $totalCount so far)..."

        $progressParams = @{
            Activity = 'Retrieving liked songs'
            Status   = "Retrieved $totalCount songs (page $pageNumber)"
        }
        if ($Limit -gt 0) {
            $progressParams['PercentComplete'] = [math]::Min(100, [int]($totalCount / $Limit * 100))
        }
        Write-Progress @progressParams

        try {
            $response = Invoke-YtmApi -Endpoint 'browse' -Body $body -ContinuationToken $continuationToken
        }
        catch {
            Write-Progress -Activity 'Retrieving liked songs' -Completed
            Write-Warning "Failed to fetch continuation: $($_.Exception.Message)"
            break
        }

        # Continuation responses have a different structure
        $contents = $null
        $newContinuationToken = $null

        if ($response.PSObject.Properties['continuationContents']) {
            $shelfContinuation = $response.continuationContents.musicShelfContinuation
            if ($shelfContinuation) {
                $contents = $shelfContinuation.contents
                # Check for next continuation
                if ($shelfContinuation.PSObject.Properties['continuations']) {
                    $contData = $shelfContinuation.continuations[0]
                    if ($contData.PSObject.Properties['nextContinuationData']) {
                        $newContinuationToken = $contData.nextContinuationData.continuation
                    }
                }
            }
        }

        if (-not $contents -or $contents.Count -eq 0) {
            Write-Verbose "No more songs in continuation response"
            break
        }

        # Output songs from continuation
        foreach ($item in $contents) {
            if ($Limit -gt 0 -and $totalCount -ge $Limit) {
                $shouldContinue = $false
                break
            }

            $song = ConvertTo-YtmSong -InputObject $item
            if ($song.VideoId -and $song.Title) {
                $song  # Output to pipeline
                $totalCount++
            }
        }

        $continuationToken = $newContinuationToken
    }

    # Clear progress bar
    if ($pageNumber -gt 1) {
        Write-Progress -Activity 'Retrieving liked songs' -Completed
    }

    Write-Verbose "Retrieved $totalCount liked songs total"
}
