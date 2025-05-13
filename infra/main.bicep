// main.bicep - Main deployment template for Azure resources
// This file is generated based on InfrastructureFixtures.ps1 definitions

@description('The location for resource deployment')
param location string = resourceGroup().location

@description('Environment name used for resource naming')
param environmentName string = 'dev'

@description('Resource name prefix')
param prefix string = 'azure-qa'

@description('Generate a unique suffix for resource names based on the resource group id')
var resourceToken = uniqueString(subscription().id, environmentName)

// Resource Group names - using existing RGs
var qaTestRgName = 'qa-test-rg'
var prodTestRgName = 'prod-test-rg'

// ============= STORAGE ACCOUNTS =============
module storage1 'modules/storageAccount.bicep' = {
  name: 'storage1-deployment'
  params: {
    name: 'storage1${resourceToken}'
    location: 'eastus'
    sku: 'Standard_LRS'
    kind: 'StorageV2'
    enableHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    tags: {
      environment: environmentName
      'azd-env-name': environmentName
    }
  }
}

module storage2 'modules/storageAccount.bicep' = {
  name: 'storage2-deployment'
  params: {
    name: 'storage2${resourceToken}'
    location: 'canadaeast'
    sku: 'Standard_LRS'
    kind: 'StorageV2'
    enableHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    tags: {
      environment: environmentName
      'azd-env-name': environmentName
    }
  }
}

// ============= KEY VAULTS =============
module kv1 'modules/keyVault.bicep' = {
  name: 'kv1-deployment'
  params: {
    name: 'kv1${resourceToken}'
    location: 'eastus'
    sku: 'standard'
    enableSoftDelete: true
    enablePurgeProtection: true
    tags: {
      environment: environmentName
      'azd-env-name': environmentName
    }
  }
}

module kv2 'modules/keyVault.bicep' = {
  name: 'kv2-deployment'
  params: {
    name: 'kv2${resourceToken}'
    location: 'canadaeast'
    sku: 'standard'
    enableSoftDelete: true
    enablePurgeProtection: true
    tags: {
      environment: environmentName
      'azd-env-name': environmentName
    }
  }
}

// ============= VIRTUAL NETWORKS =============
module vnet1 'modules/virtualNetwork.bicep' = {
  name: 'vnet1-deployment'
  params: {
    name: 'vnet1${resourceToken}'
    location: 'eastus'
    addressPrefixes: [
      '10.0.0.0/16'
    ]
    tags: {
      environment: environmentName
      'azd-env-name': environmentName
    }
  }
}

module vnet2 'modules/virtualNetwork.bicep' = {
  name: 'vnet2-deployment'
  params: {
    name: 'vnet2${resourceToken}'
    location: 'canadaeast'
    addressPrefixes: [
      '10.1.0.0/16'
    ]
    tags: {
      environment: environmentName
      'azd-env-name': environmentName
    }
  }
}

// ============= SUBNETS =============
module subnet1 'modules/subnet.bicep' = {
  name: 'subnet1-deployment'
  params: {
    name: 'subnet1'
    virtualNetworkName: vnet1.outputs.name
    addressPrefix: '10.0.0.0/24'
  }
  dependsOn: [
    vnet1
  ]
}

module subnet2 'modules/subnet.bicep' = {
  name: 'subnet2-deployment'
  params: {
    name: 'subnet2'
    virtualNetworkName: vnet2.outputs.name
    addressPrefix: '10.1.0.0/24'
  }
  dependsOn: [
    vnet2
  ]
}

// ============= NETWORK SECURITY GROUPS =============
module nsg1 'modules/networkSecurityGroup.bicep' = {
  name: 'nsg1-deployment'
  params: {
    name: 'nsg1${resourceToken}'
    location: 'eastus'
    securityRules: [
      {
        name: 'AllowHTTPS'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
        }
      }
    ]
    tags: {
      environment: environmentName
      'azd-env-name': environmentName
    }
  }
}

module nsg2 'modules/networkSecurityGroup.bicep' = {
  name: 'nsg2-deployment'
  params: {
    name: 'nsg2${resourceToken}'
    location: 'canadaeast'
    securityRules: [
      {
        name: 'AllowHTTPS'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
        }
      }
    ]
    tags: {
      environment: environmentName
      'azd-env-name': environmentName
    }
  }
}

// ============= PRIVATE DNS ZONES =============
module privatedns1 'modules/privateDnsZone.bicep' = {
  name: 'privatedns1-deployment'
  params: {
    name: 'privatedns1.azure.com'
    location: 'global'
    tags: {
      environment: environmentName
      'azd-env-name': environmentName
    }
  }
}

module privatedns2 'modules/privateDnsZone.bicep' = {
  name: 'privatedns2-deployment'
  params: {
    name: 'privatedns2.azure.com'
    location: 'global' 
    tags: {
      environment: environmentName
      'azd-env-name': environmentName
    }
  }
}

// ============= OUTPUTS =============
output storage1Name string = storage1.outputs.name
output storage2Name string = storage2.outputs.name
output keyVault1Name string = kv1.outputs.name
output keyVault2Name string = kv2.outputs.name
output vnet1Name string = vnet1.outputs.name
output vnet2Name string = vnet2.outputs.name
output subnet1Name string = subnet1.outputs.name
output subnet2Name string = subnet2.outputs.name
output nsg1Name string = nsg1.outputs.name
output nsg2Name string = nsg2.outputs.name
output privateDns1Name string = privatedns1.outputs.name
output privateDns2Name string = privatedns2.outputs.name
