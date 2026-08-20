@{
    # Scope analysis to actionable severities. Microsoft's documented settings
    # example does the same; without it Information-level findings are in scope
    # with nothing having decided that they should be.
    Severity     = @('Error', 'Warning')
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
