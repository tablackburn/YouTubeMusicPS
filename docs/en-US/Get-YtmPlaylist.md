---
external help file: YouTubeMusicPS-help.xml
Module Name: YouTubeMusicPS
online version:
schema: 2.0.0
---

# Get-YtmPlaylist

## SYNOPSIS
Retrieves playlists or playlist contents from YouTube Music.

## SYNTAX

### List (Default)
```
Get-YtmPlaylist [-Limit <Int32>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### ByName
```
Get-YtmPlaylist [-Name] <String> [-Limit <Int32>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### ById
```
Get-YtmPlaylist -Id <String> [-Limit <Int32>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
When called without parameters, lists all playlists in your library.
When called with -Name or -Id, retrieves the songs in that playlist.
Requires authentication via Connect-YtmAccount first.

## EXAMPLES

### EXAMPLE 1
```
Get-YtmPlaylist
```

Lists all playlists in your library.

### EXAMPLE 2
```
Get-YtmPlaylist -Name "Chill Vibes"
```

Gets all songs in the "Chill Vibes" playlist.

### EXAMPLE 3
```
Get-YtmPlaylist -Name "Chill Vibes" -Limit 50
```

Gets up to 50 songs from the playlist.

### EXAMPLE 4
```
Get-YtmPlaylist -Name "Chill Vibes" | Where-Object Artist -match "Adele"
```

Gets songs by Adele from the playlist.

### EXAMPLE 5
```
Get-YtmPlaylist -Id "PLrAXtmErZgOeiKm4sgNOknGvNjby9efdf"
```

Gets songs from a playlist by its ID.

## PARAMETERS

### -Name
The name of the playlist to retrieve contents for.
Supports tab completion from your library playlists.

```yaml
Type: String
Parameter Sets: ByName
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Id
The playlist ID to retrieve contents for.
Use this for public/community playlists not in your library.

```yaml
Type: String
Parameter Sets: ById
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Limit
Maximum number of items to retrieve.
Default is 0 which retrieves all items.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
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

### YouTubeMusicPS.Playlist (when listing playlists)
### YouTubeMusicPS.Song (when getting playlist contents)
## NOTES

## RELATED LINKS
