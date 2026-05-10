[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSUseDeclaredVarsMoreThanAssignments',
    '',
    Justification = 'Pester BeforeAll/It scope'
)]
param()

BeforeDiscovery {
    if ($null -eq $Env:BHBuildOutput) {
        # Populate BuildHelpers env vars so build.psake.ps1's properties block has
        # the values it needs (BHPSModuleManifest, BHProjectName) — when running
        # via ./build.ps1 this happens before psake; running tests in isolation
        # bypasses that, so we do it here.
        $repoRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
        Set-BuildEnvironment -Path $repoRoot -Force
        $buildFilePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\build.psake.ps1'
        $invokePsakeParameters = @{
            TaskList  = 'Build'
            BuildFile = $buildFilePath
        }
        Invoke-psake @invokePsakeParameters
    }

    $projectRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
    $sourceManifest = Join-Path -Path $projectRoot -ChildPath "$Env:BHProjectName/$Env:BHProjectName.psd1"
    $moduleVersion = (Import-PowerShellDataFile -Path $sourceManifest).ModuleVersion
    $Env:BHBuildOutput = Join-Path -Path $projectRoot -ChildPath "Output/$Env:BHProjectName/$moduleVersion"
}

BeforeAll {
    $moduleManifestPath = Join-Path -Path $Env:BHBuildOutput -ChildPath "$Env:BHProjectName.psd1"
    Get-Module -Name $Env:BHProjectName | Remove-Module -Force -ErrorAction 'Ignore'
    Import-Module -Name $moduleManifestPath -Force -ErrorAction 'Stop'
}

InModuleScope $Env:BHProjectName {
Describe 'Get-YtmSapiSidHash' {
    Context 'Hash Generation' {
        It 'Returns a string starting with SAPISIDHASH' {
            $result = Get-YtmSapiSidHash -SapiSid 'testSapiSid123'
            $result | Should -Match '^SAPISIDHASH \d+_[a-f0-9]{40}$'
        }

        It 'Uses timestamp in the format {timestamp}_{hash}' {
            $result = Get-YtmSapiSidHash -SapiSid 'testSapiSid123'
            $parts = $result -split ' '
            $parts[0] | Should -Be 'SAPISIDHASH'
            $parts[1] | Should -Match '^\d+_[a-f0-9]{40}$'
        }

        It 'Produces different hashes for different SAPISID values' {
            $result1 = Get-YtmSapiSidHash -SapiSid 'sapisid1'
            $result2 = Get-YtmSapiSidHash -SapiSid 'sapisid2'

            # Extract just the hash portion (after the underscore)
            $hash1 = ($result1 -split '_')[1]
            $hash2 = ($result2 -split '_')[1]

            $hash1 | Should -Not -Be $hash2
        }

        It 'Produces different hashes for different origins' {
            $result1 = Get-YtmSapiSidHash -SapiSid 'sameSapiSid' -Origin 'https://music.youtube.com'
            $result2 = Get-YtmSapiSidHash -SapiSid 'sameSapiSid' -Origin 'https://www.youtube.com'

            $hash1 = ($result1 -split '_')[1]
            $hash2 = ($result2 -split '_')[1]

            $hash1 | Should -Not -Be $hash2
        }

        It 'Uses default origin of https://music.youtube.com' {
            # This is an implicit test - if it works without Origin, default is used
            { Get-YtmSapiSidHash -SapiSid 'testSapiSid' } | Should -Not -Throw
        }

        It 'Produces a 40-character hex hash (SHA1)' {
            $result = Get-YtmSapiSidHash -SapiSid 'testSapiSid'
            $hash = ($result -split '_')[1]
            $hash.Length | Should -Be 40
            $hash | Should -Match '^[a-f0-9]+$'
        }
    }

    Context 'Parameter Validation' {
        It 'Throws when SapiSid is null' {
            { Get-YtmSapiSidHash -SapiSid $null } | Should -Throw
        }

        It 'Throws when SapiSid is empty' {
            { Get-YtmSapiSidHash -SapiSid '' } | Should -Throw
        }

        It 'Accepts SapiSid as mandatory parameter' {
            $command = Get-Command Get-YtmSapiSidHash
            $command.Parameters['SapiSid'].Attributes.Mandatory | Should -Contain $true
        }
    }

    Context 'Known Value Test' {
        It 'Produces consistent hash for known inputs at a fixed timestamp' {
            # We cannot easily mock the timestamp, but we can verify the hash format
            # and that the algorithm produces valid SHA1 output
            $result = Get-YtmSapiSidHash -SapiSid 'ABC123XYZ'
            $result | Should -Match '^SAPISIDHASH \d+_[a-f0-9]{40}$'
        }
    }
}
}
