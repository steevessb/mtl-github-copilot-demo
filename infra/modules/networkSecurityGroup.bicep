// networkSecurityGroup.bicep - Module for deploying network security groups
@description('The name of the network security group')
param name string

@description('The location of the network security group')
param location string

@description('The security rules of the network security group')
param securityRules array = []

@description('Tags for the network security group')
param tags object = {}

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2021-08-01' = {
  name: name
  location: location
  properties: {
    securityRules: securityRules
  }
  tags: tags
}

// Outputs
output id string = networkSecurityGroup.id
output name string = networkSecurityGroup.name
