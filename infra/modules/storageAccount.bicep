// storageAccount.bicep - Module for deploying storage accounts
@description('The name of the storage account')
param name string

@description('The location of the storage account')
param location string

@description('The SKU of the storage account')
@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
  'Standard_ZRS'
  'Premium_LRS'
  'Premium_ZRS'
])
param sku string = 'Standard_LRS'

@description('The kind of the storage account')
@allowed([
  'Storage'
  'StorageV2'
  'BlobStorage'
  'FileStorage'
  'BlockBlobStorage'
])
param kind string = 'StorageV2'

@description('Indicates whether the storage account permits requests to be authorized with the account access key via Shared Key')
param allowSharedKeyAccess bool = true

@description('Indicates whether traffic is allowed over HTTPS only')
param enableHttpsTrafficOnly bool = true

@description('Minimum TLS version to be permitted on requests to storage')
@allowed([
  'TLS1_0'
  'TLS1_1'
  'TLS1_2'
])
param minimumTlsVersion string = 'TLS1_2'

@description('Allow or disallow public access to all blobs or containers in the storage account')
param allowBlobPublicAccess bool = false

@description('Tags for the storage account')
param tags object = {}

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: name
  location: location
  kind: kind
  sku: {
    name: sku
  }
  properties: {
    allowSharedKeyAccess: allowSharedKeyAccess
    minimumTlsVersion: minimumTlsVersion
    supportsHttpsTrafficOnly: enableHttpsTrafficOnly
    allowBlobPublicAccess: allowBlobPublicAccess
  }
  tags: tags
}

// Outputs
output id string = storageAccount.id
output name string = storageAccount.name
