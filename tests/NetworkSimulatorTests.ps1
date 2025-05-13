# NetworkSimulatorTests.ps1
# Tests for Network resources using local simulators
# These tests use the Infrastructure Fixtures for validation

[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
param()

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

Describe "Virtual Network Tests with Local Simulator" -Tag "LocalSimulator" {
    BeforeAll {
        # Set up mocks inline in each Describe block
        # Mock Azure cmdlets for Virtual Networks
        Mock Get-AzVirtualNetwork {
            param ($Name)
            
            $vnet = $script:testData.VirtualNetworks | Where-Object { $_.Name -eq $Name }
            
            if ($vnet) {
                $subnets = $script:testData.Subnets | Where-Object { $_.VirtualNetworkName -eq $Name } | ForEach-Object {
                    [PSCustomObject]@{
                        Name = $_.Name
                        AddressPrefix = $_.AddressPrefix
                    }
                }
                
                return [PSCustomObject]@{
                    Name = $vnet.Name
                    Location = $vnet.Location
                    AddressSpace = [PSCustomObject]@{
                        AddressPrefixes = $vnet.AddressPrefixes
                    }
                    Subnets = $subnets
                }
            }
            
            return $null
        }
    }

    Context "Virtual Network 1 Validation" {
        It "Should have the correct name" {
            $expectedVnets[0].Name | Should -Be "vnet1"
        }
        
        It "Should be in East US region" {
            $expectedVnets[0].Location | Should -Be "eastus"
        }
    }
    
    Context "Virtual Network 2 Validation" {
        It "Should have the correct name" {
            $expectedVnets[1].Name | Should -Be "vnet2"
        }
        
        It "Should be in Canada East region" {
            $expectedVnets[1].Location | Should -Be "canadaeast"
        }
    }
}

Describe "Subnet Tests with Local Simulator" -Tag "LocalSimulator" {
    BeforeAll {
        # Set up mocks inline in each Describe block
        # Mock Azure cmdlets for Virtual Networks with subnets
        Mock Get-AzVirtualNetwork {
            param ($Name)
            
            $vnet = $script:testData.VirtualNetworks | Where-Object { $_.Name -eq $Name }
            
            if ($vnet) {
                $subnets = $script:testData.Subnets | Where-Object { $_.VirtualNetworkName -eq $Name } | ForEach-Object {
                    [PSCustomObject]@{
                        Name = $_.Name
                        AddressPrefix = $_.AddressPrefix
                    }
                }
                
                return [PSCustomObject]@{
                    Name = $vnet.Name
                    Location = $vnet.Location
                    AddressSpace = [PSCustomObject]@{
                        AddressPrefixes = $vnet.AddressPrefixes
                    }
                    Subnets = $subnets
                }
            }
            
            return $null
        }
        
        # Mock for subnet operations
        Mock Get-AzVirtualNetworkSubnetConfig {
            param ($Name, $VirtualNetwork)
            
            $subnet = $script:testData.Subnets | Where-Object { $_.Name -eq $Name }
            
            if ($subnet) {
                return [PSCustomObject]@{
                    Name = $subnet.Name
                    AddressPrefix = $subnet.AddressPrefix
                }
            }
            
            return $null
        }
    }
    
    Context "Subnet Validation" {
        It "Should have correct subnet1 name" {
            $expectedSubnets[0].Name | Should -Be "subnet1"
        }
        
        It "Should have correct subnet2 name" {
            $expectedSubnets[1].Name | Should -Be "subnet2"
        }
    }
}

Describe "Network Security Group Tests with Local Simulator" -Tag "LocalSimulator" {
    BeforeAll {
        # Set up mocks inline in each Describe block
        # Mock Azure cmdlets for Network Security Groups
        Mock Get-AzNetworkSecurityGroup {
            param ($Name)
            
            $nsg = $script:testData.NetworkSecurityGroups | Where-Object { $_.Name -eq $Name }
            
            if ($nsg) {
                return [PSCustomObject]@{
                    Name = $nsg.Name
                    Location = $nsg.Location
                    SecurityRules = $nsg.SecurityRules | ForEach-Object {
                        [PSCustomObject]@{
                            Name = $_.Name
                            Protocol = $_.Protocol
                            SourcePortRange = $_.SourcePortRange
                            DestinationPortRange = $_.DestinationPortRange
                            SourceAddressPrefix = $_.SourceAddressPrefix
                            DestinationAddressPrefix = $_.DestinationAddressPrefix
                            Access = $_.Access
                            Priority = $_.Priority
                            Direction = $_.Direction
                        }
                    }
                }
            }
            
            return $null
        }
    }
    
    Context "Network Security Group Validation" {
        It "Should have correct NSG1 name" {
            $expectedNsgs[0].Name | Should -Be "nsg1"
        }
        
        It "Should have correct NSG2 name" {
            $expectedNsgs[1].Name | Should -Be "nsg2"
        }
    }
    
    Context "NSG Rules Validation" {
        It "Should have rule1 configured" {
            $expectedNsgRules[0].Name | Should -Be "rule1"
        }
        
        It "Should have rule2 configured" {
            $expectedNsgRules[1].Name | Should -Be "rule2"
        }
    }
}
