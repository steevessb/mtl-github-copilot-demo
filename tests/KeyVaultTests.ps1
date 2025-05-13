# KeyVaultTests.ps1
# Tests for Key Vaults

Describe "Key Vault Tests" {
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
        if ($deploymentOutputs -and $deploymentOutputs.keyVault1Name.value) {
            $script:kv1Name = $deploymentOutputs.keyVault1Name.value
        } else {
            # Use a naming pattern similar to what's in the Bicep file
            $resourceToken = Get-Random -Minimum 10000 -Maximum 99999
            $script:kv1Name = "kv1$resourceToken"
        }
        
        if ($deploymentOutputs -and $deploymentOutputs.keyVault2Name.value) {
            $script:kv2Name = $deploymentOutputs.keyVault2Name.value
        } else {
            # Use a naming pattern similar to what's in the Bicep file
            $resourceToken = Get-Random -Minimum 10000 -Maximum 99999
            $script:kv2Name = "kv2$resourceToken"
        }
    }

    Context "Key Vault 1 Tests" {
        It "Should exist" {
            $kv = Get-AzKeyVault -VaultName $script:kv1Name -ErrorAction SilentlyContinue
            $kv | Should -Not -BeNullOrEmpty
        }
        
        It "Should be in East US region" {
            $kv = Get-AzKeyVault -VaultName $script:kv1Name -ErrorAction SilentlyContinue
            $kv.Location | Should -Be "eastus"
        }
        
        It "Should be standard SKU" {
            $kv = Get-AzKeyVault -VaultName $script:kv1Name -ErrorAction SilentlyContinue
            $kv.Sku | Should -Be "Standard"
        }
        
        It "Should have soft delete enabled" {
            $kv = Get-AzKeyVault -VaultName $script:kv1Name -ErrorAction SilentlyContinue
            $kv.EnableSoftDelete | Should -Be $true
        }
        
        It "Should have purge protection enabled" {
            $kv = Get-AzKeyVault -VaultName $script:kv1Name -ErrorAction SilentlyContinue
            $kv.EnablePurgeProtection | Should -Be $true
        }
    }
    
    Context "Key Vault 2 Tests" {
        It "Should exist" {
            $kv = Get-AzKeyVault -VaultName $script:kv2Name -ErrorAction SilentlyContinue
            $kv | Should -Not -BeNullOrEmpty
        }
        
        It "Should be in Canada East region" {
            $kv = Get-AzKeyVault -VaultName $script:kv2Name -ErrorAction SilentlyContinue
            $kv.Location | Should -Be "canadaeast"
        }
        
        It "Should be standard SKU" {
            $kv = Get-AzKeyVault -VaultName $script:kv2Name -ErrorAction SilentlyContinue
            $kv.Sku | Should -Be "Standard"
        }
        
        It "Should have soft delete enabled" {
            $kv = Get-AzKeyVault -VaultName $script:kv2Name -ErrorAction SilentlyContinue
            $kv.EnableSoftDelete | Should -Be $true
        }
        
        It "Should have purge protection enabled" {
            $kv = Get-AzKeyVault -VaultName $script:kv2Name -ErrorAction SilentlyContinue
            $kv.EnablePurgeProtection | Should -Be $true
        }
    }
}
