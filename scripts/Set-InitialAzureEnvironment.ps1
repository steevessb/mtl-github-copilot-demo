# Set-InitialAzureEnvironment.ps1
# PowerShell script to set up initial Azure environment for testing
# Quality Engineer: Run this script to create a consistent testing environment

param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "canadaeast",
    
    [Parameter(Mandatory=$false)]
    [string]$StorageAccountNamePrefix = "qastorage",
    
    [Parameter(Mandatory=$false)]
    [hashtable]$Tags = @{
        Environment = "QA"
        Owner = "QA Team"
        CostCenter = "12345"
    }
)

# Connect to Azure (if not already connected)
$context = Get-AzContext
if (-not $context) {
    # Quality Engineer: Replace with your Connect-AzureAccount.ps1 script or connect manually
    Write-Host "Not connected to Azure. Please run Connect-AzureAccount.ps1 first."
    exit 1
}

Write-Host "Creating test environment in Azure..."
Write-Host "Resource Group: $ResourceGroupName"
Write-Host "Location: $Location"

# Create Resource Group if it doesn't exist
$rg = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
if (-not $rg) {
    Write-Host "Creating Resource Group: $ResourceGroupName..."
    $rg = New-AzResourceGroup -Name $ResourceGroupName -Location $Location -Tag $Tags
    Write-Host "Resource Group created successfully."
} else {
    Write-Host "Resource Group already exists."
}

# Create a unique storage account name
$randomSuffix = -join ((48..57) + (97..122) | Get-Random -Count 6 | ForEach-Object {[char]$_})
$storageAccountName = "$($StorageAccountNamePrefix)$randomSuffix"
$storageAccountName = $storageAccountName.ToLower() -replace '[^a-z0-9]', ''
$storageAccountName = $storageAccountName.Substring(0, [System.Math]::Min(24, $storageAccountName.Length))

# Create Storage Account
Write-Host "Creating Storage Account: $storageAccountName..."
$storageAccount = New-AzStorageAccount -ResourceGroupName $ResourceGroupName `
    -Name $storageAccountName `
    -Location $Location `
    -SkuName Standard_LRS `
    -Kind StorageV2 `
    -Tag $Tags `
    -EnableHttpsTrafficOnly $true `
    -MinimumTlsVersion TLS1_2 `
    -AllowBlobPublicAccess $false

Write-Host "Storage Account created successfully: $($storageAccount.StorageAccountName)"

# Create a Network Security Group
$nsgName = "test-nsg"
Write-Host "Creating Network Security Group: $nsgName..."

$nsgRuleConfig = @(
    @{
        Name = "allow-https"
        Protocol = "Tcp"
        Direction = "Inbound"
        Priority = 100
        SourceAddressPrefix = "*"
        SourcePortRange = "*"
        DestinationAddressPrefix = "*"
        DestinationPortRange = "443"
        Access = "Allow"
    },
    @{
        Name = "deny-all"
        Protocol = "*"
        Direction = "Inbound"
        Priority = 4096
        SourceAddressPrefix = "*"
        SourcePortRange = "*"
        DestinationAddressPrefix = "*"
        DestinationPortRange = "*"
        Access = "Deny"
    }
)

$nsg = New-AzNetworkSecurityGroup -ResourceGroupName $ResourceGroupName `
    -Location $Location `
    -Name $nsgName `
    -Tag $Tags

foreach ($rule in $nsgRuleConfig) {
    $nsg | Add-AzNetworkSecurityRuleConfig `
        -Name $rule.Name `
        -Protocol $rule.Protocol `
        -Direction $rule.Direction `
        -Priority $rule.Priority `
        -SourceAddressPrefix $rule.SourceAddressPrefix `
        -SourcePortRange $rule.SourcePortRange `
        -DestinationAddressPrefix $rule.DestinationAddressPrefix `
        -DestinationPortRange $rule.DestinationPortRange `
        -Access $rule.Access | Set-AzNetworkSecurityGroup
}

Write-Host "Network Security Group created successfully: $nsgName"

# Add a resource lock to the Resource Group
Write-Host "Adding a delete lock to Resource Group..."
New-AzResourceLock -LockName "DeleteLock" `
    -LockLevel CanNotDelete `
    -ResourceGroupName $ResourceGroupName `
    -LockNotes "Prevents accidental deletion of test environment"

Write-Host "Environment setup complete. Resource Group: $ResourceGroupName is ready for testing."
Write-Host "Storage Account: $storageAccountName"
Write-Host "Network Security Group: $nsgName"

# Output the environment details for test configuration
@{
    ResourceGroupName = $ResourceGroupName
    Location = $Location
    StorageAccountName = $storageAccountName
    NetworkSecurityGroupName = $nsgName
}
