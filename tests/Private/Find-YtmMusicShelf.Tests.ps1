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
Describe 'Find-YtmMusicShelf' {
    Context 'Finding Music Shelf in Response' {
        It 'Returns musicShelfRenderer when found in sectionList' {
            $response = [PSCustomObject]@{
                contents = [PSCustomObject]@{
                    singleColumnBrowseResultsRenderer = [PSCustomObject]@{
                        tabs = @(
                            [PSCustomObject]@{
                                tabRenderer = [PSCustomObject]@{
                                    content = [PSCustomObject]@{
                                        sectionListRenderer = [PSCustomObject]@{
                                            contents = @(
                                                [PSCustomObject]@{
                                                    musicShelfRenderer = [PSCustomObject]@{
                                                        contents = @('song1', 'song2')
                                                    }
                                                }
                                            )
                                        }
                                    }
                                }
                            }
                        )
                    }
                }
            }

            $result = Find-YtmMusicShelf -Response $response
            $result | Should -Not -BeNullOrEmpty
            $result.contents | Should -Contain 'song1'
        }

        It 'Returns musicShelfRenderer when nested in itemSectionRenderer' {
            $response = [PSCustomObject]@{
                contents = [PSCustomObject]@{
                    singleColumnBrowseResultsRenderer = [PSCustomObject]@{
                        tabs = @(
                            [PSCustomObject]@{
                                tabRenderer = [PSCustomObject]@{
                                    content = [PSCustomObject]@{
                                        sectionListRenderer = [PSCustomObject]@{
                                            contents = @(
                                                [PSCustomObject]@{
                                                    itemSectionRenderer = [PSCustomObject]@{
                                                        contents = @(
                                                            [PSCustomObject]@{
                                                                musicShelfRenderer = [PSCustomObject]@{
                                                                    contents = @('nested-song')
                                                                }
                                                            }
                                                        )
                                                    }
                                                }
                                            )
                                        }
                                    }
                                }
                            }
                        )
                    }
                }
            }

            $result = Find-YtmMusicShelf -Response $response
            $result | Should -Not -BeNullOrEmpty
            $result.contents | Should -Contain 'nested-song'
        }

        It 'Returns $null when response has no contents property' {
            $response = [PSCustomObject]@{
                otherProperty = 'value'
            }

            $result = Find-YtmMusicShelf -Response $response
            $result | Should -BeNullOrEmpty
        }

        It 'Returns $null when tabs array is empty' {
            $response = [PSCustomObject]@{
                contents = [PSCustomObject]@{
                    singleColumnBrowseResultsRenderer = [PSCustomObject]@{
                        tabs = @()
                    }
                }
            }

            $result = Find-YtmMusicShelf -Response $response
            $result | Should -BeNullOrEmpty
        }

        It 'Returns $null when no musicShelfRenderer exists' {
            $response = [PSCustomObject]@{
                contents = [PSCustomObject]@{
                    singleColumnBrowseResultsRenderer = [PSCustomObject]@{
                        tabs = @(
                            [PSCustomObject]@{
                                tabRenderer = [PSCustomObject]@{
                                    content = [PSCustomObject]@{
                                        sectionListRenderer = [PSCustomObject]@{
                                            contents = @(
                                                [PSCustomObject]@{
                                                    gridRenderer = [PSCustomObject]@{
                                                        items = @('item1')
                                                    }
                                                }
                                            )
                                        }
                                    }
                                }
                            }
                        )
                    }
                }
            }

            $result = Find-YtmMusicShelf -Response $response
            $result | Should -BeNullOrEmpty
        }

        It 'Returns $null when tabRenderer has no content property' {
            $response = [PSCustomObject]@{
                contents = [PSCustomObject]@{
                    singleColumnBrowseResultsRenderer = [PSCustomObject]@{
                        tabs = @(
                            [PSCustomObject]@{
                                tabRenderer = [PSCustomObject]@{
                                    title = 'Tab without content'
                                }
                            }
                        )
                    }
                }
            }

            $result = Find-YtmMusicShelf -Response $response
            $result | Should -BeNullOrEmpty
        }

        It 'Returns $null when sectionListRenderer has no contents' {
            $response = [PSCustomObject]@{
                contents = [PSCustomObject]@{
                    singleColumnBrowseResultsRenderer = [PSCustomObject]@{
                        tabs = @(
                            [PSCustomObject]@{
                                tabRenderer = [PSCustomObject]@{
                                    content = [PSCustomObject]@{
                                        sectionListRenderer = [PSCustomObject]@{
                                            header = 'Some header'
                                        }
                                    }
                                }
                            }
                        )
                    }
                }
            }

            $result = Find-YtmMusicShelf -Response $response
            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Parameter Validation' {
        It 'Requires Response parameter' {
            $command = Get-Command Find-YtmMusicShelf
            $command.Parameters['Response'].Attributes.Mandatory | Should -Be $true
        }
    }
}
}
