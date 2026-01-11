function Invoke-YtmAuthenticationPrompt {
    <#
    .SYNOPSIS
        Checks authentication and prompts to connect if not authenticated.

    .DESCRIPTION
        Internal helper function that checks if the user is authenticated.
        If not authenticated and -Force is not specified, prompts the user
        to run Connect-YtmAccount. If the user agrees, runs the connection flow.

        This follows PowerShell's ShouldContinue + Force pattern for interactive prompts.

    .PARAMETER Cmdlet
        The calling cmdlet's $PSCmdlet object, required for ShouldContinue.

    .PARAMETER Force
        If specified, skips the interactive prompt and throws an error immediately
        when not authenticated. Use this for scripting scenarios.

    .OUTPUTS
        Boolean
        Returns $true if authentication is successful (either already authenticated
        or user connected successfully). Throws an error otherwise.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCmdlet]$Cmdlet,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    # Check if already authenticated
    $cookies = Get-YtmStoredCookies
    if ($cookies) {
        return $true
    }

    # Not authenticated - either prompt or throw based on -Force
    if ($Force) {
        throw 'Not authenticated. Please run Connect-YtmAccount first.'
    }

    # Prompt the user to connect
    $title = 'Authentication Required'
    $message = 'You are not connected to YouTube Music. Would you like to connect now?'

    if ($Cmdlet.ShouldContinue($message, $title)) {
        try {
            Connect-YtmAccount
            # Verify connection succeeded
            $cookies = Get-YtmStoredCookies
            if ($cookies) {
                return $true
            }
            throw 'Connection was cancelled or failed.'
        }
        catch {
            throw "Authentication failed: $($_.Exception.Message)"
        }
    }

    # User declined to connect
    throw 'Not authenticated. Please run Connect-YtmAccount first.'
}
