# Azure QA Automation Project

This project demonstrates a PowerShell/Pester-based QA automation architecture for Azure resources, with CI/CD integration, Infrastructure as Code deployment, and an integrated test result visualization system.

## Structure
- `src/` - PowerShell scripts and Pester tests
- `config/` - YAML configuration and fixtures
- `scripts/` - Utility scripts for Azure authentication, environment setup, and deployment
- `mock-data/` - Mock data for local testing
- `docs/` - Documentation and slide content
- `visualize/` - Node.js application for test results visualization
- `infra/` - Bicep templates for Infrastructure as Code deployment
- `tests/` - Pester test files for validating deployed infrastructure
- `TestResults/` - Storage location for test result files

## Key Concepts
- Data-driven testing with Pester
- YAML-based test fixtures for Azure resources
- Centralized Azure queries in DiscoveryPhase.ps1
- Security and compliance validation for Azure resources
- Infrastructure as Code with Bicep templates
- Automated deployment, testing, and visualization in one workflow
- CI/CD integration with Azure DevOps
- Reporting: Console, Azure DevOps, Xray Jira
- BDD-style test organization
- Local testing with Azure simulators
- Visual test results with charts and Azure integration

## Getting Started

### Option 1: Deploying Infrastructure and Running Tests
1. **Setup Environment and Deploy Infrastructure**
   ```powershell
   # Connect to Azure
   ./scripts/Connect-AzureAccount.ps1
   
   # Deploy infrastructure, run tests, and view results
   ./scripts/Deploy-Test-Visualize.ps1 -ResourceGroupName "qa-test-rg" -Location "eastus"
   ```

   This one-command solution will:
   - Deploy Azure resources using Bicep templates
   - Run tests against the deployed infrastructure
   - Start the visualization server and upload test results
   - Open the test report in your browser

2. **Custom Deployment Options**
   ```powershell
   # Skip deployment and only run tests
   ./scripts/Deploy-Test-Visualize.ps1 -SkipDeployment
   
   # Skip visualization and only deploy and test
   ./scripts/Deploy-Test-Visualize.ps1 -SkipVisualization
   
   # Deploy to a different environment
   ./scripts/Deploy-Test-Visualize.ps1 -EnvironmentName "test" -ResourceGroupName "test-rg"
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

## Infrastructure as Code (IaC)

The project uses Bicep templates to define and deploy Azure infrastructure:

- `infra/main.bicep` - Main deployment template that references all modules
- Modules for each resource type:
  - Storage Accounts
  - Key Vaults
  - Virtual Networks
  - Subnets
  - Network Security Groups
  - Private DNS Zones

### Customizing Infrastructure

1. Edit the resource definitions in `infra/main.bicep`
2. Modify or add module parameters in the module files
3. Run the deployment script with your changes:
   ```powershell
   ./scripts/Deploy-Test-Visualize.ps1
   ```

## Test Visualization

The included Node.js visualization server provides:

- Web-based test result dashboard
- Visual charts of test pass/fail rates
- Detailed test case results
- Categorized test results by test type
- Automatic report generation

To start the visualizer manually:
```powershell
cd visualize
npm install
node server.js
```

Then visit http://localhost:3000 in your browser.

See `docs/VISUALIZER.md` for more details on the visualization component.

## CI/CD Integration
- Use the provided azure-pipelines.yml for Azure DevOps integration
- Customize variables in the pipeline for your environment

See `docs/ARCHITECTURE.txt` for architectural details and `docs/CI-CD-INTEGRATION.md` for CI/CD setup instructions.
