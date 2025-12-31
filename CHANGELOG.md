# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

[0.2.0]: https://github.com/tablackburn/YouTubeMusicPS/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/tablackburn/YouTubeMusicPS/tree/v0.1.0
