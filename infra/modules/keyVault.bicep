// keyVault.bicep - Module for deploying key vaults
@description('The name of the key vault')
param name string

@description('The location of the key vault')
param location string

@description('The SKU of the key vault')
@allowed([
  'standard'
  'premium'
])
param sku string = 'standard'

@description('Property to specify whether Azure Virtual Machines are permitted to retrieve certificates stored as secrets from the key vault')
param enabledForDeployment bool = false

@description('Property to specify whether Azure Resource Manager is permitted to retrieve secrets from the key vault')
param enabledForTemplateDeployment bool = false

@description('Property to specify whether Azure Disk Encryption is permitted to retrieve secrets from the vault and unwrap keys')
param enabledForDiskEncryption bool = false

@description('Property specifying whether protection against purge is enabled for this vault')
param enablePurgeProtection bool = true

@description('Property specifying whether the soft delete functionality is enabled for this vault')
param enableSoftDelete bool = true

@description('softDelete data retention days, value should be 7-90')
param softDeleteRetentionInDays int = 90

@description('Tags for the key vault')
param tags object = {}

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: name
  location: location
  properties: {
    enabledForDeployment: enabledForDeployment
    enabledForTemplateDeployment: enabledForTemplateDeployment
    enabledForDiskEncryption: enabledForDiskEncryption
    enablePurgeProtection: enablePurgeProtection ? true : json('null')
    enableSoftDelete: enableSoftDelete
    softDeleteRetentionInDays: softDeleteRetentionInDays
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: sku
    }
    accessPolicies: []
  }
  tags: tags
}

// Outputs
output id string = keyVault.id
output name string = keyVault.name
