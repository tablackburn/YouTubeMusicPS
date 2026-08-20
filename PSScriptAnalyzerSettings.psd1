@{
    # Scope analysis to actionable severities, dropping Information-level noise.
    #
    # ParseError must be listed. It is how PSScriptAnalyzer reports a file it
    # could not parse at all, and naming Severity without it silently hides
    # syntax-broken files: a file with a missing brace reports zero findings
    # under @('Error', 'Warning'). Microsoft's documentation states this
    # directly -- "To suppress ParseErrors, don't include it as a value in the
    # Severity parameter" -- which is exactly what must not happen to a lint gate.
    Severity     = @('ParseError', 'Error', 'Warning')
    ExcludeRules = @(
        # This module reports progress to the user as it works, and that output
        # is the point rather than a debugging leftover. Write-Information would
        # be invisible without -InformationAction, and Write-Output would put
        # progress text on the success stream where callers would capture it
        # alongside real return values. Microsoft's own settings example
        # excludes this same rule.
        'PSAvoidUsingWriteHost'
    )
}
