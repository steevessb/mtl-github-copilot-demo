# Azure Test Results Visualizer Integration

This document explains how to use the Azure Test Results Visualizer with your Pester tests.

## Getting Started

### Prerequisites
- Node.js installed
- PowerShell with Pester module
- Azure subscription (optional, for cloud deployment)

### Installation

1. Install dependencies for the visualizer:
   ```
   cd visualize
   npm install
   ```

### Running Tests with Visualization

Use the provided PowerShell script to run tests and automatically launch the visualizer:

```powershell
./scripts/Test-Visualizer.ps1
```

This script will:
1. Run your Pester tests
2. Generate NUnit XML results
3. Start the Node.js visualizer server
4. **Automatically upload** the results to the visualizer
5. Open your browser to view the visualization report

Alternatively, you can run the tests and then visualize in a single step:

```powershell
./scripts/Invoke-LocalTests.ps1 -ExportResults -Visualize
```

The visualizer web interface also maintains the upload button for manual uploads of previously generated test results.

### Visualization Features

The visualizer provides:

1. **Summary Dashboard**
   - Overall pass/fail/skip statistics
   - Pie charts showing test distribution

2. **Detailed Test Results**
   - Filterable list of test cases
   - Duration information
   - Category-based grouping

3. **Azure Integration**
   - Storage of test results in Azure Blob Storage
   - Optional deployment to Azure App Service

## Azure Deployment

To deploy the visualizer to Azure:

```powershell
./scripts/Deploy-Visualizer.ps1
```

This will create:
- Azure Resource Group
- Storage Account for test results
- App Service for the visualizer

## Custom Integration

You can integrate the visualizer with your existing CI/CD pipeline:

1. Configure your pipeline to generate NUnit XML test results
2. Upload results to the visualizer (local or Azure-hosted)
3. View and share the visualization reports

## Advanced Usage

### Custom Charts

The visualizer uses Chart.js for rendering. You can modify the charts by editing:
- `visualize/views/report.ejs` - Chart configurations
- `visualize/server.js` - Data processing logic
