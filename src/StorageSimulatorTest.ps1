# StorageSimulatorTest.ps1
# Example test using Azurite storage emulator
# Quality Engineer: This demonstrates interaction with a real storage emulator

Describe 'Azurite Storage Tests' -Tag 'LocalSimulator' {
    BeforeAll {
        # Check if we're running with the simulator
        if ($env:AZURE_SIMULATOR_ENABLED -ne "true") {
            Write-Host "Warning: Azurite simulator not detected. These tests require the simulator to be running."
            return
        }
        
        # Load the test data
        $testDataPath = Join-Path $PSScriptRoot "../mock-data/AzuriteTestData.psd1"
        $testData = Import-PowerShellDataFile -Path $testDataPath
        
        # Connect to Azurite
        $storageAccount = "devstoreaccount1"
        $storageKey = "Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw=="
        $context = New-AzStorageContext -StorageAccountName $storageAccount -StorageAccountKey $storageKey -Protocol Http -Endpoint "http://127.0.0.1:10000/$storageAccount"
        
        # Create container and upload test blob
        New-AzStorageContainer -Name $testData.container -Context $context -ErrorAction SilentlyContinue | Out-Null
        $testData.content | Out-File -FilePath "temp-blob.txt" -Force
        Set-AzStorageBlobContent -File "temp-blob.txt" -Container $testData.container -Blob $testData.blob -Context $context -Force | Out-Null
        Remove-Item -Path "temp-blob.txt" -Force
        
        # Store context and test data for use in tests
        $script:storageContext = $context
        $script:testData = $testData
    }
    
    AfterAll {
        # Clean up test container
        if ($env:AZURE_SIMULATOR_ENABLED -eq "true" -and $script:storageContext) {
            Remove-AzStorageContainer -Name $script:testData.container -Context $script:storageContext -Force -ErrorAction SilentlyContinue
        }
    }
    
    Context 'Blob Operations' {
        It 'Should create and retrieve a blob' {
            # Get the blob
            $blob = Get-AzStorageBlob -Container $script:testData.container -Blob $script:testData.blob -Context $script:storageContext
            
            # Validate blob properties
            $blob | Should -Not -BeNullOrEmpty
            $blob.Name | Should -Be $script:testData.blob
        }
        
        It 'Should retrieve blob content' {
            # Download the blob content
            $tempFile = "temp-download.txt"
            Get-AzStorageBlobContent -Container $script:testData.container -Blob $script:testData.blob -Context $script:storageContext -Destination $tempFile -Force | Out-Null
            
            # Validate content
            $content = Get-Content -Path $tempFile -Raw
            $content | Should -Be $script:testData.content
            
            # Clean up
            Remove-Item -Path $tempFile -Force
        }
    }
    
    Context 'Container Operations' {
        It 'Should list containers' {
            $containers = Get-AzStorageContainer -Context $script:storageContext
            $containers | Should -Not -BeNullOrEmpty
            $containers.Name | Should -Contain $script:testData.container
        }
    }
}
