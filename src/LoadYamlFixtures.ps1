# LoadYamlFixtures.ps1
# Helper script to load YAML fixtures into PowerShell objects
# Quality Engineer: Use this to convert YAML fixtures to PowerShell objects for testing

param(
    [Parameter(Mandatory=$true)]
    [string]$YamlFilePath
)

# Check if PowerShell-yaml module is installed
if (-not (Get-Module -ListAvailable -Name powershell-yaml)) {
    Write-Host "Installing powershell-yaml module..."
    Install-Module -Name powershell-yaml -Force -Scope CurrentUser
}

# Import the module
Import-Module powershell-yaml

# Check if file exists
if (-not (Test-Path $YamlFilePath)) {
    Write-Error "YAML file not found: $YamlFilePath"
    exit 1
}

# Read and parse YAML file
try {
    $yamlContent = Get-Content -Path $YamlFilePath -Raw
    $fixtures = ConvertFrom-Yaml -Yaml $yamlContent
    
    return $fixtures
}
catch {
    Write-Error "Error loading YAML fixtures: $_"
    exit 1
}
