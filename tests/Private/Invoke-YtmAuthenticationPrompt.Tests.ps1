BeforeAll {
    . "$PSScriptRoot\..\Shared.ps1"
}

Describe 'Invoke-YtmAuthenticationPrompt' {
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

    Context 'Parameter Validation' {
        It 'Requires Cmdlet parameter' {
            $command = Get-Command Invoke-YtmAuthenticationPrompt
            $command.Parameters['Cmdlet'].Attributes |
                Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] } |
                ForEach-Object { $_.Mandatory } |
                Should -Contain $true
        }

        It 'Has Force as optional switch parameter' {
            $command = Get-Command Invoke-YtmAuthenticationPrompt
            $forceParam = $command.Parameters['Force']
            $forceParam | Should -Not -BeNullOrEmpty
            $forceParam.ParameterType | Should -Be ([switch])
        }

        It 'Returns boolean type' {
            $command = Get-Command Invoke-YtmAuthenticationPrompt
            $command.OutputType.Type | Should -Contain ([bool])
        }

        It 'Cmdlet parameter accepts PSCmdlet type' {
            $command = Get-Command Invoke-YtmAuthenticationPrompt
            $cmdletParam = $command.Parameters['Cmdlet']
            $cmdletParam.ParameterType | Should -Be ([System.Management.Automation.PSCmdlet])
        }
    }

    Context 'Behavior via Get-YtmLikedMusic' {
        BeforeEach {
            # Ensure no cookies
            if (Test-Path $testConfigPath) {
                Remove-Item $testConfigPath -Force
            }
        }

        It 'Throws with -Force when not authenticated' {
            { Get-YtmLikedMusic -Force } | Should -Throw '*Not authenticated*'
        }

        It 'Does not throw when authenticated with -Force' {
            # Set up mock cookies
            $testConfiguration = @{
                version = '1.0'
                auth = @{
                    sapiSid = 'test-sapisid'
                    cookies = 'SAPISID=test-sapisid'
                }
            }
            $testConfiguration | ConvertTo-Json | Set-Content $testConfigPath

            Mock Invoke-YtmApi {
                [PSCustomObject]@{
                    contents = [PSCustomObject]@{
                        singleColumnBrowseResultsRenderer = [PSCustomObject]@{
                            tabs = @()
                        }
                    }
                }
            }

            { Get-YtmLikedMusic -Force -WarningAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context 'Behavior via Get-YtmPlaylist' {
        BeforeEach {
            if (Test-Path $testConfigPath) {
                Remove-Item $testConfigPath -Force
            }
        }

        It 'Throws with -Force when not authenticated' {
            { Get-YtmPlaylist -Force } | Should -Throw '*Not authenticated*'
        }

        It 'Does not throw when authenticated with -Force' {
            $testConfiguration = @{
                version = '1.0'
                auth = @{
                    sapiSid = 'test-sapisid'
                    cookies = 'SAPISID=test-sapisid'
                }
            }
            $testConfiguration | ConvertTo-Json | Set-Content $testConfigPath

            Mock Invoke-YtmApi {
                [PSCustomObject]@{
                    contents = [PSCustomObject]@{
                        singleColumnBrowseResultsRenderer = [PSCustomObject]@{
                            tabs = @()
                        }
                    }
                }
            }

            { Get-YtmPlaylist -Force } | Should -Not -Throw
        }
    }

    Context 'Behavior via Remove-YtmPlaylistItem' {
        BeforeEach {
            if (Test-Path $testConfigPath) {
                Remove-Item $testConfigPath -Force
            }
        }

        It 'Throws with -Force when not authenticated' {
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
    }

    Context 'Authentication Check Logic' {
        It 'Uses Get-YtmStoredCookies to check authentication' {
            # This test verifies the function checks stored cookies
            $testConfiguration = @{
                version = '1.0'
                auth = @{
                    sapiSid = 'test-sapisid'
                    cookies = 'SAPISID=test-sapisid'
                }
            }
            $testConfiguration | ConvertTo-Json | Set-Content $testConfigPath

            Mock Invoke-YtmApi {
                [PSCustomObject]@{
                    contents = [PSCustomObject]@{
                        singleColumnBrowseResultsRenderer = [PSCustomObject]@{
                            tabs = @()
                        }
                    }
                }
            }

            # If authenticated, Get-YtmLikedMusic should proceed to call the API
            Get-YtmLikedMusic -Force -WarningAction SilentlyContinue

            Should -Invoke Invoke-YtmApi -Times 1
        }

        It 'Does not call API when not authenticated with -Force' {
            if (Test-Path $testConfigPath) {
                Remove-Item $testConfigPath -Force
            }

            Mock Invoke-YtmApi { }

            try {
                Get-YtmLikedMusic -Force
            }
            catch {
                # Expected to throw
            }

            Should -Not -Invoke Invoke-YtmApi
        }
    }
}
