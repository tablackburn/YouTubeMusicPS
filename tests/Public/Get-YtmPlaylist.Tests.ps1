BeforeAll {
    . "$PSScriptRoot\..\Shared.ps1"
}

Describe 'Get-YtmPlaylist' {
    BeforeAll {
        $script:testDir = Join-Path $TestDrive 'YouTubeMusicPS'
        $script:testConfigPath = Join-Path $testDir 'config.json'
    }

    BeforeEach {
        New-Item -Path $testDir -ItemType Directory -Force | Out-Null
        Mock Get-YtmConfigurationPath { $script:testConfigPath }
    }

    AfterEach {
        if (Test-Path $testDir) {
            Remove-Item $testDir -Recurse -Force
        }
    }

    Context 'Authentication Check' {
        It 'Throws when not authenticated with -Force' {
            if (Test-Path $testConfigPath) {
                Remove-Item $testConfigPath -Force
            }
            { Get-YtmPlaylist -Force } | Should -Throw '*Not authenticated*'
        }

        It 'Has Force parameter' {
            $command = Get-Command Get-YtmPlaylist
            $forceParam = $command.Parameters['Force']
            $forceParam | Should -Not -BeNullOrEmpty
            $forceParam.ParameterType | Should -Be ([switch])
        }
    }

    Context 'Parameter Sets' {
        It 'Has a List parameter set as default' {
            $command = Get-Command Get-YtmPlaylist
            $command.DefaultParameterSet | Should -Be 'List'
        }

        It 'Has Name parameter in ByName set' {
            $command = Get-Command Get-YtmPlaylist
            $nameParam = $command.Parameters['Name']
            $nameParam.ParameterSets.Keys | Should -Contain 'ByName'
        }

        It 'Has Id parameter in ById set' {
            $command = Get-Command Get-YtmPlaylist
            $idParam = $command.Parameters['Id']
            $idParam.ParameterSets.Keys | Should -Contain 'ById'
        }

        It 'Has Limit parameter available in all sets' {
            $command = Get-Command Get-YtmPlaylist
            $limitParam = $command.Parameters['Limit']
            $limitParam | Should -Not -BeNullOrEmpty
        }
    }

    Context 'List Playlists Mode' {
        BeforeEach {
            $testConfiguration = @{
                version = '1.0'
                auth    = @{
                    sapiSid = 'test-sapisid'
                    cookies = 'SAPISID=test-sapisid'
                }
            }
            $testConfiguration | ConvertTo-Json | Set-Content $testConfigPath
        }

        It 'Calls browse API with library playlists browseId' {
            Mock Invoke-YtmApi {
                [PSCustomObject]@{
                    contents = [PSCustomObject]@{
                        singleColumnBrowseResultsRenderer = [PSCustomObject]@{
                            tabs = @()
                        }
                    }
                }
            }

            Get-YtmPlaylist -WarningAction SilentlyContinue
            Should -Invoke Invoke-YtmApi -Times 1 -ParameterFilter {
                $Body.browseId -eq 'FEmusic_liked_playlists'
            }
        }

        It 'Returns YouTubeMusicPS.Playlist objects' {
            Mock Invoke-YtmApi {
                [PSCustomObject]@{
                    contents = [PSCustomObject]@{
                        singleColumnBrowseResultsRenderer = [PSCustomObject]@{
                            tabs = @(
                                [PSCustomObject]@{
                                    tabRenderer = [PSCustomObject]@{
                                        content = [PSCustomObject]@{
                                            sectionListRenderer = [PSCustomObject]@{
                                                contents = @(
                                                    [PSCustomObject]@{
                                                        gridRenderer = [PSCustomObject]@{
                                                            items = @(
                                                                [PSCustomObject]@{
                                                                    musicTwoRowItemRenderer = [PSCustomObject]@{
                                                                        title = [PSCustomObject]@{
                                                                            runs = @([PSCustomObject]@{ text = 'Test Playlist' })
                                                                        }
                                                                        navigationEndpoint = [PSCustomObject]@{
                                                                            browseEndpoint = [PSCustomObject]@{
                                                                                browseId = 'VLPLtest123'
                                                                            }
                                                                        }
                                                                    }
                                                                }
                                                            )
                                                        }
                                                    }
                                                )
                                            }
                                        }
                                    }
                                }
                            )
                        }
                    }
                }
            }

            $results = Get-YtmPlaylist
            $results | Should -Not -BeNullOrEmpty
            $results[0].PSTypeNames | Should -Contain 'YouTubeMusicPS.Playlist'
            $results[0].Name | Should -Be 'Test Playlist'
        }
    }

    Context 'Get Playlist Contents Mode' {
        BeforeEach {
            $testConfiguration = @{
                version = '1.0'
                auth    = @{
                    sapiSid = 'test-sapisid'
                    cookies = 'SAPISID=test-sapisid'
                }
            }
            $testConfiguration | ConvertTo-Json | Set-Content $testConfigPath

            # Mock for listing playlists (used by -Name lookup)
            Mock Invoke-YtmApi {
                [PSCustomObject]@{
                    contents = [PSCustomObject]@{
                        singleColumnBrowseResultsRenderer = [PSCustomObject]@{
                            tabs = @(
                                [PSCustomObject]@{
                                    tabRenderer = [PSCustomObject]@{
                                        content = [PSCustomObject]@{
                                            sectionListRenderer = [PSCustomObject]@{
                                                contents = @(
                                                    [PSCustomObject]@{
                                                        gridRenderer = [PSCustomObject]@{
                                                            items = @(
                                                                [PSCustomObject]@{
                                                                    musicTwoRowItemRenderer = [PSCustomObject]@{
                                                                        title = [PSCustomObject]@{
                                                                            runs = @([PSCustomObject]@{ text = 'Test Playlist' })
                                                                        }
                                                                        navigationEndpoint = [PSCustomObject]@{
                                                                            browseEndpoint = [PSCustomObject]@{
                                                                                browseId = 'VLPLtest123'
                                                                            }
                                                                        }
                                                                    }
                                                                }
                                                            )
                                                        }
                                                    }
                                                )
                                            }
                                        }
                                    }
                                }
                            )
                        }
                    }
                }
            } -ParameterFilter { $Body.browseId -eq 'FEmusic_liked_playlists' }
        }

        It 'Throws when playlist not found by name' {
            { Get-YtmPlaylist -Name 'Nonexistent Playlist' } | Should -Throw '*not found*'
        }

        It 'Prefixes playlist ID with VL for browse request' {
            Mock Invoke-YtmApi {
                [PSCustomObject]@{
                    contents = [PSCustomObject]@{
                        singleColumnBrowseResultsRenderer = [PSCustomObject]@{
                            tabs = @()
                        }
                    }
                }
            } -ParameterFilter { $Body.browseId -eq 'VLPLcustom123' }

            Get-YtmPlaylist -Id 'PLcustom123' -WarningAction SilentlyContinue
            Should -Invoke Invoke-YtmApi -Times 1 -ParameterFilter {
                $Body.browseId -eq 'VLPLcustom123'
            }
        }

        It 'Does not double-prefix VL if already present' {
            Mock Invoke-YtmApi {
                [PSCustomObject]@{
                    contents = [PSCustomObject]@{
                        singleColumnBrowseResultsRenderer = [PSCustomObject]@{
                            tabs = @()
                        }
                    }
                }
            } -ParameterFilter { $Body.browseId -eq 'VLPLcustom123' }

            Get-YtmPlaylist -Id 'VLPLcustom123' -WarningAction SilentlyContinue
            Should -Invoke Invoke-YtmApi -Times 1 -ParameterFilter {
                $Body.browseId -eq 'VLPLcustom123'
            }
        }
    }

    Context 'Limit Parameter' {
        It 'Has Limit parameter with default of 0' {
            $command = Get-Command Get-YtmPlaylist
            $limitParam = $command.Parameters['Limit']
            $limitParam | Should -Not -BeNullOrEmpty
        }

        It 'Validates Limit is non-negative' {
            { Get-YtmPlaylist -Limit -1 } | Should -Throw
        }
    }

    Context 'API Response Handling' {
        BeforeEach {
            $testConfiguration = @{
                version = '1.0'
                auth    = @{
                    sapiSid = 'test-sapisid'
                    cookies = 'SAPISID=test-sapisid'
                }
            }
            $testConfiguration | ConvertTo-Json | Set-Content $testConfigPath
        }

        It 'Warns when playlist contents API response format is unexpected' {
            Mock Invoke-YtmApi {
                # Return response without expected musicShelf structure
                [PSCustomObject]@{
                    contents = [PSCustomObject]@{
                        unexpectedProperty = 'value'
                    }
                }
            }

            $results = Get-YtmPlaylist -Id 'PLtest123' -WarningAction SilentlyContinue
            $results | Should -BeNullOrEmpty
        }
    }

    Context 'Playlist Contents Pagination' {
        BeforeEach {
            $testConfiguration = @{
                version = '1.0'
                auth    = @{
                    sapiSid = 'test-sapisid'
                    cookies = 'SAPISID=test-sapisid'
                }
            }
            $testConfiguration | ConvertTo-Json | Set-Content $testConfigPath

            # Helper to create a song item
            $script:CreateSongItem = {
                param($Title, $VideoId)
                [PSCustomObject]@{
                    musicResponsiveListItemRenderer = [PSCustomObject]@{
                        flexColumns = @(
                            [PSCustomObject]@{
                                musicResponsiveListItemFlexColumnRenderer = [PSCustomObject]@{
                                    text = [PSCustomObject]@{
                                        runs = @([PSCustomObject]@{ text = $Title })
                                    }
                                }
                            }
                        )
                        overlay = [PSCustomObject]@{
                            musicItemThumbnailOverlayRenderer = [PSCustomObject]@{
                                content = [PSCustomObject]@{
                                    musicPlayButtonRenderer = [PSCustomObject]@{
                                        playNavigationEndpoint = [PSCustomObject]@{
                                            watchEndpoint = [PSCustomObject]@{ videoId = $VideoId }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        It 'Fetches continuation pages for playlist contents' {
            Mock Invoke-YtmApi {
                if ($ContinuationToken) {
                    # Continuation response (page 2)
                    [PSCustomObject]@{
                        continuationContents = [PSCustomObject]@{
                            musicPlaylistShelfContinuation = [PSCustomObject]@{
                                contents = @(
                                    (& $script:CreateSongItem 'Song 3' 'vid3'),
                                    (& $script:CreateSongItem 'Song 4' 'vid4')
                                )
                            }
                        }
                    }
                } else {
                    # Initial response with continuation token
                    [PSCustomObject]@{
                        contents = [PSCustomObject]@{
                            singleColumnBrowseResultsRenderer = [PSCustomObject]@{
                                tabs = @(
                                    [PSCustomObject]@{
                                        tabRenderer = [PSCustomObject]@{
                                            content = [PSCustomObject]@{
                                                sectionListRenderer = [PSCustomObject]@{
                                                    contents = @(
                                                        [PSCustomObject]@{
                                                            musicPlaylistShelfRenderer = [PSCustomObject]@{
                                                                contents = @(
                                                                    (& $script:CreateSongItem 'Song 1' 'vid1'),
                                                                    (& $script:CreateSongItem 'Song 2' 'vid2')
                                                                )
                                                                continuations = @(
                                                                    [PSCustomObject]@{
                                                                        nextContinuationData = [PSCustomObject]@{
                                                                            continuation = 'token123'
                                                                        }
                                                                    }
                                                                )
                                                            }
                                                        }
                                                    )
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

            $results = @(Get-YtmPlaylist -Id 'PLtest123')

            Should -Invoke Invoke-YtmApi -Times 2
            $results.Count | Should -Be 4
            $results[0].Title | Should -Be 'Song 1'
            $results[3].Title | Should -Be 'Song 4'
        }

        It 'Handles musicShelfContinuation type' {
            Mock Invoke-YtmApi {
                if ($ContinuationToken) {
                    # Continuation response using musicShelfContinuation
                    [PSCustomObject]@{
                        continuationContents = [PSCustomObject]@{
                            musicShelfContinuation = [PSCustomObject]@{
                                contents = @(
                                    (& $script:CreateSongItem 'Song 3' 'vid3')
                                )
                            }
                        }
                    }
                } else {
                    # Initial response using musicShelfRenderer
                    [PSCustomObject]@{
                        contents = [PSCustomObject]@{
                            singleColumnBrowseResultsRenderer = [PSCustomObject]@{
                                tabs = @(
                                    [PSCustomObject]@{
                                        tabRenderer = [PSCustomObject]@{
                                            content = [PSCustomObject]@{
                                                sectionListRenderer = [PSCustomObject]@{
                                                    contents = @(
                                                        [PSCustomObject]@{
                                                            musicShelfRenderer = [PSCustomObject]@{
                                                                contents = @(
                                                                    (& $script:CreateSongItem 'Song 1' 'vid1'),
                                                                    (& $script:CreateSongItem 'Song 2' 'vid2')
                                                                )
                                                                continuations = @(
                                                                    [PSCustomObject]@{
                                                                        nextContinuationData = [PSCustomObject]@{
                                                                            continuation = 'token123'
                                                                        }
                                                                    }
                                                                )
                                                            }
                                                        }
                                                    )
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

            $results = @(Get-YtmPlaylist -Id 'PLtest123')

            Should -Invoke Invoke-YtmApi -Times 2
            $results.Count | Should -Be 3
        }

        It 'Includes PlaylistId in returned song objects' {
            Mock Invoke-YtmApi {
                [PSCustomObject]@{
                    contents = [PSCustomObject]@{
                        singleColumnBrowseResultsRenderer = [PSCustomObject]@{
                            tabs = @(
                                [PSCustomObject]@{
                                    tabRenderer = [PSCustomObject]@{
                                        content = [PSCustomObject]@{
                                            sectionListRenderer = [PSCustomObject]@{
                                                contents = @(
                                                    [PSCustomObject]@{
                                                        musicPlaylistShelfRenderer = [PSCustomObject]@{
                                                            contents = @(
                                                                (& $script:CreateSongItem 'Song 1' 'vid1')
                                                            )
                                                        }
                                                    }
                                                )
                                            }
                                        }
                                    }
                                }
                            )
                        }
                    }
                }
            }

            $results = @(Get-YtmPlaylist -Id 'PLtest123')
            $results[0].PlaylistId | Should -Be 'PLtest123'
        }
    }
}
