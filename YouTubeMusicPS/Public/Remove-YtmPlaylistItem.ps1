function Remove-YtmPlaylistItem {
    <#
    .SYNOPSIS
        Removes a song from a YouTube Music playlist.

    .DESCRIPTION
        Removes one or more songs from a playlist. Supports both pipeline input
        (from Get-YtmPlaylist) and direct parameter specification.
        Requires authentication via Connect-YtmAccount first.

    .PARAMETER Song
        A song object from Get-YtmPlaylist containing PlaylistId, SetVideoId, and VideoId.
        Accepts pipeline input.

    .PARAMETER Name
        The name of the playlist to remove from.
        Supports tab completion from your library playlists.

    .PARAMETER Title
        The title of the song to remove.

    .PARAMETER Artist
        Optional artist name to disambiguate when multiple songs have the same title.

    .EXAMPLE
        Get-YtmPlaylist -Name "Chill Vibes" | Where-Object Title -eq "Bad Song" | Remove-YtmPlaylistItem

        Removes "Bad Song" from the "Chill Vibes" playlist using pipeline.

    .EXAMPLE
        Get-YtmPlaylist -Name "Chill Vibes" | Where-Object Artist -match "Nickelback" | Remove-YtmPlaylistItem

        Removes all Nickelback songs from the playlist.

    .EXAMPLE
        Remove-YtmPlaylistItem -Name "Chill Vibes" -Title "Bad Song"

        Removes "Bad Song" from the playlist using direct parameters.

    .EXAMPLE
        Remove-YtmPlaylistItem -Name "Chill Vibes" -Title "Hello" -Artist "Adele"

        Removes "Hello" by Adele, disambiguating from other songs titled "Hello".

    .EXAMPLE
        Get-YtmPlaylist -Name "Chill Vibes" | Where-Object Title -eq "Bad Song" | Remove-YtmPlaylistItem -WhatIf

        Shows what would be removed without actually removing it.
    #>
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'Direct')]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'Pipeline', ValueFromPipeline = $true)]
        [PSTypeName('YouTubeMusicPS.Song')]
        [PSCustomObject]$Song,

        [Parameter(Mandatory = $true, ParameterSetName = 'Direct')]
        [ArgumentCompleter({
            param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
            try {
                $playlists = Get-YtmPlaylist -ErrorAction SilentlyContinue
                if ($playlists) {
                    $playlists | Where-Object { $_.Name -like "*$wordToComplete*" } | ForEach-Object {
                        $name = $_.Name
                        if ($name -match '\s') {
                            "'$name'"
                        }
                        else {
                            $name
                        }
                    }
                }
            }
            catch { }
        })]
        [string]$Name,

        [Parameter(Mandatory = $true, ParameterSetName = 'Direct')]
        [string]$Title,

        [Parameter(Mandatory = $false, ParameterSetName = 'Direct')]
        [string]$Artist
    )

    begin {
        # Check authentication
        $cookies = Get-YtmStoredCookies
        if (-not $cookies) {
            throw 'Not authenticated. Please run Connect-YtmAccount first.'
        }

        # For pipeline mode, we'll batch removals per playlist
        $removalsByPlaylist = @{}
    }

    process {
        if ($PSCmdlet.ParameterSetName -eq 'Pipeline') {
            # Validate song has required properties
            if (-not $Song.PlaylistId) {
                Write-Error "Song '$($Song.Title)' does not have a PlaylistId. Make sure it came from Get-YtmPlaylist."
                return
            }
            if (-not $Song.SetVideoId) {
                Write-Error "Song '$($Song.Title)' does not have a SetVideoId. This song cannot be removed."
                return
            }
            if (-not $Song.VideoId) {
                Write-Error "Song '$($Song.Title)' does not have a VideoId."
                return
            }

            # Group by playlist for batch processing
            if (-not $removalsByPlaylist.ContainsKey($Song.PlaylistId)) {
                $removalsByPlaylist[$Song.PlaylistId] = @()
            }
            $removalsByPlaylist[$Song.PlaylistId] += $Song
        }
        else {
            # Direct parameter mode - find the song in the playlist
            $playlists = Get-YtmPlaylist -ErrorAction Stop
            $matchingPlaylist = $playlists | Where-Object { $_.Name -eq $Name }

            if (-not $matchingPlaylist) {
                $matchingPlaylist = $playlists | Where-Object { $_.Name -ieq $Name }
            }

            if (-not $matchingPlaylist) {
                throw "Playlist '$Name' not found in your library."
            }

            if ($matchingPlaylist.Count -gt 1) {
                throw "Multiple playlists found matching '$Name'. Please use a more specific name."
            }

            # Get playlist contents
            $playlistSongs = Get-YtmPlaylist -Name $matchingPlaylist.Name -ErrorAction Stop

            # Find matching song(s)
            $matchingSongs = $playlistSongs | Where-Object { $_.Title -eq $Title }

            if (-not $matchingSongs) {
                $matchingSongs = $playlistSongs | Where-Object { $_.Title -ieq $Title }
            }

            if (-not $matchingSongs) {
                throw "Song '$Title' not found in playlist '$Name'."
            }

            # Filter by artist if specified
            if ($Artist) {
                $matchingSongs = $matchingSongs | Where-Object { $_.Artist -match [regex]::Escape($Artist) }
                if (-not $matchingSongs) {
                    throw "Song '$Title' by '$Artist' not found in playlist '$Name'."
                }
            }

            # Handle multiple matches
            if (($matchingSongs | Measure-Object).Count -gt 1 -and -not $Artist) {
                $songList = ($matchingSongs | ForEach-Object { "  - $($_.Title) by $($_.Artist)" }) -join "`n"
                throw "Multiple songs found matching '$Title'. Please specify -Artist to disambiguate:`n$songList"
            }

            # Add to removal batch
            foreach ($matchingSong in $matchingSongs) {
                if (-not $removalsByPlaylist.ContainsKey($matchingSong.PlaylistId)) {
                    $removalsByPlaylist[$matchingSong.PlaylistId] = @()
                }
                $removalsByPlaylist[$matchingSong.PlaylistId] += $matchingSong
            }
        }
    }

    end {
        # Process all removals
        foreach ($playlistId in $removalsByPlaylist.Keys) {
            $songsToRemove = $removalsByPlaylist[$playlistId]

            foreach ($songItem in $songsToRemove) {
                $actionDescription = "Remove '$($songItem.Title)' by $($songItem.Artist) from playlist"

                if ($PSCmdlet.ShouldProcess($actionDescription, 'Remove song from playlist')) {
                    Write-Verbose "Removing '$($songItem.Title)' from playlist $playlistId..."

                    $body = @{
                        playlistId = $playlistId
                        actions    = @(
                            @{
                                action         = 'ACTION_REMOVE_VIDEO'
                                setVideoId     = $songItem.SetVideoId
                                removedVideoId = $songItem.VideoId
                            }
                        )
                    }

                    try {
                        $response = Invoke-YtmApi -Endpoint 'browse/edit_playlist' -Body $body
                        Write-Verbose "Successfully removed '$($songItem.Title)'"

                        # Check response for success
                        if ($response.PSObject.Properties['status'] -and $response.status -eq 'STATUS_SUCCEEDED') {
                            Write-Verbose "API confirmed removal succeeded"
                        }
                    }
                    catch {
                        Write-Error "Failed to remove '$($songItem.Title)': $($_.Exception.Message)"
                    }
                }
            }
        }
    }
}
