function Test-YtmAuthentication {
    <#
    .SYNOPSIS
        Tests if you are authenticated with YouTube Music.

    .DESCRIPTION
        Checks your authentication status with YouTube Music and returns
        a status object indicating whether you are connected.

        Use this to verify your authentication before running other commands,
        or to troubleshoot authentication issues.

    .EXAMPLE
        Test-YtmAuthentication

        Returns an object showing your current authentication status.

    .EXAMPLE
        if ((Test-YtmAuthentication).IsAuthenticated) {
            Get-YtmLikedMusic
        }

        Only retrieves liked music if authenticated.

    .EXAMPLE
        Test-YtmAuthentication | Format-List

        Displays detailed authentication status information.

    .OUTPUTS
        YouTubeMusicPS.AuthenticationStatus

        Object with properties:
        - IsAuthenticated: Whether you are currently authenticated
        - HasStoredCredentials: Whether credentials are stored (may be expired)
        - Message: Human-readable status message
    #>
    [CmdletBinding()]
    [OutputType('YouTubeMusicPS.AuthenticationStatus')]
    param ()

    $result = [PSCustomObject]@{
        PSTypeName           = 'YouTubeMusicPS.AuthenticationStatus'
        IsAuthenticated      = $false
        HasStoredCredentials = $false
        Message              = 'Not authenticated. Run Connect-YtmAccount to connect.'
    }

    # Check if we have stored credentials
    $cookies = Get-YtmStoredCookies
    if (-not $cookies) {
        return $result
    }

    $result.HasStoredCredentials = $true

    # Test if the credentials are still valid by making an API call
    Write-Verbose "Testing stored credentials with API call..."
    try {
        $testBody = @{
            browseId = 'FEmusic_liked_videos'
        }
        $response = Invoke-YtmApi -Endpoint 'browse' -Body $testBody -ErrorAction Stop

        if ($response) {
            $result.IsAuthenticated = $true
            $result.Message = 'Connected to YouTube Music.'
        }
    }
    catch {
        $errorMessage = $_.Exception.Message
        if ($errorMessage -match 'expired|401|403') {
            $result.Message = 'Credentials have expired. Run Connect-YtmAccount to reconnect.'
        }
        else {
            $result.Message = "Authentication test failed: $errorMessage"
        }
    }

    return $result
}
