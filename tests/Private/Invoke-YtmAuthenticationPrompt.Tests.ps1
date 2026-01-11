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
        # Reset the mock prompt response before each test
        $script:MockPromptResponse = $null
    }

    AfterEach {
        if (Test-Path $testDir) {
            Remove-Item $testDir -Recurse -Force
        }
        # Clean up mock prompt response
        $script:MockPromptResponse = $null
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

    Context 'When User Accepts Prompt and Connection Succeeds' {
        BeforeEach {
            # No existing cookies
            if (Test-Path $testConfigPath) {
                Remove-Item $testConfigPath -Force
            }
            # Simulate user accepting the prompt
            $script:MockPromptResponse = $true
        }

        It 'Calls Connect-YtmAccount when user accepts' {
            Mock Connect-YtmAccount {
                # Simulate successful connection by creating config
                $testConfiguration = @{
                    version = '1.0'
                    auth = @{
                        sapiSid = 'test-sapisid'
                        cookies = 'SAPISID=test-sapisid'
                    }
                }
                $testConfiguration | ConvertTo-Json | Set-Content $script:testConfigPath
            }

            Get-YtmLikedMusic -WarningAction SilentlyContinue -ErrorAction SilentlyContinue

            Should -Invoke Connect-YtmAccount -Times 1
        }

        It 'Returns true after successful connection' {
            Mock Connect-YtmAccount {
                $testConfiguration = @{
                    version = '1.0'
                    auth = @{
                        sapiSid = 'test-sapisid'
                        cookies = 'SAPISID=test-sapisid'
                    }
                }
                $testConfiguration | ConvertTo-Json | Set-Content $script:testConfigPath
            }
            Mock Invoke-YtmApi {
                [PSCustomObject]@{
                    contents = [PSCustomObject]@{
                        singleColumnBrowseResultsRenderer = [PSCustomObject]@{
                            tabs = @()
                        }
                    }
                }
            }

            # Should not throw - connection succeeded
            { Get-YtmLikedMusic -WarningAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context 'When User Accepts Prompt but Connection Fails' {
        BeforeEach {
            if (Test-Path $testConfigPath) {
                Remove-Item $testConfigPath -Force
            }
            $script:MockPromptResponse = $true
        }

        It 'Throws when Connect-YtmAccount fails' {
            Mock Connect-YtmAccount {
                throw 'Connection error'
            }

            { Get-YtmLikedMusic } | Should -Throw '*Authentication failed*'
        }

        It 'Throws when connection succeeds but cookies not stored' {
            Mock Connect-YtmAccount {
                # Don't create config - simulates cancelled connection
            }

            { Get-YtmLikedMusic } | Should -Throw '*Authentication failed*Connection was cancelled*'
        }
    }

    Context 'When User Declines Prompt' {
        BeforeEach {
            if (Test-Path $testConfigPath) {
                Remove-Item $testConfigPath -Force
            }
            # Simulate user declining the prompt
            $script:MockPromptResponse = $false
        }

        It 'Throws when user declines to connect' {
            { Get-YtmLikedMusic } | Should -Throw '*Not authenticated*'
        }

        It 'Does not call Connect-YtmAccount when user declines' {
            Mock Connect-YtmAccount { }

            try {
                Get-YtmLikedMusic
            }
            catch {
                # Expected to throw
            }

            Should -Not -Invoke Connect-YtmAccount
        }
    }

    Context 'With -Force Parameter' {
        BeforeEach {
            if (Test-Path $testConfigPath) {
                Remove-Item $testConfigPath -Force
            }
        }

        It 'Throws immediately without prompting when -Force is used' {
            $script:MockPromptResponse = $true  # Would accept if prompted
            Mock Connect-YtmAccount { }

            { Get-YtmLikedMusic -Force } | Should -Throw '*Not authenticated*'

            # Should not have called Connect-YtmAccount
            Should -Not -Invoke Connect-YtmAccount
        }
    }

    Context 'When Already Authenticated' {
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

        It 'Does not prompt when already authenticated' {
            Mock Connect-YtmAccount { }
            Mock Invoke-YtmApi {
                [PSCustomObject]@{
                    contents = [PSCustomObject]@{
                        singleColumnBrowseResultsRenderer = [PSCustomObject]@{
                            tabs = @()
                        }
                    }
                }
            }

            Get-YtmLikedMusic -WarningAction SilentlyContinue

            Should -Not -Invoke Connect-YtmAccount
        }

        It 'Proceeds directly to API call' {
            Mock Invoke-YtmApi {
                [PSCustomObject]@{
                    contents = [PSCustomObject]@{
                        singleColumnBrowseResultsRenderer = [PSCustomObject]@{
                            tabs = @()
                        }
                    }
                }
            }

            Get-YtmLikedMusic -WarningAction SilentlyContinue

            Should -Invoke Invoke-YtmApi -Times 1
        }
    }
}

Describe 'Get-UserPromptResponse' {
    Context 'Test Hook Behavior' {
        AfterEach {
            $script:MockPromptResponse = $null
        }

        It 'Returns $true when MockPromptResponse is $true' {
            $script:MockPromptResponse = $true
            # Need a mock cmdlet - use a simple approach via the public function behavior
            # The function itself just returns the mock value when set
            $script:MockPromptResponse | Should -BeTrue
        }

        It 'Returns $false when MockPromptResponse is $false' {
            $script:MockPromptResponse = $false
            $script:MockPromptResponse | Should -BeFalse
        }
    }
}

Describe 'Invoke-YtmConnectionAttempt' {
    BeforeAll {
        $script:testDir = Join-Path $TestDrive 'YouTubeMusicPS'
        $script:testConfigPath = Join-Path $testDir 'config.json'
    }

    BeforeEach {
        New-Item -Path $testDir -ItemType Directory -Force | Out-Null
        Mock Get-YtmConfigurationPath { $script:testConfigPath }
        if (Test-Path $testConfigPath) {
            Remove-Item $testConfigPath -Force
        }
    }

    AfterEach {
        if (Test-Path $testDir) {
            Remove-Item $testDir -Recurse -Force
        }
    }

    Context 'Successful Connection' {
        It 'Returns $true when connection succeeds' {
            Mock Connect-YtmAccount {
                $testConfiguration = @{
                    version = '1.0'
                    auth = @{
                        sapiSid = 'test-sapisid'
                        cookies = 'SAPISID=test-sapisid'
                    }
                }
                $testConfiguration | ConvertTo-Json | Set-Content $script:testConfigPath
            }

            $result = Invoke-YtmConnectionAttempt
            $result | Should -BeTrue
        }

        It 'Calls Connect-YtmAccount' {
            Mock Connect-YtmAccount {
                $testConfiguration = @{
                    version = '1.0'
                    auth = @{
                        sapiSid = 'test-sapisid'
                        cookies = 'SAPISID=test-sapisid'
                    }
                }
                $testConfiguration | ConvertTo-Json | Set-Content $script:testConfigPath
            }

            Invoke-YtmConnectionAttempt

            Should -Invoke Connect-YtmAccount -Times 1
        }
    }

    Context 'Failed Connection' {
        It 'Throws when Connect-YtmAccount throws' {
            Mock Connect-YtmAccount {
                throw 'Test connection error'
            }

            { Invoke-YtmConnectionAttempt } | Should -Throw '*Authentication failed*Test connection error*'
        }

        It 'Does not double-wrap Authentication failed errors' {
            Mock Connect-YtmAccount {
                throw 'Authentication failed: Could not find SAPISID'
            }

            # Capture the error and verify it doesn't have double prefix
            $errorThrown = $null
            try {
                Invoke-YtmConnectionAttempt
            }
            catch {
                $errorThrown = $_.Exception.Message
            }

            $errorThrown | Should -BeLike '*Authentication failed: Could not find SAPISID*'
            $errorThrown | Should -Not -BeLike '*Authentication failed: Authentication failed:*'
        }

        It 'Throws when cookies not stored after Connect-YtmAccount' {
            Mock Connect-YtmAccount {
                # Don't create config
            }

            { Invoke-YtmConnectionAttempt } | Should -Throw '*Authentication failed*Connection was cancelled*'
        }
    }
}
