BeforeAll {
    . "$PSScriptRoot\..\Shared.ps1"
}

Describe 'ConvertTo-YtmPlaylist' {
    Context 'Basic Playlist Parsing' {
        BeforeAll {
            $script:mockPlaylistData = [PSCustomObject]@{
                musicTwoRowItemRenderer = [PSCustomObject]@{
                    title = [PSCustomObject]@{
                        runs = @(
                            [PSCustomObject]@{ text = 'Test Playlist' }
                        )
                    }
                    subtitle = [PSCustomObject]@{
                        runs = @(
                            [PSCustomObject]@{ text = '25 songs' }
                        )
                    }
                    navigationEndpoint = [PSCustomObject]@{
                        browseEndpoint = [PSCustomObject]@{
                            browseId = 'VLPLrAXtmErZgOeiKm4sgNOknGvNjby9efdf'
                        }
                    }
                    thumbnailRenderer = [PSCustomObject]@{
                        musicThumbnailRenderer = [PSCustomObject]@{
                            thumbnail = [PSCustomObject]@{
                                thumbnails = @(
                                    [PSCustomObject]@{ url = 'https://i.ytimg.com/small.jpg'; width = 60 }
                                    [PSCustomObject]@{ url = 'https://i.ytimg.com/large.jpg'; width = 226 }
                                )
                            }
                        }
                    }
                }
            }
        }

        It 'Returns an object with PSTypeName YouTubeMusicPS.Playlist' {
            $result = ConvertTo-YtmPlaylist -InputObject $mockPlaylistData
            $result.PSTypeNames | Should -Contain 'YouTubeMusicPS.Playlist'
        }

        It 'Extracts the Name correctly' {
            $result = ConvertTo-YtmPlaylist -InputObject $mockPlaylistData
            $result.Name | Should -Be 'Test Playlist'
        }

        It 'Extracts the PlaylistId correctly and removes VL prefix' {
            $result = ConvertTo-YtmPlaylist -InputObject $mockPlaylistData
            $result.PlaylistId | Should -Be 'PLrAXtmErZgOeiKm4sgNOknGvNjby9efdf'
        }

        It 'Extracts the TrackCount correctly' {
            $result = ConvertTo-YtmPlaylist -InputObject $mockPlaylistData
            $result.TrackCount | Should -Be 25
        }

        It 'Gets the largest thumbnail URL' {
            $result = ConvertTo-YtmPlaylist -InputObject $mockPlaylistData
            $result.ThumbnailUrl | Should -Be 'https://i.ytimg.com/large.jpg'
        }
    }

    Context 'Track Count Parsing' {
        It 'Parses singular "1 song" format' {
            $data = [PSCustomObject]@{
                musicTwoRowItemRenderer = [PSCustomObject]@{
                    subtitle = [PSCustomObject]@{
                        runs = @([PSCustomObject]@{ text = '1 song' })
                    }
                }
            }
            $result = ConvertTo-YtmPlaylist -InputObject $data
            $result.TrackCount | Should -Be 1
        }

        It 'Parses plural "songs" format' {
            $data = [PSCustomObject]@{
                musicTwoRowItemRenderer = [PSCustomObject]@{
                    subtitle = [PSCustomObject]@{
                        runs = @([PSCustomObject]@{ text = '100 songs' })
                    }
                }
            }
            $result = ConvertTo-YtmPlaylist -InputObject $data
            $result.TrackCount | Should -Be 100
        }
    }

    Context 'Missing Data Handling' {
        It 'Returns null for missing Name' {
            $data = [PSCustomObject]@{
                musicTwoRowItemRenderer = [PSCustomObject]@{}
            }
            $result = ConvertTo-YtmPlaylist -InputObject $data
            $result.Name | Should -BeNullOrEmpty
        }

        It 'Returns null for missing PlaylistId' {
            $data = [PSCustomObject]@{
                musicTwoRowItemRenderer = [PSCustomObject]@{}
            }
            $result = ConvertTo-YtmPlaylist -InputObject $data
            $result.PlaylistId | Should -BeNullOrEmpty
        }

        It 'Returns null for missing TrackCount' {
            $data = [PSCustomObject]@{
                musicTwoRowItemRenderer = [PSCustomObject]@{}
            }
            $result = ConvertTo-YtmPlaylist -InputObject $data
            $result.TrackCount | Should -BeNullOrEmpty
        }

        It 'Handles data without musicTwoRowItemRenderer wrapper' {
            $data = [PSCustomObject]@{
                title = [PSCustomObject]@{
                    runs = @([PSCustomObject]@{ text = 'Direct Title' })
                }
            }
            $result = ConvertTo-YtmPlaylist -InputObject $data
            $result.Name | Should -Be 'Direct Title'
        }
    }

    Context 'Pipeline Support' {
        It 'Accepts input from pipeline' {
            $data = [PSCustomObject]@{
                musicTwoRowItemRenderer = [PSCustomObject]@{
                    title = [PSCustomObject]@{
                        runs = @([PSCustomObject]@{ text = 'Pipeline Test' })
                    }
                }
            }
            $result = $data | ConvertTo-YtmPlaylist
            $result.Name | Should -Be 'Pipeline Test'
        }

        It 'Processes multiple items from pipeline' {
            $items = @(
                [PSCustomObject]@{
                    musicTwoRowItemRenderer = [PSCustomObject]@{
                        title = [PSCustomObject]@{
                            runs = @([PSCustomObject]@{ text = 'Playlist 1' })
                        }
                    }
                },
                [PSCustomObject]@{
                    musicTwoRowItemRenderer = [PSCustomObject]@{
                        title = [PSCustomObject]@{
                            runs = @([PSCustomObject]@{ text = 'Playlist 2' })
                        }
                    }
                }
            )
            $results = $items | ConvertTo-YtmPlaylist
            $results.Count | Should -Be 2
            $results[0].Name | Should -Be 'Playlist 1'
            $results[1].Name | Should -Be 'Playlist 2'
        }
    }

    Context 'PlaylistId VL Prefix Handling' {
        It 'Removes VL prefix from PlaylistId' {
            $data = [PSCustomObject]@{
                musicTwoRowItemRenderer = [PSCustomObject]@{
                    navigationEndpoint = [PSCustomObject]@{
                        browseEndpoint = [PSCustomObject]@{
                            browseId = 'VLPLxxxxxxxx'
                        }
                    }
                }
            }
            $result = ConvertTo-YtmPlaylist -InputObject $data
            $result.PlaylistId | Should -Be 'PLxxxxxxxx'
        }

        It 'Keeps PlaylistId without VL prefix unchanged' {
            $data = [PSCustomObject]@{
                musicTwoRowItemRenderer = [PSCustomObject]@{
                    navigationEndpoint = [PSCustomObject]@{
                        browseEndpoint = [PSCustomObject]@{
                            browseId = 'PLxxxxxxxx'
                        }
                    }
                }
            }
            $result = ConvertTo-YtmPlaylist -InputObject $data
            $result.PlaylistId | Should -Be 'PLxxxxxxxx'
        }
    }
}
