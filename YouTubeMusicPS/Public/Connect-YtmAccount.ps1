function Connect-YtmAccount {
    <#
    .SYNOPSIS
        Authenticates with YouTube Music.

    .DESCRIPTION
        Authenticates with YouTube Music by guiding you through copying cookies
        from your browser. This is a one-time setup that takes about 30 seconds.

        When run without parameters, opens YouTube Music in your browser and
        walks you through the steps to copy your authentication cookies.

        Alternatively, use -Cookie to provide cookies directly if you've already
        copied them.

    .PARAMETER Cookie
        The full cookie string from your browser.
        If not provided, you'll be guided through the process interactively.

    .EXAMPLE
        Connect-YtmAccount

        Opens YouTube Music and guides you through the authentication process.

    .EXAMPLE
        Connect-YtmAccount -Cookie 'SAPISID=abc123; HSID=xyz789; ...'

        Authenticates using previously copied cookies.

    .OUTPUTS
        None
        Displays a success message if authentication is valid.

    .NOTES
        Cookies typically remain valid for about 2 years unless you log out
        of your Google account.
    #>
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'Guided')]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'Cookie')]
        [ValidateNotNullOrEmpty()]
        [string]$Cookie
    )

    if ($PSCmdlet.ParameterSetName -eq 'Cookie') {
        $cookieString = $Cookie.Trim()
    }
    else {
        # Guided flow
        if (-not $PSCmdlet.ShouldProcess('YouTubeMusicPS', 'Open browser for guided authentication')) {
            return
        }

        $cookieString = Start-YtmGuidedAuth
        if (-not $cookieString) {
            return
        }
    }

    # Extract SAPISID from cookies
    $sapiSid = $null
    if ($cookieString -match '__Secure-3PAPISID=([^;]+)') {
        $sapiSid = $Matches[1]
        Write-Verbose "Extracted __Secure-3PAPISID from cookies"
    }
    elseif ($cookieString -match 'SAPISID=([^;]+)') {
        $sapiSid = $Matches[1]
        Write-Verbose "Extracted SAPISID from cookies"
    }
    else {
        throw "Could not find SAPISID or __Secure-3PAPISID in the provided cookies. Please ensure you copied the full cookie string."
    }

    # Validate SAPISID format (should contain only alphanumeric, underscore, dash, slash, dot)
    if ($sapiSid -notmatch '^[A-Za-z0-9_/\-\.]+$') {
        throw "Extracted SAPISID contains unexpected characters. Please ensure you copied the cookie string correctly."
    }

    Set-YtmStoredCookies -SapiSid $sapiSid -Cookies $cookieString

    # Test the authentication
    Write-Verbose "Testing authentication..."
    try {
        $testBody = @{
            browseId = 'FEmusic_liked_videos'
        }
        $response = Invoke-YtmApi -Endpoint 'browse' -Body $testBody

        if ($response) {
            Write-Information "Successfully connected to YouTube Music!" -InformationAction Continue
        }
    }
    catch {
        Remove-YtmStoredCookies
        throw "Authentication failed: $($_.Exception.Message). Please check your cookies and try again."
    }
}
