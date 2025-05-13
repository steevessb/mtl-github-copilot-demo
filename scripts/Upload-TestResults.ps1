# Upload-TestResults.ps1
# Uploads Pester test results to the visualizer server
# Quality Engineer: This script uploads test results to the visualization server

param (
    [Parameter(Mandatory=$true)]
    [string]$TestResultFile,
    
    [string]$VisualizerUrl = "http://localhost:3000"
)

# Validate test result file exists
if (-not (Test-Path $TestResultFile)) {
    Write-Error "Test result file not found at $TestResultFile"
    exit 1
}

# Get the file name from the path
$fileName = Split-Path -Leaf $TestResultFile

Write-Host "Uploading test results from $fileName to visualizer..."

try {
    # Upload the file using Invoke-RestMethod
    $formData = @{
        testResults = Get-Item -Path $TestResultFile
    }
    
    $response = Invoke-RestMethod -Uri "$VisualizerUrl/upload" -Method Post -Form $formData
    
    Write-Host "Upload completed"
    
    if ($response -match "report/report-\d+") {
        # Extract the report ID
        $reportId = $response -replace ".*?report/(report-\d+).*", '$1'
        return $reportId
    }
} catch {
    Write-Error "Error uploading test results: $_"
    exit 1
}
