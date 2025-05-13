# Install-Visualizer.ps1
# PowerShell script to install and set up the test visualizer
# Quality Engineer: Run this script to set up the visualization server

param(
    [Parameter(Mandatory=$false)]
    [string]$VisualizerPath = "$PSScriptRoot/../visualize",
    
    [Parameter(Mandatory=$false)]
    [switch]$StartServer = $true
)

# Check if Node.js is installed
try {
    $nodeVersion = node --version
    Write-Host "Node.js is installed: $nodeVersion" -ForegroundColor Green
} catch {
    Write-Error "Node.js is not installed. Please install it from https://nodejs.org/"
    exit 1
}

# Check if npm is installed
try {
    $npmVersion = npm --version
    Write-Host "npm is installed: $npmVersion" -ForegroundColor Green
} catch {
    Write-Error "npm is not installed. Please install it from https://nodejs.org/"
    exit 1
}

# Navigate to the visualizer directory
Set-Location -Path $VisualizerPath

# Check if node_modules exists
if (-not (Test-Path -Path "node_modules")) {
    Write-Host "Installing dependencies..." -ForegroundColor Cyan
    npm install
} else {
    Write-Host "Dependencies already installed." -ForegroundColor Yellow
    Write-Host "To reinstall dependencies, delete the node_modules folder and run this script again." -ForegroundColor Yellow
}

# Create .env file if it doesn't exist
if (-not (Test-Path -Path ".env")) {
    Write-Host "Creating .env file from template..." -ForegroundColor Cyan
    Copy-Item -Path ".env.example" -Destination ".env"
    Write-Host ".env file created. Update it with your Azure Storage connection string if needed." -ForegroundColor Green
} else {
    Write-Host ".env file already exists." -ForegroundColor Yellow
}

# Create reports directory if it doesn't exist
if (-not (Test-Path -Path "public/reports")) {
    Write-Host "Creating reports directory..." -ForegroundColor Cyan
    New-Item -Path "public/reports" -ItemType Directory -Force | Out-Null
    Write-Host "Reports directory created." -ForegroundColor Green
} else {
    Write-Host "Reports directory already exists." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Visualizer installation complete!" -ForegroundColor Green

# Start the server if requested
if ($StartServer) {
    Write-Host "Starting visualizer server..." -ForegroundColor Cyan
    npm start
} else {
    Write-Host "To start the visualizer server, run:" -ForegroundColor Green
    Write-Host "cd $VisualizerPath && npm start" -ForegroundColor Yellow
    Write-Host "Or use the Test-Visualizer.ps1 script" -ForegroundColor Yellow
}
