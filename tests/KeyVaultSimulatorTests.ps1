# KeyVaultSimulatorTests.ps1
# Tests for Key Vaults using local simulators
# These tests use the Infrastructure Fixtures for validation

[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
param()

Describe "Key Vault Tests with Local Simulator" -Tag "LocalSimulator" {
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
        
        # Load test data
        $testDataPath = Join-Path -Path $rootPath -ChildPath "mock-data\AzuriteTestData.psd1"
        if (Test-Path -Path $testDataPath) {
            $script:testData = Import-PowerShellDataFile -Path $testDataPath
        }
        
        # Mock Azure cmdlets for Key Vault
        Mock Get-AzKeyVault {
            param ($VaultName)
            
            $keyVault = $script:testData.KeyVaults | Where-Object { $_.Name -eq $VaultName }
            
            if ($keyVault) {
                return [PSCustomObject]@{
                    VaultName = $keyVault.Name
                    Location = $keyVault.Location
                    Sku = $keyVault.Sku
                    EnableSoftDelete = $keyVault.EnableSoftDelete
                    EnablePurgeProtection = $keyVault.EnablePurgeProtection
                }
            }
            
            return $null
        }
    }

    Context "Key Vault 1 Validation" {
        It "Should have the correct name" {
            $expectedKeyVaults[0].Name | Should -Be "kv1"
        }
        
        It "Should be in East US region" {
            $expectedKeyVaults[0].Location | Should -Be "eastus"
        }
    }
    
    Context "Key Vault 2 Validation" {
        It "Should have the correct name" {
            $expectedKeyVaults[1].Name | Should -Be "kv2"
        }
        
        It "Should be in Canada East region" {
            $expectedKeyVaults[1].Location | Should -Be "canadaeast"
        }
    }
    
    Context "Key Vault Fixture Validation" {
        It "Should have two key vaults defined" {
            $expectedKeyVaults.Count | Should -Be 2
        }
    }
}
