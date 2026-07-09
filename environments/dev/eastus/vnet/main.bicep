targetScope = 'resourceGroup'

@allowed([
  'dev'
  'prod'
])
@description('Environment selector for VNet deployment.')
param environmentType string

@description('Deployment location for all VNets.')
param location string = resourceGroup().location

@description('Hub VNet resource ID for peering.')
param hubVnetResourceId string

@description('Base tags applied to all resources.')
param tags object = {}

module dev './main.dev.bicep' = if (environmentType == 'dev') {
  name: 'vnet-dev'
  params: {
    location: location
    hubVnetResourceId: hubVnetResourceId
    tags: tags
  }
}

module prod './main.prod.bicep' = if (environmentType == 'prod') {
  name: 'vnet-prod'
  params: {
    location: location
    hubVnetResourceId: hubVnetResourceId
    tags: tags
  }
}

output deployedVnetNames array = (environmentType == 'dev'
  ? dev.?outputs.deployedVnetNames
  : prod.?outputs.deployedVnetNames) ?? []

output deployedVnetIds array = (environmentType == 'dev' ? dev.?outputs.deployedVnetIds : prod.?outputs.deployedVnetIds) ?? []
