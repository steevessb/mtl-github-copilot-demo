# Deploy-Test-Report.ps1
# Unified script to deploy, test, and report on Azure infrastructure
# Quality Engineer: Run this script to execute the full end-to-end process

param (
    [switch]$UseLocalSimulator, # Set to use Azurite instead of real Azure
    [switch]$SkipDeploy,        # Skip the deployment step
    [switch]$SkipTests,         # Skip the testing step
    [switch]$SkipReporting      # Skip the reporting/visualization step
)

# Global variables
$rootDir = Split-Path -Parent $PSScriptRoot
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$testResultsDir = Join-Path $rootDir "TestResults"
$visualizerDir = Join-Path $rootDir "visualize"

# Ensure test results directory exists
if (-not (Test-Path $testResultsDir)) {
    New-Item -Path $testResultsDir -ItemType Directory -Force | Out-Null
}

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "Azure Infrastructure Deploy, Test, and Report Tool" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "Mode: $(if ($UseLocalSimulator) { 'Local Simulator' } else { 'Real Azure' })"
Write-Host "Root Directory: $rootDir"
Write-Host "Test Results Directory: $testResultsDir"
Write-Host "Visualizer Directory: $visualizerDir"
Write-Host "Timestamp: $timestamp"
Write-Host "==========================================================" -ForegroundColor Cyan

# Check for PowerShell modules
function Ensure-ModuleInstalled {
    param (
        [string]$ModuleName
    )
    
    if (-not (Get-Module -ListAvailable -Name $ModuleName)) {
        Write-Host "Installing $ModuleName module..." -ForegroundColor Yellow
        Install-Module -Name $ModuleName -Force -AllowClobber -Scope CurrentUser
    }
}

# Check for required modules
Ensure-ModuleInstalled -ModuleName "Az"
Ensure-ModuleInstalled -ModuleName "Pester"

# Step 1: Deploy Infrastructure
if (-not $SkipDeploy) {
    Write-Host "`nStep 1: Deploying infrastructure..." -ForegroundColor Green
    
    if ($UseLocalSimulator) {
        # For local simulation, we'll just set up the mock data without requiring Azurite
        Write-Host "Using local simulation without real Azure resources..." -ForegroundColor Yellow
        
        # Set environment variable to indicate we're using local simulation
        $env:AZURE_SIMULATOR_ENABLED = "true"
          # Set up local test data
        $infrastructureFixturesPath = Join-Path $rootDir "src\InfrastructureFixtures.ps1"
        
        # Source the fixtures file to get the expected resources
        if (Test-Path $infrastructureFixturesPath) {
            . $infrastructureFixturesPath
            
            # Create the mock test data based on fixtures
            # This simulates the Azure deployment output
            $mockDeploymentData = @{
                storageAccount1 = @{ 
                    Name = $expectedStorageAccounts[0].Name
                    Location = $expectedStorageAccounts[0].Location
                }
                storageAccount2 = @{ 
                    Name = $expectedStorageAccounts[1].Name
                    Location = $expectedStorageAccounts[1].Location
                }
                keyVault1 = @{ 
                    Name = $expectedKeyVaults[0].Name
                    Location = $expectedKeyVaults[0].Location
                }
                keyVault2 = @{ 
                    Name = $expectedKeyVaults[1].Name
                    Location = $expectedKeyVaults[1].Location
                }
                vnet1 = @{ 
                    Name = $expectedVnets[0].Name
                    Location = $expectedVnets[0].Location
                }
                vnet2 = @{ 
                    Name = $expectedVnets[1].Name
                    Location = $expectedVnets[1].Location
                }
            }
            
            # Save mock deployment outputs for reference
            $mockDeploymentOutputFile = Join-Path $testResultsDir "deployment-outputs.json"
            $mockDeploymentData | ConvertTo-Json -Depth 4 | Out-File $mockDeploymentOutputFile
            Write-Host "Mock deployment outputs saved to: $mockDeploymentOutputFile" -ForegroundColor Green
            
            Write-Host "Local simulation environment is ready for testing" -ForegroundColor Green
        } else {
            Write-Warning "Infrastructure fixtures not found at: $infrastructureFixturesPath"
        }
    } else {
        # Deploy using Bicep
        $deployScript = Join-Path $rootDir "scripts\Deploy-Resources.ps1"
        if (Test-Path $deployScript) {
            & $deployScript
        } else {
            Write-Error "Deploy-Resources.ps1 script not found at $deployScript"
            exit 1
        }
    }
}

# Step 2: Run Tests
if (-not $SkipTests) {
    Write-Host "`nStep 2: Running tests..." -ForegroundColor Green
    
    # Determine which test files to use
    if ($UseLocalSimulator) {
        $testFiles = @(
            "SimpleStorageSimulatorTests.ps1",
            "KeyVaultSimulatorTests.ps1",
            "NetworkSimulatorTests.ps1"
        )
        $testTag = "LocalSimulator"
    } else {
        $testFiles = @(
            "StorageTests.ps1",
            "KeyVaultTests.ps1",
            "NetworkTests.ps1"
        )
        $testTag = "AzureCloud"
    }
    
    # Run each test file
    foreach ($testFile in $testFiles) {
        $testFilePath = Join-Path $rootDir "tests\$testFile"
        
        if (Test-Path $testFilePath) {
            Write-Host "Running tests from $testFile..."
            
            try {
                # Test result file path
                $testResultFile = Join-Path $testResultsDir "$($testFile.Replace('.ps1',''))-$timestamp.xml"
                
                # Use the proper Pester configuration
                $pesterConfig = [PesterConfiguration]::Default
                $pesterConfig.Run.Path = $testFilePath
                $pesterConfig.Run.PassThru = $true
                $pesterConfig.Filter.Tag = $testTag
                $pesterConfig.TestResult.Enabled = $true
                $pesterConfig.TestResult.OutputFormat = "NUnitXml"
                $pesterConfig.TestResult.OutputPath = $testResultFile
                
                $testResults = Invoke-Pester -Configuration $pesterConfig
                
                # Report test results
                Write-Host "Tests completed with $($testResults.PassedCount) passed, $($testResults.FailedCount) failed, $($testResults.SkippedCount) skipped tests"
                Write-Host "Test results saved to: $testResultFile"
            } catch {
                Write-Host "Error running tests in $testFile : $_" -ForegroundColor Red
            }
        } else {
            Write-Warning "Test file not found: $testFilePath"
        }
    }
}

# Step 3: Start Visualization and Upload Results
if (-not $SkipReporting) {
    Write-Host "`nStep 3: Starting visualizer and uploading test results..." -ForegroundColor Green
    
    # Start visualizer if not already running
    $startVisualizerScript = Join-Path $rootDir "scripts\Start-Visualizer.ps1"
    if (Test-Path $startVisualizerScript) {
        & $startVisualizerScript
    } else {
        Write-Error "Start-Visualizer.ps1 script not found at $startVisualizerScript"
        exit 1
    }
    
    # Find and upload test results
    $testResultFiles = Get-ChildItem -Path $testResultsDir -Filter "*-$timestamp.xml"
    
    if ($testResultFiles.Count -eq 0) {
        Write-Warning "No test result files found for timestamp $timestamp"
    } else {
        # Upload each test result file
        foreach ($testResultFile in $testResultFiles) {
            $uploadScript = Join-Path $rootDir "scripts\Upload-TestResults.ps1"
            if (Test-Path $uploadScript) {
                & $uploadScript -TestResultFile $testResultFile.FullName
            } else {
                Write-Warning "Upload-TestResults.ps1 script not found at $uploadScript"
            }
        }
        
        # Open visualizer in browser
        $visualizerUrl = "http://localhost:3000"
        Write-Host "Opening visualizer in browser: $visualizerUrl"
        Start-Process $visualizerUrl
    }
}

# Clean up if using local simulator
if ($UseLocalSimulator -and -not $SkipDeploy) {
    # Clean up environment variables
    $env:AZURE_SIMULATOR_ENABLED = $null
    Write-Host "Local simulation environment variables cleared" -ForegroundColor Yellow
}

Write-Host "`n==========================================================" -ForegroundColor Cyan
Write-Host "Process completed!" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Cyan
