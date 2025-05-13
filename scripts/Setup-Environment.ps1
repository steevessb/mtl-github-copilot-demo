# Setup-Environment.ps1
# Script to install all required modules and dependencies for the Azure QA Automation project

param (
    [Parameter(Mandatory = $false)]
    [switch]$SkipAzureModules,
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipNodeJs,
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipVisualizer,
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipPester
)

$ErrorActionPreference = "Stop"
$rootPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$visualizerPath = Join-Path $rootPath "visualize"

Write-Host "========================================================="
Write-Host "Azure QA Automation Project - Environment Setup"
Write-Host "========================================================="
Write-Host "This script will install all required modules and dependencies."
Write-Host "Root Directory: $rootPath"
Write-Host "========================================================="
Write-Host ""

function Test-CommandExists {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Command
    )
    
    $exists = $null
    try {
        $exists = Get-Command $Command -ErrorAction Stop
    } catch {
        $exists = $false
    }
    
    return [bool]$exists
}

# Step 1: Install required PowerShell modules
if (-not $SkipAzureModules) {
    Write-Host "Step 1: Installing required PowerShell modules..." -ForegroundColor Green
    
    # Check if modules are already installed
    $requiredModules = @(
        @{Name = "Az"; Version = "11.0.0"},
        @{Name = "Az.Bicep"; Version = "2.0.0"},
        @{Name = "powershell-yaml"; Version = "0.4.2"}
    )
    
    foreach ($module in $requiredModules) {
        $installedModule = Get-Module -ListAvailable -Name $module.Name -ErrorAction SilentlyContinue
        
        if (-not $installedModule -or $installedModule.Version -lt [version]$module.Version) {
            Write-Host "Installing module $($module.Name) version $($module.Version)..."
            Install-Module -Name $module.Name -Force -AllowClobber -Scope CurrentUser -MinimumVersion $module.Version -Repository PSGallery
            Write-Host "Module $($module.Name) installed successfully." -ForegroundColor Green
        } else {
            Write-Host "Module $($module.Name) version $($installedModule.Version) is already installed." -ForegroundColor Yellow
        }
    }
}
else {
    Write-Host "Skipping Azure PowerShell modules installation..."
}

# Step 2: Install Pester module
if (-not $SkipPester) {
    Write-Host "Step 2: Installing Pester module..." -ForegroundColor Green
    
    $pesterModule = Get-Module -ListAvailable -Name Pester -ErrorAction SilentlyContinue
    $requiredPesterVersion = "5.4.0"
    
    if (-not $pesterModule -or $pesterModule.Version -lt [version]$requiredPesterVersion) {
        Write-Host "Installing Pester $requiredPesterVersion..."
        Install-Module -Name Pester -Force -AllowClobber -Scope CurrentUser -MinimumVersion $requiredPesterVersion -Repository PSGallery
        Write-Host "Pester module installed successfully." -ForegroundColor Green
    } else {
        Write-Host "Pester module version $($pesterModule.Version) is already installed." -ForegroundColor Yellow
    }
}
else {
    Write-Host "Skipping Pester module installation..."
}

# Step 3: Check Node.js installation
if (-not $SkipNodeJs) {
    Write-Host "Step 3: Checking Node.js installation..." -ForegroundColor Green
    
    $nodeInstalled = Test-CommandExists -Command "node"
    $npmInstalled = Test-CommandExists -Command "npm"
    $requiredNodeVersion = "14.0.0"
    
    if (-not $nodeInstalled) {
        Write-Host "Node.js is not installed. Installing Node.js..."
        
        # Check if we have the installer
        $nodeInstallerPath = Join-Path $rootPath "downloads\node-v20.10.0-x64.msi"
        
        if (Test-Path $nodeInstallerPath) {
            Write-Host "Using existing Node.js installer: $nodeInstallerPath"
            Start-Process -FilePath "msiexec.exe" -ArgumentList "/i", $nodeInstallerPath, "/quiet", "/norestart" -Wait
            Write-Host "Node.js installed. Please restart your PowerShell session after this script completes." -ForegroundColor Yellow
        } else {
            Write-Host "Node.js installer not found. Please download and install Node.js from https://nodejs.org/" -ForegroundColor Red
            Write-Host "After installing Node.js, restart your PowerShell session and run this script again." -ForegroundColor Red
        }
    } else {
        $nodeVersion = node -v
        Write-Host "Node.js version $nodeVersion is already installed." -ForegroundColor Yellow
        
        if (-not $npmInstalled) {
            Write-Host "npm is not installed. Please reinstall Node.js to include npm." -ForegroundColor Red
        } else {
            $npmVersion = npm -v
            Write-Host "npm version $npmVersion is installed." -ForegroundColor Yellow
        }
    }
}
else {
    Write-Host "Skipping Node.js check..."
}

# Step 4: Install visualizer dependencies
if (-not $SkipVisualizer -and (Test-CommandExists -Command "npm")) {
    Write-Host "Step 4: Installing visualizer dependencies..." -ForegroundColor Green
    
    if (Test-Path $visualizerPath) {
        Push-Location $visualizerPath
        
        # Check if package.json exists
        if (Test-Path "package.json") {
            Write-Host "Installing npm packages for visualizer..."
            npm install
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "Visualizer dependencies installed successfully." -ForegroundColor Green
            } else {
                Write-Host "Failed to install visualizer dependencies." -ForegroundColor Red
            }
        } else {
            Write-Host "package.json not found in visualizer directory. Cannot install dependencies." -ForegroundColor Red
        }
        
        Pop-Location
    } else {
        Write-Host "Visualizer directory not found at $visualizerPath." -ForegroundColor Red
    }
}
else {
    Write-Host "Skipping visualizer dependencies installation..."
}

# Step 5: Create test results directory
$testResultsPath = Join-Path $rootPath "TestResults"
if (-not (Test-Path $testResultsPath)) {
    Write-Host "Creating test results directory: $testResultsPath"
    New-Item -Path $testResultsPath -ItemType Directory -Force | Out-Null
    Write-Host "Test results directory created." -ForegroundColor Green
}

# Step 6: Test Azure connectivity
Write-Host "Step 6: Testing Azure connectivity..." -ForegroundColor Green

try {
    $context = Get-AzContext -ErrorAction SilentlyContinue
    
    if ($context -and $context.Account) {
        Write-Host "Already connected to Azure as $($context.Account.Id)" -ForegroundColor Green
        Write-Host "Subscription: $($context.Subscription.Name) ($($context.Subscription.Id))" -ForegroundColor Green
    } else {
        Write-Host "Not connected to Azure. You can connect using:" -ForegroundColor Yellow
        Write-Host "  Connect-AzAccount" -ForegroundColor Yellow
    }
} catch {
    Write-Host "Azure PowerShell modules not loaded or not installed correctly." -ForegroundColor Red
    Write-Host "Please make sure you've installed the Az module and imported it." -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "========================================================="
Write-Host "Environment setup completed!"
Write-Host "========================================================="
Write-Host ""
Write-Host "Next Steps:"
Write-Host "1. Connect to Azure if not already connected: Connect-AzAccount"
Write-Host "2. Run the deployment script: ./scripts/Deploy-Test-Visualize.ps1"
Write-Host "3. If you installed Node.js, restart your PowerShell session"
Write-Host ""
Write-Host "For more information, see the README.md file or the docs directory."
Write-Host "========================================================="
