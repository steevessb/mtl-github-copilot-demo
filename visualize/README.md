# Azure Test Results Visualizer

This Node.js application creates beautiful visualizations for your Pester test results, with Azure integration for storing and sharing reports.

## Features

- Parse NUnit XML test results from Pester
- Generate pie charts, bar charts, and other visualizations
- Store reports in Azure Blob Storage (optional)
- Web interface for viewing test results
- Export reports as PDF or images

## Setup

1. Install dependencies:
   ```
   npm install
   ```

2. Configure Azure Storage (optional):
   Rename `.env.example` to `.env` and update with your Azure Storage account details.

3. Start the server:
   ```
   npm start
   ```

4. Open your browser to http://localhost:3000

## Usage

1. Run your Pester tests with output format NUnitXml:
   ```powershell
   .\scripts\Invoke-LocalTests.ps1 -ExportResults
   ```

2. Upload the test results XML file to the visualizer

3. View and share your visualizations

## API Endpoints

- `GET /` - Web interface
- `POST /upload` - Upload test results
- `GET /reports/:id` - View a specific report
- `GET /api/results` - Get all test results as JSON

## Azure Integration

This tool can integrate with Azure in the following ways:
- Store reports in Azure Blob Storage
- Authenticate using Azure AD
- Deploy as an Azure Web App
