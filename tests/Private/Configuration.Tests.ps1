BeforeAll {
    . "$PSScriptRoot\..\Shared.ps1"
}

Describe 'Get-YtmConfigurationPath' {
    Context 'Path Generation' {
        It 'Returns a string path' {
            $result = Get-YtmConfigurationPath
            $result | Should -BeOfType [string]
        }

        It 'Returns a path ending with config.json' {
            $result = Get-YtmConfigurationPath
            $result | Should -Match 'config\.json$'
        }

        It 'Returns a path containing YouTubeMusicPS' {
            $result = Get-YtmConfigurationPath
            $result | Should -Match 'YouTubeMusicPS'
        }

        It 'Returns an absolute path' {
            $result = Get-YtmConfigurationPath
            [System.IO.Path]::IsPathRooted($result) | Should -Be $true
        }
    }

    Context 'Platform Detection' {
        It 'Returns a valid path for the current platform' {
            $result = Get-YtmConfigurationPath
            $parent = Split-Path $result -Parent

            # The function creates the directory, so it should exist
            Test-Path $parent | Should -Be $true
        }
    }
}

Describe 'Get-YtmConfiguration' {
    BeforeAll {
        $script:testDir = Join-Path $TestDrive 'YouTubeMusicPS'
        $script:testConfigPath = Join-Path $testDir 'config.json'
    }

    BeforeEach {
        # Create test directory
        New-Item -Path $testDir -ItemType Directory -Force | Out-Null

        # Use Pester Mock
        Mock Get-YtmConfigurationPath { $script:testConfigPath }
    }

    AfterEach {
        # Clean up test directory
        if (Test-Path $testDir) {
            Remove-Item $testDir -Recurse -Force
        }
    }

    Context 'Missing Configuration File' {
        It 'Returns default config when file does not exist' {
            $result = Get-YtmConfiguration
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Returns config with version 1.0 when file does not exist' {
            $result = Get-YtmConfiguration
            $result.version | Should -Be '1.0'
        }

        It 'Returns config with null auth when file does not exist' {
            $result = Get-YtmConfiguration
            $result.auth | Should -BeNullOrEmpty
        }
    }

    Context 'Valid Configuration File' {
        BeforeEach {
            $config = @{
                version = '1.0'
                auth = @{
                    sapiSid = 'test-sapisid'
                    cookies = 'test-cookies'
                }
            }
            $config | ConvertTo-Json | Set-Content -Path $testConfigPath
        }

        It 'Reads configuration from file' {
            $result = Get-YtmConfiguration
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Returns correct version' {
            $result = Get-YtmConfiguration
            $result.version | Should -Be '1.0'
        }

        It 'Returns auth data' {
            $result = Get-YtmConfiguration
            $result.auth | Should -Not -BeNullOrEmpty
            $result.auth.sapiSid | Should -Be 'test-sapisid'
            $result.auth.cookies | Should -Be 'test-cookies'
        }
    }

    Context 'Invalid Configuration File' {
        It 'Throws when file contains invalid JSON' {
            Set-Content -Path $testConfigPath -Value 'not valid json {'
            { Get-YtmConfiguration } | Should -Throw '*Failed to read configuration*'
        }

        It 'Throws when configuration is missing version property' {
            $config = @{ auth = $null }
            $config | ConvertTo-Json | Set-Content -Path $testConfigPath
            { Get-YtmConfiguration } | Should -Throw "*missing 'version' property*"
        }
    }
}

Describe 'Set-YtmConfiguration' {
    BeforeAll {
        $script:testDir = Join-Path $TestDrive 'YouTubeMusicPS'
        $script:testConfigPath = Join-Path $testDir 'config.json'
    }

    BeforeEach {
        # Create test directory
        New-Item -Path $testDir -ItemType Directory -Force | Out-Null

        # Use Pester Mock
        Mock Get-YtmConfigurationPath { $script:testConfigPath }
    }

    AfterEach {
        # Clean up test directory
        if (Test-Path $testDir) {
            Remove-Item $testDir -Recurse -Force
        }
    }

    Context 'Writing Configuration' {
        It 'Creates the configuration file' {
            $config = [PSCustomObject]@{
                version = '1.0'
                auth = $null
            }
            Set-YtmConfiguration -Configuration $config
            Test-Path $testConfigPath | Should -Be $true
        }

        It 'Writes valid JSON' {
            $config = [PSCustomObject]@{
                version = '1.0'
                auth = $null
            }
            Set-YtmConfiguration -Configuration $config
            { Get-Content $testConfigPath -Raw | ConvertFrom-Json } | Should -Not -Throw
        }

        It 'Writes correct version' {
            $config = [PSCustomObject]@{
                version = '2.0'
                auth = $null
            }
            Set-YtmConfiguration -Configuration $config
            $saved = Get-Content $testConfigPath -Raw | ConvertFrom-Json
            $saved.version | Should -Be '2.0'
        }

        It 'Writes auth data correctly' {
            $config = [PSCustomObject]@{
                version = '1.0'
                auth = [PSCustomObject]@{
                    sapiSid = 'my-sapisid'
                    cookies = 'my-cookies'
                }
            }
            Set-YtmConfiguration -Configuration $config
            $saved = Get-Content $testConfigPath -Raw | ConvertFrom-Json
            $saved.auth.sapiSid | Should -Be 'my-sapisid'
            $saved.auth.cookies | Should -Be 'my-cookies'
        }

        It 'Overwrites existing configuration' {
            $config1 = [PSCustomObject]@{ version = '1.0'; auth = $null }
            $config2 = [PSCustomObject]@{ version = '1.0'; auth = [PSCustomObject]@{ sapiSid = 'new' } }

            Set-YtmConfiguration -Configuration $config1
            Set-YtmConfiguration -Configuration $config2

            $saved = Get-Content $testConfigPath -Raw | ConvertFrom-Json
            $saved.auth.sapiSid | Should -Be 'new'
        }
    }

    Context 'Validation' {
        It 'Throws when configuration is missing version' {
            $config = [PSCustomObject]@{ auth = $null }
            { Set-YtmConfiguration -Configuration $config } | Should -Throw "*missing 'version' property*"
        }

        It 'Throws when configuration is null' {
            { Set-YtmConfiguration -Configuration $null } | Should -Throw
        }
    }

    Context 'ShouldProcess Support' {
        It 'Supports -WhatIf' {
            $config = [PSCustomObject]@{ version = '1.0'; auth = $null }
            Set-YtmConfiguration -Configuration $config -WhatIf
            Test-Path $testConfigPath | Should -Be $false
        }
    }

    Context 'Directory Creation' {
        BeforeEach {
            # Remove the test directory
            if (Test-Path $testDir) {
                Remove-Item $testDir -Recurse -Force
            }
        }

        It 'Creates directory if it does not exist' {
            $config = [PSCustomObject]@{ version = '1.0'; auth = $null }
            Set-YtmConfiguration -Configuration $config
            Test-Path $testDir | Should -Be $true
        }
    }
}
