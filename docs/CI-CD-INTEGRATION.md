# Azure QA Test Visualization in CI/CD

This guide explains how to integrate the Azure QA Test Visualizer with your CI/CD pipeline.

## Azure DevOps Pipeline Integration

Add the following steps to your Azure pipeline to generate and store test visualizations:

```yaml
# azure-pipelines.yml
steps:
- task: PowerShell@2
  displayName: 'Run Pester Tests'
  inputs:
    targetType: 'inline'
    script: |
      Install-Module -Name Pester -RequiredVersion 5.3.3 -Force -SkipPublisherCheck
      $testResultsPath = "$(Build.ArtifactStagingDirectory)/TestResults.xml"
      $pesterConfig = New-PesterConfiguration
      $pesterConfig.Run.Path = "./src"
      $pesterConfig.Output.Verbosity = 'Detailed'
      $pesterConfig.TestResult.Enabled = $true
      $pesterConfig.TestResult.OutputFormat = 'NUnitXml'
      $pesterConfig.TestResult.OutputPath = $testResultsPath
      Invoke-Pester -Configuration $pesterConfig
      
- task: PublishTestResults@2
  displayName: 'Publish Test Results'
  inputs:
    testResultsFormat: 'NUnit'
    testResultsFiles: '$(Build.ArtifactStagingDirectory)/TestResults.xml'
    failTaskOnFailedTests: true

- task: NodeTool@0
  displayName: 'Install Node.js'
  inputs:
    versionSpec: '14.x'

- task: PowerShell@2
  displayName: 'Generate Test Visualization'
  inputs:
    targetType: 'inline'
    script: |
      # Install dependencies for visualizer
      cd ./visualize
      npm install
      
      # Process test results and generate visualization
      $testResultsPath = "$(Build.ArtifactStagingDirectory)/TestResults.xml"
      $reportPath = "$(Build.ArtifactStagingDirectory)/TestReport"
      
      # Create a static HTML report
      node -e "
        const fs = require('fs');
        const path = require('path');
        const xml2js = require('xml2js');
        const ejs = require('ejs');
        
        // Parse the XML file
        const parser = new xml2js.Parser({ explicitArray: false });
        const data = fs.readFileSync('$testResultsPath', 'utf8');
        
        parser.parseString(data, (err, result) => {
          if (err) throw err;
          
          // Process test results
          const testResults = processTestResults(result);
          
          // Generate HTML report
          ejs.renderFile('views/report.ejs', { report: testResults }, {}, (err, html) => {
            if (err) throw err;
            fs.mkdirSync('$reportPath', { recursive: true });
            fs.writeFileSync(path.join('$reportPath', 'index.html'), html);
            fs.copyFileSync('public/css/styles.css', path.join('$reportPath', 'styles.css'));
            console.log('Report generated successfully!');
          });
        });
        
        function processTestResults(xmlData) {
          // Full processing function from server.js
          // ...abbreviated for clarity...
        }
      "
      
- task: PublishBuildArtifacts@1
  displayName: 'Publish Test Visualization'
  inputs:
    pathToPublish: '$(Build.ArtifactStagingDirectory)/TestReport'
    artifactName: 'TestVisualization'
```

## GitHub Actions Integration

For GitHub Actions, you can use a similar approach:

```yaml
# .github/workflows/test-pipeline.yml
name: Test and Visualize

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: windows-latest
    
    steps:
    - uses: actions/checkout@v2
    
    - name: Install Pester
      shell: pwsh
      run: |
        Install-Module -Name Pester -RequiredVersion 5.3.3 -Force -SkipPublisherCheck
    
    - name: Run Tests
      shell: pwsh
      run: |
        $testResultsPath = "./TestResults.xml"
        $pesterConfig = New-PesterConfiguration
        $pesterConfig.Run.Path = "./src"
        $pesterConfig.Output.Verbosity = 'Detailed'
        $pesterConfig.TestResult.Enabled = $true
        $pesterConfig.TestResult.OutputFormat = 'NUnitXml'
        $pesterConfig.TestResult.OutputPath = $testResultsPath
        Invoke-Pester -Configuration $pesterConfig
    
    - name: Set up Node.js
      uses: actions/setup-node@v2
      with:
        node-version: '14'
    
    - name: Generate Test Visualization
      shell: pwsh
      run: |
        cd ./visualize
        npm install
        
        # Create visualization report
        # Similar Node.js script as in Azure DevOps example
    
    - name: Upload Test Results
      uses: actions/upload-artifact@v2
      with:
        name: test-results
        path: ./TestResults.xml
    
    - name: Upload Test Visualization
      uses: actions/upload-artifact@v2
      with:
        name: test-visualization
        path: ./TestReport
```

## Azure Functions Deployment

For a more permanent solution, you can deploy the visualizer as an Azure Function App:

1. Add deployment script to your pipeline:

```yaml
- task: AzureFunctionApp@1
  displayName: 'Deploy Visualizer to Azure Function'
  inputs:
    azureSubscription: 'Your-Azure-Connection'
    appType: 'functionApp'
    appName: 'qa-test-visualizer'
    package: './visualize'
    deploymentMethod: 'auto'
```

2. Configure the Azure Function App to run the Node.js server:

```json
{
  "name": "visualizer",
  "version": "1.0.0",
  "description": "Test Visualizer as Azure Function",
  "scripts": {
    "start": "func start"
  },
  "dependencies": {
    "express": "^4.18.2",
    "chart.js": "^4.4.0",
    "xml2js": "^0.6.2",
    "azure-storage": "^2.10.7"
  }
}
```

## Store Test Results in Azure Blob Storage

To keep a history of test results:

```powershell
# Upload test results to Azure Blob Storage
$connectionString = "YOUR_STORAGE_ACCOUNT_CONNECTION_STRING"
$containerName = "test-results"
$blobName = "TestResults-$(Get-Date -Format 'yyyy-MM-dd-HHmmss').xml"
$context = New-AzStorageContext -ConnectionString $connectionString
Set-AzStorageBlobContent -Context $context -Container $containerName -Blob $blobName -File $testResultsPath
```
