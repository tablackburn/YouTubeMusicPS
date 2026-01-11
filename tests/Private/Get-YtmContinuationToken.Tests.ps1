BeforeAll {
    . "$PSScriptRoot\..\Shared.ps1"
}

Describe 'Get-YtmContinuationToken' {
    Context 'Extracting Continuation Token' {
        It 'Returns continuation token when present' {
            $musicShelf = [PSCustomObject]@{
                contents = @('song1', 'song2')
                continuations = @(
                    [PSCustomObject]@{
                        nextContinuationData = [PSCustomObject]@{
                            continuation = 'token123abc'
                        }
                    }
                )
            }

            $result = Get-YtmContinuationToken -MusicShelf $musicShelf
            $result | Should -Be 'token123abc'
        }

        It 'Returns $null when no continuations property exists' {
            $musicShelf = [PSCustomObject]@{
                contents = @('song1', 'song2')
            }

            $result = Get-YtmContinuationToken -MusicShelf $musicShelf
            $result | Should -BeNullOrEmpty
        }

        It 'Returns $null when continuations array is empty' {
            $musicShelf = [PSCustomObject]@{
                contents = @('song1')
                continuations = @()
            }

            $result = Get-YtmContinuationToken -MusicShelf $musicShelf
            $result | Should -BeNullOrEmpty
        }

        It 'Returns $null when continuations is null' {
            $musicShelf = [PSCustomObject]@{
                contents = @('song1')
                continuations = $null
            }

            $result = Get-YtmContinuationToken -MusicShelf $musicShelf
            $result | Should -BeNullOrEmpty
        }

        It 'Returns $null when nextContinuationData is missing' {
            $musicShelf = [PSCustomObject]@{
                contents = @('song1')
                continuations = @(
                    [PSCustomObject]@{
                        reloadContinuationData = [PSCustomObject]@{
                            continuation = 'reload-token'
                        }
                    }
                )
            }

            $result = Get-YtmContinuationToken -MusicShelf $musicShelf
            $result | Should -BeNullOrEmpty
        }

        It 'Uses first continuation item when multiple exist' {
            $musicShelf = [PSCustomObject]@{
                contents = @('song1')
                continuations = @(
                    [PSCustomObject]@{
                        nextContinuationData = [PSCustomObject]@{
                            continuation = 'first-token'
                        }
                    },
                    [PSCustomObject]@{
                        nextContinuationData = [PSCustomObject]@{
                            continuation = 'second-token'
                        }
                    }
                )
            }

            $result = Get-YtmContinuationToken -MusicShelf $musicShelf
            $result | Should -Be 'first-token'
        }
    }

    Context 'Parameter Validation' {
        It 'Requires MusicShelf parameter' {
            $command = Get-Command Get-YtmContinuationToken
            $command.Parameters['MusicShelf'].Attributes.Mandatory | Should -Be $true
        }
    }
}
