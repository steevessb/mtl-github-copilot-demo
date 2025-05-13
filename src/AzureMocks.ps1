# AzureMocks.ps1
# PowerShell mocks for Azure services
# Quality Engineer: This file provides mock objects for local testing

function Initialize-AzureMocks {
    [CmdletBinding()]
    param()

    # Path to the mock data directory
    $mockDataPath = Join-Path $PSScriptRoot ".." "mock-data"
    $mockFixturesPath = Join-Path $mockDataPath "AzureFixtures.yml"

    # Load mock data from YAML
    if (Test-Path $mockFixturesPath) {
        $fixtures = & "$PSScriptRoot/LoadYamlFixtures.ps1" -YamlFilePath $mockFixturesPath
    } else {
        Write-Warning "Mock fixtures not found at $mockFixturesPath"
        $fixtures = @{
            storageAccounts = @()
            resourceGroups = @()
            networkSecurityGroups = @()
        }
    }

    # Mock Storage Accounts
    $script:MockStorageAccounts = @()
    foreach ($sa in $fixtures.storageAccounts) {
        $mockStorageAccount = [PSCustomObject]@{
            StorageAccountName = $sa.name
            Location = $sa.location
            EnableHttpsTrafficOnly = $true
            MinimumTlsVersion = "TLS1_2"
            AllowBlobPublicAccess = $false
            Kind = $sa.type
            Sku = @{
                Name = $sa.sku
            }
            Tags = @{}
        }

        # Add tags
        foreach ($tagPair in $sa.tags) {
            foreach ($key in $tagPair.Keys) {
                $mockStorageAccount.Tags[$key] = $tagPair[$key]
            }
        }

        $script:MockStorageAccounts += $mockStorageAccount
    }

    # Mock Key Vaults
    $script:MockKeyVaults = @(
        [PSCustomObject]@{
            VaultName = "kv-dev-01"
            Location = "eastus"
            EnableSoftDelete = $true
            EnablePurgeProtection = $false
            Tags = @{
                Environment = "Development"
                Owner = "QA Team"
            }
        },
        [PSCustomObject]@{
            VaultName = "kv-prod-01"
            Location = "canadaeast"
            EnableSoftDelete = $true
            EnablePurgeProtection = $true
            Tags = @{
                Environment = "Production"
                Owner = "Operations"
            }
        }
    )

    # Mock Web Apps
    $script:MockWebApps = @(
        [PSCustomObject]@{
            Name = "webapp-dev-01"
            Location = "eastus"
            HttpsOnly = $true
            SiteConfig = @{
                MinTlsVersion = "1.2"
            }
            Tags = @{
                Environment = "Development"
            }
        },
        [PSCustomObject]@{
            Name = "webapp-prod-01"
            Location = "canadaeast"
            HttpsOnly = $true
            SiteConfig = @{
                MinTlsVersion = "1.2"
            }
            Tags = @{
                Environment = "Production"
            }
        }
    )

    # Mock SQL Servers
    $script:MockSqlServers = @(
        [PSCustomObject]@{
            ServerName = "sql-dev-01"
            ResourceGroupName = "rg-dev"
            Location = "eastus"
            Tags = @{
                Environment = "Development"
            }
        },
        [PSCustomObject]@{
            ServerName = "sql-prod-01"
            ResourceGroupName = "rg-prod"
            Location = "canadaeast"
            Tags = @{
                Environment = "Production"
            }
        }
    )

    # Mock Azure AD Administrator
    $script:MockAzureADAdmin = [PSCustomObject]@{
        DisplayName = "SQL Admin"
        ObjectId = "00000000-0000-0000-0000-000000000000"
    }

    # Mock SQL Audit Policy
    $script:MockSqlAuditPolicy = [PSCustomObject]@{
        BlobStorageTargetState = "Enabled"
    }
}

# Functions to mock Azure PowerShell cmdlets
function MockGet-AzStorageAccount {
    return $script:MockStorageAccounts
}

function MockGet-AzKeyVault {
    return $script:MockKeyVaults
}

function MockGet-AzWebApp {
    return $script:MockWebApps
}

function MockGet-AzSqlServer {
    return $script:MockSqlServers
}

function MockGet-AzSqlServerActiveDirectoryAdministrator {
    param (
        [string]$ResourceGroupName,
        [string]$ServerName
    )
    
    # In a real mock, we'd filter by parameters
    return $script:MockAzureADAdmin
}

function MockGet-AzSqlServerAudit {
    param (
        [string]$ResourceGroupName,
        [string]$ServerName
    )
    
    # In a real mock, we'd filter by parameters
    return $script:MockSqlAuditPolicy
}

# Setup the mocks if running in simulator mode
function Setup-AzureMocks {
    # Initialize the mock data
    Initialize-AzureMocks
    
    # Mock Azure PowerShell cmdlets
    Mock -CommandName Get-AzStorageAccount -MockWith { MockGet-AzStorageAccount }
    Mock -CommandName Get-AzKeyVault -MockWith { MockGet-AzKeyVault }
    Mock -CommandName Get-AzWebApp -MockWith { MockGet-AzWebApp }
    Mock -CommandName Get-AzSqlServer -MockWith { MockGet-AzSqlServer }
    Mock -CommandName Get-AzSqlServerActiveDirectoryAdministrator -MockWith { MockGet-AzSqlServerActiveDirectoryAdministrator @PSBoundParameters }
    Mock -CommandName Get-AzSqlServerAudit -MockWith { MockGet-AzSqlServerAudit @PSBoundParameters }
    
    Write-Host "Azure service mocks have been set up for local testing"
}
