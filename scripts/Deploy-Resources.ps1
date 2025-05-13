# Deploy-Resources.ps1
# Deploys infrastructure resources to Azure using Bicep
# Quality Engineer: This script deploys resources defined in main.bicep

param (
    [string]$ResourceGroupName = "QA-Automation-RG",
    [string]$Location = "eastus",
    [string]$BicepFilePath = $null,
    [string]$OutputFile = $null
)

# Import Az module if not already imported
if (-not (Get-Module -Name Az)) {
    Import-Module Az -ErrorAction Stop
}

# Determine bicep file path
if (-not $BicepFilePath) {
    $rootDir = Split-Path -Parent $PSScriptRoot
    $BicepFilePath = Join-Path $rootDir "infra\main.bicep"
}

# Set default output file if not provided
if (-not $OutputFile) {
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $rootDir = Split-Path -Parent $PSScriptRoot
    $testResultsDir = Join-Path $rootDir "TestResults"
    
    # Ensure test results directory exists
    if (-not (Test-Path $testResultsDir)) {
        New-Item -Path $testResultsDir -ItemType Directory -Force | Out-Null
    }
    
    $OutputFile = Join-Path $testResultsDir "deployment-outputs-$timestamp.json"
}

# Validate bicep file exists
if (-not (Test-Path $BicepFilePath)) {
    Write-Error "Bicep file not found at $BicepFilePath"
    exit 1
}

# Check if logged in to Azure
$context = Get-AzContext
if (-not $context) {
    Write-Host "Not logged in to Azure. Please login now."
    Connect-AzAccount
}

# Create or validate resource group
$resourceGroup = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
if (-not $resourceGroup) {
    Write-Host "Creating resource group $ResourceGroupName in $Location..."
    New-AzResourceGroup -Name $ResourceGroupName -Location $Location
} else {
    Write-Host "Using existing resource group $ResourceGroupName in $($resourceGroup.Location)"
}

# Generate a unique deployment name
$deploymentName = "qa-automation-$((Get-Date).ToString('yyyyMMddHHmmss'))"

# Create a resource token to make resources unique
$resourceToken = -join ((48..57) + (97..122) | Get-Random -Count 8 | ForEach-Object { [char]$_ })

# Deploy the infrastructure
try {
    Write-Host "Deploying infrastructure to Azure..."
    
    $deployment = New-AzResourceGroupDeployment `
        -Name $deploymentName `
        -ResourceGroupName $ResourceGroupName `
        -TemplateFile $BicepFilePath `
        -resourceToken $resourceToken `
        -Mode Incremental `
        -Verbose
    
    # Check if deployment succeeded
    if ($deployment.ProvisioningState -eq "Succeeded") {
        Write-Host "Deployment succeeded!" -ForegroundColor Green
        
        # Export deployment outputs
        $outputs = @{}
        foreach ($key in $deployment.Outputs.Keys) {
            $outputs[$key] = $deployment.Outputs[$key].Value
        }
        
        # Add timestamp and deployment name
        $outputs["_metadata"] = @{
            "timestamp" = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            "deploymentName" = $deploymentName
            "resourceGroupName" = $ResourceGroupName
        }
        
        # Save outputs to file
        $outputs | ConvertTo-Json -Depth 4 | Out-File -FilePath $OutputFile
        Write-Host "Deployment outputs saved to: $OutputFile" -ForegroundColor Green
        
        return $deployment
    } else {
        Write-Error "Deployment failed with state: $($deployment.ProvisioningState)"
        exit 1
    }
} catch {
    Write-Error "Error deploying infrastructure: $_"
    exit 1
}
