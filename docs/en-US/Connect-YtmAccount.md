---
external help file: YouTubeMusicPS-help.xml
Module Name: YouTubeMusicPS
online version:
schema: 2.0.0
---

# Connect-YtmAccount

## SYNOPSIS
Authenticates with YouTube Music.

## SYNTAX

### Guided (Default)
```
Connect-YtmAccount [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### Cookie
```
Connect-YtmAccount -Cookie <String> [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION
Authenticates with YouTube Music by guiding you through copying cookies
from your browser.
This is a one-time setup that takes about 30 seconds.

When run without parameters, opens YouTube Music in your browser and
walks you through the steps to copy your authentication cookies.

Alternatively, use -Cookie to provide cookies directly if you've already
copied them.

## EXAMPLES

### EXAMPLE 1
```
Connect-YtmAccount
```

Opens YouTube Music and guides you through the authentication process.

### EXAMPLE 2
```
Connect-YtmAccount -Cookie 'SAPISID=abc123; HSID=xyz789; ...'
```

Authenticates using previously copied cookies.

## PARAMETERS

### -Cookie
The full cookie string from your browser.
If not provided, you'll be guided through the process interactively.

```yaml
Type: String
Parameter Sets: Cookie
Aliases:

Required: True
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

### None
### Displays a success message if authentication is valid.
## NOTES
Cookies typically remain valid for about 2 years unless you log out
of your Google account.

## RELATED LINKS
