// server.js
// Main entry point for the Node.js visualization server
// Quality Engineer: This server provides a web interface for visualizing Pester test results

require('dotenv').config();
const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const xml2js = require('xml2js');
const azure = require('azure-storage');

// Initialize Express app
const app = express();
const port = process.env.PORT || 3000;
const upload = multer({ dest: 'uploads/' });

// Set up view engine
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));
app.use(express.static(path.join(__dirname, 'public')));

// Initialize Azure Blob Storage client (if configured)
let blobService = null;
if (process.env.AZURE_STORAGE_CONNECTION_STRING) {
    blobService = azure.createBlobService(process.env.AZURE_STORAGE_CONNECTION_STRING);
    // Create container if it doesn't exist
    blobService.createContainerIfNotExists('testresults', {
        publicAccessLevel: 'blob'
    }, (error) => {
        if (error) {
            console.error('Error creating Azure Blob container:', error);
        } else {
            console.log('Azure Blob Storage connected and container created/verified');
        }
    });
}

// Home page route
app.get('/', (req, res) => {
    // Get list of reports from reports directory
    const reportsDir = path.join(__dirname, 'public', 'reports');
    
    // Create directory if it doesn't exist
    if (!fs.existsSync(reportsDir)) {
        fs.mkdirSync(reportsDir, { recursive: true });
    }
    
    // Read reports directory
    fs.readdir(reportsDir, (err, files) => {
        if (err) {
            console.error('Error reading reports directory:', err);
            return res.render('index', { reports: [] });
        }
        
        // Filter for JSON report files
        const reports = files
            .filter(file => file.endsWith('.json'))
            .map(file => {
                const reportData = JSON.parse(fs.readFileSync(path.join(reportsDir, file), 'utf8'));
                return {
                    id: file.replace('.json', ''),
                    name: reportData.name || file,
                    date: reportData.date || 'Unknown',
                    passed: reportData.summary.passed,
                    failed: reportData.summary.failed,
                    skipped: reportData.summary.skipped
                };
            });
        
        res.render('index', { reports });
    });
});

// Consolidated view route
app.get('/consolidated', (req, res) => {
    // Get list of reports from reports directory
    const reportsDir = path.join(__dirname, 'public', 'reports');
    
    // Create directory if it doesn't exist
    if (!fs.existsSync(reportsDir)) {
        fs.mkdirSync(reportsDir, { recursive: true });
    }
    
    // Read reports directory
    fs.readdir(reportsDir, (err, files) => {
        if (err) {
            console.error('Error reading reports directory:', err);
            return res.render('consolidated', { reports: [] });
        }
        
        // Filter for JSON report files
        const reports = files
            .filter(file => file.endsWith('.json'))
            .map(file => {
                const reportData = JSON.parse(fs.readFileSync(path.join(reportsDir, file), 'utf8'));
                return {
                    id: file.replace('.json', ''),
                    name: reportData.name || file,
                    date: reportData.date || 'Unknown',
                    summary: reportData.summary,
                    categories: reportData.categories,
                    testCases: reportData.testCases
                };
            });
        
        res.render('consolidated', { reports });
    });
});

// Upload results route
app.post('/upload', upload.single('testResults'), (req, res) => {
    if (!req.file) {
        return res.status(400).send('No file uploaded');
    }
    
    // Parse the XML file
    const parser = new xml2js.Parser({ explicitArray: false });
    fs.readFile(req.file.path, (err, data) => {
        if (err) {
            console.error('Error reading uploaded file:', err);
            return res.status(500).send('Error reading file');
        }
        
        parser.parseString(data, (err, result) => {
            if (err) {
                console.error('Error parsing XML:', err);
                return res.status(500).send('Invalid XML file');
            }
            
            try {                // Process test results
                const testResults = processTestResults(result);
                const reportId = `report-${Date.now()}`;
                const reportPath = path.join(__dirname, 'public', 'reports', `${reportId}.json`);
                
                // Save processed results
                fs.writeFileSync(reportPath, JSON.stringify(testResults));
                
                // Upload to Azure Blob Storage if configured
                if (blobService) {
                    blobService.createBlockBlobFromLocalFile(
                        'testresults',
                        `${reportId}.json`,
                        reportPath,
                        (error) => {
                            if (error) {
                                console.error('Error uploading to Azure Blob Storage:', error);
                            } else {
                                console.log('Report uploaded to Azure Blob Storage');
                                // Add Azure URL to the report
                                testResults.azureUrl = blobService.getUrl('testresults', `${reportId}.json`);
                                fs.writeFileSync(reportPath, JSON.stringify(testResults));
                            }
                        }
                    );
                }
                  // Check if this is a programmatic upload (API request)
                // If Accept header includes application/json, return JSON response
                if (req.headers.accept && req.headers.accept.includes('application/json')) {
                    return res.json({ 
                        success: true, 
                        reportId: reportId,
                        reportUrl: `/report/${reportId}`,
                        summary: testResults.summary
                    });
                }
                
                // If it's a browser upload, redirect to the consolidated view
                res.redirect('/consolidated');
            } catch (error) {
                console.error('Error processing test results:', error);
                res.status(500).send('Error processing test results');
            }
        });
    });
});

// View report route
app.get('/report/:id', (req, res) => {
    const reportPath = path.join(__dirname, 'public', 'reports', `${req.params.id}.json`);
    
    if (!fs.existsSync(reportPath)) {
        return res.status(404).send('Report not found');
    }
    
    const reportData = JSON.parse(fs.readFileSync(reportPath, 'utf8'));
    res.render('report', { report: reportData });
});

// API endpoint to get test results as JSON
app.get('/api/results/:id', (req, res) => {
    const reportPath = path.join(__dirname, 'public', 'reports', `${req.params.id}.json`);
    
    if (!fs.existsSync(reportPath)) {
        return res.status(404).json({ error: 'Report not found' });
    }
    
    const reportData = JSON.parse(fs.readFileSync(reportPath, 'utf8'));
    res.json(reportData);
});

// Helper function to extract meaningful test names
function extractTestName(fullName, attrs) {
    // Best option: use the description attribute if available
    if (attrs && attrs.description) {
        return attrs.description;
    }
    
    if (!fullName) return 'Unnamed Test';
    
    // Fallback: extract from the name
    // For names like "Azure Security Compliance Tests.Web App Security.All Web Apps should use minimum TLS 1.2"
    // Extract the most descriptive part
    const nameParts = fullName.split('.');
    if (nameParts.length >= 3) {
        return nameParts[nameParts.length - 1];
    }
    
    // Last resort: return the original name
    return fullName;
}

// Process test results from NUnit XML format
function processTestResults(xmlData) {
    const testResults = {
        name: 'Pester Test Results',
        date: new Date().toISOString(),
        summary: {
            total: 0,
            passed: 0,
            failed: 0,
            skipped: 0
        },
        categories: {},
        testCases: []
    };
      // Extract test-suite information from NUnit XML
    const testSuite = xmlData['test-results']['test-suite'];
      // Process test summary
    testResults.name = testSuite && testSuite.$ ? testSuite.$.name || 'Pester Test Results' : 'Pester Test Results';
      // XML attributes are in the $ property with xml2js parser
    const testResultsAttr = xmlData['test-results'] && xmlData['test-results'].$ ? xmlData['test-results'].$ : null;
    
    // Extract values from the XML attributes if they exist
    if (testResultsAttr) {
        testResults.summary.total = parseInt(testResultsAttr.total) || 0;
        testResults.summary.failed = parseInt(testResultsAttr.failures) || 0;
        testResults.summary.notRun = parseInt(testResultsAttr['not-run']) || 0;
        testResults.summary.inconclusive = parseInt(testResultsAttr.inconclusive) || 0;
        testResults.summary.ignored = parseInt(testResultsAttr.ignored) || 0;
        testResults.summary.invalid = parseInt(testResultsAttr.invalid) || 0;
        testResults.summary.skipped = parseInt(testResultsAttr.skipped) || 0;
        testResults.summary.errors = parseInt(testResultsAttr.errors) || 0;    } else {
        console.log('WARNING: Could not find test-results attributes in XML');
    }
    
    // Calculate passed tests - in Pester 9 passed tests = total - failures - not-run - other categories
    // Check if the success attribute is set on test cases
    let successCount = 0;
    
    // Count all successful test cases
    function countSuccessfulTests(obj) {
        if (!obj) return;
          // Check if this is a test case
        if (obj['test-case']) {
            const testCases = Array.isArray(obj['test-case']) ? obj['test-case'] : [obj['test-case']];
            testCases.forEach(testCase => {
                // Check $ property for attributes
                const attrs = testCase.$ || {};
                if (attrs.success === 'True' || attrs.result === 'Success') {
                    successCount++;
                }
            });
        }
        
        // Recursively process child objects
        if (typeof obj === 'object') {
            for (const key in obj) {
                if (typeof obj[key] === 'object') {
                    countSuccessfulTests(obj[key]);
                }
            }
        }
    }
    
    countSuccessfulTests(xmlData);
      // If we found success attributes, use that count
    if (successCount > 0) {
        testResults.summary.passed = successCount;
    } else {
        // Otherwise calculate from total minus all other categories
        testResults.summary.passed = testResults.summary.total - 
            (testResults.summary.failed + 
             testResults.summary.notRun + 
             testResults.summary.inconclusive + 
             testResults.summary.ignored + 
             testResults.summary.invalid + 
             testResults.summary.skipped + 
             testResults.summary.errors);
    }
      // Ensure passed count is never negative
    testResults.summary.passed = Math.max(0, testResults.summary.passed);
    
    // If skipped is not set directly, use notRun or other categories
    if (testResults.summary.skipped === 0) {
        testResults.summary.skipped = testResults.summary.notRun + 
                                     testResults.summary.inconclusive +
                                     testResults.summary.ignored +
                                     testResults.summary.invalid;
    }
    
    // Process individual test cases
    function processTestSuite(suite, parentContext = []) {
        if (!suite) return;
          // Skip the root Pester element and file paths
        const currentContext = [...parentContext];
        if (suite.$ && suite.$.name && suite.$.name !== 'Pester' && !suite.$.name.startsWith('C:\\')) {
            currentContext.push(suite.$.name);
        }
        
        // Add category data
        if (currentContext.length > 0) {
            const category = currentContext[0];
            if (!testResults.categories[category]) {
                testResults.categories[category] = {
                    total: 0,
                    passed: 0,
                    failed: 0,
                    skipped: 0
                };
            }
        }
        
        // Process nested test suites
        if (suite['results'] && suite['results']['test-suite']) {
            const nestedSuites = Array.isArray(suite['results']['test-suite']) 
                ? suite['results']['test-suite'] 
                : [suite['results']['test-suite']];
            
            nestedSuites.forEach(nestedSuite => {
                processTestSuite(nestedSuite, currentContext);
            });
        }
        
        // Process test cases
        if (suite['results'] && suite['results']['test-case']) {
            const testCases = Array.isArray(suite['results']['test-case']) 
                ? suite['results']['test-case'] 
                : [suite['results']['test-case']];
              testCases.forEach(testCase => {
                // Get attributes from $ property 
                const attrs = testCase.$ || {};
                
                // Determine the test result - use success attribute or result
                let testResult = 'Unknown';
                if (attrs.success === 'True') {
                    testResult = 'Success';
                } else if (attrs.success === 'False') {
                    testResult = 'Failure';
                } else {
                    testResult = attrs.result || 'Unknown';
                }                // Extract test case data
                const test = {
                    name: extractTestName(attrs.name || 'Unnamed Test', attrs),
                    description: attrs.description || (attrs.name || 'Unnamed Test'),
                    result: testResult,
                    duration: parseFloat(attrs.time) || 0,
                    context: [...currentContext]
                };
                
                // Add to test cases array
                testResults.testCases.push(test);
                
                // Update category statistics if applicable
                if (currentContext.length > 0) {
                    const category = currentContext[0];
                    testResults.categories[category].total++;
                    
                    switch (test.result) {
                        case 'Success':
                            testResults.categories[category].passed++;
                            break;
                        case 'Failure':
                            testResults.categories[category].failed++;
                            break;
                        default: // Inconclusive, Ignored, NotRun, etc.
                            testResults.categories[category].skipped++;
                            break;
                    }
                }
            });
        }
    }
    
    // Start processing from the root test suite
    processTestSuite(testSuite);
    
    // Check if we have test cases - if not, try a more aggressive approach
    if (testResults.testCases.length === 0) {
        // Try to find all test cases in the XML no matter where they are
        function findAllTestCases(obj, context = []) {
            if (!obj) return;
            
            if (obj['test-case']) {
                const testCases = Array.isArray(obj['test-case']) 
                    ? obj['test-case'] 
                    : [obj['test-case']];
                  testCases.forEach(testCase => {
                    // Get attributes from $ property
                    const attrs = testCase.$ || {};
                    
                    // Determine the test result - use success attribute or result
                    let testResult = 'Unknown';
                    if (attrs.success === 'True') {
                        testResult = 'Success';
                    } else if (attrs.success === 'False') {
                        testResult = 'Failure';
                    } else {
                        testResult = attrs.result || 'Unknown';
                    }                    
                    const test = {
                        name: extractTestName(attrs.name || 'Unnamed Test', attrs),
                        description: attrs.description || (attrs.name || 'Unnamed Test'),
                        result: testResult,
                        duration: parseFloat(attrs.time) || 0,
                        context: [...context]
                    };
                    
                    testResults.testCases.push(test);
                });
            }
            
            // Recursively search for test cases in nested objects
            if (typeof obj === 'object') {
                for (const key in obj) {
                    if (typeof obj[key] === 'object' && obj[key] !== null) {                        // If we're in a test-suite, add its name to the context
                        const newContext = [...context];
                        if (key === 'test-suite' && obj[key].$ && obj[key].$.name && 
                            obj[key].$.name !== 'Pester' && !obj[key].$.name.startsWith('C:\\')) {
                            newContext.push(obj[key].$.name);
                        }
                        findAllTestCases(obj[key], newContext);
                    }
                }
            }
        }
        
        // Start the recursive search from the root
        findAllTestCases(xmlData);
    }
    
    return testResults;
}

// Start the server
app.listen(port, () => {
    console.log(`Test Visualizer server running at http://localhost:${port}`);
});
