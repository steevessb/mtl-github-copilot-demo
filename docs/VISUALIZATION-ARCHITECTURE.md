# Test Visualizer Architecture

## Overview

The Azure QA Test Visualizer is a Node.js application that provides beautiful and interactive visualizations for Pester test results. It includes integration with Azure services for storage and hosting.

```
┌──────────────────┐     ┌───────────────────┐     ┌─────────────────┐
│                  │     │                   │     │                 │
│ PowerShell Tests ├────►│ XML Test Results  ├────►│ Node.js Server  │
│ (Pester)         │     │ (NUnit Format)    │     │                 │
│                  │     │                   │     │                 │
└──────────────────┘     └───────────────────┘     └────────┬────────┘
                                                            │
                                                            ▼
┌──────────────────┐     ┌───────────────────┐     ┌─────────────────┐
│                  │     │                   │     │                 │
│ Browser          │◄────┤ Visualization     │◄────┤ Test Results    │
│ (Charts & UI)    │     │ (HTML/CSS/JS)     │     │ Processing      │
│                  │     │                   │     │                 │
└──────────────────┘     └───────────────────┘     └─────────────────┘
```

## Component Details

### 1. Test Runner (PowerShell/Pester)

- Executes Pester tests against Azure resources
- Supports local simulation mode with Azurite
- Generates NUnit XML format test results
- Integration with PowerShell scripts for test execution

### 2. Visualization Server (Node.js)

- Express.js web server
- Processes XML test results into structured data
- Generates interactive visualizations
- REST API endpoints for test result operations
- Azure Blob Storage integration for result persistence

### 3. User Interface (Web)

- Responsive web interface
- Chart.js for interactive visualizations:
  - Pie charts for overall pass/fail statistics
  - Bar charts for category-based results
  - Doughnut charts for test duration analysis
- Filterable test result tables
- Test result sharing capabilities

### 4. Azure Integration

- Storage of test results in Azure Blob Storage
- Optional deployment to Azure App Service
- Azure DevOps pipeline integration

## Data Flow

1. **Test Execution**:
   - PowerShell scripts execute Pester tests
   - Tests run against real Azure resources or simulator
   - Results saved in NUnit XML format

2. **Results Processing**:
   - XML parsed and transformed into structured JSON
   - Test categories and metrics extracted
   - Statistical analysis performed

3. **Visualization Generation**:
   - Chart configurations created based on test metrics
   - Interactive web interface populated with data
   - Results stored for historical comparison

4. **User Interaction**:
   - Users can filter and explore test results
   - Export reports in various formats
   - Share results via Azure Blob Storage URLs

## Deployment Options

1. **Local Development**:
   - Run locally with `npm start`
   - Access via http://localhost:3000

2. **Azure App Service**:
   - Deploy as Node.js web app
   - Persistent visualization service
   - Integrated with Azure AD for authentication

3. **Containerized Deployment**:
   - Docker container for portable deployment
   - Kubernetes for scalable test visualization

## Extensibility

The architecture is designed to be extensible:

1. **New Visualizations**:
   - Add new chart types by extending report.ejs
   - Implement custom visualizations with D3.js

2. **Additional Test Formats**:
   - Support for JUnit and other XML formats
   - Integration with other testing frameworks

3. **Data Export**:
   - PDF report generation
   - Excel/CSV export options
   - Integration with document management systems
