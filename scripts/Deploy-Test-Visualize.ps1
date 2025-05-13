# Deploy-Test-Visualize.ps1
# Script to deploy Azure resources from Bicep templates, run tests, and visualize results
param (
    [Parameter(Mandatory = $false)]
    [string]$EnvironmentName = "dev",
    
    [Parameter(Mandatory = $false)]
    [string]$Location = "eastus",
    
    [Parameter(Mandatory = $false)]
    [string]$ResourceGroupName = "qa-test-rg",
    
    [Parameter(Mandatory = $false)]
    [string]$VisualizerPort = 3000,
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipDeployment,
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipTests,
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipVisualization
)

# Script variables
$ErrorActionPreference = "Stop"
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootPath = Split-Path -Parent $scriptPath
$testResultsPath = Join-Path $rootPath "TestResults"
$visualizePath = Join-Path $rootPath "visualize"

Write-Host "========================================================="
Write-Host "Azure QA Automation Deploy, Test, and Visualize Tool"
Write-Host "========================================================="
Write-Host "Environment: $EnvironmentName"
Write-Host "Location: $Location"
Write-Host "Resource Group: $ResourceGroupName"
Write-Host "Visualizer Port: $VisualizerPort"
Write-Host "Root Directory: $rootPath"
Write-Host "Test Results Directory: $testResultsPath"
Write-Host "Visualizer Directory: $visualizePath"
Write-Host "========================================================="
Write-Host ""

# Check if resource group exists, create if it doesn't
$resourceGroup = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
if (-not $resourceGroup) {
    Write-Host "Creating resource group $ResourceGroupName in $Location..."
    $resourceGroup = New-AzResourceGroup -Name $ResourceGroupName -Location $Location
    Write-Host "Resource group created successfully."
}

# Create test results directory if it doesn't exist
if (-not (Test-Path $testResultsPath)) {
    New-Item -Path $testResultsPath -ItemType Directory -Force | Out-Null
    Write-Host "Created test results directory: $testResultsPath"
}

# Step 1: Deploy Infrastructure
if (-not $SkipDeployment) {
    Write-Host "Step 1: Deploying infrastructure..." -ForegroundColor Green
    
    # Building bicep file path
    $bicepFile = Join-Path $rootPath "infra/main.bicep"
    
    Write-Host "Deploying Bicep template: $bicepFile to resource group: $ResourceGroupName..."
    
    # Deploy the Bicep template
    $deployParams = @{
        ResourceGroupName = $ResourceGroupName
        TemplateFile      = $bicepFile
        environmentName   = $EnvironmentName
        location          = $Location
    }
    
    try {
        $deployment = New-AzResourceGroupDeployment @deployParams -Verbose
        Write-Host "Deployment completed successfully." -ForegroundColor Green
        
        # Extract deployment outputs for use by tests
        $deploymentOutputs = $deployment.Outputs
        $outputsFilePath = Join-Path $testResultsPath "deployment-outputs.json"
        $deploymentOutputs | ConvertTo-Json | Out-File -FilePath $outputsFilePath
        Write-Host "Deployment outputs saved to: $outputsFilePath"
    }
    catch {
        Write-Host "Deployment failed with error: $_" -ForegroundColor Red
        Write-Host $_.Exception.Message
        exit 1
    }
}
else {
    Write-Host "Skipping infrastructure deployment..."
}

# Step 2: Run Tests
if (-not $SkipTests) {
    Write-Host "Step 2: Running tests against deployed infrastructure..." -ForegroundColor Green
    
    # Import Infrastructure Fixtures
    $infrastructureFixturesPath = Join-Path $rootPath "src/InfrastructureFixtures.ps1"
    if (Test-Path $infrastructureFixturesPath) {
        . $infrastructureFixturesPath
        Write-Host "Infrastructure fixtures imported from $infrastructureFixturesPath"
    }
    else {
        Write-Host "Warning: Infrastructure fixtures file not found at: $infrastructureFixturesPath" -ForegroundColor Yellow
    }
    
    # Determine test files to run
    $testFiles = @(
        "StorageTests.ps1"
        "KeyVaultTests.ps1"
        "NetworkTests.ps1"
    )
    
    # Create timestamp for test result files
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    
    # Run each test file
    foreach ($testFile in $testFiles) {
        $testFilePath = Join-Path $rootPath "tests/$testFile"
        if (Test-Path $testFilePath) {
            $testResultFile = Join-Path $testResultsPath "$($testFile.Replace('.ps1',''))-$timestamp.xml"
            
            Write-Host "Running tests from $testFile..."
            try {
                # Run the Pester tests and generate an XML result file
                $pesterCommand = "Invoke-Pester -Path '$testFilePath' -OutputFile '$testResultFile' -OutputFormat NUnitXml -PassThru"
                $testResults = Invoke-Expression $pesterCommand
                
                # Report test results
                Write-Host "Tests completed with $($testResults.PassedCount) passed, $($testResults.FailedCount) failed, $($testResults.SkippedCount) skipped tests"
                Write-Host "Test results saved to: $testResultFile"
            }
            catch {
                Write-Host "Error running tests in $testFile : $_" -ForegroundColor Red
            }
        }
        else {
            Write-Host "Warning: Test file not found: $testFilePath" -ForegroundColor Yellow
        }
    }
}
else {
    Write-Host "Skipping test execution..."
}

# Step 3: Start Visualizer and Upload Results
if (-not $SkipVisualization) {
    Write-Host "Step 3: Starting visualizer and uploading test results..." -ForegroundColor Green
    
    # Check if Node.js is installed
    try {
        $nodeVersion = node -v
        Write-Host "Node.js version: $nodeVersion"
    }
    catch {
        Write-Host "Node.js is not installed or not in PATH. Please install Node.js to use the visualizer." -ForegroundColor Red
        exit 1
    }
    
    # Start the visualizer in the background
    $visualizerScript = Join-Path $visualizePath "server.js"
    if (Test-Path $visualizerScript) {
        try {
            # Check if visualizer is already running
            $testConnection = $null
            try {
                $testConnection = Invoke-WebRequest -Uri "http://localhost:$VisualizerPort" -TimeoutSec 2 -ErrorAction SilentlyContinue
            }
            catch {
                # Connection failed, which means server is not running
            }
            
            if ($testConnection -and $testConnection.StatusCode -eq 200) {
                Write-Host "Visualizer is already running on port $VisualizerPort"
            }
            else {
                # Change directory to visualizer folder
                Push-Location $visualizePath
                
                # Start the visualizer in a new window
                Start-Process powershell -ArgumentList "-Command cd '$visualizePath'; node server.js" -WindowStyle Normal
                
                # Go back to original directory
                Pop-Location
                
                # Wait for the server to start
                Write-Host "Waiting for visualizer to start..."
                Start-Sleep -Seconds 5
                Write-Host "Visualizer started on port $VisualizerPort"
            }
            
            # Upload test results to the visualizer
            # Find all XML test results from this run
            $testResultFiles = Get-ChildItem -Path $testResultsPath -Filter "*-$timestamp.xml"
            if ($testResultFiles.Count -gt 0) {
                foreach ($resultFile in $testResultFiles) {
                    $uploadUrl = "http://localhost:$VisualizerPort/upload"
                    $filePath = $resultFile.FullName
                    
                    Write-Host "Uploading test results from $($resultFile.Name) to visualizer..."
                    
                    # Use curl to upload the file
                    $curlCommand = "curl -X POST -F `"file=@$filePath`" $uploadUrl"
                    Invoke-Expression $curlCommand
                    
                    Write-Host "Upload completed"
                }
                
                # Open the visualization in the default browser
                Start-Process "http://localhost:$VisualizerPort"
                Write-Host "Visualization opened in browser"
            }
            else {
                Write-Host "No test result files found to upload" -ForegroundColor Yellow
            }
        }
        catch {
            Write-Host "Error starting or using visualizer: $_" -ForegroundColor Red
        }
    }
    else {
        Write-Host "Warning: Visualizer server script not found at: $visualizerScript" -ForegroundColor Yellow
    }
}
else {
    Write-Host "Skipping visualization..."
}

Write-Host ""
Write-Host "========================================================="
Write-Host "Process completed!"
Write-Host "========================================================="
