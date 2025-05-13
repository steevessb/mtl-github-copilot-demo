# YamlFixtureTest.ps1
# Example test using YAML fixtures for data-driven testing
# Quality Engineer: Use this pattern to create data-driven tests from YAML configurations

. $PSScriptRoot/DiscoveryPhase.ps1
. $PSScriptRoot/LoadYamlFixtures.ps1

Describe 'Azure Resource Testing with YAML Fixtures' {
    BeforeAll {
        # Load fixtures from YAML
        $script:fixtures = & "$PSScriptRoot/LoadYamlFixtures.ps1" -YamlFilePath "$PSScriptRoot/../config/AzureFixtures.yml"
        
        # Get actual resources
        $script:actualStorageAccounts = Get-AzStorageAccount
        $script:actualResourceGroups = Get-AzResourceGroup
    }
    
    Context 'Storage Account Tests' {
        # Data-driven test using fixtures from YAML
        foreach ($expected in $script:fixtures.storageAccounts) {
            It "Storage Account '$($expected.name)' should exist and match specifications" {
                $actual = $script:actualStorageAccounts | Where-Object { $_.StorageAccountName -eq $expected.name }
                $actual | Should -Not -BeNullOrEmpty -Because "Storage account '$($expected.name)' should exist"
                
                if ($actual) {
                    $actual.Location | Should -Be $expected.location -Because "Location should match fixture"
                    $actual.Sku.Name | Should -Be $expected.sku -Because "SKU should match fixture"
                    $actual.Kind | Should -Be $expected.type -Because "Account type should match fixture"
                    
                    # Check for required tags
                    foreach ($tagPair in $expected.tags) {
                        foreach ($tagName in $tagPair.Keys) {
                            $actual.Tags.Keys | Should -Contain $tagName -Because "Storage account should have tag '$tagName'"
                        }
                    }
                }
            }
        }
    }
    
    Context 'Resource Group Tests' {
        # Data-driven test using fixtures from YAML
        foreach ($expected in $script:fixtures.resourceGroups) {
            It "Resource Group '$($expected.name)' should exist and match specifications" {
                $actual = $script:actualResourceGroups | Where-Object { $_.ResourceGroupName -eq $expected.name }
                $actual | Should -Not -BeNullOrEmpty -Because "Resource group '$($expected.name)' should exist"
                
                if ($actual) {
                    $actual.Location | Should -Be $expected.location -Because "Location should match fixture"
                    
                    # Check for required tags
                    foreach ($tagPair in $expected.tags) {
                        foreach ($tagName in $tagPair.Keys) {
                            $actual.Tags.Keys | Should -Contain $tagName -Because "Resource group should have tag '$tagName'"
                        }
                    }
                }
            }
        }
    }
}
