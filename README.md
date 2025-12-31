# YouTubeMusicPS

![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20macOS%20%7C%20Linux-lightgrey)
[![AI Assisted](https://img.shields.io/badge/AI-Assisted-blue)](https://claude.ai)
[![License](https://img.shields.io/github/license/tablackburn/YouTubeMusicPS)](LICENSE)

A PowerShell module for managing YouTube Music through automation and scripting.

## Overview

YouTubeMusicPS provides cmdlets for interacting with your YouTube Music library. Currently focused on retrieving liked songs, with more features planned. The module uses cookie-based authentication with a guided setup process that walks you through each step.

## Features

- **Guided Authentication**: Step-by-step interactive setup that walks you through copying cookies from your browser
- **Liked Songs Retrieval**: Get your complete liked songs library with full pagination support
- **Playlist Management**: List playlists, view contents, and remove songs with tab completion
- **Progress Tracking**: Visual progress indicator when retrieving large libraries
- **Pipeline Support**: All cmdlets follow PowerShell conventions for pipeline operations
- **Secure Storage**: Credentials stored locally in your user profile

## Requirements

- PowerShell 5.1 or higher (PowerShell 7+ recommended)
- A YouTube Music account
- A web browser (Chrome, Edge, Firefox, etc.)

## Installation

### From Source

```powershell
# Clone the repository
git clone https://github.com/tablackburn/YouTubeMusicPS.git
cd YouTubeMusicPS

# Import the module
Import-Module ./YouTubeMusicPS/YouTubeMusicPS.psd1
```

## Quick Start

### 1. Connect Your Account

```powershell
# Run the guided authentication
Connect-YtmAccount
```

This opens YouTube Music in your browser and walks you through copying your authentication cookies. The process takes about 30 seconds.

### 2. Get Your Liked Songs

```powershell
# Get all liked songs
Get-YtmLikedMusic

# Get first 50 songs
Get-YtmLikedMusic -Limit 50

# Export to CSV
Get-YtmLikedMusic | Export-Csv -Path liked_songs.csv
```

## Examples

### Retrieving Liked Music

```powershell
# Get all liked songs with full details
$songs = Get-YtmLikedMusic
$songs.Count  # Total number of liked songs

# Display as table
Get-YtmLikedMusic | Format-Table Title, Artist, Album -AutoSize

# Get songs by a specific artist
Get-YtmLikedMusic | Where-Object { $_.Artist -like "*Taylor Swift*" }

# Get total duration of liked songs
$songs = Get-YtmLikedMusic
$totalMinutes = ($songs | Measure-Object -Property DurationSeconds -Sum).Sum / 60
Write-Host "Total: $([math]::Round($totalMinutes / 60, 1)) hours"
```

### Working with Song Data

```powershell
# Each song has these properties
Get-YtmLikedMusic | Select-Object -First 1 | Format-List

# VideoId         : dQw4w9WgXcQ
# Title           : Never Gonna Give You Up
# Artist          : Rick Astley
# ArtistId        : UCuAXFkgsw1L7xaCfnd5JJOw
# Album           : Whenever You Need Somebody
# AlbumId         : MPREb_...
# Duration        : 3:33
# DurationSeconds : 213
# ThumbnailUrl    : https://...
# LikeStatus      : LIKE
```

### Managing Playlists

```powershell
# List all your playlists
Get-YtmPlaylist

# Get songs in a specific playlist (tab completion works!)
Get-YtmPlaylist -Name "Chill Vibes"

# Remove a song from a playlist using pipeline
Get-YtmPlaylist -Name "Chill Vibes" | Where-Object Title -eq "Bad Song" | Remove-YtmPlaylistItem

# Remove multiple songs matching a pattern
Get-YtmPlaylist -Name "Chill Vibes" | Where-Object Artist -match "Nickelback" | Remove-YtmPlaylistItem

# Remove a song using direct parameters
Remove-YtmPlaylistItem -Name "Chill Vibes" -Title "Bad Song"

# Preview what would be removed without actually removing
Get-YtmPlaylist -Name "Chill Vibes" | Where-Object Title -eq "Bad Song" | Remove-YtmPlaylistItem -WhatIf
```

### Disconnecting

```powershell
# Remove stored credentials
Disconnect-YtmAccount
```

## Authentication

### How It Works

YouTube Music uses cookie-based authentication. The `Connect-YtmAccount` command guides you through:

1. Opening YouTube Music in your browser
2. Opening Developer Tools (F12)
3. Going to the Network tab
4. Copying the Cookie header from any request

Your cookies are stored locally and remain valid for approximately 2 years unless you log out of your Google account.

### Manual Authentication

If you prefer to provide cookies directly:

```powershell
Connect-YtmAccount -Cookie 'SAPISID=abc123; HSID=xyz789; ...'
```

### Storage Location

Credentials are stored in:
- **Windows**: `%LOCALAPPDATA%\YouTubeMusicPS\config.json`
- **macOS/Linux**: `~/.config/YouTubeMusicPS/config.json`

### Security Notes

- Cookies are stored in plaintext on your local machine
- Never share your cookies or commit them to source control
- Your YouTube Music cookies grant access to your Google account
- Run `Disconnect-YtmAccount` to remove stored credentials

## Development

### Running Tests

```powershell
# Run all tests
Invoke-Pester -Path ./tests

# Run with code coverage
$config = New-PesterConfiguration
$config.Run.Path = './tests'
$config.CodeCoverage.Enabled = $true
$config.CodeCoverage.Path = './YouTubeMusicPS/**/*.ps1'
Invoke-Pester -Configuration $config
```

### Project Structure

```
YouTubeMusicPS/
├── YouTubeMusicPS/
│   ├── Public/           # Exported cmdlets
│   ├── Private/          # Internal functions
│   ├── YouTubeMusicPS.psd1
│   └── YouTubeMusicPS.psm1
├── tests/                # Pester tests
├── build.ps1            # Build script
└── README.md
```

## Command Reference

| Cmdlet | Description |
|--------|-------------|
| `Connect-YtmAccount` | Authenticate with YouTube Music (guided or manual) |
| `Disconnect-YtmAccount` | Remove stored credentials |
| `Get-YtmLikedMusic` | Retrieve liked songs from your library |
| `Get-YtmPlaylist` | List playlists or get playlist contents |
| `Remove-YtmPlaylistItem` | Remove songs from a playlist |

For detailed help on any cmdlet:

```powershell
Get-Help Connect-YtmAccount -Full
Get-Help Get-YtmLikedMusic -Examples
```

## Roadmap

Future features under consideration:
- Search functionality
- Library statistics
- Album/artist browsing
- Playlist creation and editing

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## Acknowledgments

- Inspired by [ytmusicapi](https://github.com/sigma67/ytmusicapi) (Python) and [YouTubeMusicAPI](https://github.com/Jeevuz/YouTubeMusicAPI) (C#)
- Developed with assistance from [Claude](https://claude.ai) by Anthropic

## License

MIT License - see [LICENSE](LICENSE) for details.

## Resources

- **GitHub Repository**: https://github.com/tablackburn/YouTubeMusicPS
- **ytmusicapi (Python)**: https://github.com/sigma67/ytmusicapi
