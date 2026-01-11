function Find-YtmMusicShelf {
    <#
    .SYNOPSIS
        Finds the music shelf renderer in a YouTube Music API response.

    .DESCRIPTION
        Navigates the complex nested structure of YouTube Music API responses
        to locate the musicShelfRenderer that contains the list of songs.
        This is used by Get-YtmLikedMusic to find songs in the initial browse response.

    .PARAMETER Response
        The raw API response from a YouTube Music browse endpoint.

    .OUTPUTS
        PSCustomObject
        The musicShelfRenderer object if found, otherwise $null.

    .EXAMPLE
        $musicShelf = Find-YtmMusicShelf -Response $apiResponse
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Response
    )

    $musicShelf = $null

    if ($Response.PSObject.Properties['contents']) {
        $tabs = $Response.contents.singleColumnBrowseResultsRenderer.tabs
        if ($tabs) {
            foreach ($tab in $tabs) {
                $tabRenderer = $tab.tabRenderer
                if ($tabRenderer.PSObject.Properties['content']) {
                    $sectionList = $tabRenderer.content.sectionListRenderer
                    if ($sectionList.PSObject.Properties['contents']) {
                        foreach ($section in $sectionList.contents) {
                            if ($section.PSObject.Properties['itemSectionRenderer']) {
                                $itemSection = $section.itemSectionRenderer
                                if ($itemSection.PSObject.Properties['contents']) {
                                    foreach ($item in $itemSection.contents) {
                                        if ($item.PSObject.Properties['musicShelfRenderer']) {
                                            $musicShelf = $item.musicShelfRenderer
                                            break
                                        }
                                    }
                                }
                            }
                            elseif ($section.PSObject.Properties['musicShelfRenderer']) {
                                $musicShelf = $section.musicShelfRenderer
                                break
                            }
                        }
                    }
                }
            }
        }
    }

    return $musicShelf
}
