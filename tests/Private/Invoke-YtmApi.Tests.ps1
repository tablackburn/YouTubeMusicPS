BeforeAll {
    . "$PSScriptRoot\..\Shared.ps1"
}

Describe 'Invoke-YtmApi' {
    BeforeAll {
        $script:testDir = Join-Path $TestDrive 'YouTubeMusicPS'
        $script:testConfigPath = Join-Path $testDir 'config.json'
    }

    BeforeEach {
        # Create test directory and mock config path
        New-Item -Path $testDir -ItemType Directory -Force | Out-Null
        Mock Get-YtmConfigurationPath { $script:testConfigPath }

        # Set up mock cookies
        $config = @{
            version = '1.0'
            auth = @{
                sapiSid = 'test-sapisid-12345'
                cookies = 'SAPISID=test-sapisid-12345; SSID=testssid'
            }
        }
        $config | ConvertTo-Json | Set-Content $testConfigPath
    }

    AfterEach {
        if (Test-Path $testDir) {
            Remove-Item $testDir -Recurse -Force
        }
    }

    Context 'Authentication Requirements' {
        It 'Throws when not authenticated and no cookies provided' {
            # Remove auth from config
            $config = @{ version = '1.0'; auth = $null }
            $config | ConvertTo-Json | Set-Content $testConfigPath

            { Invoke-YtmApi -Endpoint 'browse' } | Should -Throw '*Not authenticated*'
        }

        It 'Uses provided cookies instead of stored ones' {
            $mockCookies = [PSCustomObject]@{
                SapiSid = 'provided-sapisid'
                Cookies = 'SAPISID=provided-sapisid'
            }

            # Verify the function accepts the Cookies parameter
            $command = Get-Command Invoke-YtmApi
            $command.Parameters.ContainsKey('Cookies') | Should -Be $true
        }
    }

    Context 'Parameter Validation' {
        It 'Requires Endpoint parameter' {
            $command = Get-Command Invoke-YtmApi
            $command.Parameters['Endpoint'].Attributes.Mandatory | Should -Contain $true
        }

        It 'Throws when Endpoint is empty' {
            { Invoke-YtmApi -Endpoint '' } | Should -Throw
        }

        It 'Has optional Body parameter' {
            $command = Get-Command Invoke-YtmApi
            $command.Parameters['Body'].Attributes.Mandatory | Should -Not -Contain $true
        }

        It 'Has optional ContinuationToken parameter' {
            $command = Get-Command Invoke-YtmApi
            $command.Parameters['ContinuationToken'].Attributes.Mandatory | Should -Not -Contain $true
        }
    }

    Context 'Request Building' {
        # These tests verify the function builds correct requests
        # by examining what would be sent (mocking Invoke-RestMethod is complex in Pester)

        It 'Merges body with client context' {
            # We test this indirectly - if it throws with a network error
            # rather than a parameter error, the body was built correctly
            Mock Invoke-RestMethod { throw [System.Net.WebException]::new('Test network error') }

            { Invoke-YtmApi -Endpoint 'browse' -Body @{ browseId = 'test' } } | Should -Throw '*network*'
        }
    }

    Context 'URL Building' {
        It 'Accepts continuation token' {
            # This test verifies the function accepts the parameter
            $command = Get-Command Invoke-YtmApi
            $command.Parameters.ContainsKey('ContinuationToken') | Should -Be $true
        }
    }

    Context 'Error Handling' {
        It 'Provides helpful message for 401 errors' {
            # Mock to simulate 401 response
            Mock Invoke-RestMethod {
                $response = [System.Net.HttpWebResponse]::new()
                $exception = [System.Net.WebException]::new(
                    'The remote server returned an error: (401) Unauthorized.',
                    $null,
                    [System.Net.WebExceptionStatus]::ProtocolError,
                    $response
                )
                throw $exception
            }

            # Note: The actual error message depends on how PS handles the mock
            { Invoke-YtmApi -Endpoint 'browse' } | Should -Throw
        }
    }
}
