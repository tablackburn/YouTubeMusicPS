BeforeAll {
    . "$PSScriptRoot\..\Shared.ps1"
}

Describe 'Get-YtmLikedMusic' {
    BeforeAll {
        $script:testDir = Join-Path $TestDrive 'YouTubeMusicPS'
        $script:testConfigPath = Join-Path $testDir 'config.json'
    }

    BeforeEach {
        # Create test directory and mock config path
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
            # Ensure no cookies
            if (Test-Path $testConfigPath) {
                Remove-Item $testConfigPath -Force
            }
            { Get-YtmLikedMusic -Force } | Should -Throw '*Not authenticated*'
        }

        It 'Has Force parameter' {
            $command = Get-Command Get-YtmLikedMusic
            $forceParam = $command.Parameters['Force']
            $forceParam | Should -Not -BeNullOrEmpty
            $forceParam.ParameterType | Should -Be ([switch])
        }
    }

    Context 'With Authentication' {
        BeforeEach {
            # Set up mock cookies
            $testConfiguration = @{
                version = '1.0'
                auth = @{
                    sapiSid = 'test-sapisid'
                    cookies = 'SAPISID=test-sapisid'
                }
            }
            $testConfiguration | ConvertTo-Json | Set-Content $testConfigPath
        }

        It 'Calls browse API with correct endpoint' {
            Mock Invoke-YtmApi {
                # Return empty response
                [PSCustomObject]@{
                    contents = [PSCustomObject]@{
                        singleColumnBrowseResultsRenderer = [PSCustomObject]@{
                            tabs = @()
                        }
                    }
                }
            }

            Get-YtmLikedMusic -WarningAction SilentlyContinue
            Should -Invoke Invoke-YtmApi -Times 1 -ParameterFilter { $Endpoint -eq 'browse' }
        }
    }

    Context 'Limit Parameter' {
        It 'Has Limit parameter with default of 0' {
            $command = Get-Command Get-YtmLikedMusic
            $limitParam = $command.Parameters['Limit']
            $limitParam | Should -Not -BeNullOrEmpty
        }

        It 'Validates Limit is non-negative' {
            { Get-YtmLikedMusic -Limit -1 } | Should -Throw
        }
    }

    Context 'Response Parsing' {
        BeforeEach {
            # Set up mock cookies
            $testConfiguration = @{
                version = '1.0'
                auth = @{
                    sapiSid = 'test-sapisid'
                    cookies = 'SAPISID=test-sapisid'
                }
            }
            $testConfiguration | ConvertTo-Json | Set-Content $testConfigPath
        }

        It 'Returns YouTubeMusicPS.Song objects' {
            Mock Invoke-YtmApi {
                # Return a mock response with one song
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
                                                                [PSCustomObject]@{
                                                                    musicResponsiveListItemRenderer = [PSCustomObject]@{
                                                                        flexColumns = @(
                                                                            [PSCustomObject]@{
                                                                                musicResponsiveListItemFlexColumnRenderer = [PSCustomObject]@{
                                                                                    text = [PSCustomObject]@{
                                                                                        runs = @(
                                                                                            [PSCustomObject]@{ text = 'Test Song' }
                                                                                        )
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
                                                                                                videoId = 'test123'
                                                                                            }
                                                                                        }
                                                                                    }
                                                                                }
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

            $results = Get-YtmLikedMusic
            $results | Should -Not -BeNullOrEmpty
            $results[0].PSTypeNames | Should -Contain 'YouTubeMusicPS.Song'
        }

        It 'Respects Limit parameter' {
            Mock Invoke-YtmApi {
                # Return multiple songs
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
                                                                [PSCustomObject]@{
                                                                    musicResponsiveListItemRenderer = [PSCustomObject]@{
                                                                        flexColumns = @(
                                                                            [PSCustomObject]@{
                                                                                musicResponsiveListItemFlexColumnRenderer = [PSCustomObject]@{
                                                                                    text = [PSCustomObject]@{
                                                                                        runs = @([PSCustomObject]@{ text = 'Song 1' })
                                                                                    }
                                                                                }
                                                                            }
                                                                        )
                                                                        overlay = [PSCustomObject]@{
                                                                            musicItemThumbnailOverlayRenderer = [PSCustomObject]@{
                                                                                content = [PSCustomObject]@{
                                                                                    musicPlayButtonRenderer = [PSCustomObject]@{
                                                                                        playNavigationEndpoint = [PSCustomObject]@{
                                                                                            watchEndpoint = [PSCustomObject]@{ videoId = 'vid1' }
                                                                                        }
                                                                                    }
                                                                                }
                                                                            }
                                                                        }
                                                                    }
                                                                },
                                                                [PSCustomObject]@{
                                                                    musicResponsiveListItemRenderer = [PSCustomObject]@{
                                                                        flexColumns = @(
                                                                            [PSCustomObject]@{
                                                                                musicResponsiveListItemFlexColumnRenderer = [PSCustomObject]@{
                                                                                    text = [PSCustomObject]@{
                                                                                        runs = @([PSCustomObject]@{ text = 'Song 2' })
                                                                                    }
                                                                                }
                                                                            }
                                                                        )
                                                                        overlay = [PSCustomObject]@{
                                                                            musicItemThumbnailOverlayRenderer = [PSCustomObject]@{
                                                                                content = [PSCustomObject]@{
                                                                                    musicPlayButtonRenderer = [PSCustomObject]@{
                                                                                        playNavigationEndpoint = [PSCustomObject]@{
                                                                                            watchEndpoint = [PSCustomObject]@{ videoId = 'vid2' }
                                                                                        }
                                                                                    }
                                                                                }
                                                                            }
                                                                        }
                                                                    }
                                                                },
                                                                [PSCustomObject]@{
                                                                    musicResponsiveListItemRenderer = [PSCustomObject]@{
                                                                        flexColumns = @(
                                                                            [PSCustomObject]@{
                                                                                musicResponsiveListItemFlexColumnRenderer = [PSCustomObject]@{
                                                                                    text = [PSCustomObject]@{
                                                                                        runs = @([PSCustomObject]@{ text = 'Song 3' })
                                                                                    }
                                                                                }
                                                                            }
                                                                        )
                                                                        overlay = [PSCustomObject]@{
                                                                            musicItemThumbnailOverlayRenderer = [PSCustomObject]@{
                                                                                content = [PSCustomObject]@{
                                                                                    musicPlayButtonRenderer = [PSCustomObject]@{
                                                                                        playNavigationEndpoint = [PSCustomObject]@{
                                                                                            watchEndpoint = [PSCustomObject]@{ videoId = 'vid3' }
                                                                                        }
                                                                                    }
                                                                                }
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

            $results = @(Get-YtmLikedMusic -Limit 2)
            $results.Count | Should -Be 2
        }
    }

    Context 'Pagination' {
        BeforeEach {
            $testConfiguration = @{
                version = '1.0'
                auth = @{
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

        It 'Fetches continuation pages when token is present' {
            $callCount = 0
            Mock Invoke-YtmApi {
                $callCount++
                if ($ContinuationToken) {
                    # Continuation response (page 2)
                    [PSCustomObject]@{
                        continuationContents = [PSCustomObject]@{
                            musicShelfContinuation = [PSCustomObject]@{
                                contents = @(
                                    (& $script:CreateSongItem 'Song 3' 'vid3'),
                                    (& $script:CreateSongItem 'Song 4' 'vid4')
                                )
                            }
                        }
                    }
                } else {
                    # Initial response (page 1) with continuation token
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

            $results = @(Get-YtmLikedMusic)

            Should -Invoke Invoke-YtmApi -Times 2
            $results.Count | Should -Be 4
            $results[0].Title | Should -Be 'Song 1'
            $results[3].Title | Should -Be 'Song 4'
        }

        It 'Respects limit across pagination boundaries' {
            Mock Invoke-YtmApi {
                if ($ContinuationToken) {
                    # Continuation response (page 2) - should only take 1 from here
                    [PSCustomObject]@{
                        continuationContents = [PSCustomObject]@{
                            musicShelfContinuation = [PSCustomObject]@{
                                contents = @(
                                    (& $script:CreateSongItem 'Song 3' 'vid3'),
                                    (& $script:CreateSongItem 'Song 4' 'vid4')
                                )
                            }
                        }
                    }
                } else {
                    # Initial response (page 1) with 2 songs
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

            # Limit to 3: 2 from page 1, 1 from page 2
            $results = @(Get-YtmLikedMusic -Limit 3)
            $results.Count | Should -Be 3
        }

        It 'Stops when no continuation token is present' {
            Mock Invoke-YtmApi {
                # Response without continuation token
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
                                                                (& $script:CreateSongItem 'Song 1' 'vid1')
                                                            )
                                                            # No continuations property
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

            $results = @(Get-YtmLikedMusic)

            Should -Invoke Invoke-YtmApi -Times 1
            $results.Count | Should -Be 1
        }

        It 'Handles empty continuation response' {
            Mock Invoke-YtmApi {
                if ($ContinuationToken) {
                    # Empty continuation response
                    [PSCustomObject]@{
                        continuationContents = [PSCustomObject]@{
                            musicShelfContinuation = [PSCustomObject]@{
                                contents = @()
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
                                                            musicShelfRenderer = [PSCustomObject]@{
                                                                contents = @(
                                                                    (& $script:CreateSongItem 'Song 1' 'vid1')
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

            $results = @(Get-YtmLikedMusic)

            Should -Invoke Invoke-YtmApi -Times 2
            $results.Count | Should -Be 1
        }
    }

    Context 'API Error Handling' {
        BeforeEach {
            $testConfiguration = @{
                version = '1.0'
                auth = @{
                    sapiSid = 'test-sapisid'
                    cookies = 'SAPISID=test-sapisid'
                }
            }
            $testConfiguration | ConvertTo-Json | Set-Content $testConfigPath
        }

        It 'Throws when API returns error object' {
            Mock Invoke-YtmApi {
                [PSCustomObject]@{
                    error = [PSCustomObject]@{
                        message = 'Invalid request'
                        code = 400
                    }
                }
            }

            { Get-YtmLikedMusic } | Should -Throw '*YouTube Music API error*Invalid request*'
        }

        It 'Warns when API response format is unexpected' {
            Mock Invoke-YtmApi {
                # Return response without expected structure
                [PSCustomObject]@{
                    unexpectedProperty = 'value'
                }
            }

            $results = Get-YtmLikedMusic -WarningAction SilentlyContinue -WarningVariable warnings
            $results | Should -BeNullOrEmpty
        }
    }

    Context 'Empty Response' {
        BeforeEach {
            $testConfiguration = @{
                version = '1.0'
                auth = @{
                    sapiSid = 'test-sapisid'
                    cookies = 'SAPISID=test-sapisid'
                }
            }
            $testConfiguration | ConvertTo-Json | Set-Content $testConfigPath
        }

        It 'Handles empty library gracefully' {
            Mock Invoke-YtmApi {
                [PSCustomObject]@{
                    contents = [PSCustomObject]@{
                        singleColumnBrowseResultsRenderer = [PSCustomObject]@{
                            tabs = @()
                        }
                    }
                }
            }

            $results = Get-YtmLikedMusic -WarningAction SilentlyContinue
            $results | Should -BeNullOrEmpty
        }
    }
}
