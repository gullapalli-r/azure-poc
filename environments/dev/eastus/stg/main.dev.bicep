targetScope = 'resourceGroup'

@description('Deployment location for all Storage resources.')
param location string = resourceGroup().location

@description('Subnet resource ID used by storage private endpoint.')
param subnetId string

@description('Optional Log Analytics workspace ID for diagnostics.')
param diagnosticLogWorkspaceId string = ''

@description('Base tags applied to all resources.')
param tags object = {}

var storageConfig = [
  {
    namePrefix: 'stpocdeveus01'
    sku: 'Standard_LRS'
    containers: [
      'raw'
      'curated'
    ]
  }
]

module stg 'br:bicepiacregistry.azurecr.io/bicep/constructs/storage-account:0.5.0' = [
  for (item, i) in storageConfig: {
    name: 'stg-dev-${i}'
    params: {
      location: location
      name: toLower(take('${item.namePrefix}${substring(uniqueString(subscription().id, resourceGroup().id, string(i)), 0, 6)}', 24))
      sku: item.sku
      kind: 'StorageV2'
      subnetId: subnetId
      tags: union(tags, {
        environment: 'dev'
        region: location
      })
      diagnosticLogWorkspaceId: diagnosticLogWorkspaceId
      accessTier: 'Hot'
      publicNetworkAccess: 'Disabled'
      privateEndpointGroupNames: [
        'blob'
      ]
      allowedCopyScope: 'PrivateLink'
      isVersioningEnabled: true
      containerDeleteRetentionPolicy: true
      containerDeleteRetentionPolicyDays: 30
      containers: [
        for c in item.containers: {
          name: c
        }
      ]
    }
  }
]

output deployedStorageNames array = [for (item, i) in storageConfig: stg[i].outputs.name]
output deployedStorageIds array = [for (item, i) in storageConfig: stg[i].outputs.id]
