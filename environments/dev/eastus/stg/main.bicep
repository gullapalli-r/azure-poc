targetScope = 'resourceGroup'

@allowed([
  'dev'
  'prod'
])
@description('Environment selector for Storage deployment.')
param environmentType string

@description('Deployment location for all Storage resources.')
param location string = resourceGroup().location

@description('Subnet resource ID used by storage private endpoint.')
param subnetId string

@description('Optional Log Analytics workspace ID for diagnostics.')
param diagnosticLogWorkspaceId string = ''

@description('Base tags applied to all resources.')
param tags object = {}

module dev 'main.dev.bicep' = if (environmentType == 'dev') {
  name: 'stg-dev'
  params: {
    location: location
    subnetId: subnetId
    diagnosticLogWorkspaceId: diagnosticLogWorkspaceId
    tags: tags
  }
}

module prod 'main.prod.bicep' = if (environmentType == 'prod') {
  name: 'stg-prod'
  params: {
    location: location
    subnetId: subnetId
    diagnosticLogWorkspaceId: diagnosticLogWorkspaceId
    tags: tags
  }
}

output deployedStorageNames array = (environmentType == 'dev'
  ? dev.?outputs.deployedStorageNames
  : prod.?outputs.deployedStorageNames) ?? []

output deployedStorageIds array = (environmentType == 'dev'
  ? dev.?outputs.deployedStorageIds
  : prod.?outputs.deployedStorageIds) ?? []
