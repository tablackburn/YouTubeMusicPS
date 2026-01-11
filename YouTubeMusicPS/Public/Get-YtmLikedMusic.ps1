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

    .PARAMETER Force
        Skips the interactive prompt to connect if not authenticated.
        Instead, throws an error immediately. Use this for scripting scenarios.

    .EXAMPLE
        Get-YtmLikedMusic

        Gets all liked songs. Prompts to connect if not authenticated.

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
        [int]$Limit = 0,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    # Check authentication (prompts to connect if not authenticated, unless -Force)
    $null = Invoke-YtmAuthenticationPrompt -Cmdlet $PSCmdlet -Force:$Force

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

    # Check for API-level errors in the response
    if ($response.PSObject.Properties['error']) {
        throw "YouTube Music API error: $($response.error.message)"
    }

    # Find the music shelf in the initial response
    $musicShelf = Find-YtmMusicShelf -Response $response

    if (-not $musicShelf) {
        Write-Warning "Unable to parse API response. The YouTube Music API format may have changed."
        Write-Verbose "Response structure: $($response | ConvertTo-Json -Depth 3 -Compress)"
        return
    }

    if (-not $musicShelf.PSObject.Properties['contents'] -or $musicShelf.contents.Count -eq 0) {
        Write-Information "Your liked songs library is empty." -InformationAction Continue
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
    $continuationToken = Get-YtmContinuationToken -MusicShelf $musicShelf

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
                    $continuationItem = $shelfContinuation.continuations[0]
                    if ($continuationItem.PSObject.Properties['nextContinuationData']) {
                        $newContinuationToken = $continuationItem.nextContinuationData.continuation
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
