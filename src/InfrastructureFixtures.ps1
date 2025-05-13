# InfrastructureFixtures.ps1
# Contains expected Azure objects and configurations for validation
# Quality Engineer: Update these fixtures to match your environment specs
$expectedStorageAccounts = @(
    @{ Name = 'storage1'; Location = 'eastus' },
    @{ Name = 'storage2'; Location = 'canadaeast' }
)
# Add more expected resources as needed
$expectedResourceGroups = @(
    @{ Name = 'qa-test-rg'; Location = 'canadaeast' },
    @{ Name = 'prod-test-rg'; Location = 'canadaeast' }
)
#add keyvaults, private dns zones, vnets, subnets, nsgs, etc.
$expectedKeyVaults = @(
    @{ Name = 'kv1'; Location = 'eastus' },
    @{ Name = 'kv2'; Location = 'canadaeast' }
)
$expectedPrivateDnsZones = @(
    @{ Name = 'privatedns1'; Location = 'eastus' },
    @{ Name = 'privatedns2'; Location = 'canadaeast' }
)
$expectedVnets = @(
    @{ Name = 'vnet1'; Location = 'eastus' },
    @{ Name = 'vnet2'; Location = 'canadaeast' }
)
#subnets
$expectedSubnets = @(
    @{ Name = 'subnet1'; Location = 'eastus' },
    @{ Name = 'subnet2'; Location = 'canadaeast' }
)
#nsgs
$expectedNsgs = @(
    @{ Name = 'nsg1'; Location = 'eastus' },
    @{ Name = 'nsg2'; Location = 'canadaeast' }
)
#add test data like ip ranges as rules for private network
$expectedNsgRules = @(
    @{ Name = 'rule1'; Location = 'eastus' },
    @{ Name = 'rule2'; Location = 'canadaeast' }
)
#add a test user that can connect with vault values
$expectedTestUser = @(
    @{ Name = 'testuser1'; Location = 'eastus' },
    @{ Name = 'testuser2'; Location = 'canadaeast' }
)