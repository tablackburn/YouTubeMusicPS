BeforeAll {
    . "$PSScriptRoot\..\Shared.ps1"
}

Describe 'Connect-YtmAccount' {
    BeforeAll {
        $script:testDir = Join-Path $TestDrive 'YouTubeMusicPS'
        $script:testConfigPath = Join-Path $testDir 'config.json'
    }

    BeforeEach {
        # Create test directory and mock config path
        New-Item -Path $testDir -ItemType Directory -Force | Out-Null
        Mock Get-YtmConfigurationPath { $script:testConfigPath }

        # Clean config
        if (Test-Path $testConfigPath) {
            Remove-Item $testConfigPath -Force
        }
    }

    AfterEach {
        if (Test-Path $testDir) {
            Remove-Item $testDir -Recurse -Force
        }
    }

    Context 'Cookie Parameter Set' {
        It 'Extracts SAPISID from cookie string' {
            Mock Invoke-YtmApi { [PSCustomObject]@{ success = $true } }

            Connect-YtmAccount -Cookie 'SAPISID=abc123xyz; SSID=other'
            $stored = Get-YtmStoredCookies
            $stored.SapiSid | Should -Be 'abc123xyz'
        }

        It 'Extracts __Secure-3PAPISID preferentially' {
            Mock Invoke-YtmApi { [PSCustomObject]@{ success = $true } }

            Connect-YtmAccount -Cookie 'SAPISID=old123; __Secure-3PAPISID=new456; SSID=other'
            $stored = Get-YtmStoredCookies
            $stored.SapiSid | Should -Be 'new456'
        }

        It 'Stores the full cookie string' {
            Mock Invoke-YtmApi { [PSCustomObject]@{ success = $true } }

            $fullCookies = 'SAPISID=abc123; SSID=xyz789; SID=123'
            Connect-YtmAccount -Cookie $fullCookies
            $stored = Get-YtmStoredCookies
            $stored.Cookies | Should -Be $fullCookies
        }

        It 'Throws when SAPISID is not found in cookies' {
            { Connect-YtmAccount -Cookie 'SSID=xyz; SID=123' } | Should -Throw '*Could not find SAPISID*'
        }

        It 'Accepts SAPISID with dots' {
            Mock Invoke-YtmApi { [PSCustomObject]@{ success = $true } }

            Connect-YtmAccount -Cookie 'SAPISID=abc.123.xyz'
            $stored = Get-YtmStoredCookies
            $stored.SapiSid | Should -Be 'abc.123.xyz'
        }

        It 'Accepts SAPISID with slashes and dashes' {
            Mock Invoke-YtmApi { [PSCustomObject]@{ success = $true } }

            Connect-YtmAccount -Cookie 'SAPISID=abc/123-xyz_456'
            $stored = Get-YtmStoredCookies
            $stored.SapiSid | Should -Be 'abc/123-xyz_456'
        }

        It 'Throws when SAPISID contains invalid characters' {
            { Connect-YtmAccount -Cookie 'SAPISID=abc<script>alert(1)</script>' } | Should -Throw '*unexpected characters*'
        }

        It 'Throws when SAPISID contains spaces' {
            { Connect-YtmAccount -Cookie 'SAPISID=abc 123' } | Should -Throw '*unexpected characters*'
        }
    }

    Context 'Authentication Testing' {
        It 'Tests authentication by calling browse API' {
            Mock Invoke-YtmApi { [PSCustomObject]@{ success = $true } }

            Connect-YtmAccount -Cookie 'SAPISID=test123'
            Should -Invoke Invoke-YtmApi -Times 1
        }

        It 'Removes cookies when authentication fails' {
            Mock Invoke-YtmApi { throw 'Auth failed' }

            { Connect-YtmAccount -Cookie 'SAPISID=invalid123' } | Should -Throw
            $stored = Get-YtmStoredCookies
            $stored | Should -BeNullOrEmpty
        }

        It 'Keeps cookies when authentication succeeds' {
            Mock Invoke-YtmApi { [PSCustomObject]@{ success = $true } }

            Connect-YtmAccount -Cookie 'SAPISID=valid123'
            $stored = Get-YtmStoredCookies
            $stored | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Parameter Validation' {
        It 'Cookie parameter is mandatory in Cookie parameter set' {
            $command = Get-Command Connect-YtmAccount
            $cookieParam = $command.Parameters['Cookie']
            $attrs = $cookieParam.Attributes | Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] }
            ($attrs | Where-Object { $_.Mandatory }).Count | Should -BeGreaterThan 0
        }

        It 'Throws when Cookie is empty' {
            { Connect-YtmAccount -Cookie '' } | Should -Throw
        }
    }

    Context 'ShouldProcess Support' {
        It 'Supports -WhatIf' {
            Mock Invoke-YtmApi { [PSCustomObject]@{ success = $true } }

            Connect-YtmAccount -Cookie 'SAPISID=test123' -WhatIf
            $stored = Get-YtmStoredCookies
            $stored | Should -BeNullOrEmpty
        }
    }

    Context 'Parameter Sets' {
        It 'Has Guided as default parameter set' {
            $command = Get-Command Connect-YtmAccount
            $command.DefaultParameterSet | Should -Be 'Guided'
        }

        It 'Has Cookie parameter set' {
            $command = Get-Command Connect-YtmAccount
            $command.ParameterSets.Name | Should -Contain 'Cookie'
        }

        It 'Has Guided parameter set' {
            $command = Get-Command Connect-YtmAccount
            $command.ParameterSets.Name | Should -Contain 'Guided'
        }
    }
}
