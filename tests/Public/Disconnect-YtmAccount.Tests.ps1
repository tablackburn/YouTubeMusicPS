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
Describe 'Disconnect-YtmAccount' {
    BeforeAll {
        $script:testDir = Join-Path $TestDrive 'YouTubeMusicPS'
        $script:testConfigPath = Join-Path $testDir 'config.json'
    }

    BeforeEach {
        # Create test directory and mock config path
        New-Item -Path $testDir -ItemType Directory -Force | Out-Null
        Mock Get-YtmConfigurationPath { $script:testConfigPath }

        # Set up existing cookies
        $testConfiguration = @{
            version = '1.0'
            auth = @{
                sapiSid = 'existing-sapisid'
                cookies = 'existing-cookies'
            }
        }
        $testConfiguration | ConvertTo-Json | Set-Content $testConfigPath
    }

    AfterEach {
        if (Test-Path $testDir) {
            Remove-Item $testDir -Recurse -Force
        }
    }

    Context 'Disconnecting' {
        It 'Removes stored cookies' {
            Disconnect-YtmAccount
            $stored = Get-YtmStoredCookies
            $stored | Should -BeNullOrEmpty
        }

        It 'Does not throw when no cookies exist' {
            Remove-YtmStoredCookies  # Ensure no cookies
            { Disconnect-YtmAccount } | Should -Not -Throw
        }

        It 'Preserves configuration file with version' {
            Disconnect-YtmAccount
            Test-Path $testConfigPath | Should -Be $true
            $testConfiguration = Get-Content $testConfigPath -Raw | ConvertFrom-Json
            $testConfiguration.version | Should -Be '1.0'
        }
    }

    Context 'ShouldProcess Support' {
        It 'Supports -WhatIf' {
            Disconnect-YtmAccount -WhatIf
            $stored = Get-YtmStoredCookies
            $stored | Should -Not -BeNullOrEmpty
        }

        It 'Supports -Confirm:$false' {
            # This should work without prompting
            { Disconnect-YtmAccount -Confirm:$false } | Should -Not -Throw
            $stored = Get-YtmStoredCookies
            $stored | Should -BeNullOrEmpty
        }
    }

    Context 'Output' {
        It 'Does not return any objects' {
            $result = Disconnect-YtmAccount
            $result | Should -BeNullOrEmpty
        }
    }
}
}
