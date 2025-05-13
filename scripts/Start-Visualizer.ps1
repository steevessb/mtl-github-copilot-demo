# Start-Visualizer.ps1
# Starts the Node.js visualization server
# Quality Engineer: This script ensures the visualizer server is running

$rootDir = Split-Path -Parent $PSScriptRoot
$visualizerDir = Join-Path $rootDir "visualize"

# Check if visualization server directory exists
if (-not (Test-Path $visualizerDir)) {
    Write-Error "Visualizer directory not found at $visualizerDir"
    exit 1
}

# Change to visualizer directory
Push-Location $visualizerDir

try {
    # Check if Node.js is installed
    try {
        $nodeVersion = node -v
        Write-Host "Node.js version: $nodeVersion"
    } catch {
        Write-Error "Node.js is not installed or not in PATH. Please install Node.js"
        exit 1
    }

    # Check if the server is already running
    $isRunning = $false
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:3000" -TimeoutSec 2 -ErrorAction SilentlyContinue
        if ($response.StatusCode -eq 200) {
            $isRunning = $true
            Write-Host "Visualizer is already running on port 3000"
        }
    } catch {
        # Server not running, which is fine
    }

    # Start the server if not already running
    if (-not $isRunning) {
        # Check if dependencies are installed
        if (-not (Test-Path (Join-Path $visualizerDir "node_modules"))) {
            Write-Host "Installing dependencies..."
            npm install
        }

        # Start the server in the background
        Write-Host "Starting visualizer server..."
        $startCommand = 'Start-Process -FilePath "node" -ArgumentList "server.js" -NoNewWindow -PassThru'
        
        # For Windows, we need to use a different approach with Start-Job
        $job = Start-Job -ScriptBlock {
            param($dir)
            Set-Location $dir
            $process = Start-Process -FilePath "node" -ArgumentList "server.js" -NoNewWindow -PassThru
            # Return the process ID
            return $process.Id
        } -ArgumentList $visualizerDir
        
        # Wait a bit for the server to start
        Start-Sleep -Seconds 2
        
        # Get the process ID from the job
        $processId = Receive-Job -Job $job
        Remove-Job -Job $job -Force
        
        if ($processId) {
            Write-Host "Visualizer server started (Process ID: $processId)"
            
            # Wait for the server to be responsive
            $timeout = 30
            $elapsed = 0
            $serverReady = $false
            
            while (-not $serverReady -and $elapsed -lt $timeout) {
                try {
                    $response = Invoke-WebRequest -Uri "http://localhost:3000" -TimeoutSec 1 -ErrorAction SilentlyContinue
                    if ($response.StatusCode -eq 200) {
                        $serverReady = $true
                        Write-Host "Visualizer server is ready at http://localhost:3000"
                    }
                } catch {
                    # Server not yet responsive
                    Write-Host "Waiting for server to become responsive... ($elapsed/$timeout seconds)"
                    Start-Sleep -Seconds 1
                    $elapsed++
                }
            }
            
            if (-not $serverReady) {
                Write-Warning "Visualizer server started but not responding within $timeout seconds"
            }
        } else {
            Write-Error "Failed to start visualizer server"
        }
    }
} finally {
    # Return to the original directory
    Pop-Location
}
