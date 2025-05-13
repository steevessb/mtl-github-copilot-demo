# NetworkTests.ps1
# Tests for Virtual Networks, Subnets, NSGs, and Private DNS Zones

Describe "Network Tests" {
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
        # Virtual Networks
        if ($deploymentOutputs -and $deploymentOutputs.vnet1Name.value) {
            $script:vnet1Name = $deploymentOutputs.vnet1Name.value
        } else {
            $resourceToken = Get-Random -Minimum 10000 -Maximum 99999
            $script:vnet1Name = "vnet1$resourceToken"
        }
        
        if ($deploymentOutputs -and $deploymentOutputs.vnet2Name.value) {
            $script:vnet2Name = $deploymentOutputs.vnet2Name.value
        } else {
            $resourceToken = Get-Random -Minimum 10000 -Maximum 99999
            $script:vnet2Name = "vnet2$resourceToken"
        }
        
        # Subnets
        if ($deploymentOutputs -and $deploymentOutputs.subnet1Name.value) {
            $script:subnet1Name = $deploymentOutputs.subnet1Name.value
        } else {
            $script:subnet1Name = "subnet1"
        }
        
        if ($deploymentOutputs -and $deploymentOutputs.subnet2Name.value) {
            $script:subnet2Name = $deploymentOutputs.subnet2Name.value
        } else {
            $script:subnet2Name = "subnet2"
        }
        
        # NSGs
        if ($deploymentOutputs -and $deploymentOutputs.nsg1Name.value) {
            $script:nsg1Name = $deploymentOutputs.nsg1Name.value
        } else {
            $resourceToken = Get-Random -Minimum 10000 -Maximum 99999
            $script:nsg1Name = "nsg1$resourceToken"
        }
        
        if ($deploymentOutputs -and $deploymentOutputs.nsg2Name.value) {
            $script:nsg2Name = $deploymentOutputs.nsg2Name.value
        } else {
            $resourceToken = Get-Random -Minimum 10000 -Maximum 99999
            $script:nsg2Name = "nsg2$resourceToken"
        }
        
        # Private DNS Zones
        if ($deploymentOutputs -and $deploymentOutputs.privateDns1Name.value) {
            $script:privateDns1Name = $deploymentOutputs.privateDns1Name.value
        } else {
            $script:privateDns1Name = "privatedns1.azure.com"
        }
        
        if ($deploymentOutputs -and $deploymentOutputs.privateDns2Name.value) {
            $script:privateDns2Name = $deploymentOutputs.privateDns2Name.value
        } else {
            $script:privateDns2Name = "privatedns2.azure.com"
        }
    }

    Context "Virtual Network 1 Tests" {
        It "Should exist" {
            $vnet = Get-AzVirtualNetwork -Name $script:vnet1Name -ErrorAction SilentlyContinue
            $vnet | Should -Not -BeNullOrEmpty
        }
        
        It "Should be in East US region" {
            $vnet = Get-AzVirtualNetwork -Name $script:vnet1Name -ErrorAction SilentlyContinue
            $vnet.Location | Should -Be "eastus"
        }
        
        It "Should have address space 10.0.0.0/16" {
            $vnet = Get-AzVirtualNetwork -Name $script:vnet1Name -ErrorAction SilentlyContinue
            $vnet.AddressSpace.AddressPrefixes | Should -Contain "10.0.0.0/16"
        }
        
        It "Should contain subnet1" {
            $vnet = Get-AzVirtualNetwork -Name $script:vnet1Name -ErrorAction SilentlyContinue
            $vnet.Subnets.Name | Should -Contain $script:subnet1Name
        }
    }
    
    Context "Virtual Network 2 Tests" {
        It "Should exist" {
            $vnet = Get-AzVirtualNetwork -Name $script:vnet2Name -ErrorAction SilentlyContinue
            $vnet | Should -Not -BeNullOrEmpty
        }
        
        It "Should be in Canada East region" {
            $vnet = Get-AzVirtualNetwork -Name $script:vnet2Name -ErrorAction SilentlyContinue
            $vnet.Location | Should -Be "canadaeast"
        }
        
        It "Should have address space 10.1.0.0/16" {
            $vnet = Get-AzVirtualNetwork -Name $script:vnet2Name -ErrorAction SilentlyContinue
            $vnet.AddressSpace.AddressPrefixes | Should -Contain "10.1.0.0/16"
        }
        
        It "Should contain subnet2" {
            $vnet = Get-AzVirtualNetwork -Name $script:vnet2Name -ErrorAction SilentlyContinue
            $vnet.Subnets.Name | Should -Contain $script:subnet2Name
        }
    }
    
    Context "Subnet Tests" {
        It "Subnet1 should have address prefix 10.0.0.0/24" {
            $vnet = Get-AzVirtualNetwork -Name $script:vnet1Name -ErrorAction SilentlyContinue
            $subnet = $vnet.Subnets | Where-Object { $_.Name -eq $script:subnet1Name }
            $subnet.AddressPrefix | Should -Be "10.0.0.0/24"
        }
        
        It "Subnet2 should have address prefix 10.1.0.0/24" {
            $vnet = Get-AzVirtualNetwork -Name $script:vnet2Name -ErrorAction SilentlyContinue
            $subnet = $vnet.Subnets | Where-Object { $_.Name -eq $script:subnet2Name }
            $subnet.AddressPrefix | Should -Be "10.1.0.0/24"
        }
    }
    
    Context "Network Security Group Tests" {
        It "NSG1 should exist" {
            $nsg = Get-AzNetworkSecurityGroup -Name $script:nsg1Name -ErrorAction SilentlyContinue
            $nsg | Should -Not -BeNullOrEmpty
        }
        
        It "NSG1 should be in East US region" {
            $nsg = Get-AzNetworkSecurityGroup -Name $script:nsg1Name -ErrorAction SilentlyContinue
            $nsg.Location | Should -Be "eastus"
        }
        
        It "NSG1 should have AllowHTTPS rule" {
            $nsg = Get-AzNetworkSecurityGroup -Name $script:nsg1Name -ErrorAction SilentlyContinue
            $rule = $nsg.SecurityRules | Where-Object { $_.Name -eq "AllowHTTPS" }
            $rule | Should -Not -BeNullOrEmpty
            $rule.Protocol | Should -Be "Tcp"
            $rule.DestinationPortRange | Should -Be "443"
        }
        
        It "NSG2 should exist" {
            $nsg = Get-AzNetworkSecurityGroup -Name $script:nsg2Name -ErrorAction SilentlyContinue
            $nsg | Should -Not -BeNullOrEmpty
        }
        
        It "NSG2 should be in Canada East region" {
            $nsg = Get-AzNetworkSecurityGroup -Name $script:nsg2Name -ErrorAction SilentlyContinue
            $nsg.Location | Should -Be "canadaeast"
        }
        
        It "NSG2 should have AllowHTTPS rule" {
            $nsg = Get-AzNetworkSecurityGroup -Name $script:nsg2Name -ErrorAction SilentlyContinue
            $rule = $nsg.SecurityRules | Where-Object { $_.Name -eq "AllowHTTPS" }
            $rule | Should -Not -BeNullOrEmpty
            $rule.Protocol | Should -Be "Tcp"
            $rule.DestinationPortRange | Should -Be "443"
        }
    }
    
    Context "Private DNS Zone Tests" {
        It "Private DNS Zone 1 should exist" {
            $dnsZone = Get-AzPrivateDnsZone -Name $script:privateDns1Name -ErrorAction SilentlyContinue
            $dnsZone | Should -Not -BeNullOrEmpty
        }
        
        It "Private DNS Zone 2 should exist" {
            $dnsZone = Get-AzPrivateDnsZone -Name $script:privateDns2Name -ErrorAction SilentlyContinue
            $dnsZone | Should -Not -BeNullOrEmpty
        }
    }
}
