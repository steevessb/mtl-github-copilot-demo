# DiscoveryPhase.ps1
# Centralizes all Azure Cloud AZ queries for test discovery
# Quality Engineer: Dot-source this file in all test scripts to ensure consistent environment discovery

# Check if we're running in simulation mode
if ($env:AZURE_SIMULATOR_ENABLED -eq "true") {
    Write-Host "Running in simulator mode. Skipping actual Azure queries."
    # Use mock values for simulator mode
    $actualStorageAccounts = @()
} else {
    # Only execute real queries if not in simulator mode
    BeforeDiscovery {
        $actualStorageAccounts = Get-AzStorageAccount
        # Add more Az resource queries as needed
    }
}
