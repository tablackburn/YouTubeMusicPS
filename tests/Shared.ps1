# Shared test setup for YouTubeMusicPS tests
# This file is dot-sourced by all test files

$script:ModuleRoot = Split-Path -Parent $PSScriptRoot
$script:ModulePath = Join-Path $script:ModuleRoot 'YouTubeMusicPS'

# Import private functions first, then public
$Private = @(Get-ChildItem -Path (Join-Path $script:ModulePath 'Private/*.ps1') -ErrorAction SilentlyContinue)
$Public = @(Get-ChildItem -Path (Join-Path $script:ModulePath 'Public/*.ps1') -ErrorAction SilentlyContinue)

foreach ($import in @($Private + $Public)) {
    try {
        . $import.FullName
    }
    catch {
        Write-Warning "Failed to import $($import.FullName): $_"
    }
}
