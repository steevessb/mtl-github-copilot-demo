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

### Option A: One-Command Solution
Use the unified command to deploy, test, and report in one step:

```powershell
# For real Azure resources
./scripts/Deploy-Test-Report.ps1

# For local simulation without Azure connection
./scripts/Deploy-Test-Report.ps1 -UseLocalSimulator
```

This one-command solution will:
- Deploy Azure resources using Bicep templates (or simulate them locally)
- Run tests against the deployed infrastructure (real or simulated)
- Start the visualization server and upload test results
- Open the test report in your browser

### Option B: Manual Deployment and Testing
1. **Setup Environment and Deploy Infrastructure**
   ```powershell
   # Connect to Azure
   ./scripts/Connect-AzureAccount.ps1
   
   # Deploy resources to Azure
   ./scripts/Deploy-Resources.ps1 -ResourceGroupName "qa-test-rg" -Location "eastus"
   ```

2. **Running Tests Against Azure or Local Simulators**
   ```powershell
   # For real Azure resources
   ./scripts/Deploy-Test-Visualize.ps1
   
   # For local simulation without Azure connection
   ./scripts/Deploy-Test-Visualize-Local.ps1
   ```
  ## Local Testing with Simulation

This project supports testing without a real Azure connection using local simulators:

```powershell
# Run all local testing with a single command
./scripts/Deploy-Test-Report.ps1 -UseLocalSimulator
```

The above script handles all the steps below automatically:

1. **Setup Local Environment**
   ```powershell
   # Install simulator components (if needed)
   ./scripts/Install-AzureSimulator.ps1
   ```

2. **Run Tests with Local Simulator**
   ```powershell
   # Start simulator and run tests
   ./scripts/Deploy-Test-Visualize-Local.ps1
   
   # When finished
   ./scripts/Stop-AzureSimulator.ps1
   ```

## Infrastructure as Code (IaC)

The project uses Bicep templates to define and deploy Azure infrastructure:

- `infra/main.bicep` - Main deployment template that references all modules
- Modules for each resource type:
  - Storage Accounts (`storageAccount.bicep`)
  - Key Vaults (`keyVault.bicep`)
  - Virtual Networks (`virtualNetwork.bicep`)
  - Subnets (`subnet.bicep`)
  - Network Security Groups (`networkSecurityGroup.bicep`)
  - Private DNS Zones (`privateDnsZone.bicep`)

### Customizing Infrastructure

1. Edit the resource definitions in `infra/main.bicep`
2. Modify or add module parameters in the module files
3. Run the deployment script with your changes:
   ```powershell
   ./scripts/Deploy-Resources.ps1
   ```

## Test Visualization Server

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

Visit `http://localhost:3000` in your browser to view the dashboard.

To upload test results to the visualizer:
```powershell
./scripts/Upload-TestResults.ps1 -TestResultFile "./TestResults/TestResults.xml"
```
npm install
node server.js
```

## Documentation

For more detailed information, see:

- [Architecture Overview](./docs/ARCHITECTURE.txt)
- [End-to-End Workflow](./docs/END-TO-END-WORKFLOW.md)
- [Infrastructure as Code](./docs/INFRASTRUCTURE-AS-CODE.md)
- [Visualization Architecture](./docs/VISUALIZATION-ARCHITECTURE.md)
- [Visualizer Documentation](./docs/VISUALIZER.md)
- [CI/CD Integration](./docs/CI-CD-INTEGRATION.md)
- [Implementation Summary](./docs/IMPLEMENTATION-SUMMARY.md)

## CI/CD Integration

This project includes Azure DevOps pipeline configuration for CI/CD:

```yaml
# Use the provided configuration file in config/azure-pipelines.yml
# Example usage in Azure DevOps:
trigger:
  - main

pool:
  vmImage: 'windows-latest'

jobs:
- job: TestAndDeploy
  steps:
  - task: PowerShell@2
    inputs:
      filePath: './scripts/Deploy-Test-Report.ps1'
      arguments: '-UseLocalSimulator'
```

See `docs/CI-CD-INTEGRATION.md` for detailed CI/CD setup instructions.

## Extending the Framework

### Add New Resource Types

1. Create Bicep modules in `infra/modules/`
2. Add resource definitions to `infra/main.bicep`
3. Update fixtures in `src/InfrastructureFixtures.ps1`
4. Create test files in `tests/` directory

### Add New Tests

Create new test files in the `tests/` directory following these patterns:

```powershell
# For real Azure tests
ResourceType.ps1

# For local simulator tests
ResourceTypeSimulator.ps1
```

Ensure tests are properly tagged:
- Use `AzureCloud` tag for real Azure tests
- Use `LocalSimulator` tag for simulator tests
