# End-to-End Workflow: Deploy, Test, Visualize

This document describes the end-to-end workflow for deploying Azure infrastructure, testing it with Pester, and visualizing the test results.

## Overview

The workflow consists of three main stages:

1. **Deploy**: Use Bicep templates to deploy Azure resources
2. **Test**: Run Pester tests against the deployed infrastructure
3. **Visualize**: Display test results in a web-based dashboard

The entire workflow is automated through a single PowerShell script, making it easy to run in development environments or integrate with CI/CD pipelines.

## Prerequisites

- Azure PowerShell modules installed
- PowerShell 7.0 or later
- Node.js 14.x or later (for visualization server)
- Azure subscription with contributor access
- Pester 5.0 or later

## Workflow Details

### Step 1: Infrastructure Deployment

The deployment stage uses Bicep templates to create or update Azure resources:

1. The main deployment script `Deploy-Test-Visualize.ps1` is executed
2. The script checks if the target resource group exists
3. The Bicep template `infra/main.bicep` is deployed to the resource group
4. Parameters like environment name and location are passed to the deployment
5. The deployment creates all defined resources using modular Bicep files
6. Deployment outputs (resource names, etc.) are captured and saved for testing

### Step 2: Infrastructure Testing

Once the infrastructure is deployed, tests are run to validate it:

1. Pester tests are loaded from the `tests` directory
2. Each test category (storage, key vault, network) is run in sequence
3. Tests compare the actual deployed resources against expected configurations
4. Test failures indicate compliance issues or misconfigurations
5. Test results are saved in NUnit XML format in the `TestResults` directory

### Step 3: Result Visualization

The test results are then visualized in a web dashboard:

1. The Node.js visualization server is started (if not already running)
2. Test result XML files are uploaded to the server
3. The server processes the XML and generates JSON reports
4. A web browser is opened to display the test results dashboard
5. The dashboard shows pass/fail statistics, test details, and charts

## Running the Workflow

To run the entire workflow, use the following command:

```powershell
./scripts/Deploy-Test-Visualize.ps1 -ResourceGroupName "qa-test-rg" -Location "eastus"
```

### Common Parameters

- `-ResourceGroupName`: The name of the target Azure resource group
- `-Location`: The Azure region to deploy resources in
- `-EnvironmentName`: The environment name (dev, test, prod)
- `-VisualizerPort`: The port for the visualization server (default: 3000)
- `-SkipDeployment`: Skip the deployment phase
- `-SkipTests`: Skip the testing phase
- `-SkipVisualization`: Skip the visualization phase

## Customizing the Workflow

### Custom Infrastructure

To modify the infrastructure being deployed:

1. Edit the `infra/main.bicep` file
2. Adjust parameters in module files as needed
3. Run the workflow script to deploy your changes

### Custom Tests

To add new tests:

1. Create a new test file in the `tests` directory
2. Follow the Pester test format (see existing test files for examples)
3. Update the workflow script to include your test file

### Custom Visualization

To enhance the visualization:

1. Modify the `visualize/views/report.ejs` template
2. Add new charts or visualizations as needed
3. Update the server.js file to include additional data processing

## CI/CD Integration

The workflow can be integrated into CI/CD pipelines:

1. Add the `Deploy-Test-Visualize.ps1` script to your pipeline
2. Set up appropriate service principals and permissions
3. Configure pipeline variables for resource group, location, etc.
4. Use the `-SkipVisualization` flag in CI/CD scenarios
5. Publish test results to the pipeline's test reporting system

## Troubleshooting

Common issues and solutions:

- **Deployment Failures**: Check Azure permissions and resource name conflicts
- **Test Failures**: Examine test results for specific compliance issues
- **Visualization Issues**: Ensure Node.js is installed and server is running

For detailed logs, run the workflow script with the `-Verbose` parameter.
