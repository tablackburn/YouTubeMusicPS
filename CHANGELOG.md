# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.4.0] - 2026-01-11

### Added

- Add format file for cleaner default output display
  - Song objects now display as table with Title, Artist, Album, Duration columns
  - Playlist objects display as table with Name, TrackCount columns
  - AuthenticationStatus displays as list with all properties
  - All properties remain accessible via `Select-Object *` or by name

## [0.3.0] - 2026-01-11

### Added

- Add `Test-YtmAuthentication` cmdlet to check authentication status
  - Returns detailed status object with `IsAuthenticated`, `HasStoredCredentials`, and `Message`
  - Makes API call to verify credentials are still valid
- Add interactive authentication prompt when running commands without being connected
  - Prompts "Would you like to connect now?" with Y/N option
  - Automatically runs `Connect-YtmAccount` if user accepts
- Add `-Force` parameter to `Get-YtmLikedMusic`, `Get-YtmPlaylist`, and `Remove-YtmPlaylistItem`
  - Skips interactive prompt and throws error immediately (for scripting scenarios)

### Changed

- Improve error messages to distinguish between authentication issues, empty libraries, and API parsing errors
- Error messages now avoid nested "Authentication failed:" prefixes

## [0.2.2] - 2026-01-10

### Changed

- Refactor nested helper functions to module-scope for improved performance
- Add deep null checks in API response parsing to prevent potential errors
- Add playlist ID format validation to reject malformed inputs early
- Add error handling for track count parsing to handle edge cases gracefully

## [0.2.1] - 2026-01-10

### Fixed

- Fix duration parsing to handle malformed input gracefully instead of throwing
- Fix PowerShell 5.1 compatibility by checking if `$IsWindows` variable exists before using it
- Add SAPISID cookie format validation to reject malformed values
- Update README to document actual config storage location priority (OneDrive > Documents > LocalAppData)
- Fix CI workflow job names to match branch protection required status checks

## [0.2.0] - 2025-01-01

### Added

- Add `Get-YtmPlaylist` cmdlet for playlist management
  - List all playlists when called without parameters
  - Get playlist contents with `-Name` or `-Id` parameter
  - Tab completion for playlist names
- Add `Remove-YtmPlaylistItem` cmdlet for removing songs from playlists
  - Pipeline support: songs from `Get-YtmPlaylist` carry their `PlaylistId`
  - Direct parameter support with `-Name`, `-Title`, and optional `-Artist`
  - Full `-WhatIf` and `-Confirm` support
- Add `ConvertTo-YtmPlaylist` private helper for parsing playlist metadata
- Add `SetVideoId` and `PlaylistId` properties to song objects for playlist operations

## [0.1.0] - 2024-12-30

### Added

- Initial release of YouTubeMusicPS module
- Add `Connect-YtmAccount` cmdlet with guided and manual authentication
- Add `Disconnect-YtmAccount` cmdlet for removing stored credentials
- Add `Get-YtmLikedMusic` cmdlet for retrieving liked songs with pagination
- Add cross-platform configuration storage
- Add comprehensive Pester test suite

[0.4.0]: https://github.com/tablackburn/YouTubeMusicPS/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/tablackburn/YouTubeMusicPS/compare/v0.2.2...v0.3.0
[0.2.2]: https://github.com/tablackburn/YouTubeMusicPS/compare/v0.2.1...v0.2.2
[0.2.1]: https://github.com/tablackburn/YouTubeMusicPS/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/tablackburn/YouTubeMusicPS/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/tablackburn/YouTubeMusicPS/tree/v0.1.0
