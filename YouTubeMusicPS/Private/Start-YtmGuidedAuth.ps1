function Start-YtmGuidedAuth {
    <#
    .SYNOPSIS
        Guides the user through copying cookies from their browser.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param ()

    # Introduction
    Write-Host ""
    Write-Host "=== YouTube Music Authentication ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "This will walk you through a one-time setup to connect your YouTube Music account."
    Write-Host ""
    Write-Host "What will happen:" -ForegroundColor Yellow
    Write-Host "  1. Your browser will open to YouTube Music"
    Write-Host "  2. You'll copy a cookie value from the browser's Developer Tools"
    Write-Host "  3. Come back here - this terminal will guide you through each step"
    Write-Host ""
    Write-Host "This takes about 30 seconds. Your cookies stay on your computer and are valid"
    Write-Host "for about 2 years."
    Write-Host ""

    # Prompt to open browser
    $response = Read-Host "Ready to begin? (Y/n)"
    if ($response -and $response -notmatch '^[Yy]') {
        Write-Host ""
        Write-Host "Authentication cancelled." -ForegroundColor Yellow
        return $null
    }

    # Step 1: Open browser
    Write-Host ""
    Write-Host "Step 1 of 5: Opening YouTube Music..." -ForegroundColor Yellow
    Write-Host ""

    Start-Process "https://music.youtube.com"

    Write-Host "  A browser window should have opened."
    Write-Host "  If you're not logged in, please sign in to your Google account now."
    Write-Host ""
    Write-Host "  Press Enter here when you see the YouTube Music home page..."
    $null = Read-Host

    # Step 2: Open DevTools
    Write-Host ""
    Write-Host "Step 2 of 5: Open Developer Tools" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  In the browser, press " -NoNewline
    Write-Host "F12" -ForegroundColor Green -NoNewline
    Write-Host " to open Developer Tools"
    Write-Host "  (or right-click anywhere and select 'Inspect')"
    Write-Host ""
    Write-Host "  Press Enter here when Developer Tools is open..."
    $null = Read-Host

    # Step 3: Go to Network tab
    Write-Host ""
    Write-Host "Step 3 of 5: Go to the Network tab" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  In Developer Tools, click the " -NoNewline
    Write-Host "Network" -ForegroundColor Green -NoNewline
    Write-Host " tab at the top"
    Write-Host ""
    Write-Host "  Press Enter here when you're on the Network tab..."
    $null = Read-Host

    # Step 4: Find and copy cookie
    Write-Host ""
    Write-Host "Step 4 of 5: Copy the cookie value" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  1. " -NoNewline
    Write-Host "Refresh the page" -ForegroundColor Green -NoNewline
    Write-Host " (press F5 or click the refresh button)"
    Write-Host ""
    Write-Host "  2. In the Network tab, you'll see a list of requests appear."
    Write-Host "     Click on " -NoNewline
    Write-Host "any request" -ForegroundColor Green -NoNewline
    Write-Host " (the first one is fine)"
    Write-Host ""
    Write-Host "  3. In the panel that opens, look for:" -NoNewline
    Write-Host ""
    Write-Host "     Request Headers" -ForegroundColor White
    Write-Host "       Cookie: " -ForegroundColor Gray -NoNewline
    Write-Host "[long text...]" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  4. " -NoNewline
    Write-Host "Triple-click" -ForegroundColor Green -NoNewline
    Write-Host " the cookie value to select it all, then " -NoNewline
    Write-Host "Ctrl+C" -ForegroundColor Green -NoNewline
    Write-Host " to copy"
    Write-Host ""
    Write-Host "  Press Enter here when you've copied the cookie..."
    $null = Read-Host

    # Step 5: Read from clipboard
    Write-Host ""
    Write-Host "Step 5 of 5: Verifying..." -ForegroundColor Yellow
    Write-Host ""

    $clipboardContent = (Get-Clipboard -Raw).Trim()

    if ([string]::IsNullOrWhiteSpace($clipboardContent)) {
        Write-Host "  Clipboard is empty." -ForegroundColor Red
        Write-Host "  Please go back and copy the cookie value, then run Connect-YtmAccount again."
        return $null
    }

    # Basic validation - check for expected cookie patterns
    if ($clipboardContent -notmatch 'SAPISID|__Secure-3PAPISID') {
        Write-Host "  The clipboard doesn't appear to contain YouTube Music cookies." -ForegroundColor Red
        Write-Host ""
        Write-Host "  Make sure you:" -ForegroundColor Yellow
        Write-Host "    - Are logged in to YouTube Music"
        Write-Host "    - Copied the value next to 'Cookie:' in Request Headers"
        Write-Host "    - Used 'Copy value' (not 'Copy')"
        Write-Host ""
        Write-Host "  Run Connect-YtmAccount again to retry."
        return $null
    }

    Write-Host "  Cookies verified!" -ForegroundColor Green
    Write-Host ""

    return $clipboardContent
}
