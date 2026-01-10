BeforeAll {
    . "$PSScriptRoot\..\Shared.ps1"
}

Describe 'Start-YtmGuidedAuth' {
    BeforeEach {
        # Default mocks - user proceeds through all prompts
        Mock Write-Host { }
        Mock Start-Process { }
        Mock Read-Host { 'y' }
        Mock Get-Clipboard { 'SAPISID=abc123xyz; SSID=other; SID=123' }
    }

    Context 'User Cancellation' {
        It 'Returns $null when user declines to begin' {
            Mock Read-Host { 'n' }

            $result = Start-YtmGuidedAuth
            $result | Should -BeNullOrEmpty
        }

        It 'Returns $null when user enters anything other than Y/y' {
            Mock Read-Host { 'no' }

            $result = Start-YtmGuidedAuth
            $result | Should -BeNullOrEmpty
        }

        It 'Proceeds when user enters lowercase y' {
            Mock Read-Host { 'y' }

            $result = Start-YtmGuidedAuth
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Proceeds when user enters uppercase Y' {
            Mock Read-Host { 'Y' }

            $result = Start-YtmGuidedAuth
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Proceeds when user presses Enter (empty response)' {
            Mock Read-Host { '' }

            $result = Start-YtmGuidedAuth
            $result | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Browser Launch' {
        It 'Calls Start-Process with YouTube Music URL' {
            Start-YtmGuidedAuth

            Should -Invoke Start-Process -Times 1 -ParameterFilter {
                $FilePath -eq 'https://music.youtube.com'
            }
        }

        It 'Does not launch browser if user cancels' {
            Mock Read-Host { 'n' }

            Start-YtmGuidedAuth

            Should -Invoke Start-Process -Times 0
        }
    }

    Context 'Clipboard Validation' {
        It 'Returns $null when clipboard is empty' {
            Mock Get-Clipboard { '' }

            $result = Start-YtmGuidedAuth
            $result | Should -BeNullOrEmpty
        }

        It 'Returns $null when clipboard is whitespace only' {
            Mock Get-Clipboard { '   ' }

            $result = Start-YtmGuidedAuth
            $result | Should -BeNullOrEmpty
        }

        It 'Throws when clipboard returns $null' {
            Mock Get-Clipboard { $null }

            # Current implementation calls .Trim() on null which throws
            { Start-YtmGuidedAuth } | Should -Throw
        }

        It 'Returns $null when cookies missing SAPISID' {
            Mock Get-Clipboard { 'SSID=xyz; SID=123; other=value' }

            $result = Start-YtmGuidedAuth
            $result | Should -BeNullOrEmpty
        }

        It 'Returns cookie string when SAPISID is present' {
            Mock Get-Clipboard { 'SAPISID=abc123; SSID=xyz' }

            $result = Start-YtmGuidedAuth
            $result | Should -Be 'SAPISID=abc123; SSID=xyz'
        }

        It 'Returns cookie string when __Secure-3PAPISID is present' {
            Mock Get-Clipboard { '__Secure-3PAPISID=secure456; SSID=xyz' }

            $result = Start-YtmGuidedAuth
            $result | Should -Be '__Secure-3PAPISID=secure456; SSID=xyz'
        }

        It 'Trims whitespace from clipboard content' {
            Mock Get-Clipboard { '  SAPISID=abc123; SSID=xyz  ' }

            $result = Start-YtmGuidedAuth
            $result | Should -Be 'SAPISID=abc123; SSID=xyz'
        }
    }

    Context 'User Prompts' {
        It 'Calls Read-Host multiple times for each step' {
            Start-YtmGuidedAuth

            # Initial prompt + 4 step prompts = 5 total
            Should -Invoke Read-Host -Times 5
        }
    }
}
