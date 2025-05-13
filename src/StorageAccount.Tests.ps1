# Example Pester Test: StorageAccount.Tests.ps1
# Data-driven test comparing actual vs expected Azure Storage Accounts
# Quality Engineer: Use Describe/It blocks for BDD, iterate over fixtures
. $PSScriptRoot/DiscoveryPhase.ps1
. $PSScriptRoot/InfrastructureFixtures.ps1
Describe 'Azure Storage Accounts' {
    foreach ($expected in $expectedStorageAccounts) {
        It "should exist: $($expected.Name) in $($expected.Location)" {
            $actual = $actualStorageAccounts | Where-Object { $_.StorageAccountName -eq $expected.Name -and $_.Location -eq $expected.Location }
            $actual | Should -Not -BeNullOrEmpty
        }
    }
}
