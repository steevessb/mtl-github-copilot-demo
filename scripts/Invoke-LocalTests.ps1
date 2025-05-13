# Invoke-LocalTests.ps1
# Script to run tests using the local Azure simulator
# Quality Engineer: Run this script to execute tests locally without Azure subscription

param(
    [Parameter(Mandatory=$false)]
    [string]$TestPath = "$PSScriptRoot/../src",
    
    [Parameter(Mandatory=$false)]
    [string]$Tag = "LocalSimulator",
    
    [Parameter(Mandatory=$false)]
    [switch]$ExportResults,
    
    [Parameter(Mandatory=$false)]
    [switch]$Visualize
)

# Check if simulator is running
if ($env:AZURE_SIMULATOR_ENABLED -ne "true") {
    Write-Host "Azure simulator is not running. Starting simulator..."
    & "$PSScriptRoot/Start-AzureSimulator.ps1"
}

# Import required modules - forcing version 5.3.3
$requiredVersion = "5.3.3"
$pesterModule = Get-Module -Name Pester -ListAvailable | Where-Object { $_.Version -eq $requiredVersion }

if ($pesterModule) {
    Import-Module -Name Pester -RequiredVersion $requiredVersion -Force
    Write-Host "Using Pester version $requiredVersion" -ForegroundColor Green
} else {
    Write-Host "Pester version $requiredVersion not found. Installing..." -ForegroundColor Yellow
    Install-Module -Name Pester -RequiredVersion $requiredVersion -Force -SkipPublisherCheck
    Import-Module -Name Pester -RequiredVersion $requiredVersion -Force
    Write-Host "Pester version $requiredVersion installed and loaded" -ForegroundColor Green
}

# Configure Pester
$pesterConfig = New-PesterConfiguration
$pesterConfig.Run.Path = $TestPath
$pesterConfig.Filter.Tag = $Tag
$pesterConfig.Output.Verbosity = 'Detailed'

if ($ExportResults) {
    # Create results directory if it doesn't exist
    $resultsDir = "$PSScriptRoot/../test-results"
    if (-not (Test-Path $resultsDir)) {
        New-Item -Path $resultsDir -ItemType Directory -Force | Out-Null
    }
    
    $resultsPath = "$resultsDir/TestResults-Local-$(Get-Date -Format 'yyyy-MM-dd-HHmmss').xml"
    $pesterConfig.TestResult.Enabled = $true
    $pesterConfig.TestResult.OutputFormat = 'NUnitXml'
    $pesterConfig.TestResult.OutputPath = $resultsPath
}

# Run tests
Write-Host "Running tests with local Azure simulator..." -ForegroundColor Cyan
$testResults = Invoke-Pester -Configuration $pesterConfig -PassThru

# Display results summary
Write-Host ""
Write-Host "Test Results Summary:" -ForegroundColor Cyan
Write-Host "Total: $($testResults.TotalCount)" -ForegroundColor White
Write-Host "Passed: $($testResults.PassedCount)" -ForegroundColor Green
Write-Host "Failed: $($testResults.FailedCount)" -ForegroundColor Red
Write-Host "Skipped: $($testResults.SkippedCount)" -ForegroundColor Yellow
Write-Host ""

if ($ExportResults) {
    Write-Host "Test results exported to: $resultsPath" -ForegroundColor Green
    
    # Launch visualizer if requested
    if ($Visualize) {
        Write-Host "Launching visualizer with test results..." -ForegroundColor Cyan
        & "$PSScriptRoot/Test-Visualizer.ps1" -TestResultPath $resultsPath -StartVisualizer
    }
}

# Note: The simulator will continue running
# To stop it, run: ./scripts/Stop-AzureSimulator.ps1
Write-Host "Tests complete. The local Azure simulator is still running."
Write-Host "To stop the simulator, run: ./scripts/Stop-AzureSimulator.ps1"
