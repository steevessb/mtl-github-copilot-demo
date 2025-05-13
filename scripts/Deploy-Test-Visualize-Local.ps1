# Deploy-Test-Visualize-Local.ps1
# Script to simulate deployment of Azure resources using Azurite, run tests, and visualize results
# Uses local simulators and InfrastructureFixtures.ps1 data

param (
    [Parameter(Mandatory = $false)]
    [string]$VisualizerPort = 3000,
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipSimulatorSetup,
    
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
$mockDataPath = Join-Path $rootPath "mock-data"
$azuriteDataPath = Join-Path $rootPath "azurite-data"
$infrastructureFixturesPath = Join-Path $rootPath "src/InfrastructureFixtures.ps1"

Write-Host "========================================================="
Write-Host "Azure QA Automation Local Simulator Deploy, Test, and Visualize Tool"
Write-Host "========================================================="
Write-Host "Using local Azure simulators (Azurite) instead of real Azure"
Write-Host "Root Directory: $rootPath"
Write-Host "Test Results Directory: $testResultsPath"
Write-Host "Visualizer Directory: $visualizePath"
Write-Host "Mock Data Directory: $mockDataPath"
Write-Host "Azurite Data Directory: $azuriteDataPath"
Write-Host "========================================================="
Write-Host ""

# Create test results directory if it doesn't exist
if (-not (Test-Path $testResultsPath)) {
    New-Item -Path $testResultsPath -ItemType Directory -Force | Out-Null
    Write-Host "Created test results directory: $testResultsPath"
}

# Step 1: Setup local Azure simulator
if (-not $SkipSimulatorSetup) {
    Write-Host "Step 1: Setting up local Azure simulator..." -ForegroundColor Green
    
    # Check if Azurite is installed
    $azurite = Get-Command azurite -ErrorAction SilentlyContinue
    if (-not $azurite) {
        Write-Host "Azurite not found. Installing Azure simulator components..."
        & "$scriptPath/Install-AzureSimulator.ps1"
    }
      # Check if Azurite is already running
    $azuritePidFile = Join-Path $azuriteDataPath "azurite.pid"
    $azuriteRunning = $false
    
    if (Test-Path $azuritePidFile) {
        $azuritePid = Get-Content $azuritePidFile
        try {
            $process = Get-Process -Id $azuritePid -ErrorAction SilentlyContinue
            if ($process -and $process.Name -eq "node") {
                $azuriteRunning = $true
                Write-Host "Azurite is already running (Process ID: $azuritePid)"
            }
        } catch {
            # Process not found, Azurite is not running
        }
    }
    
    if (-not $azuriteRunning) {
        Write-Host "Starting Azurite simulator..."
        & "$scriptPath/Start-AzureSimulator.ps1"
    }
    
    # Set environment variables for using the simulator
    $env:AZURE_STORAGE_CONNECTION_STRING = "DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;BlobEndpoint=http://127.0.0.1:10000/devstoreaccount1;QueueEndpoint=http://127.0.0.1:10001/devstoreaccount1;TableEndpoint=http://127.0.0.1:10002/devstoreaccount1;"
    $env:AZURE_SIMULATOR_ENABLED = "true"
    
    # Import fixtures and create simulated resources
    Write-Host "Setting up simulated Azure resources from fixtures..."
    
    # Import infrastructure fixtures
    . $infrastructureFixturesPath
    
    # Create a mock deployment output file with resource names from fixtures
    $mockDeploymentOutputs = @{
        storage1Name = @{ value = $expectedStorageAccounts[0].Name }
        storage2Name = @{ value = $expectedStorageAccounts[1].Name }
        keyVault1Name = @{ value = $expectedKeyVaults[0].Name }
        keyVault2Name = @{ value = $expectedKeyVaults[1].Name }
        vnet1Name = @{ value = $expectedVnets[0].Name }
        vnet2Name = @{ value = $expectedVnets[1].Name }
        subnet1Name = @{ value = $expectedSubnets[0].Name }
        subnet2Name = @{ value = $expectedSubnets[1].Name }
        nsg1Name = @{ value = $expectedNsgs[0].Name }
        nsg2Name = @{ value = $expectedNsgs[1].Name }
        privateDns1Name = @{ value = "privatedns1.azure.com" }
        privateDns2Name = @{ value = "privatedns2.azure.com" }
    }
    
    # Save mock deployment outputs
    $mockDeploymentOutputsPath = Join-Path $testResultsPath "deployment-outputs.json"
    $mockDeploymentOutputs | ConvertTo-Json | Out-File -FilePath $mockDeploymentOutputsPath
    Write-Host "Mock deployment outputs saved to: $mockDeploymentOutputsPath"
    
    # Create a PSD1 file with test data for the simulators
    $testDataPath = Join-Path $mockDataPath "AzuriteTestData.psd1"
    
    @"
@{
    StorageAccounts = @(
        @{
            Name = "$($expectedStorageAccounts[0].Name)"
            Location = "$($expectedStorageAccounts[0].Location)"
            Sku = "Standard_LRS"
            Kind = "StorageV2"
            EnableHttpsTrafficOnly = `$true
            MinimumTlsVersion = "TLS1_2"
            AllowBlobPublicAccess = `$false
        },
        @{
            Name = "$($expectedStorageAccounts[1].Name)"
            Location = "$($expectedStorageAccounts[1].Location)"
            Sku = "Standard_LRS"
            Kind = "StorageV2"
            EnableHttpsTrafficOnly = `$true
            MinimumTlsVersion = "TLS1_2"
            AllowBlobPublicAccess = `$false
        }
    )
    KeyVaults = @(
        @{
            Name = "$($expectedKeyVaults[0].Name)"
            Location = "$($expectedKeyVaults[0].Location)"
            Sku = "standard"
            EnableSoftDelete = `$true
            EnablePurgeProtection = `$true
        },
        @{
            Name = "$($expectedKeyVaults[1].Name)"
            Location = "$($expectedKeyVaults[1].Location)"
            Sku = "standard"
            EnableSoftDelete = `$true
            EnablePurgeProtection = `$true
        }
    )
    VirtualNetworks = @(
        @{
            Name = "$($expectedVnets[0].Name)"
            Location = "$($expectedVnets[0].Location)"
            AddressPrefixes = @("10.0.0.0/16")
        },
        @{
            Name = "$($expectedVnets[1].Name)"
            Location = "$($expectedVnets[1].Location)"
            AddressPrefixes = @("10.1.0.0/16")
        }
    )
    Subnets = @(
        @{
            Name = "$($expectedSubnets[0].Name)"
            Location = "$($expectedSubnets[0].Location)"
            VirtualNetworkName = "$($expectedVnets[0].Name)"
            AddressPrefix = "10.0.0.0/24"
        },
        @{
            Name = "$($expectedSubnets[1].Name)"
            Location = "$($expectedSubnets[1].Location)"
            VirtualNetworkName = "$($expectedVnets[1].Name)"
            AddressPrefix = "10.1.0.0/24"
        }
    )
    NetworkSecurityGroups = @(
        @{
            Name = "$($expectedNsgs[0].Name)"
            Location = "$($expectedNsgs[0].Location)"
            SecurityRules = @(
                @{
                    Name = "$($expectedNsgRules[0].Name)"
                    Protocol = "Tcp"
                    SourcePortRange = "*"
                    DestinationPortRange = "443"
                    SourceAddressPrefix = "*"
                    DestinationAddressPrefix = "*"
                    Access = "Allow"
                    Priority = 100
                    Direction = "Inbound"
                }
            )
        },
        @{
            Name = "$($expectedNsgs[1].Name)"
            Location = "$($expectedNsgs[1].Location)"
            SecurityRules = @(
                @{
                    Name = "$($expectedNsgRules[1].Name)"
                    Protocol = "Tcp"
                    SourcePortRange = "*"
                    DestinationPortRange = "443"
                    SourceAddressPrefix = "*"
                    DestinationAddressPrefix = "*"
                    Access = "Allow"
                    Priority = 100
                    Direction = "Inbound"
                }
            )
        }
    )
    TestUsers = @(
        @{
            Name = "$($expectedTestUser[0].Name)"
            Location = "$($expectedTestUser[0].Location)"
        },
        @{
            Name = "$($expectedTestUser[1].Name)"
            Location = "$($expectedTestUser[1].Location)"
        }
    )
}
"@ | Out-File -FilePath $testDataPath -Force
    
    Write-Host "Test data for local simulators saved to: $testDataPath"
}
else {
    Write-Host "Skipping local simulator setup..."
}

# Step 2: Run Tests
if (-not $SkipTests) {
    Write-Host "Step 2: Running tests against local simulators..." -ForegroundColor Green
    
    # Create timestamp for test result files
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
      # Determine test files to run
    $testFiles = @(
        "SimpleStorageSimulatorTests.ps1"
    )
    
    # Run each test file
    foreach ($testFile in $testFiles) {
        $testFilePath = Join-Path $rootPath "tests/$testFile"
        if (Test-Path $testFilePath) {
            $testResultFile = Join-Path $testResultsPath "$($testFile.Replace('.ps1',''))-$timestamp.xml"
              Write-Host "Running tests from $testFile with simulator..."
            try {
                # Run the Pester tests with LocalSimulator tag and generate an XML result file
                $testResultFile = Join-Path $testResultsPath "$($testFile.Replace('.ps1',''))-$timestamp.xml"
                
                # Use the proper Pester configuration format
                $pesterConfig = [PesterConfiguration]::Default
                $pesterConfig.Run.Path = $testFilePath
                $pesterConfig.Run.PassThru = $true
                $pesterConfig.Filter.Tag = "LocalSimulator"
                $pesterConfig.TestResult.Enabled = $true
                $pesterConfig.TestResult.OutputFormat = "NUnitXml"
                $pesterConfig.TestResult.OutputPath = $testResultFile
                
                $testResults = Invoke-Pester -Configuration $pesterConfig
                
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
                    $curlCommand = "curl -X POST -F `"testResults=@$filePath`" $uploadUrl"
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
Write-Host "Local simulator process completed!"
Write-Host "Azure resources are simulated based on InfrastructureFixtures.ps1"
Write-Host "To stop Azurite, run: ./scripts/Stop-AzureSimulator.ps1"
Write-Host "========================================================="