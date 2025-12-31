BeforeAll {
    . "$PSScriptRoot\..\Shared.ps1"
}

Describe 'Cookie Storage Functions' {
    BeforeAll {
        $script:testDir = Join-Path $TestDrive 'YouTubeMusicPS'
        $script:testConfigPath = Join-Path $testDir 'config.json'
    }

    BeforeEach {
        # Create test directory
        New-Item -Path $testDir -ItemType Directory -Force | Out-Null

        # Use Pester Mock
        Mock Get-YtmConfigurationPath { $script:testConfigPath }

        # Start with clean config
        if (Test-Path $testConfigPath) {
            Remove-Item $testConfigPath -Force
        }
    }

    AfterEach {
        # Clean up test directory
        if (Test-Path $testDir) {
            Remove-Item $testDir -Recurse -Force
        }
    }

    Describe 'Get-YtmStoredCookies' {
        Context 'No Stored Cookies' {
            It 'Returns null when no configuration exists' {
                $result = Get-YtmStoredCookies
                $result | Should -BeNullOrEmpty
            }

            It 'Returns null when auth is null' {
                $config = @{ version = '1.0'; auth = $null }
                $config | ConvertTo-Json | Set-Content $testConfigPath
                $result = Get-YtmStoredCookies
                $result | Should -BeNullOrEmpty
            }

            It 'Returns null when sapiSid is missing' {
                $config = @{
                    version = '1.0'
                    auth = @{ cookies = 'some-cookies' }
                }
                $config | ConvertTo-Json | Set-Content $testConfigPath
                $result = Get-YtmStoredCookies
                $result | Should -BeNullOrEmpty
            }

            It 'Returns null when cookies is missing' {
                $config = @{
                    version = '1.0'
                    auth = @{ sapiSid = 'some-sapisid' }
                }
                $config | ConvertTo-Json | Set-Content $testConfigPath
                $result = Get-YtmStoredCookies
                $result | Should -BeNullOrEmpty
            }
        }

        Context 'With Stored Cookies' {
            BeforeEach {
                $config = @{
                    version = '1.0'
                    auth = @{
                        sapiSid = 'stored-sapisid'
                        cookies = 'stored-cookies-string'
                    }
                }
                $config | ConvertTo-Json | Set-Content $testConfigPath
            }

            It 'Returns a PSCustomObject' {
                $result = Get-YtmStoredCookies
                $result | Should -BeOfType [PSCustomObject]
            }

            It 'Returns SapiSid property' {
                $result = Get-YtmStoredCookies
                $result.SapiSid | Should -Be 'stored-sapisid'
            }

            It 'Returns Cookies property' {
                $result = Get-YtmStoredCookies
                $result.Cookies | Should -Be 'stored-cookies-string'
            }
        }
    }

    Describe 'Set-YtmStoredCookies' {
        Context 'Storing Cookies' {
            It 'Stores cookies in configuration' {
                Set-YtmStoredCookies -SapiSid 'new-sapisid' -Cookies 'new-cookies'
                $result = Get-YtmStoredCookies
                $result | Should -Not -BeNullOrEmpty
            }

            It 'Stores correct SapiSid' {
                Set-YtmStoredCookies -SapiSid 'my-sapisid' -Cookies 'my-cookies'
                $result = Get-YtmStoredCookies
                $result.SapiSid | Should -Be 'my-sapisid'
            }

            It 'Stores correct Cookies' {
                Set-YtmStoredCookies -SapiSid 'my-sapisid' -Cookies 'SAPISID=abc; SSID=xyz'
                $result = Get-YtmStoredCookies
                $result.Cookies | Should -Be 'SAPISID=abc; SSID=xyz'
            }

            It 'Overwrites existing cookies' {
                Set-YtmStoredCookies -SapiSid 'old' -Cookies 'old-cookies'
                Set-YtmStoredCookies -SapiSid 'new' -Cookies 'new-cookies'
                $result = Get-YtmStoredCookies
                $result.SapiSid | Should -Be 'new'
                $result.Cookies | Should -Be 'new-cookies'
            }

            It 'Preserves configuration version' {
                Set-YtmStoredCookies -SapiSid 'test' -Cookies 'test-cookies'
                $config = Get-Content $testConfigPath -Raw | ConvertFrom-Json
                $config.version | Should -Be '1.0'
            }
        }

        Context 'Parameter Validation' {
            It 'Throws when SapiSid is empty' {
                { Set-YtmStoredCookies -SapiSid '' -Cookies 'cookies' } | Should -Throw
            }

            It 'Throws when Cookies is empty' {
                { Set-YtmStoredCookies -SapiSid 'sapisid' -Cookies '' } | Should -Throw
            }
        }

        Context 'ShouldProcess Support' {
            It 'Supports -WhatIf' {
                Set-YtmStoredCookies -SapiSid 'test' -Cookies 'test' -WhatIf
                $result = Get-YtmStoredCookies
                $result | Should -BeNullOrEmpty
            }
        }
    }

    Describe 'Remove-YtmStoredCookies' {
        Context 'Removing Cookies' {
            BeforeEach {
                # Set up existing cookies
                Set-YtmStoredCookies -SapiSid 'existing' -Cookies 'existing-cookies'
            }

            It 'Removes stored cookies' {
                Remove-YtmStoredCookies
                $result = Get-YtmStoredCookies
                $result | Should -BeNullOrEmpty
            }

            It 'Preserves configuration version after removal' {
                Remove-YtmStoredCookies
                $config = Get-Content $testConfigPath -Raw | ConvertFrom-Json
                $config.version | Should -Be '1.0'
            }

            It 'Sets auth to null' {
                Remove-YtmStoredCookies
                $config = Get-Content $testConfigPath -Raw | ConvertFrom-Json
                $config.auth | Should -BeNullOrEmpty
            }
        }

        Context 'ShouldProcess Support' {
            BeforeEach {
                Set-YtmStoredCookies -SapiSid 'existing' -Cookies 'existing-cookies'
            }

            It 'Supports -WhatIf' {
                Remove-YtmStoredCookies -WhatIf
                $result = Get-YtmStoredCookies
                $result | Should -Not -BeNullOrEmpty
            }
        }

        Context 'Idempotent Behavior' {
            It 'Does not throw when cookies do not exist' {
                { Remove-YtmStoredCookies } | Should -Not -Throw
            }

            It 'Can be called multiple times' {
                Remove-YtmStoredCookies
                { Remove-YtmStoredCookies } | Should -Not -Throw
            }
        }
    }
}
