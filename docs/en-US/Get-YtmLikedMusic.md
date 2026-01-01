---
external help file: YouTubeMusicPS-help.xml
Module Name: YouTubeMusicPS
online version:
schema: 2.0.0
---

# Get-YtmLikedMusic

## SYNOPSIS
Retrieves your liked songs from YouTube Music.

## SYNTAX

```
Get-YtmLikedMusic [[-Limit] <Int32>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Gets the list of songs you have liked (thumbs up) on YouTube Music.
Requires authentication via Connect-YtmAccount first.
Supports pagination to retrieve your entire library.

## EXAMPLES

### EXAMPLE 1
```
Get-YtmLikedMusic
```

Gets all liked songs.

### EXAMPLE 2
```
Get-YtmLikedMusic -Limit 50
```

Gets up to 50 liked songs.

### EXAMPLE 3
```
Get-YtmLikedMusic | Select-Object Title, Artist, Album
```

Gets liked songs and displays selected properties.

### EXAMPLE 4
```
Get-YtmLikedMusic | Export-Csv -Path liked_songs.csv
```

Exports all liked songs to a CSV file.

## PARAMETERS

### -Limit
Maximum number of songs to retrieve.
Default is 0 which retrieves all songs.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProgressAction
{{ Fill ProgressAction Description }}

```yaml
Type: ActionPreference
Parameter Sets: (All)
Aliases: proga

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### YouTubeMusicPS.Song
### Objects with properties:
### - VideoId: YouTube video identifier
### - Title: Song title
### - Artist: Artist name(s)
### - ArtistId: Artist channel ID
### - Album: Album name (if available)
### - AlbumId: Album browse ID
### - Duration: Duration as string (e.g., "3:45")
### - DurationSeconds: Duration in seconds
### - ThumbnailUrl: URL to thumbnail image
### - LikeStatus: Current like status
## NOTES

## RELATED LINKS
