function Invoke-YtmApi {
    <#
    .SYNOPSIS
        Makes authenticated API calls to YouTube Music.

    .DESCRIPTION
        Sends HTTP requests to the YouTube Music API with proper authentication
        headers and client context. Handles response parsing and error handling.

    .PARAMETER Endpoint
        The API endpoint to call (e.g., 'browse', 'search')

    .PARAMETER Body
        The request body as a hashtable. Will be merged with client context.

    .PARAMETER Cookies
        Optional cookie object. If not provided, uses stored cookies.

    .PARAMETER ContinuationToken
        Optional continuation token for pagination.

    .OUTPUTS
        PSCustomObject
        The parsed JSON response from the API

    .EXAMPLE
        $body = @{ browseId = 'FEmusic_liked_videos' }
        $response = Invoke-YtmApi -Endpoint 'browse' -Body $body
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Endpoint,

        [Parameter(Mandatory = $false)]
        [hashtable]$Body = @{},

        [Parameter(Mandatory = $false)]
        [PSCustomObject]$Cookies,

        [Parameter(Mandatory = $false)]
        [string]$ContinuationToken
    )

    # Constants
    $ytmBaseApi = 'https://music.youtube.com/youtubei/v1/'
    $ytmParams = '?alt=json&key=AIzaSyC9XL3ZjWddXya6X74dJoCTL-WEYFDNX30'
    $userAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
    $origin = 'https://music.youtube.com'

    # Get cookies if not provided
    if (-not $Cookies) {
        $Cookies = Get-YtmStoredCookies
        if (-not $Cookies) {
            throw 'Not authenticated. Please run Connect-YtmAccount first.'
        }
    }

    # Build authorization header
    $authorization = Get-YtmSapiSidHash -SapiSid $Cookies.SapiSid -Origin $origin

    # Build headers
    $headers = @{
        'User-Agent'     = $userAgent
        'Origin'         = $origin
        'Authorization'  = $authorization
        'Cookie'         = $Cookies.Cookies
    }

    # Get client context and merge with body
    $context = Get-YtmClientContext
    $requestBody = $context.Clone()
    foreach ($key in $Body.Keys) {
        $requestBody[$key] = $Body[$key]
    }

    # Build URL
    $url = $ytmBaseApi + $Endpoint + $ytmParams
    if ($ContinuationToken) {
        $url += "&ctoken=$ContinuationToken&continuation=$ContinuationToken"
    }

    Write-Verbose "Making request to: $url"

    try {
        $jsonBody = $requestBody | ConvertTo-Json -Depth 10
        Write-Verbose "Request body: $jsonBody"

        $response = Invoke-RestMethod -Uri $url -Method Post -Headers $headers -Body $jsonBody -ContentType 'application/json' -ErrorAction Stop

        return $response
    }
    catch {
        $statusCode = $null
        if ($_.Exception.Response) {
            $statusCode = [int]$_.Exception.Response.StatusCode
        }

        if ($statusCode -eq 401 -or $statusCode -eq 403) {
            throw "Authentication failed. Your cookies may have expired. Please run Connect-YtmAccount again."
        }

        throw "YouTube Music API request failed: $($_.Exception.Message)"
    }
}
