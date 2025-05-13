// virtualNetwork.bicep - Module for deploying virtual networks
@description('The name of the virtual network')
param name string

@description('The location of the virtual network')
param location string

@description('The address prefixes of the virtual network')
param addressPrefixes array

@description('Tags for the virtual network')
param tags object = {}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-08-01' = {
  name: name
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: addressPrefixes
    }
  }
  tags: tags
}

// Outputs
output id string = virtualNetwork.id
output name string = virtualNetwork.name
