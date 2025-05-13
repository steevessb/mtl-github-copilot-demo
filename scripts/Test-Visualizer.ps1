# Test-Visualizer.ps1
# PowerShell script to run tests and upload results to the visualizer
# Quality Engineer: Use this script to run tests and visualize results

param(
    [Parameter(Mandatory=$false)]
    [string]$TestPath = "$PSScriptRoot/../src",
    
    [Parameter(Mandatory=$false)]
    [string]$Tag = "LocalSimulator",
    
    [Parameter(Mandatory=$false)]
    [string]$VisualizerUrl = "http://localhost:3000",
    
    [Parameter(Mandatory=$false)]
    [switch]$RunSimulator = $true,
    
    [Parameter(Mandatory=$false)]
    [switch]$StartVisualizer = $true,
    
    [Parameter(Mandatory=$false)]
    [string]$TestResultPath = ""
)

# Make sure we have the right Pester version
$requiredVersion = "5.3.3"
$pesterModule = Get-Module -Name Pester -ListAvailable | Where-Object { $_.Version -eq $requiredVersion }

if (-not $pesterModule) {
    Write-Host "Pester version $requiredVersion not found. Installing..." -ForegroundColor Yellow
    Install-Module -Name Pester -RequiredVersion $requiredVersion -Force -SkipPublisherCheck
}

Import-Module -Name Pester -RequiredVersion $requiredVersion -Force

# Start the Azure simulator if requested
if ($RunSimulator) {
    Write-Host "Starting Azure simulator..." -ForegroundColor Cyan
    & "$PSScriptRoot/Start-AzureSimulator.ps1"
}

# Create output directory for test results
$outputDir = "$PSScriptRoot/../test-results"
if (-not (Test-Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
}

# If test result path is provided, use it instead of running tests
if ($TestResultPath -and (Test-Path $TestResultPath)) {
    $resultsPath = $TestResultPath
    Write-Host "Using existing test results file: $resultsPath" -ForegroundColor Cyan
} else {
    $resultsPath = "$outputDir/TestResults-$(Get-Date -Format 'yyyy-MM-dd-HHmmss').xml"

    # Run the tests
    Write-Host "Running tests with Pester..." -ForegroundColor Cyan
    $pesterConfig = New-PesterConfiguration
    $pesterConfig.Run.Path = $TestPath
    $pesterConfig.Filter.Tag = $Tag
    $pesterConfig.Output.Verbosity = 'Detailed'
    $pesterConfig.TestResult.Enabled = $true
    $pesterConfig.TestResult.OutputFormat = 'NUnitXml'
    $pesterConfig.TestResult.OutputPath = $resultsPath

    Invoke-Pester -Configuration $pesterConfig
}

# Start the visualizer if requested
if ($StartVisualizer) {
    $visualizerRunning = $false
    
    try {
        $visualizerCheck = Invoke-WebRequest -Uri $VisualizerUrl -UseBasicParsing -TimeoutSec 5 -ErrorAction SilentlyContinue
        if ($visualizerCheck.StatusCode -eq 200) {
            $visualizerRunning = $true
        }
    } catch {
        # Visualizer not running
    }
    
    if (-not $visualizerRunning) {
        Write-Host "Starting visualizer server..." -ForegroundColor Cyan
        Start-Process -FilePath "node" -ArgumentList "$PSScriptRoot/../visualize/server.js" -WorkingDirectory "$PSScriptRoot/../visualize"
        
        # Give the server time to start
        Start-Sleep -Seconds 5
    }    # Open the browser to upload the results
    Write-Host "Opening browser to upload test results..." -ForegroundColor Green
    Start-Process $VisualizerUrl
    
    # Automatically upload the results using Invoke-RestMethod
    try {
        Write-Host "Automatically uploading test results to visualizer..." -ForegroundColor Cyan
        $boundary = [System.Guid]::NewGuid().ToString()
        $LF = "`r`n"
        $bodyLines = (
            "--$boundary",
            "Content-Disposition: form-data; name=`"testResults`"; filename=`"$(Split-Path $resultsPath -Leaf)`"",
            "Content-Type: application/xml$LF",
            [System.IO.File]::ReadAllText($resultsPath),
            "--$boundary--$LF"
        ) -join $LF
        
        $headers = @{
            "Accept" = "application/json"
        }
        
        $response = Invoke-RestMethod -Uri "$VisualizerUrl/upload" -Method Post -Body $bodyLines -ContentType "multipart/form-data; boundary=`"$boundary`"" -Headers $headers -TimeoutSec 30
        
        # Open the report URL directly
        if ($response.reportId) {
            Start-Process "$VisualizerUrl/report/$($response.reportId)"
            Write-Host "Test results automatically uploaded and report opened." -ForegroundColor Green
            
            # Display summary
            Write-Host ""
            Write-Host "Test Results Summary from Visualizer:" -ForegroundColor Cyan
            Write-Host "Total: $($response.summary.total)" -ForegroundColor White
            Write-Host "Passed: $($response.summary.passed)" -ForegroundColor Green
            Write-Host "Failed: $($response.summary.failed)" -ForegroundColor Red
            Write-Host "Skipped: $($response.summary.skipped)" -ForegroundColor Yellow
        } else {
            # If we couldn't get a report ID, just open the main page
            Start-Process $VisualizerUrl
            Write-Host "Test results uploaded but couldn't get report ID." -ForegroundColor Yellow
        }
    } catch {
        Write-Host "Automatic upload failed. Please upload the file manually through the web interface." -ForegroundColor Yellow
        Write-Host "Error: $_" -ForegroundColor Red
        Start-Process $VisualizerUrl
    }
      # Display instructions
    Write-Host ""
    Write-Host "Your test results are available at: $resultsPath" -ForegroundColor Green
    Write-Host ""
    Write-Host "You can also manually upload test results at:" -ForegroundColor Cyan
    Write-Host "$VisualizerUrl" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Test results file: $resultsPath" -ForegroundColor Green
Write-Host "Visualizer URL: $VisualizerUrl" -ForegroundColor Green
