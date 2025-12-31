BeforeAll {
    . "$PSScriptRoot\..\Shared.ps1"
}

Describe 'Disconnect-YtmAccount' {
    BeforeAll {
        $script:testDir = Join-Path $TestDrive 'YouTubeMusicPS'
        $script:testConfigPath = Join-Path $testDir 'config.json'
    }

    BeforeEach {
        # Create test directory and mock config path
        New-Item -Path $testDir -ItemType Directory -Force | Out-Null
        Mock Get-YtmConfigurationPath { $script:testConfigPath }

        # Set up existing cookies
        $config = @{
            version = '1.0'
            auth = @{
                sapiSid = 'existing-sapisid'
                cookies = 'existing-cookies'
            }
        }
        $config | ConvertTo-Json | Set-Content $testConfigPath
    }

    AfterEach {
        if (Test-Path $testDir) {
            Remove-Item $testDir -Recurse -Force
        }
    }

    Context 'Disconnecting' {
        It 'Removes stored cookies' {
            Disconnect-YtmAccount
            $stored = Get-YtmStoredCookies
            $stored | Should -BeNullOrEmpty
        }

        It 'Does not throw when no cookies exist' {
            Remove-YtmStoredCookies  # Ensure no cookies
            { Disconnect-YtmAccount } | Should -Not -Throw
        }

        It 'Preserves configuration file with version' {
            Disconnect-YtmAccount
            Test-Path $testConfigPath | Should -Be $true
            $config = Get-Content $testConfigPath -Raw | ConvertFrom-Json
            $config.version | Should -Be '1.0'
        }
    }

    Context 'ShouldProcess Support' {
        It 'Supports -WhatIf' {
            Disconnect-YtmAccount -WhatIf
            $stored = Get-YtmStoredCookies
            $stored | Should -Not -BeNullOrEmpty
        }

        It 'Supports -Confirm:$false' {
            # This should work without prompting
            { Disconnect-YtmAccount -Confirm:$false } | Should -Not -Throw
            $stored = Get-YtmStoredCookies
            $stored | Should -BeNullOrEmpty
        }
    }

    Context 'Output' {
        It 'Does not return any objects' {
            $result = Disconnect-YtmAccount
            $result | Should -BeNullOrEmpty
        }
    }
}
