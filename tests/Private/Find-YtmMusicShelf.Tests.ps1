BeforeAll {
    . "$PSScriptRoot\..\Shared.ps1"
}

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
