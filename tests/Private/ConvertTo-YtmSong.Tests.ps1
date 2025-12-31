BeforeAll {
    . "$PSScriptRoot\..\Shared.ps1"
}

Describe 'ConvertTo-YtmSong' {
    Context 'Basic Song Parsing' {
        BeforeAll {
            # Create a mock API response that mimics YouTube Music's structure
            $script:mockSongData = [PSCustomObject]@{
                musicResponsiveListItemRenderer = [PSCustomObject]@{
                    flexColumns = @(
                        # Title column (index 0)
                        [PSCustomObject]@{
                            musicResponsiveListItemFlexColumnRenderer = [PSCustomObject]@{
                                text = [PSCustomObject]@{
                                    runs = @(
                                        [PSCustomObject]@{ text = 'Test Song Title' }
                                    )
                                }
                            }
                        },
                        # Artist column (index 1)
                        [PSCustomObject]@{
                            musicResponsiveListItemFlexColumnRenderer = [PSCustomObject]@{
                                text = [PSCustomObject]@{
                                    runs = @(
                                        [PSCustomObject]@{
                                            text = 'Test Artist'
                                            navigationEndpoint = [PSCustomObject]@{
                                                browseEndpoint = [PSCustomObject]@{
                                                    browseId = 'UCxxxxxxxxxxxx'
                                                }
                                            }
                                        }
                                    )
                                }
                            }
                        },
                        # Album column (index 2)
                        [PSCustomObject]@{
                            musicResponsiveListItemFlexColumnRenderer = [PSCustomObject]@{
                                text = [PSCustomObject]@{
                                    runs = @(
                                        [PSCustomObject]@{
                                            text = 'Test Album'
                                            navigationEndpoint = [PSCustomObject]@{
                                                browseEndpoint = [PSCustomObject]@{
                                                    browseId = 'MPRExxxxxxxx'
                                                    browseEndpointContextSupportedConfigs = [PSCustomObject]@{
                                                        browseEndpointContextMusicConfig = [PSCustomObject]@{
                                                            pageType = 'MUSIC_PAGE_TYPE_ALBUM'
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    )
                                }
                            }
                        }
                    )
                    fixedColumns = @(
                        [PSCustomObject]@{
                            musicResponsiveListItemFixedColumnRenderer = [PSCustomObject]@{
                                text = [PSCustomObject]@{
                                    simpleText = '3:45'
                                }
                            }
                        }
                    )
                    overlay = [PSCustomObject]@{
                        musicItemThumbnailOverlayRenderer = [PSCustomObject]@{
                            content = [PSCustomObject]@{
                                musicPlayButtonRenderer = [PSCustomObject]@{
                                    playNavigationEndpoint = [PSCustomObject]@{
                                        watchEndpoint = [PSCustomObject]@{
                                            videoId = 'dQw4w9WgXcQ'
                                        }
                                    }
                                }
                            }
                        }
                    }
                    thumbnail = [PSCustomObject]@{
                        musicThumbnailRenderer = [PSCustomObject]@{
                            thumbnail = [PSCustomObject]@{
                                thumbnails = @(
                                    [PSCustomObject]@{ url = 'https://i.ytimg.com/small.jpg'; width = 60 }
                                    [PSCustomObject]@{ url = 'https://i.ytimg.com/large.jpg'; width = 226 }
                                )
                            }
                        }
                    }
                    menu = [PSCustomObject]@{
                        menuRenderer = [PSCustomObject]@{
                            items = @(
                                [PSCustomObject]@{
                                    menuServiceItemRenderer = [PSCustomObject]@{
                                        serviceEndpoint = [PSCustomObject]@{
                                            likeEndpoint = [PSCustomObject]@{
                                                status = 'LIKE'
                                            }
                                        }
                                    }
                                }
                            )
                        }
                    }
                }
            }
        }

        It 'Returns an object with PSTypeName YouTubeMusicPS.Song' {
            $result = ConvertTo-YtmSong -InputObject $mockSongData
            $result.PSTypeNames | Should -Contain 'YouTubeMusicPS.Song'
        }

        It 'Extracts the VideoId correctly' {
            $result = ConvertTo-YtmSong -InputObject $mockSongData
            $result.VideoId | Should -Be 'dQw4w9WgXcQ'
        }

        It 'Extracts the Title correctly' {
            $result = ConvertTo-YtmSong -InputObject $mockSongData
            $result.Title | Should -Be 'Test Song Title'
        }

        It 'Extracts the Artist correctly' {
            $result = ConvertTo-YtmSong -InputObject $mockSongData
            $result.Artist | Should -Be 'Test Artist'
        }

        It 'Extracts the ArtistId correctly' {
            $result = ConvertTo-YtmSong -InputObject $mockSongData
            $result.ArtistId | Should -Be 'UCxxxxxxxxxxxx'
        }

        It 'Extracts the Album correctly' {
            $result = ConvertTo-YtmSong -InputObject $mockSongData
            $result.Album | Should -Be 'Test Album'
        }

        It 'Extracts the AlbumId correctly' {
            $result = ConvertTo-YtmSong -InputObject $mockSongData
            $result.AlbumId | Should -Be 'MPRExxxxxxxx'
        }

        It 'Extracts the Duration correctly' {
            $result = ConvertTo-YtmSong -InputObject $mockSongData
            $result.Duration | Should -Be '3:45'
        }

        It 'Calculates DurationSeconds correctly for mm:ss format' {
            $result = ConvertTo-YtmSong -InputObject $mockSongData
            $result.DurationSeconds | Should -Be 225  # 3*60 + 45
        }

        It 'Gets the largest thumbnail URL' {
            $result = ConvertTo-YtmSong -InputObject $mockSongData
            $result.ThumbnailUrl | Should -Be 'https://i.ytimg.com/large.jpg'
        }

        It 'Extracts the LikeStatus correctly' {
            $result = ConvertTo-YtmSong -InputObject $mockSongData
            $result.LikeStatus | Should -Be 'LIKE'
        }
    }

    Context 'Duration Parsing' {
        It 'Parses mm:ss duration format' {
            $data = [PSCustomObject]@{
                fixedColumns = @(
                    [PSCustomObject]@{
                        musicResponsiveListItemFixedColumnRenderer = [PSCustomObject]@{
                            text = [PSCustomObject]@{ simpleText = '4:30' }
                        }
                    }
                )
            }
            $result = ConvertTo-YtmSong -InputObject $data
            $result.DurationSeconds | Should -Be 270  # 4*60 + 30
        }

        It 'Parses hh:mm:ss duration format' {
            $data = [PSCustomObject]@{
                fixedColumns = @(
                    [PSCustomObject]@{
                        musicResponsiveListItemFixedColumnRenderer = [PSCustomObject]@{
                            text = [PSCustomObject]@{ simpleText = '1:02:30' }
                        }
                    }
                )
            }
            $result = ConvertTo-YtmSong -InputObject $data
            $result.DurationSeconds | Should -Be 3750  # 1*3600 + 2*60 + 30
        }

        It 'Handles duration in runs format' {
            $data = [PSCustomObject]@{
                fixedColumns = @(
                    [PSCustomObject]@{
                        musicResponsiveListItemFixedColumnRenderer = [PSCustomObject]@{
                            text = [PSCustomObject]@{
                                runs = @(
                                    [PSCustomObject]@{ text = '5:15' }
                                )
                            }
                        }
                    }
                )
            }
            $result = ConvertTo-YtmSong -InputObject $data
            $result.Duration | Should -Be '5:15'
            $result.DurationSeconds | Should -Be 315  # 5*60 + 15
        }
    }

    Context 'Missing Data Handling' {
        It 'Returns null for missing VideoId' {
            $data = [PSCustomObject]@{}
            $result = ConvertTo-YtmSong -InputObject $data
            $result.VideoId | Should -BeNullOrEmpty
        }

        It 'Returns null for missing Title' {
            $data = [PSCustomObject]@{}
            $result = ConvertTo-YtmSong -InputObject $data
            $result.Title | Should -BeNullOrEmpty
        }

        It 'Returns null for missing Duration' {
            $data = [PSCustomObject]@{}
            $result = ConvertTo-YtmSong -InputObject $data
            $result.Duration | Should -BeNullOrEmpty
            $result.DurationSeconds | Should -BeNullOrEmpty
        }

        It 'Handles data without musicResponsiveListItemRenderer wrapper' {
            $data = [PSCustomObject]@{
                flexColumns = @(
                    [PSCustomObject]@{
                        musicResponsiveListItemFlexColumnRenderer = [PSCustomObject]@{
                            text = [PSCustomObject]@{
                                runs = @([PSCustomObject]@{ text = 'Direct Title' })
                            }
                        }
                    }
                )
            }
            $result = ConvertTo-YtmSong -InputObject $data
            $result.Title | Should -Be 'Direct Title'
        }
    }

    Context 'Pipeline Support' {
        It 'Accepts input from pipeline' {
            $data = [PSCustomObject]@{
                flexColumns = @(
                    [PSCustomObject]@{
                        musicResponsiveListItemFlexColumnRenderer = [PSCustomObject]@{
                            text = [PSCustomObject]@{
                                runs = @([PSCustomObject]@{ text = 'Pipeline Test' })
                            }
                        }
                    }
                )
            }
            $result = $data | ConvertTo-YtmSong
            $result.Title | Should -Be 'Pipeline Test'
        }

        It 'Processes multiple items from pipeline' {
            $items = @(
                [PSCustomObject]@{
                    flexColumns = @(
                        [PSCustomObject]@{
                            musicResponsiveListItemFlexColumnRenderer = [PSCustomObject]@{
                                text = [PSCustomObject]@{
                                    runs = @([PSCustomObject]@{ text = 'Song 1' })
                                }
                            }
                        }
                    )
                },
                [PSCustomObject]@{
                    flexColumns = @(
                        [PSCustomObject]@{
                            musicResponsiveListItemFlexColumnRenderer = [PSCustomObject]@{
                                text = [PSCustomObject]@{
                                    runs = @([PSCustomObject]@{ text = 'Song 2' })
                                }
                            }
                        }
                    )
                }
            )
            $results = $items | ConvertTo-YtmSong
            $results.Count | Should -Be 2
            $results[0].Title | Should -Be 'Song 1'
            $results[1].Title | Should -Be 'Song 2'
        }
    }

    Context 'Multiple Artists' {
        It 'Concatenates multiple artist names' {
            $data = [PSCustomObject]@{
                flexColumns = @(
                    [PSCustomObject]@{
                        musicResponsiveListItemFlexColumnRenderer = [PSCustomObject]@{
                            text = [PSCustomObject]@{
                                runs = @([PSCustomObject]@{ text = 'Title' })
                            }
                        }
                    },
                    [PSCustomObject]@{
                        musicResponsiveListItemFlexColumnRenderer = [PSCustomObject]@{
                            text = [PSCustomObject]@{
                                runs = @(
                                    [PSCustomObject]@{ text = 'Artist 1' }
                                    [PSCustomObject]@{ text = ' & ' }
                                    [PSCustomObject]@{ text = 'Artist 2' }
                                )
                            }
                        }
                    }
                )
            }
            $result = ConvertTo-YtmSong -InputObject $data
            $result.Artist | Should -Be 'Artist 1 & Artist 2'
        }
    }
}
