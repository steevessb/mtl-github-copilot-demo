// privateDnsZone.bicep - Module for deploying private DNS zones
@description('The name of the private DNS zone')
param name string

@description('The location of the private DNS zone')
param location string = 'global'

@description('Tags for the private DNS zone')
param tags object = {}

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: name
  location: location
  tags: tags
}

// Outputs
output id string = privateDnsZone.id
output name string = privateDnsZone.name
