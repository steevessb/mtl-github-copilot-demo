# Deploy-Visualizer.ps1
# PowerShell script to deploy the visualizer to Azure
# Quality Engineer: Use this script to deploy the visualizer to Azure App Service

param (
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupName = "qa-visualizer-rg",
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "canadaeast",
    
    [Parameter(Mandatory=$false)]
    [string]$AppServiceName = "qa-test-visualizer",
    
    [Parameter(Mandatory=$false)]
    [string]$StorageAccountName = "qavisualizerstorage",
    
    [Parameter(Mandatory=$false)]
    [string]$ContainerName = "testresults"
)

# Check if Azure CLI is installed
try {
    $azVersion = az --version
    Write-Host "Azure CLI is installed" -ForegroundColor Green
} catch {
    Write-Error "Azure CLI is not installed. Please install it from https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
}

# Login to Azure
Write-Host "Logging in to Azure..." -ForegroundColor Cyan
az login

# Create resource group if it doesn't exist
Write-Host "Creating resource group if it doesn't exist..." -ForegroundColor Cyan
$rgExists = az group exists --name $ResourceGroupName
if ($rgExists -eq "false") {
    az group create --name $ResourceGroupName --location $Location
    Write-Host "Resource group created: $ResourceGroupName" -ForegroundColor Green
} else {
    Write-Host "Resource group already exists: $ResourceGroupName" -ForegroundColor Yellow
}

# Create storage account if it doesn't exist
Write-Host "Creating storage account..." -ForegroundColor Cyan
$storageAccount = az storage account show --name $StorageAccountName --resource-group $ResourceGroupName --query "name" -o tsv 2>$null
if (-not $storageAccount) {
    az storage account create --name $StorageAccountName --resource-group $ResourceGroupName --location $Location --sku Standard_LRS --kind StorageV2
    Write-Host "Storage account created: $StorageAccountName" -ForegroundColor Green
} else {
    Write-Host "Storage account already exists: $StorageAccountName" -ForegroundColor Yellow
}

# Get storage account connection string
$connectionString = az storage account show-connection-string --name $StorageAccountName --resource-group $ResourceGroupName --query "connectionString" -o tsv

# Create blob container
Write-Host "Creating blob container..." -ForegroundColor Cyan
az storage container create --name $ContainerName --account-name $StorageAccountName --public-access blob

# Create App Service Plan if it doesn't exist
Write-Host "Creating App Service Plan..." -ForegroundColor Cyan
$appServicePlanName = "$AppServiceName-plan"
$appPlan = az appservice plan show --name $appServicePlanName --resource-group $ResourceGroupName --query "name" -o tsv 2>$null
if (-not $appPlan) {
    az appservice plan create --name $appServicePlanName --resource-group $ResourceGroupName --location $Location --sku B1 --is-linux
    Write-Host "App Service Plan created: $appServicePlanName" -ForegroundColor Green
} else {
    Write-Host "App Service Plan already exists: $appServicePlanName" -ForegroundColor Yellow
}

# Create App Service if it doesn't exist
Write-Host "Creating App Service..." -ForegroundColor Cyan
$webapp = az webapp show --name $AppServiceName --resource-group $ResourceGroupName --query "name" -o tsv 2>$null
if (-not $webapp) {
    az webapp create --name $AppServiceName --resource-group $ResourceGroupName --plan $appServicePlanName --runtime "NODE|14-lts"
    Write-Host "App Service created: $AppServiceName" -ForegroundColor Green
} else {
    Write-Host "App Service already exists: $AppServiceName" -ForegroundColor Yellow
}

# Set application settings
Write-Host "Configuring App Service settings..." -ForegroundColor Cyan
az webapp config appsettings set --name $AppServiceName --resource-group $ResourceGroupName --settings AZURE_STORAGE_CONNECTION_STRING="$connectionString"

# Prepare the visualizer code for deployment
Write-Host "Preparing code for deployment..." -ForegroundColor Cyan
$visualizerPath = "$PSScriptRoot/../visualize"
$envFilePath = "$visualizerPath/.env"

# Create .env file with the connection string
$envContent = "AZURE_STORAGE_CONNECTION_STRING=$connectionString`nPORT=8080"
$envContent | Out-File -FilePath $envFilePath -Encoding utf8

# Deploy the visualizer to Azure App Service
Write-Host "Deploying visualizer to Azure App Service..." -ForegroundColor Cyan
az webapp deploy --name $AppServiceName --resource-group $ResourceGroupName --src-path $visualizerPath --type zip

# Output details
$appUrl = "https://$AppServiceName.azurewebsites.net"
Write-Host ""
Write-Host "Deployment complete!" -ForegroundColor Green
Write-Host "Visualizer URL: $appUrl" -ForegroundColor Green
Write-Host "Resource Group: $ResourceGroupName" -ForegroundColor Green
Write-Host "Storage Account: $StorageAccountName" -ForegroundColor Green
Write-Host ""
Write-Host "To visualize test results, upload them to:" -ForegroundColor Green
Write-Host "$appUrl" -ForegroundColor Yellow

# Open the browser to the deployed visualizer
Start-Process $appUrl
