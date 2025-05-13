# StorageSimulatorTests.ps1
# Tests for Storage Accounts using local simulators
# These tests use the Infrastructure Fixtures for validation

[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
param()

Describe "Storage Account Tests with Local Simulator" -Tag "LocalSimulator" {
    BeforeAll {
        # Import fixtures - using full path for reliability
        $scriptPath = $PSScriptRoot
        $rootPath = Split-Path -Parent $scriptPath
        
        # Source the fixtures file directly
        $infrastructureFixturesPath = Join-Path -Path $rootPath -ChildPath "src\InfrastructureFixtures.ps1"
        if (Test-Path -Path $infrastructureFixturesPath) {
            . $infrastructureFixturesPath
        } else {
            Write-Warning "Infrastructure fixtures not found at: $infrastructureFixturesPath"
        }
    }

    Context "Storage Account Validation - Storage 1" {
        It "Should have the correct name" {
            $expectedStorageAccounts[0].Name | Should -Be "storage1"
        }
        
        It "Should be in East US region" {
            $expectedStorageAccounts[0].Location | Should -Be "eastus"
        }
    }
    
    Context "Storage Account Validation - Storage 2" {
        It "Should have the correct name" {
            $expectedStorageAccounts[1].Name | Should -Be "storage2"
        }
        
        It "Should be in Canada East region" {
            $expectedStorageAccounts[1].Location | Should -Be "canadaeast"
        }
    }
    
    Context "Local Simulator Connection Test" {
        It "Should have Azurite connection string set" {
            $env:AZURE_STORAGE_CONNECTION_STRING | Should -Not -BeNullOrEmpty
        }
        
        It "Should have Azurite simulator enabled flag set" {
            $env:AZURE_SIMULATOR_ENABLED | Should -Be "true"
        }
    }
}
