# Install-AzureSimulator.ps1
# Installs and configures local Azure simulators for testing
# Quality Engineer: Run this script to set up a local Azure testing environment

# Check if Node.js is installed (required for Azurite)
$nodejs = Get-Command node -ErrorAction SilentlyContinue
if (-not $nodejs) {
    Write-Host "Node.js is required for Azurite. Please install Node.js and try again."
    Write-Host "Download from: https://nodejs.org/en/download/"
    exit 1
}

# Install Azurite (Azure Storage Emulator)
Write-Host "Installing Azurite (Azure Storage Emulator)..."
npm install -g azurite

# Create a directory for Azurite data
$azuriteDataPath = Join-Path $PSScriptRoot ".." "azurite-data"
if (-not (Test-Path $azuriteDataPath)) {
    New-Item -Path $azuriteDataPath -ItemType Directory -Force | Out-Null
    Write-Host "Created Azurite data directory: $azuriteDataPath"
}

# Install PowerShell modules for Azure mocking
Write-Host "Installing required PowerShell modules..."
$modules = @(
    "Az.Accounts", 
    "Az.Storage", 
    "Az.KeyVault", 
    "Az.Websites",
    "Az.Sql"
)

foreach ($module in $modules) {
    if (-not (Get-Module -ListAvailable -Name $module)) {
        Write-Host "Installing module: $module"
        Install-Module -Name $module -Force -Scope CurrentUser
    } else {
        Write-Host "Module already installed: $module"
    }
}

# Install Pester 5.3.3 specifically
$requiredPesterVersion = "5.3.3"
$pesterModule = Get-Module -Name Pester -ListAvailable | Where-Object { $_.Version -eq $requiredPesterVersion }

if (-not $pesterModule) {
    Write-Host "Installing Pester version $requiredPesterVersion"
    Install-Module -Name Pester -RequiredVersion $requiredPesterVersion -Force -SkipPublisherCheck
} else {
    Write-Host "Pester version $requiredPesterVersion already installed"
}

# Create directories for mock data
$mockDataPath = Join-Path $PSScriptRoot ".." "mock-data"
if (-not (Test-Path $mockDataPath)) {
    New-Item -Path $mockDataPath -ItemType Directory -Force | Out-Null
    Write-Host "Created mock data directory: $mockDataPath"
}

# Copy our Azure fixture YAML to the mock data directory
$fixturesYaml = Join-Path $PSScriptRoot ".." "config" "AzureFixtures.yml"
$mockFixturesPath = Join-Path $mockDataPath "AzureFixtures.yml"
Copy-Item -Path $fixturesYaml -Destination $mockFixturesPath -Force
Write-Host "Copied fixtures to mock data directory"

Write-Host "Azure Simulator installation complete."
Write-Host "To start Azurite, run: Start-AzureSimulator.ps1"
