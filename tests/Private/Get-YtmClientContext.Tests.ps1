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
Describe 'Get-YtmClientContext' {
    Context 'Default Values' {
        It 'Returns a hashtable' {
            $result = Get-YtmClientContext
            $result | Should -BeOfType [hashtable]
        }

        It 'Contains a context key' {
            $result = Get-YtmClientContext
            $result.Keys | Should -Contain 'context'
        }

        It 'Contains client information' {
            $result = Get-YtmClientContext
            $result.context.Keys | Should -Contain 'client'
        }

        It 'Sets clientName to WEB_REMIX' {
            $result = Get-YtmClientContext
            $result.context.client.clientName | Should -Be 'WEB_REMIX'
        }

        It 'Sets default language to en' {
            $result = Get-YtmClientContext
            $result.context.client.hl | Should -Be 'en'
        }

        It 'Sets default location to US' {
            $result = Get-YtmClientContext
            $result.context.client.gl | Should -Be 'US'
        }

        It 'Sets clientVersion in format 1.YYYYMMDD.01.00' {
            $result = Get-YtmClientContext
            $result.context.client.clientVersion | Should -Match '^1\.\d{8}\.01\.00$'
        }

        It 'Uses a stable client version' {
            $result = Get-YtmClientContext
            $result.context.client.clientVersion | Should -Be '1.20241127.01.00'
        }
    }

    Context 'Custom Parameters' {
        It 'Accepts custom language' {
            $result = Get-YtmClientContext -Language 'de'
            $result.context.client.hl | Should -Be 'de'
        }

        It 'Accepts custom location' {
            $result = Get-YtmClientContext -Location 'GB'
            $result.context.client.gl | Should -Be 'GB'
        }

        It 'Accepts both custom language and location' {
            $result = Get-YtmClientContext -Language 'fr' -Location 'FR'
            $result.context.client.hl | Should -Be 'fr'
            $result.context.client.gl | Should -Be 'FR'
        }
    }

    Context 'Parameter Validation' {
        It 'Throws when Language is empty' {
            { Get-YtmClientContext -Language '' } | Should -Throw
        }

        It 'Throws when Location is empty' {
            { Get-YtmClientContext -Location '' } | Should -Throw
        }
    }
}
}
