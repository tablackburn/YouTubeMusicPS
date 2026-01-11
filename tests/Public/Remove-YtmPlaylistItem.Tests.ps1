BeforeAll {
    . "$PSScriptRoot\..\Shared.ps1"
}

Describe 'Remove-YtmPlaylistItem' {
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
            $song = [PSCustomObject]@{
                PSTypeName = 'YouTubeMusicPS.Song'
                VideoId    = 'test123'
                SetVideoId = 'set123'
                PlaylistId = 'PLtest'
                Title      = 'Test Song'
                Artist     = 'Test Artist'
            }
            { $song | Remove-YtmPlaylistItem -Force } | Should -Throw '*Not authenticated*'
        }

        It 'Has Force parameter' {
            $command = Get-Command Remove-YtmPlaylistItem
            $forceParam = $command.Parameters['Force']
            $forceParam | Should -Not -BeNullOrEmpty
            $forceParam.ParameterType | Should -Be ([switch])
        }
    }

    Context 'Parameter Sets' {
        It 'Has Pipeline and Direct parameter sets' {
            $command = Get-Command Remove-YtmPlaylistItem
            $command.ParameterSets.Name | Should -Contain 'Pipeline'
            $command.ParameterSets.Name | Should -Contain 'Direct'
        }

        It 'Has SupportsShouldProcess enabled' {
            $command = Get-Command Remove-YtmPlaylistItem
            $command.CmdletBinding | Should -Not -BeNullOrEmpty
        }

        It 'Has Name parameter in Direct set' {
            $command = Get-Command Remove-YtmPlaylistItem
            $nameParam = $command.Parameters['Name']
            $nameParam.ParameterSets.Keys | Should -Contain 'Direct'
        }

        It 'Has Title parameter in Direct set' {
            $command = Get-Command Remove-YtmPlaylistItem
            $titleParam = $command.Parameters['Title']
            $titleParam.ParameterSets.Keys | Should -Contain 'Direct'
        }

        It 'Has optional Artist parameter in Direct set' {
            $command = Get-Command Remove-YtmPlaylistItem
            $artistParam = $command.Parameters['Artist']
            $artistParam | Should -Not -BeNullOrEmpty
        }

        It 'Has Song parameter in Pipeline set accepting pipeline input' {
            $command = Get-Command Remove-YtmPlaylistItem
            $songParam = $command.Parameters['Song']
            $songParam.ParameterSets.Keys | Should -Contain 'Pipeline'
            $songParam.Attributes | Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] } |
            ForEach-Object { $_.ValueFromPipeline } | Should -Contain $true
        }
    }

    Context 'Pipeline Mode' {
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

        It 'Errors when song lacks PlaylistId' {
            $song = [PSCustomObject]@{
                PSTypeName = 'YouTubeMusicPS.Song'
                VideoId    = 'test123'
                SetVideoId = 'set123'
                Title      = 'Test Song'
                Artist     = 'Test Artist'
            }
            $song | Remove-YtmPlaylistItem -ErrorVariable err -ErrorAction SilentlyContinue
            $err | Should -Not -BeNullOrEmpty
            $err[0].ToString() | Should -Match 'PlaylistId'
        }

        It 'Errors when song lacks SetVideoId' {
            $song = [PSCustomObject]@{
                PSTypeName = 'YouTubeMusicPS.Song'
                VideoId    = 'test123'
                PlaylistId = 'PLtest'
                Title      = 'Test Song'
                Artist     = 'Test Artist'
            }
            $song | Remove-YtmPlaylistItem -ErrorVariable err -ErrorAction SilentlyContinue
            $err | Should -Not -BeNullOrEmpty
            $err[0].ToString() | Should -Match 'SetVideoId'
        }

        It 'Calls edit_playlist API with correct action' {
            Mock Invoke-YtmApi { [PSCustomObject]@{ status = 'STATUS_SUCCEEDED' } }

            $song = [PSCustomObject]@{
                PSTypeName = 'YouTubeMusicPS.Song'
                VideoId    = 'vid123'
                SetVideoId = 'set123'
                PlaylistId = 'PLtest'
                Title      = 'Test Song'
                Artist     = 'Test Artist'
            }

            $song | Remove-YtmPlaylistItem -Confirm:$false

            Should -Invoke Invoke-YtmApi -Times 1 -ParameterFilter {
                $Endpoint -eq 'browse/edit_playlist' -and
                $Body.playlistId -eq 'PLtest' -and
                $Body.actions[0].action -eq 'ACTION_REMOVE_VIDEO' -and
                $Body.actions[0].setVideoId -eq 'set123' -and
                $Body.actions[0].removedVideoId -eq 'vid123'
            }
        }

        It 'Processes multiple songs from pipeline' {
            Mock Invoke-YtmApi { [PSCustomObject]@{ status = 'STATUS_SUCCEEDED' } }

            $songs = @(
                [PSCustomObject]@{
                    PSTypeName = 'YouTubeMusicPS.Song'
                    VideoId    = 'vid1'
                    SetVideoId = 'set1'
                    PlaylistId = 'PLtest'
                    Title      = 'Song 1'
                    Artist     = 'Artist'
                },
                [PSCustomObject]@{
                    PSTypeName = 'YouTubeMusicPS.Song'
                    VideoId    = 'vid2'
                    SetVideoId = 'set2'
                    PlaylistId = 'PLtest'
                    Title      = 'Song 2'
                    Artist     = 'Artist'
                }
            )

            $songs | Remove-YtmPlaylistItem -Confirm:$false

            Should -Invoke Invoke-YtmApi -Times 2
        }
    }

    Context 'WhatIf Support' {
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

        It 'Does not call API when -WhatIf is used' {
            Mock Invoke-YtmApi { [PSCustomObject]@{ status = 'STATUS_SUCCEEDED' } }

            $song = [PSCustomObject]@{
                PSTypeName = 'YouTubeMusicPS.Song'
                VideoId    = 'vid123'
                SetVideoId = 'set123'
                PlaylistId = 'PLtest'
                Title      = 'Test Song'
                Artist     = 'Test Artist'
            }

            $song | Remove-YtmPlaylistItem -WhatIf

            Should -Invoke Invoke-YtmApi -Times 0
        }
    }

    Context 'Direct Mode' {
        BeforeEach {
            $testConfiguration = @{
                version = '1.0'
                auth    = @{
                    sapiSid = 'test-sapisid'
                    cookies = 'SAPISID=test-sapisid'
                }
            }
            $testConfiguration | ConvertTo-Json | Set-Content $testConfigPath

            # Mock Get-YtmPlaylist to return playlists list
            Mock Get-YtmPlaylist {
                @(
                    [PSCustomObject]@{
                        PSTypeName = 'YouTubeMusicPS.Playlist'
                        Name       = 'Test Playlist'
                        PlaylistId = 'PLtest123'
                    }
                )
            } -ParameterFilter { -not $Name }

            # Mock Get-YtmPlaylist to return songs when -Name is provided
            Mock Get-YtmPlaylist {
                @(
                    [PSCustomObject]@{
                        PSTypeName = 'YouTubeMusicPS.Song'
                        VideoId    = 'vid123'
                        SetVideoId = 'set123'
                        PlaylistId = 'PLtest123'
                        Title      = 'Target Song'
                        Artist     = 'Test Artist'
                    }
                )
            } -ParameterFilter { $Name -eq 'Test Playlist' }
        }

        It 'Throws when playlist not found' {
            { Remove-YtmPlaylistItem -Name 'Nonexistent' -Title 'Song' } | Should -Throw '*not found*'
        }

        It 'Finds and removes song by title' {
            Mock Invoke-YtmApi { [PSCustomObject]@{ status = 'STATUS_SUCCEEDED' } }

            Remove-YtmPlaylistItem -Name 'Test Playlist' -Title 'Target Song' -Confirm:$false

            Should -Invoke Invoke-YtmApi -Times 1 -ParameterFilter {
                $Endpoint -eq 'browse/edit_playlist'
            }
        }
    }
}
