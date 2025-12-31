function Get-YtmPlaylist {
    <#
    .SYNOPSIS
        Retrieves playlists or playlist contents from YouTube Music.

    .DESCRIPTION
        When called without parameters, lists all playlists in your library.
        When called with -Name or -Id, retrieves the songs in that playlist.
        Requires authentication via Connect-YtmAccount first.

    .PARAMETER Name
        The name of the playlist to retrieve contents for.
        Supports tab completion from your library playlists.

    .PARAMETER Id
        The playlist ID to retrieve contents for.
        Use this for public/community playlists not in your library.

    .PARAMETER Limit
        Maximum number of items to retrieve. Default is 0 which retrieves all items.

    .EXAMPLE
        Get-YtmPlaylist

        Lists all playlists in your library.

    .EXAMPLE
        Get-YtmPlaylist -Name "Chill Vibes"

        Gets all songs in the "Chill Vibes" playlist.

    .EXAMPLE
        Get-YtmPlaylist -Name "Chill Vibes" -Limit 50

        Gets up to 50 songs from the playlist.

    .EXAMPLE
        Get-YtmPlaylist -Name "Chill Vibes" | Where-Object Artist -match "Adele"

        Gets songs by Adele from the playlist.

    .EXAMPLE
        Get-YtmPlaylist -Id "PLrAXtmErZgOeiKm4sgNOknGvNjby9efdf"

        Gets songs from a playlist by its ID.

    .OUTPUTS
        YouTubeMusicPS.Playlist (when listing playlists)
        YouTubeMusicPS.Song (when getting playlist contents)
    #>
    [CmdletBinding(DefaultParameterSetName = 'List')]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'ByName', Position = 0)]
        [ArgumentCompleter({
            param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
            # Get playlists for tab completion
            try {
                $playlists = Get-YtmPlaylist -ErrorAction SilentlyContinue
                if ($playlists) {
                    $playlists | Where-Object { $_.Name -like "*$wordToComplete*" } | ForEach-Object {
                        $name = $_.Name
                        # Quote names with spaces
                        if ($name -match '\s') {
                            "'$name'"
                        }
                        else {
                            $name
                        }
                    }
                }
            }
            catch {
                # Silently fail if not authenticated
            }
        })]
        [string]$Name,

        [Parameter(Mandatory = $true, ParameterSetName = 'ById')]
        [string]$Id,

        [Parameter(Mandatory = $false)]
        [ValidateRange(0, [int]::MaxValue)]
        [int]$Limit = 0
    )

    # Check authentication
    $cookies = Get-YtmStoredCookies
    if (-not $cookies) {
        throw 'Not authenticated. Please run Connect-YtmAccount first.'
    }

    # Determine which mode we're in
    if ($PSCmdlet.ParameterSetName -eq 'List') {
        # List all playlists
        Get-LibraryPlaylists
    }
    elseif ($PSCmdlet.ParameterSetName -eq 'ByName') {
        # Resolve name to ID and get contents
        $playlists = Get-LibraryPlaylists
        $matchingPlaylist = $playlists | Where-Object { $_.Name -eq $Name }

        if (-not $matchingPlaylist) {
            # Try case-insensitive match
            $matchingPlaylist = $playlists | Where-Object { $_.Name -ieq $Name }
        }

        if (-not $matchingPlaylist) {
            throw "Playlist '$Name' not found in your library. Use Get-YtmPlaylist to see available playlists."
        }

        if ($matchingPlaylist.Count -gt 1) {
            throw "Multiple playlists found matching '$Name'. Please use a more specific name."
        }

        Get-PlaylistContents -PlaylistId $matchingPlaylist.PlaylistId -Limit $Limit
    }
    else {
        # Get contents by ID
        Get-PlaylistContents -PlaylistId $Id -Limit $Limit
    }
}

function Get-LibraryPlaylists {
    <#
    .SYNOPSIS
        Internal helper to retrieve library playlists.
    #>

    Write-Verbose "Fetching playlists from YouTube Music library..."

    $body = @{
        browseId = 'FEmusic_liked_playlists'
    }

    try {
        $response = Invoke-YtmApi -Endpoint 'browse' -Body $body
    }
    catch {
        throw "Failed to retrieve playlists: $($_.Exception.Message)"
    }

    # Navigate to the grid/shelf containing playlists
    $items = $null

    if ($response.PSObject.Properties['contents']) {
        $tabs = $response.contents.singleColumnBrowseResultsRenderer.tabs
        if ($tabs) {
            foreach ($tab in $tabs) {
                $tabRenderer = $tab.tabRenderer
                if ($tabRenderer.PSObject.Properties['content']) {
                    $sectionList = $tabRenderer.content.sectionListRenderer
                    if ($sectionList.PSObject.Properties['contents']) {
                        foreach ($section in $sectionList.contents) {
                            # Look for gridRenderer or musicShelfRenderer
                            if ($section.PSObject.Properties['gridRenderer']) {
                                $items = $section.gridRenderer.items
                                break
                            }
                            elseif ($section.PSObject.Properties['musicShelfRenderer']) {
                                $items = $section.musicShelfRenderer.contents
                                break
                            }
                            elseif ($section.PSObject.Properties['itemSectionRenderer']) {
                                $itemSection = $section.itemSectionRenderer
                                if ($itemSection.PSObject.Properties['contents']) {
                                    foreach ($item in $itemSection.contents) {
                                        if ($item.PSObject.Properties['gridRenderer']) {
                                            $items = $item.gridRenderer.items
                                            break
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    if (-not $items) {
        Write-Warning "No playlists found or unable to parse response."
        return
    }

    # Convert each playlist item
    foreach ($item in $items) {
        # Skip "New Playlist" button or similar non-playlist items
        if ($item.PSObject.Properties['musicTwoRowItemRenderer']) {
            $playlist = ConvertTo-YtmPlaylist -InputObject $item
            if ($playlist.PlaylistId -and $playlist.Name) {
                $playlist
            }
        }
    }
}

function Get-PlaylistContents {
    <#
    .SYNOPSIS
        Internal helper to retrieve playlist contents.
    #>
    param (
        [Parameter(Mandatory = $true)]
        [string]$PlaylistId,

        [Parameter(Mandatory = $false)]
        [int]$Limit = 0
    )

    Write-Verbose "Fetching playlist contents for $PlaylistId..."

    # Playlist browse IDs need 'VL' prefix
    $browseId = if ($PlaylistId.StartsWith('VL')) { $PlaylistId } else { "VL$PlaylistId" }
    # Store the actual playlist ID (without VL prefix) for song objects
    $actualPlaylistId = if ($PlaylistId.StartsWith('VL')) { $PlaylistId.Substring(2) } else { $PlaylistId }

    $body = @{
        browseId = $browseId
    }

    try {
        $response = Invoke-YtmApi -Endpoint 'browse' -Body $body
    }
    catch {
        throw "Failed to retrieve playlist contents: $($_.Exception.Message)"
    }

    # Find the music shelf in the response
    $musicShelf = $null

    if ($response.PSObject.Properties['contents']) {
        $tabs = $response.contents.singleColumnBrowseResultsRenderer.tabs
        if ($tabs) {
            foreach ($tab in $tabs) {
                $tabRenderer = $tab.tabRenderer
                if ($tabRenderer.PSObject.Properties['content']) {
                    $sectionList = $tabRenderer.content.sectionListRenderer
                    if ($sectionList.PSObject.Properties['contents']) {
                        foreach ($section in $sectionList.contents) {
                            if ($section.PSObject.Properties['musicPlaylistShelfRenderer']) {
                                $musicShelf = $section.musicPlaylistShelfRenderer
                                break
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

    if (-not $musicShelf -or -not $musicShelf.PSObject.Properties['contents']) {
        Write-Warning "Playlist is empty or unable to parse response."
        return
    }

    $totalCount = 0
    $shouldContinue = $true

    # Process initial batch
    $contents = $musicShelf.contents
    foreach ($item in $contents) {
        if ($Limit -gt 0 -and $totalCount -ge $Limit) {
            $shouldContinue = $false
            break
        }

        $song = ConvertTo-YtmSong -InputObject $item -PlaylistId $actualPlaylistId
        if ($song.VideoId -and $song.Title) {
            $song
            $totalCount++
        }
    }

    # Get continuation token for pagination
    $continuationToken = $null
    if ($musicShelf.PSObject.Properties['continuations']) {
        $continuations = $musicShelf.continuations
        if ($continuations -and $continuations.Count -gt 0) {
            $continuationItem = $continuations[0]
            if ($continuationItem.PSObject.Properties['nextContinuationData']) {
                $continuationToken = $continuationItem.nextContinuationData.continuation
            }
        }
    }

    # Continue fetching while we have a token and haven't hit the limit
    $pageNumber = 1
    while ($shouldContinue -and $continuationToken) {
        $pageNumber++
        Write-Verbose "Fetching more songs (retrieved $totalCount so far)..."

        $progressParams = @{
            Activity = 'Retrieving playlist songs'
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
            Write-Progress -Activity 'Retrieving playlist songs' -Completed
            Write-Warning "Failed to fetch continuation: $($_.Exception.Message)"
            break
        }

        # Continuation responses have a different structure
        $contents = $null
        $newContinuationToken = $null

        if ($response.PSObject.Properties['continuationContents']) {
            $shelfContinuation = $response.continuationContents.musicPlaylistShelfContinuation
            if (-not $shelfContinuation) {
                $shelfContinuation = $response.continuationContents.musicShelfContinuation
            }
            if ($shelfContinuation) {
                $contents = $shelfContinuation.contents
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

            $song = ConvertTo-YtmSong -InputObject $item -PlaylistId $actualPlaylistId
            if ($song.VideoId -and $song.Title) {
                $song
                $totalCount++
            }
        }

        $continuationToken = $newContinuationToken
    }

    # Clear progress bar
    if ($pageNumber -gt 1) {
        Write-Progress -Activity 'Retrieving playlist songs' -Completed
    }

    Write-Verbose "Retrieved $totalCount songs from playlist"
}
