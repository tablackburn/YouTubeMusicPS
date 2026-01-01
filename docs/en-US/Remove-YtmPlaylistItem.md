---
external help file: YouTubeMusicPS-help.xml
Module Name: YouTubeMusicPS
online version:
schema: 2.0.0
---

# Remove-YtmPlaylistItem

## SYNOPSIS
Removes a song from a YouTube Music playlist.

## SYNTAX

### Direct (Default)
```
Remove-YtmPlaylistItem -Name <String> -Title <String> [-Artist <String>] [-ProgressAction <ActionPreference>]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

### Pipeline
```
Remove-YtmPlaylistItem -Song <PSObject> [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION
Removes one or more songs from a playlist.
Supports both pipeline input
(from Get-YtmPlaylist) and direct parameter specification.
Requires authentication via Connect-YtmAccount first.

## EXAMPLES

### EXAMPLE 1
```
Get-YtmPlaylist -Name "Chill Vibes" | Where-Object Title -eq "Bad Song" | Remove-YtmPlaylistItem
```

Removes "Bad Song" from the "Chill Vibes" playlist using pipeline.

### EXAMPLE 2
```
Get-YtmPlaylist -Name "Chill Vibes" | Where-Object Artist -match "Nickelback" | Remove-YtmPlaylistItem
```

Removes all Nickelback songs from the playlist.

### EXAMPLE 3
```
Remove-YtmPlaylistItem -Name "Chill Vibes" -Title "Bad Song"
```

Removes "Bad Song" from the playlist using direct parameters.

### EXAMPLE 4
```
Remove-YtmPlaylistItem -Name "Chill Vibes" -Title "Hello" -Artist "Adele"
```

Removes "Hello" by Adele, disambiguating from other songs titled "Hello".

### EXAMPLE 5
```
Get-YtmPlaylist -Name "Chill Vibes" | Where-Object Title -eq "Bad Song" | Remove-YtmPlaylistItem -WhatIf
```

Shows what would be removed without actually removing it.

## PARAMETERS

### -Song
A song object from Get-YtmPlaylist containing PlaylistId, SetVideoId, and VideoId.
Accepts pipeline input.

```yaml
Type: PSObject
Parameter Sets: Pipeline
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Name
The name of the playlist to remove from.
Supports tab completion from your library playlists.

```yaml
Type: String
Parameter Sets: Direct
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Title
The title of the song to remove.

```yaml
Type: String
Parameter Sets: Direct
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Artist
Optional artist name to disambiguate when multiple songs have the same title.

```yaml
Type: String
Parameter Sets: Direct
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
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

## NOTES

## RELATED LINKS
