# StorageTests.ps1
# Tests for Storage Accounts

Describe "Storage Account Tests" {
    BeforeAll {
        # Import fixtures if not already imported
        $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
        $rootPath = Split-Path -Parent $scriptPath
        $infrastructureFixturesPath = Join-Path $rootPath "src/InfrastructureFixtures.ps1"
        if (Test-Path $infrastructureFixturesPath) {
            . $infrastructureFixturesPath
        }
        
        # Load deployment outputs if available
        $testResultsPath = Join-Path $rootPath "TestResults"
        $outputsFilePath = Join-Path $testResultsPath "deployment-outputs.json"
        if (Test-Path $outputsFilePath) {
            $deploymentOutputs = Get-Content -Path $outputsFilePath | ConvertFrom-Json
        }
        
        # Get resource names from deployment outputs if available, otherwise use defaults from fixtures
        if ($deploymentOutputs -and $deploymentOutputs.storage1Name.value) {
            $script:storage1Name = $deploymentOutputs.storage1Name.value
        } else {
            # Use a naming pattern similar to what's in the Bicep file
            $resourceToken = Get-Random -Minimum 10000 -Maximum 99999
            $script:storage1Name = "storage1$resourceToken"
        }
        
        if ($deploymentOutputs -and $deploymentOutputs.storage2Name.value) {
            $script:storage2Name = $deploymentOutputs.storage2Name.value
        } else {
            # Use a naming pattern similar to what's in the Bicep file
            $resourceToken = Get-Random -Minimum 10000 -Maximum 99999
            $script:storage2Name = "storage2$resourceToken"
        }
    }

    Context "Storage Account 1 Tests" {
        It "Should exist" {
            $storage = Get-AzStorageAccount -Name $script:storage1Name -ErrorAction SilentlyContinue
            $storage | Should -Not -BeNullOrEmpty
        }
        
        It "Should be in East US region" {
            $storage = Get-AzStorageAccount -Name $script:storage1Name -ErrorAction SilentlyContinue
            $storage.Location | Should -Be "eastus"
        }
        
        It "Should be using Standard_LRS SKU" {
            $storage = Get-AzStorageAccount -Name $script:storage1Name -ErrorAction SilentlyContinue
            $storage.Sku.Name | Should -Be "Standard_LRS"
        }
        
        It "Should be StorageV2 kind" {
            $storage = Get-AzStorageAccount -Name $script:storage1Name -ErrorAction SilentlyContinue
            $storage.Kind | Should -Be "StorageV2"
        }
        
        It "Should have HTTPS traffic only enabled" {
            $storage = Get-AzStorageAccount -Name $script:storage1Name -ErrorAction SilentlyContinue
            $storage.EnableHttpsTrafficOnly | Should -Be $true
        }
        
        It "Should have minimum TLS version 1.2" {
            $storage = Get-AzStorageAccount -Name $script:storage1Name -ErrorAction SilentlyContinue
            $storage.MinimumTlsVersion | Should -Be "TLS1_2"
        }
        
        It "Should have blob public access disabled" {
            $storage = Get-AzStorageAccount -Name $script:storage1Name -ErrorAction SilentlyContinue
            $storage.AllowBlobPublicAccess | Should -Be $false
        }
    }
    
    Context "Storage Account 2 Tests" {
        It "Should exist" {
            $storage = Get-AzStorageAccount -Name $script:storage2Name -ErrorAction SilentlyContinue
            $storage | Should -Not -BeNullOrEmpty
        }
        
        It "Should be in Canada East region" {
            $storage = Get-AzStorageAccount -Name $script:storage2Name -ErrorAction SilentlyContinue
            $storage.Location | Should -Be "canadaeast"
        }
        
        It "Should be using Standard_LRS SKU" {
            $storage = Get-AzStorageAccount -Name $script:storage2Name -ErrorAction SilentlyContinue
            $storage.Sku.Name | Should -Be "Standard_LRS"
        }
        
        It "Should be StorageV2 kind" {
            $storage = Get-AzStorageAccount -Name $script:storage2Name -ErrorAction SilentlyContinue
            $storage.Kind | Should -Be "StorageV2"
        }
        
        It "Should have HTTPS traffic only enabled" {
            $storage = Get-AzStorageAccount -Name $script:storage2Name -ErrorAction SilentlyContinue
            $storage.EnableHttpsTrafficOnly | Should -Be $true
        }
        
        It "Should have minimum TLS version 1.2" {
            $storage = Get-AzStorageAccount -Name $script:storage2Name -ErrorAction SilentlyContinue
            $storage.MinimumTlsVersion | Should -Be "TLS1_2"
        }
        
        It "Should have blob public access disabled" {
            $storage = Get-AzStorageAccount -Name $script:storage2Name -ErrorAction SilentlyContinue
            $storage.AllowBlobPublicAccess | Should -Be $false
        }
    }
}
