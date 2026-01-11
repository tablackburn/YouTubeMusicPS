---
external help file: YouTubeMusicPS-help.xml
Module Name: YouTubeMusicPS
online version:
schema: 2.0.0
---

# Test-YtmAuthentication

## SYNOPSIS
Tests if you are authenticated with YouTube Music.

## SYNTAX

```
Test-YtmAuthentication [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Checks your authentication status with YouTube Music and returns
a status object indicating whether you are connected.

Use this to verify your authentication before running other commands,
or to troubleshoot authentication issues.

## EXAMPLES

### EXAMPLE 1
```
Test-YtmAuthentication
```

Returns an object showing your current authentication status.

### EXAMPLE 2
```
if ((Test-YtmAuthentication).IsAuthenticated) {
    Get-YtmLikedMusic
}
```

Only retrieves liked music if authenticated.

### EXAMPLE 3
```
Test-YtmAuthentication | Format-List
```

Displays detailed authentication status information.

## PARAMETERS

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

### YouTubeMusicPS.AuthenticationStatus
### Object with properties:
### - IsAuthenticated: Whether you are currently authenticated
### - HasStoredCredentials: Whether credentials are stored (may be expired)
### - Message: Human-readable status message
## NOTES

## RELATED LINKS
