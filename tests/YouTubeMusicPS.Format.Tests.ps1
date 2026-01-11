BeforeAll {
    $script:ModuleRoot = Split-Path -Parent $PSScriptRoot
    $script:ModulePath = Join-Path $script:ModuleRoot 'YouTubeMusicPS'
    $script:FormatFilePath = Join-Path $script:ModulePath 'YouTubeMusicPS.Format.ps1xml'
}

Describe 'YouTubeMusicPS.Format.ps1xml' {
    Context 'Format File Validity' {
        It 'Format file exists' {
            Test-Path $script:FormatFilePath | Should -BeTrue
        }

        It 'Format file is valid XML' {
            { [xml](Get-Content $script:FormatFilePath -Raw) } | Should -Not -Throw
        }

        It 'Format file has ViewDefinitions' {
            $xml = [xml](Get-Content $script:FormatFilePath -Raw)
            $xml.Configuration.ViewDefinitions | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Song Format View' {
        BeforeAll {
            $xml = [xml](Get-Content $script:FormatFilePath -Raw)
            $script:songView = $xml.Configuration.ViewDefinitions.View |
                Where-Object { $_.ViewSelectedBy.TypeName -eq 'YouTubeMusicPS.Song' }
        }

        It 'Has a view for YouTubeMusicPS.Song type' {
            $songView | Should -Not -BeNullOrEmpty
        }

        It 'Uses TableControl for display' {
            $songView.TableControl | Should -Not -BeNullOrEmpty
        }

        It 'Shows Title column' {
            $columns = $songView.TableControl.TableRowEntries.TableRowEntry.TableColumnItems.TableColumnItem.PropertyName
            $columns | Should -Contain 'Title'
        }

        It 'Shows Artist column' {
            $columns = $songView.TableControl.TableRowEntries.TableRowEntry.TableColumnItems.TableColumnItem.PropertyName
            $columns | Should -Contain 'Artist'
        }

        It 'Shows Album column' {
            $columns = $songView.TableControl.TableRowEntries.TableRowEntry.TableColumnItems.TableColumnItem.PropertyName
            $columns | Should -Contain 'Album'
        }

        It 'Shows Duration column' {
            $columns = $songView.TableControl.TableRowEntries.TableRowEntry.TableColumnItems.TableColumnItem.PropertyName
            $columns | Should -Contain 'Duration'
        }

        It 'Does not show VideoId column by default' {
            $columns = $songView.TableControl.TableRowEntries.TableRowEntry.TableColumnItems.TableColumnItem.PropertyName
            $columns | Should -Not -Contain 'VideoId'
        }

        It 'Does not show ThumbnailUrl column by default' {
            $columns = $songView.TableControl.TableRowEntries.TableRowEntry.TableColumnItems.TableColumnItem.PropertyName
            $columns | Should -Not -Contain 'ThumbnailUrl'
        }
    }

    Context 'Playlist Format View' {
        BeforeAll {
            $xml = [xml](Get-Content $script:FormatFilePath -Raw)
            $script:playlistView = $xml.Configuration.ViewDefinitions.View |
                Where-Object { $_.ViewSelectedBy.TypeName -eq 'YouTubeMusicPS.Playlist' }
        }

        It 'Has a view for YouTubeMusicPS.Playlist type' {
            $playlistView | Should -Not -BeNullOrEmpty
        }

        It 'Uses TableControl for display' {
            $playlistView.TableControl | Should -Not -BeNullOrEmpty
        }

        It 'Shows Name column' {
            $columns = $playlistView.TableControl.TableRowEntries.TableRowEntry.TableColumnItems.TableColumnItem.PropertyName
            $columns | Should -Contain 'Name'
        }

        It 'Shows TrackCount column' {
            $columns = $playlistView.TableControl.TableRowEntries.TableRowEntry.TableColumnItems.TableColumnItem.PropertyName
            $columns | Should -Contain 'TrackCount'
        }

        It 'Does not show PlaylistId column by default' {
            $columns = $playlistView.TableControl.TableRowEntries.TableRowEntry.TableColumnItems.TableColumnItem.PropertyName
            $columns | Should -Not -Contain 'PlaylistId'
        }

        It 'Does not show ThumbnailUrl column by default' {
            $columns = $playlistView.TableControl.TableRowEntries.TableRowEntry.TableColumnItems.TableColumnItem.PropertyName
            $columns | Should -Not -Contain 'ThumbnailUrl'
        }
    }

    Context 'AuthenticationStatus Format View' {
        BeforeAll {
            $xml = [xml](Get-Content $script:FormatFilePath -Raw)
            $script:authView = $xml.Configuration.ViewDefinitions.View |
                Where-Object { $_.ViewSelectedBy.TypeName -eq 'YouTubeMusicPS.AuthenticationStatus' }
        }

        It 'Has a view for YouTubeMusicPS.AuthenticationStatus type' {
            $authView | Should -Not -BeNullOrEmpty
        }

        It 'Uses ListControl for display' {
            $authView.ListControl | Should -Not -BeNullOrEmpty
        }

        It 'Shows IsAuthenticated property' {
            $properties = $authView.ListControl.ListEntries.ListEntry.ListItems.ListItem.PropertyName
            $properties | Should -Contain 'IsAuthenticated'
        }

        It 'Shows HasStoredCredentials property' {
            $properties = $authView.ListControl.ListEntries.ListEntry.ListItems.ListItem.PropertyName
            $properties | Should -Contain 'HasStoredCredentials'
        }

        It 'Shows Message property' {
            $properties = $authView.ListControl.ListEntries.ListEntry.ListItems.ListItem.PropertyName
            $properties | Should -Contain 'Message'
        }
    }

    Context 'Hidden Properties Still Accessible' {
        It 'Song objects retain all properties when using Select-Object *' {
            $song = [PSCustomObject]@{
                PSTypeName      = 'YouTubeMusicPS.Song'
                VideoId         = 'test-video-id'
                SetVideoId      = 'test-set-video-id'
                PlaylistId      = 'test-playlist-id'
                Title           = 'Test Song'
                Artist          = 'Test Artist'
                ArtistId        = 'test-artist-id'
                Album           = 'Test Album'
                AlbumId         = 'test-album-id'
                Duration        = '3:45'
                DurationSeconds = 225
                ThumbnailUrl    = 'https://example.com/thumb.jpg'
                LikeStatus      = 'LIKE'
            }

            $allProps = $song | Select-Object *
            $allProps.VideoId | Should -Be 'test-video-id'
            $allProps.ArtistId | Should -Be 'test-artist-id'
            $allProps.AlbumId | Should -Be 'test-album-id'
            $allProps.ThumbnailUrl | Should -Be 'https://example.com/thumb.jpg'
        }

        It 'Playlist objects retain all properties when using Select-Object *' {
            $playlist = [PSCustomObject]@{
                PSTypeName   = 'YouTubeMusicPS.Playlist'
                Name         = 'Test Playlist'
                PlaylistId   = 'test-playlist-id'
                TrackCount   = 42
                ThumbnailUrl = 'https://example.com/thumb.jpg'
            }

            $allProps = $playlist | Select-Object *
            $allProps.PlaylistId | Should -Be 'test-playlist-id'
            $allProps.ThumbnailUrl | Should -Be 'https://example.com/thumb.jpg'
        }
    }
}
