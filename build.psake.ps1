param()

# Allow end users to add their own custom psake tasks
$customPsakeFile = Join-Path -Path $PSScriptRoot -ChildPath 'custom.psake.ps1'
if (Test-Path -Path $customPsakeFile) {
    Include -FileNamePathToInclude $customPsakeFile
}

properties {
    # Set this to $true to create a module with a monolithic PSM1
    $PSBPreference.Build.CompileModule = $false
    $PSBPreference.Help.DefaultLocale = 'en-US'
    # Use absolute paths for test output (relative paths resolve from tests directory)
    $PSBPreference.Test.OutputFile = [IO.Path]::Combine($PSScriptRoot, 'out', 'testResults.xml')
    $PSBPreference.Test.OutputFormat = 'NUnitXml'
    $PSBPreference.Test.CodeCoverage.Enabled = $true
    $PSBPreference.Test.CodeCoverage.Files = @(
        "$PSScriptRoot/YouTubeMusicPS/Public/*.ps1"
        "$PSScriptRoot/YouTubeMusicPS/Private/*.ps1"
    )
    $PSBPreference.Test.CodeCoverage.Threshold = 0  # Threshold enforced by Codecov
    $PSBPreference.Test.CodeCoverage.OutputFile = [IO.Path]::Combine($PSScriptRoot, 'out', 'codeCoverage.xml')
    $PSBPreference.Test.CodeCoverage.OutputFileFormat = 'JaCoCo'
}

Task -Name 'Default' -Depends 'Test'

Task -Name 'GetDependencies' -Description 'List module dependencies from dependency files' {
    # Requires PSDepend to be available
    if (-not (Get-Module -Name 'PSDepend' -ListAvailable)) {
        throw 'PSDepend module is not available. Please run with -Bootstrap flag first.'
    }
    
    Import-Module -Name 'PSDepend' -Verbose:$false
    
    $modules = @()
    
    # Get dependencies from build.depend.psd1
    if (Test-Path 'build.depend.psd1') {
        $buildDeps = Get-Dependency -Path 'build.depend.psd1'
        foreach ($dep in $buildDeps) {
            if ($dep.Version) {
                $modules += "$($dep.DependencyName):$($dep.Version)"
            }
        }
    }
    
    # Get dependencies from requirements.psd1
    if (Test-Path 'requirements.psd1') {
        $runtimeDeps = Get-Dependency -Path 'requirements.psd1'
        foreach ($dep in $runtimeDeps) {
            if ($dep.Version) {
                $modules += "$($dep.DependencyName):$($dep.Version)"
            }
        }
    }
    
    $moduleList = $modules -join ', '
    
    # Output for GitHub Actions or local use
    if ($env:GITHUB_OUTPUT) {
        Write-Output "modules=$moduleList" >> $env:GITHUB_OUTPUT
    }
    
    Write-Host "Module cache list: $moduleList"
}

Task -Name 'Init_Integration' -Description 'Load integration test environment variables from local.settings.ps1' {
    $localSettingsPath = Join-Path -Path $PSScriptRoot -ChildPath 'tests/local.settings.ps1'
    if (Test-Path -Path $localSettingsPath) {
        Write-Host "Loading integration test settings from tests/local.settings.ps1" -ForegroundColor Cyan
        . $localSettingsPath
    } else {
        Write-Host "No local.settings.ps1 found - integration tests will be skipped" -ForegroundColor Yellow
    }
}

# Note: -Depends replaces PowerShellBuild's default dependencies, so we must include Pester and Analyze explicitly
Task -Name 'Test' -FromModule 'PowerShellBuild' -MinimumVersion '0.7.3' -Depends 'Init_Integration', 'Pester', 'Analyze'
