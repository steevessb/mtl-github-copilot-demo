// subnet.bicep - Module for deploying subnets
@description('The name of the subnet')
param name string

@description('The name of the virtual network')
param virtualNetworkName string

@description('The address prefix of the subnet')
param addressPrefix string

@description('Service endpoints to enable on the subnet')
param serviceEndpoints array = []

@description('Enable or disable private endpoint network policies on the subnet')
param privateEndpointNetworkPolicies string = 'Enabled'

@description('Enable or disable private link service network policies on the subnet')
param privateLinkServiceNetworkPolicies string = 'Enabled'

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2021-08-01' = {
  name: '${virtualNetworkName}/${name}'
  properties: {
    addressPrefix: addressPrefix
    serviceEndpoints: serviceEndpoints
    privateEndpointNetworkPolicies: privateEndpointNetworkPolicies
    privateLinkServiceNetworkPolicies: privateLinkServiceNetworkPolicies
  }
}

// Outputs
output id string = subnet.id
output name string = name
