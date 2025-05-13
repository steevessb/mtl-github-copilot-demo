# Start-AzureSimulator.ps1
# Starts the local Azure simulators for testing
# Quality Engineer: Run this script before running your tests locally

# Create data directory if it doesn't exist
$azuriteDataPath = Join-Path $PSScriptRoot ".." "azurite-data"
if (-not (Test-Path $azuriteDataPath)) {
    New-Item -Path $azuriteDataPath -ItemType Directory -Force | Out-Null
}

# Start Azurite in the background
$azuriteProcess = Start-Process -PassThru -FilePath "azurite" -ArgumentList "--silent", "--location", $azuriteDataPath, "--debug", "$azuriteDataPath\debug.log"

# Display connection information
Write-Host "Azurite is running (Process ID: $($azuriteProcess.Id))"
Write-Host "Blob Service: http://127.0.0.1:10000"
Write-Host "Queue Service: http://127.0.0.1:10001"
Write-Host "Table Service: http://127.0.0.1:10002"

# Save process ID to file for stopping later
$azuriteProcess.Id | Out-File -FilePath "$azuriteDataPath\azurite.pid" -Force

# Set environment variables for tests
$env:AZURE_STORAGE_CONNECTION_STRING = "DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;BlobEndpoint=http://127.0.0.1:10000/devstoreaccount1;QueueEndpoint=http://127.0.0.1:10001/devstoreaccount1;TableEndpoint=http://127.0.0.1:10002/devstoreaccount1;"
$env:AZURE_SIMULATOR_ENABLED = "true"

Write-Host "Environment variables set for local testing."
Write-Host "To stop Azurite, run: Stop-AzureSimulator.ps1"
Write-Host "To run tests with the simulator, use: Invoke-Pester -Path ./src -Tag 'LocalSimulator'"
