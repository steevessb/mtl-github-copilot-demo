# ResourceGroup.Tests.ps1
# Tests for Azure Resource Group validation
# Quality Engineer: Update this file to test your specific resource group requirements

. $PSScriptRoot/DiscoveryPhase.ps1
. $PSScriptRoot/InfrastructureFixtures.ps1

Describe 'Azure Resource Group Tests' {
    BeforeAll {
        # Retrieve all resource groups in target subscription
        $script:actualResourceGroups = Get-AzResourceGroup
    }

    Context 'Resource Group Existence' {
        # Environment variables can be set in the pipeline
        $expectedResourceGroupName = $env:RESOURCE_GROUP ?? "qa-test-rg"
        $expectedLocation = $env:LOCATION ?? "canadaeast"
        
        It "Resource Group '$expectedResourceGroupName' should exist" {
            $rg = $script:actualResourceGroups | Where-Object { $_.ResourceGroupName -eq $expectedResourceGroupName }
            $rg | Should -Not -BeNullOrEmpty -Because "Resource Group '$expectedResourceGroupName' should exist"
        }
        
        It "Resource Group '$expectedResourceGroupName' should be in location '$expectedLocation'" {
            $rg = $script:actualResourceGroups | Where-Object { $_.ResourceGroupName -eq $expectedResourceGroupName }
            $rg.Location | Should -Be $expectedLocation -Because "Resource Group location should match requirements"
        }
    }
    
    Context 'Resource Group Tags' {
        $requiredTags = @('Environment', 'Owner', 'CostCenter')
        $expectedResourceGroupName = $env:RESOURCE_GROUP ?? "qa-test-rg"
        
        It "Resource Group '$expectedResourceGroupName' should have required tags" {
            $rg = $script:actualResourceGroups | Where-Object { $_.ResourceGroupName -eq $expectedResourceGroupName }
            
            foreach ($tag in $requiredTags) {
                $rg.Tags.Keys | Should -Contain $tag -Because "Resource group should have tag '$tag'"
            }
        }
    }
    
    Context 'Resource Group Lock' {
        $expectedResourceGroupName = $env:RESOURCE_GROUP ?? "qa-test-rg"
        
        It "Resource Group '$expectedResourceGroupName' should have a delete lock" {
            $locks = Get-AzResourceLock -ResourceGroupName $expectedResourceGroupName
            $deleteLock = $locks | Where-Object { $_.Properties.level -eq "CanNotDelete" }
            $deleteLock | Should -Not -BeNullOrEmpty -Because "Production resource groups should have delete locks"
        }
    }
}
