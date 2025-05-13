# StorageSimulatorTests.ps1
# Tests for Storage Accounts using local simulators
# These tests use mocked data and Azurite storage simulator

[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
param()

Describe "Storage Account Tests with Local Simulator" -Tag "LocalSimulator" {
    BeforeAll {
        # Import fixtures
        $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
        $rootPath = Split-Path -Parent $scriptPath
        
        $infrastructureFixturesPath = Join-Path $rootPath "src/InfrastructureFixtures.ps1"
        if (Test-Path $infrastructureFixturesPath) {
            . $infrastructureFixturesPath
        } else {
            Write-Warning "Infrastructure fixtures not found: $infrastructureFixturesPath"
        }
        
        # Load test data
        $testDataPath = Join-Path $rootPath "mock-data/AzuriteTestData.psd1"
        if (Test-Path $testDataPath) {
            $script:testData = Import-PowerShellDataFile -Path $testDataPath
        } else {
            $script:testData = @{
                StorageAccounts = @(
                    @{
                        Name = "storage1"
                        Location = "eastus"
                        Sku = "Standard_LRS"
                        Kind = "StorageV2"
                        EnableHttpsTrafficOnly = $true
                        MinimumTlsVersion = "TLS1_2"
                        AllowBlobPublicAccess = $false
                    },
                    @{
                        Name = "storage2"
                        Location = "canadaeast"
                        Sku = "Standard_LRS"
                        Kind = "StorageV2"
                        EnableHttpsTrafficOnly = $true
                        MinimumTlsVersion = "TLS1_2"
                        AllowBlobPublicAccess = $false
                    }
                )
            }
        }
        
        # Mock Azure cmdlets using the test data
        Mock Get-AzStorageAccount {
            param ($Name)
            
            $storageAccount = $script:testData.StorageAccounts | Where-Object { $_.Name -eq $Name }
            
            if ($storageAccount) {
                return [PSCustomObject]@{
                    Name = $storageAccount.Name
                    Location = $storageAccount.Location
                    Sku = [PSCustomObject]@{ Name = $storageAccount.Sku }
                    Kind = $storageAccount.Kind
                    EnableHttpsTrafficOnly = $storageAccount.EnableHttpsTrafficOnly
                    MinimumTlsVersion = $storageAccount.MinimumTlsVersion
                    AllowBlobPublicAccess = $storageAccount.AllowBlobPublicAccess
                }
            }
            
            return $null
        }
    }

    Context "Storage Account 1 Tests" {
        It "Should exist" {
            $storage = Get-AzStorageAccount -Name $expectedStorageAccounts[0].Name -ErrorAction SilentlyContinue
            $storage | Should -Not -BeNullOrEmpty
        }
        
        It "Should be in East US region" {
            $storage = Get-AzStorageAccount -Name $expectedStorageAccounts[0].Name -ErrorAction SilentlyContinue
            $storage.Location | Should -Be "eastus"
        }
        
        It "Should be using Standard_LRS SKU" {
            $storage = Get-AzStorageAccount -Name $expectedStorageAccounts[0].Name -ErrorAction SilentlyContinue
            $storage.Sku.Name | Should -Be "Standard_LRS"
        }
        
        It "Should be StorageV2 kind" {
            $storage = Get-AzStorageAccount -Name $expectedStorageAccounts[0].Name -ErrorAction SilentlyContinue
            $storage.Kind | Should -Be "StorageV2"
        }
        
        It "Should have HTTPS traffic only enabled" {
            $storage = Get-AzStorageAccount -Name $expectedStorageAccounts[0].Name -ErrorAction SilentlyContinue
            $storage.EnableHttpsTrafficOnly | Should -Be $true
        }
        
        It "Should have minimum TLS version 1.2" {
            $storage = Get-AzStorageAccount -Name $expectedStorageAccounts[0].Name -ErrorAction SilentlyContinue
            $storage.MinimumTlsVersion | Should -Be "TLS1_2"
        }
        
        It "Should have blob public access disabled" {
            $storage = Get-AzStorageAccount -Name $expectedStorageAccounts[0].Name -ErrorAction SilentlyContinue
            $storage.AllowBlobPublicAccess | Should -Be $false
        }
    }
    
    Context "Storage Account 2 Tests" {
        It "Should exist" {
            $storage = Get-AzStorageAccount -Name $expectedStorageAccounts[1].Name -ErrorAction SilentlyContinue
            $storage | Should -Not -BeNullOrEmpty
        }
        
        It "Should be in Canada East region" {
            $storage = Get-AzStorageAccount -Name $expectedStorageAccounts[1].Name -ErrorAction SilentlyContinue
            $storage.Location | Should -Be "canadaeast"
        }
        
        It "Should be using Standard_LRS SKU" {
            $storage = Get-AzStorageAccount -Name $expectedStorageAccounts[1].Name -ErrorAction SilentlyContinue
            $storage.Sku.Name | Should -Be "Standard_LRS"
        }
        
        It "Should be StorageV2 kind" {
            $storage = Get-AzStorageAccount -Name $expectedStorageAccounts[1].Name -ErrorAction SilentlyContinue
            $storage.Kind | Should -Be "StorageV2"
        }
        
        It "Should have HTTPS traffic only enabled" {
            $storage = Get-AzStorageAccount -Name $expectedStorageAccounts[1].Name -ErrorAction SilentlyContinue
            $storage.EnableHttpsTrafficOnly | Should -Be $true
        }
        
        It "Should have minimum TLS version 1.2" {
            $storage = Get-AzStorageAccount -Name $expectedStorageAccounts[1].Name -ErrorAction SilentlyContinue
            $storage.MinimumTlsVersion | Should -Be "TLS1_2"
        }
        
        It "Should have blob public access disabled" {
            $storage = Get-AzStorageAccount -Name $expectedStorageAccounts[1].Name -ErrorAction SilentlyContinue
            $storage.AllowBlobPublicAccess | Should -Be $false
        }
    }
}