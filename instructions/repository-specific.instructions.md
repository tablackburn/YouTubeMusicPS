---
applyTo: '**/*'
description: 'Repository-specific instructions for YouTubeMusicPS'
---

# YouTubeMusicPS Repository Instructions

This file contains instructions specific to the YouTubeMusicPS PowerShell module. These
instructions supplement the standard AIM modules and take precedence for repository-specific
conventions.

## Project Overview

YouTubeMusicPS is a PowerShell module for interacting with YouTube Music through automation and
scripting. It uses cookie-based authentication and provides cmdlets for managing the user's
YouTube Music library.

## Module Structure

```text
YouTubeMusicPS/
├── YouTubeMusicPS/
│   ├── Public/           # Exported cmdlets (user-facing functions)
│   ├── Private/          # Internal helper functions
│   ├── YouTubeMusicPS.psd1   # Module manifest
│   └── YouTubeMusicPS.psm1   # Module loader
├── tests/                # Pester tests
│   ├── Public/           # Tests for public functions
│   ├── Private/          # Tests for private functions
│   └── Shared.ps1        # Shared test utilities
├── instructions/         # AI agent instructions (AIM)
├── build.ps1            # Build entry point
└── build.psake.ps1      # psake build tasks
```

## Naming Conventions

### Function Prefix

All public cmdlets use the `Ytm` prefix (short for YouTube Music):

- `Connect-YtmAccount`
- `Disconnect-YtmAccount`
- `Get-YtmLikedMusic`

### Private Function Naming

Private functions also use the `Ytm` prefix but are not exported:

- `Get-YtmConfiguration`
- `Invoke-YtmApi`
- `Get-YtmClientContext`

## API Interaction

### YouTube Music API

The module interacts with YouTube Music's internal API endpoints. Key considerations:

- All API calls go through `Invoke-YtmApi` in the Private folder
- Authentication requires specific cookies: `SAPISID`, `HSID`, `SSID`, `APISID`, `SID`
- The `SAPISIDHASH` header must be generated for each request using `Get-YtmSapiSidHash`
- API responses use nested JSON structures that require careful parsing

### Client Context

Each API request requires a client context object. Use `Get-YtmClientContext` to generate this.
The context includes:

- Client name and version
- User agent information
- Language and location settings

## Testing Requirements

### Pester Tests

- All public functions must have corresponding tests in `tests/Public/`
- All private functions should have tests in `tests/Private/`
- Use the `Shared.ps1` file for common test utilities and mock data
- Mock external API calls - never make real HTTP requests in tests

### Running Tests

```powershell
# Run all tests
Invoke-Pester -Path ./tests

# Run with coverage
$config = New-PesterConfiguration
$config.Run.Path = './tests'
$config.CodeCoverage.Enabled = $true
$config.CodeCoverage.Path = './YouTubeMusicPS/**/*.ps1'
Invoke-Pester -Configuration $config
```

## Security Considerations

### Cookie Handling

- Cookies contain sensitive authentication data
- Never log or display full cookie values
- Store cookies securely using the configuration system
- Warn users about cookie security in documentation

### Configuration Storage

- Configuration is stored in the user's local app data folder
- Windows: `%LOCALAPPDATA%\YouTubeMusicPS\config.json`
- macOS/Linux: `~/.config/YouTubeMusicPS/config.json`
- Configuration files contain sensitive data and should never be committed

## Error Handling

### API Errors

- Check for HTTP status codes and handle appropriately
- YouTube Music API may return errors in the response body even with 200 status
- Parse error messages from the `error` field in responses
- Provide user-friendly error messages for common issues (authentication expired, rate limiting)

### Authentication Errors

- If cookies are invalid or expired, prompt user to re-authenticate
- Use `Disconnect-YtmAccount` to clear invalid credentials
- Guide users through the re-authentication process

## Future Development

### Planned Features

The README mentions these features are under consideration:

- Search functionality
- Playlist management
- Library statistics
- Album/artist browsing

When implementing new features:

1. Follow existing patterns in the codebase
2. Add both public cmdlets and private helper functions as needed
3. Include comprehensive Pester tests
4. Update the README with new cmdlet documentation
5. Follow the existing error handling patterns

## Dependencies

- PowerShell 5.1 or higher (PowerShell 7+ recommended)
- No external module dependencies for runtime
- Pester (for testing)
- psake (for build automation)

## Build Process

The module uses psake for build automation:

```powershell
# Run the build
./build.ps1

# Run specific tasks
./build.ps1 -Task Test
./build.ps1 -Task Build
```
