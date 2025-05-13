@{
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
    KeyVaults = @(
        @{
            Name = "kv1"
            Location = "eastus"
            Sku = "standard"
            EnableSoftDelete = $true
            EnablePurgeProtection = $true
        },
        @{
            Name = "kv2"
            Location = "canadaeast"
            Sku = "standard"
            EnableSoftDelete = $true
            EnablePurgeProtection = $true
        }
    )
    VirtualNetworks = @(
        @{
            Name = "vnet1"
            Location = "eastus"
            AddressPrefixes = @("10.0.0.0/16")
        },
        @{
            Name = "vnet2"
            Location = "canadaeast"
            AddressPrefixes = @("10.1.0.0/16")
        }
    )
    Subnets = @(
        @{
            Name = "subnet1"
            Location = "eastus"
            VirtualNetworkName = "vnet1"
            AddressPrefix = "10.0.0.0/24"
        },
        @{
            Name = "subnet2"
            Location = "canadaeast"
            VirtualNetworkName = "vnet2"
            AddressPrefix = "10.1.0.0/24"
        }
    )
    NetworkSecurityGroups = @(
        @{
            Name = "nsg1"
            Location = "eastus"
            SecurityRules = @(
                @{
                    Name = "rule1"
                    Protocol = "Tcp"
                    SourcePortRange = "*"
                    DestinationPortRange = "443"
                    SourceAddressPrefix = "*"
                    DestinationAddressPrefix = "*"
                    Access = "Allow"
                    Priority = 100
                    Direction = "Inbound"
                }
            )
        },
        @{
            Name = "nsg2"
            Location = "canadaeast"
            SecurityRules = @(
                @{
                    Name = "rule2"
                    Protocol = "Tcp"
                    SourcePortRange = "*"
                    DestinationPortRange = "443"
                    SourceAddressPrefix = "*"
                    DestinationAddressPrefix = "*"
                    Access = "Allow"
                    Priority = 100
                    Direction = "Inbound"
                }
            )
        }
    )
    TestUsers = @(
        @{
            Name = "testuser1"
            Location = "eastus"
        },
        @{
            Name = "testuser2"
            Location = "canadaeast"
        }
    )
}
