# InfrastructureFixtures.ps1
# Contains expected Azure objects and configurations for validation
# Quality Engineer: Update these fixtures to match your environment specs
$expectedStorageAccounts = @(
    @{ Name = 'storage1'; Location = 'eastus' },
    @{ Name = 'storage2'; Location = 'canadaeast' }
)
# Add more expected resources as needed
