# Azure QA Automation Project

This project demonstrates a PowerShell/Pester-based QA automation architecture for Azure resources, with CI/CD integration and best practices for quality engineers.

## Structure
- `src/` - PowerShell scripts and Pester tests
- `config/` - YAML configuration and fixtures
- `scripts/` - Utility scripts for Azure authentication and environment setup
- `mock-data/` - Mock data for local testing
- `docs/` - Documentation and slide content
- `visualize/` - Node.js application for test results visualization

## Key Concepts
- Data-driven testing with Pester
- YAML-based test fixtures for Azure resources
- Centralized Azure queries in DiscoveryPhase.ps1
- Security and compliance validation for Azure resources
- CI/CD integration with Azure DevOps
- Reporting: Console, Azure DevOps, Xray Jira
- BDD-style test organization
- Local testing with Azure simulators
- Visual test results with charts and Azure integration

## Getting Started

### Option 1: Testing with Azure Subscription
1. **Setup Environment**
   ```powershell
   # Connect to Azure
   ./scripts/Connect-AzureAccount.ps1
   
   # Set up test environment
   ./scripts/Set-InitialAzureEnvironment.ps1 -ResourceGroupName "qa-test-rg"
   ```

2. **Run Tests against real Azure**
   ```powershell
   # Install required modules
   Install-Module -Name Pester -Force
   Install-Module -Name Az -Force
   Install-Module -Name powershell-yaml -Force
   
   # Run all tests
   Invoke-Pester -Path ./src
   ```

### Option 2: Testing with Local Simulator
1. **Setup Local Azure Simulator**
   ```powershell
   # Install simulator components
   ./scripts/Install-AzureSimulator.ps1
   
   # Start simulator
   ./scripts/Start-AzureSimulator.ps1
   ```

2. **Run Tests with Local Simulator**
   ```powershell
   # Run tests tagged for local simulation
   ./scripts/Invoke-LocalTests.ps1
   
   # When finished
   ./scripts/Stop-AzureSimulator.ps1
   ```

### CI/CD Integration
- Use the provided azure-pipelines.yml for Azure DevOps integration
- Customize variables in the pipeline for your environment

See `docs/ARCHITECTURE.txt` for architectural details.
