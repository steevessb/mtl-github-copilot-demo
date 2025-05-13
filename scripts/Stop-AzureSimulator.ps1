# Stop-AzureSimulator.ps1
# Stops the local Azure simulators
# Quality Engineer: Run this script after you're done testing locally

# Find and stop Azurite process
$azuriteDataPath = Join-Path $PSScriptRoot ".." "azurite-data"
$pidFile = "$azuriteDataPath\azurite.pid"

if (Test-Path $pidFile) {
    $processId = Get-Content $pidFile
    
    try {
        $process = Get-Process -Id $processId -ErrorAction SilentlyContinue
        if ($process) {
            Write-Host "Stopping Azurite (Process ID: $processId)..."
            Stop-Process -Id $processId -Force
            Write-Host "Azurite stopped successfully."
        } else {
            Write-Host "Azurite process not found. It may have been stopped already."
        }
    } catch {
        Write-Host "Error stopping Azurite: $_"
    }
    
    # Remove PID file
    Remove-Item $pidFile -Force -ErrorAction SilentlyContinue
} else {
    Write-Host "Azurite PID file not found. It may not be running."
}

# Clear environment variables
$env:AZURE_STORAGE_CONNECTION_STRING = $null
$env:AZURE_SIMULATOR_ENABLED = $null

Write-Host "Azure Simulator stopped and environment variables cleared."
