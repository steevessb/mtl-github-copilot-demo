# Connect-AzureAccount.ps1
# Helper script to authenticate with Azure using service principal or managed identity
# Quality Engineer: Use this script in CI/CD pipelines or local development

param(
    [Parameter(Mandatory=$false)]
    [string]$TenantId = $env:AZURE_TENANT_ID,
    
    [Parameter(Mandatory=$false)]
    [string]$ClientId = $env:AZURE_CLIENT_ID,
    
    [Parameter(Mandatory=$false)]
    [string]$ClientSecret = $env:AZURE_CLIENT_SECRET,
    
    [Parameter(Mandatory=$false)]
    [switch]$UseManagedIdentity
)

# Quality Engineer: This script handles both service principal and managed identity scenarios
# Use managed identity in Azure DevOps or Azure environments, use service principal elsewhere

if ($UseManagedIdentity) {
    Write-Host "Connecting to Azure using Managed Identity..."
    # For Azure DevOps agents, App Service, or other Azure services
    Connect-AzAccount -Identity
}
else {
    # Validate required parameters for service principal
    if (-not $TenantId -or -not $ClientId -or -not $ClientSecret) {
        Write-Error "TenantId, ClientId, and ClientSecret must be provided or available as environment variables"
        exit 1
    }

    Write-Host "Connecting to Azure using Service Principal..."
    $SecureSecret = ConvertTo-SecureString -String $ClientSecret -AsPlainText -Force
    $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ClientId, $SecureSecret
    
    Connect-AzAccount -ServicePrincipal -Tenant $TenantId -Credential $Credential
}

# List available subscriptions
Get-AzSubscription | Format-Table Name, Id -AutoSize
