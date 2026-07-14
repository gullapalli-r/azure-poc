targetScope = 'resourceGroup'

@description('Geo-location of the resources.')
param location string = resourceGroup().location

var environmentName = 'prod01'

var name = 'platform'

var vnet = {
  name: 'SPOKE-PoC-EastUS-prod-01'
  resourceGroup: 'rg-poc-prod-eastus'
  privatelink: 'SNET-SPOKE-PoC-EastUS-prod-01-PrivateLink'
}

var genericTag = {
  poc_env: 'prod'
}

module data1 'br:bicepiacregistry.azurecr.io/bicep/stamps/platform-services:0.1.0' = {
  name: '${deployment().name}-DATA01'
  params: {
    location: location
    name: name
    tags: genericTag
    environmentName: environmentName
    vnet_privateLinkSubnet: vnet.privatelink
    vnet_resourceGroup: vnet.resourceGroup
    vnet_name: vnet.name

    enableLogWorkspace: true
    enableStorage: true
    enableContainerRegistry: true

        storage_items: [
      {
        shortName: 'logs'
        hierarchicalNamespaceEnabled: false
        allowedCopyScope: 'PrivateLink'
        sftpEnabled: false
        accessTier: 'Cool'
        containerDeleteRetentionPolicy: true
        allowContainerPermanentDelete: true
        containerDeleteRetentionPolicyDays: 30
        isVersioningEnabled: true
        deleteRetentionPolicyDays: 2
        fileShares: [
          {
            name: 'filesharetest1'
          }
          {
            name: 'filesharetest2'
          }
        ]
        containers: [
          {
            name: 'testcontainer1'
          }
          {
            name: 'testcontainer2'
          }
        ]
        tags: genericTag
      }
      {
        shortName: 'data'
        accessTier: 'Hot'
        hierarchicalNamespaceEnabled: true
        allowedCopyScope: 'PrivateLink'
        sftpEnabled: true
        containerDeleteRetentionPolicy: true
        allowContainerPermanentDelete: true
        containerDeleteRetentionPolicyDays: 30
        isVersioningEnabled: true
        deleteRetentionPolicyDays: 2
        fileShares: [
          {
            name: 'filesharetest1'
          }
          {
            name: 'filesharetest2'
          }
        ]
        containers: [
          {
            name: 'testcontainer1'
          }
          {
            name: 'testcontainer2'
          }
        ]
        tags: genericTag
      }
    ]

    containerRegistry_items: [
      {
        shortName: 'acr01'
        skuName: 'Premium'
        adminUserEnabled: false
        quarantinePolicyStatusEnabled: true
        retentionPolicyStatusEnabled: true
        retentionPolicyDays: 30
        exportPolicyStatusEnabled: false
        softDeletePolicyStatusEnabled: true
        softDeletePolicyDays: 30
        trustedServicesBypassEnabled: true
        zoneRedundancyEnabled: false
        anonymousPullEnabled: false
        tags: genericTag
      }
    ]
  }
}
