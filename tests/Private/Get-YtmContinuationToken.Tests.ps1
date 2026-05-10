[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSUseDeclaredVarsMoreThanAssignments',
    '',
    Justification = 'Pester BeforeAll/It scope'
)]
param()

BeforeDiscovery {
    if ($null -eq $Env:BHBuildOutput) {
        # Populate BuildHelpers env vars so build.psake.ps1's properties block has
        # the values it needs (BHPSModuleManifest, BHProjectName) — when running
        # via ./build.ps1 this happens before psake; running tests in isolation
        # bypasses that, so we do it here.
        $repoRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
        Set-BuildEnvironment -Path $repoRoot -Force
        $buildFilePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\build.psake.ps1'
        $invokePsakeParameters = @{
            TaskList  = 'Build'
            BuildFile = $buildFilePath
        }
        Invoke-psake @invokePsakeParameters
    }

    $projectRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
    $sourceManifest = Join-Path -Path $projectRoot -ChildPath "$Env:BHProjectName/$Env:BHProjectName.psd1"
    $moduleVersion = (Import-PowerShellDataFile -Path $sourceManifest).ModuleVersion
    $Env:BHBuildOutput = Join-Path -Path $projectRoot -ChildPath "Output/$Env:BHProjectName/$moduleVersion"
}

BeforeAll {
    $moduleManifestPath = Join-Path -Path $Env:BHBuildOutput -ChildPath "$Env:BHProjectName.psd1"
    Get-Module -Name $Env:BHProjectName | Remove-Module -Force -ErrorAction 'Ignore'
    Import-Module -Name $moduleManifestPath -Force -ErrorAction 'Stop'
}

InModuleScope $Env:BHProjectName {
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
}
