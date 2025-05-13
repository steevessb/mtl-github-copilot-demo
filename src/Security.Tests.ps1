# Security.Tests.ps1
# Tests for security compliance and best practices
# Quality Engineer: Update this file to match your organization's security requirements

. $PSScriptRoot/DiscoveryPhase.ps1

# Include mock implementation for local simulator
$usingLocalSimulator = $false
if ($env:AZURE_SIMULATOR_ENABLED -eq "true") {
    # For local testing using mocks
    . $PSScriptRoot/AzureMocks.ps1
    $usingLocalSimulator = $true
}

Describe 'Azure Security Compliance Tests' -Tag @('Security', 'Compliance', 'LocalSimulator') {    BeforeAll {
        # Setup mocks if running in simulator mode
        if ($usingLocalSimulator) {
            Write-Host "Running tests with local Azure simulator"
            Setup-AzureMocks
            
            # Use mock data directly
            $script:storageAccounts = MockGet-AzStorageAccount
            $script:keyVaults = MockGet-AzKeyVault
            $script:webApps = MockGet-AzWebApp
            $script:sqlServers = MockGet-AzSqlServer
        } else {
            # Retrieve resources to test from real Azure
            $script:storageAccounts = Get-AzStorageAccount
            $script:keyVaults = Get-AzKeyVault
            $script:webApps = Get-AzWebApp
            $script:sqlServers = Get-AzSqlServer
        }
    }
    
    Context 'Storage Account Security' {
        It 'All Storage Accounts should have HTTPS-only enabled' {
            foreach ($sa in $script:storageAccounts) {
                $sa.EnableHttpsTrafficOnly | Should -BeTrue -Because "Storage Account '$($sa.StorageAccountName)' should have HTTPS-only traffic enabled"
            }
        }
        
        It 'All Storage Accounts should have minimum TLS 1.2' {
            foreach ($sa in $script:storageAccounts) {
                $sa.MinimumTlsVersion | Should -BeIn @('TLS1_2') -Because "Storage Account '$($sa.StorageAccountName)' should use TLS 1.2 or higher"
            }
        }
        
        It 'All Storage Accounts should have Blob Public Access disabled' {
            foreach ($sa in $script:storageAccounts) {
                $sa.AllowBlobPublicAccess | Should -BeFalse -Because "Storage Account '$($sa.StorageAccountName)' should not allow public blob access"
            }
        }
    }
    
    Context 'Key Vault Security' {
        It 'All Key Vaults should have Soft Delete enabled' {
            foreach ($kv in $script:keyVaults) {
                $kv.EnableSoftDelete | Should -BeTrue -Because "Key Vault '$($kv.VaultName)' should have soft delete enabled"
            }
        }
        
        It 'All Key Vaults should have Purge Protection enabled in Production' {
            foreach ($kv in $script:keyVaults) {
                # Check if this is a production key vault (based on naming convention or tags)
                $isProd = $kv.Tags.Environment -eq 'Production' -or $kv.VaultName -like '*prod*'
                
                if ($isProd) {
                    $kv.EnablePurgeProtection | Should -BeTrue -Because "Production Key Vault '$($kv.VaultName)' should have purge protection enabled"
                }
            }
        }
    }
    
    Context 'Web App Security' {
        It 'All Web Apps should have HTTPS-only enabled' {
            foreach ($app in $script:webApps) {
                $app.HttpsOnly | Should -BeTrue -Because "Web App '$($app.Name)' should have HTTPS-only enabled"
            }
        }
        
        It 'All Web Apps should use minimum TLS 1.2' {
            foreach ($app in $script:webApps) {
                $app.SiteConfig.MinTlsVersion | Should -BeIn @('1.2') -Because "Web App '$($app.Name)' should use TLS 1.2 or higher"
            }
        }
    }
    
    Context 'SQL Server Security' {
        It 'All SQL Servers should have Azure AD authentication enabled' {
            foreach ($sql in $script:sqlServers) {
                $adAdmin = Get-AzSqlServerActiveDirectoryAdministrator -ResourceGroupName $sql.ResourceGroupName -ServerName $sql.ServerName
                $adAdmin | Should -Not -BeNullOrEmpty -Because "SQL Server '$($sql.ServerName)' should have Azure AD authentication enabled"
            }
        }
        
        It 'All SQL Servers should have Auditing enabled' {
            foreach ($sql in $script:sqlServers) {
                $auditPolicy = Get-AzSqlServerAudit -ResourceGroupName $sql.ResourceGroupName -ServerName $sql.ServerName
                $auditPolicy.BlobStorageTargetState | Should -Be 'Enabled' -Because "SQL Server '$($sql.ServerName)' should have auditing enabled"
            }
        }
    }
}
