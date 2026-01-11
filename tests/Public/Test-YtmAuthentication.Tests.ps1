BeforeAll {
    . "$PSScriptRoot\..\Shared.ps1"
}

Describe 'Test-YtmAuthentication' {
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

    Context 'No Stored Credentials' {
        It 'Returns IsAuthenticated = $false when no config exists' {
            # Ensure no config file
            if (Test-Path $testConfigPath) {
                Remove-Item $testConfigPath -Force
            }

            $result = Test-YtmAuthentication

            $result.IsAuthenticated | Should -BeFalse
            $result.HasStoredCredentials | Should -BeFalse
            $result.Message | Should -Match 'Not authenticated'
        }

        It 'Returns correct type' {
            if (Test-Path $testConfigPath) {
                Remove-Item $testConfigPath -Force
            }

            $result = Test-YtmAuthentication

            $result.PSTypeNames | Should -Contain 'YouTubeMusicPS.AuthenticationStatus'
        }
    }

    Context 'With Stored Credentials' {
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

        It 'Returns IsAuthenticated = $true when API call succeeds' {
            Mock Invoke-YtmApi {
                [PSCustomObject]@{
                    contents = [PSCustomObject]@{}
                }
            }

            $result = Test-YtmAuthentication

            $result.IsAuthenticated | Should -BeTrue
            $result.HasStoredCredentials | Should -BeTrue
            $result.Message | Should -Match 'Connected'
        }

        It 'Returns expired message when API fails with 401/403/expired error' {
            Mock Invoke-YtmApi {
                throw 'Authentication failed. Your cookies may have expired.'
            }

            $result = Test-YtmAuthentication

            $result.IsAuthenticated | Should -BeFalse
            $result.HasStoredCredentials | Should -BeTrue
            $result.Message | Should -Match 'Credentials have expired'
        }

        It 'Returns generic error message when API fails with other errors' {
            Mock Invoke-YtmApi {
                throw 'Network connection timeout'
            }

            $result = Test-YtmAuthentication

            $result.IsAuthenticated | Should -BeFalse
            $result.HasStoredCredentials | Should -BeTrue
            $result.Message | Should -Match 'Authentication test failed.*Network connection timeout'
        }

        It 'Makes API call to verify credentials' {
            Mock Invoke-YtmApi {
                [PSCustomObject]@{
                    contents = [PSCustomObject]@{}
                }
            }

            Test-YtmAuthentication

            Should -Invoke Invoke-YtmApi -Times 1 -ParameterFilter {
                $Endpoint -eq 'browse' -and $Body.browseId -eq 'FEmusic_liked_videos'
            }
        }
    }

    Context 'Output Object' {
        It 'Has all expected properties' {
            if (Test-Path $testConfigPath) {
                Remove-Item $testConfigPath -Force
            }

            $result = Test-YtmAuthentication

            $result.PSObject.Properties.Name | Should -Contain 'IsAuthenticated'
            $result.PSObject.Properties.Name | Should -Contain 'HasStoredCredentials'
            $result.PSObject.Properties.Name | Should -Contain 'Message'
        }
    }
}
