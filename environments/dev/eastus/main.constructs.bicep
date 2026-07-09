@description('Deployment Location')
param location string = resourceGroup().location

@description('Name of Storage Account. Must be unique within Azure.')
@minLength(3)
@maxLength(24)
param stgname string
param devvnetname string

@description('Name of the resource group of the vnet')
param vnetResourceGroupName string

@description('Name of the VNET')
param vnetName string

@description('Name of the subnet to host the private links')
param vnetSubnetName string

@description('Gets or sets a list of key value pairs that describe the resource. These tags can be used for viewing and grouping this resource (across resource groups). A maximum of 15 tags can be provided for a resource. Each tag must have a key with a length no greater than 128 characters and a value with a length no greater than 256 characters.')
param tags object = {}

@description('Name of the law id.')
param diagnosticLogWorkspaceId string

var subnetId = resourceId(vnetResourceGroupName, 'Microsoft.Network/virtualNetworks/subnets', vnetName, vnetSubnetName)

module storage_no_hns 'br:bicepiacregistry.azurecr.io/bicep/constructs/storage-account:0.5.0' = {
  name: '${deployment().name}-NoHNS'
  params: {
    fileShares: [
      {
        name: 'testshare123'
        shareQuota: 5
      }
      {
        name: 'testsharetesting'
      }
    ]

    location: location
    name: name
    tags: tags
    subnetId: subnetId
    accessTier: 'Hot'
    sku: 'Standard_LRS'
    diagnosticLogWorkspaceId: diagnosticLogWorkspaceId
    containerDeleteRetentionPolicy: false
    isVersioningEnabled: true
    privateEndpointGroupNames: [
      'blob'
    ]
    containers: [
      {
        name: 'testcontainer1'
      }
      {
        name: 'testcontainer2'
      }
    ]
    managementPolicyRules: [
      {
        enabled: true
        name: 'Delete-Blob'
        type: 'Lifecycle'
        definition: {
          actions: {
            baseBlob: {
              delete: {
                daysAfterModificationGreaterThan: 30
              }
            }
          }
          filters: {
            blobTypes: [
              'blockBlob'
            ]
            prefixMatch: [
              'testcontainer1/'
            ]
          }
        }
      }
      {
        enabled: true
        name: 'version-Blob'
        type: 'Lifecycle'
        definition: {
          actions: {
            version: {
              delete: {
                daysAfterCreationGreaterThan: 7
              }
            }
          }
          filters: {
            blobTypes: [
              'blockBlob'
            ]
            prefixMatch: [
              'testcontainer2/'
            ]
          }
        }
      }
      {
        enabled: true
        name: 'cool-Blob'
        type: 'Lifecycle'
        definition: {
          actions: {
            baseBlob: {
              tierToCool: {
                daysAfterCreationGreaterThan: 30
              }
            }
          }
          filters: {
            blobTypes: [
              'blockBlob'
            ]
            prefixMatch: [
              'testcontainer2/'
            ]
          }
        }
      }
    ]
  }
}


module vnetDeployment '../main.bicep' = [
  for iteration in ['init', 'idem']: {
    scope: resourceGroup
    name: '${uniqueString(deployment().name, resourceLocation)}-test-${iteration}'
    params: {
      name: vNetName
      addressPrefixes: [
        addressPrefix
      ]
      dnsServers: [
        '10.0.1.4'
        '10.0.1.5'
      ]
      networkSecurityGroups: [
        {
          name: 'SNET-IaC-EastUS-Test-01-PrivateLink-NSG' //SPOKE-IaC-EastUS-Test-01
          securityRules: [] // add rules as needed
        }
        {
          name: 'SNET-IaC-EastUS-Test-01-AppsVM-NSG' //SPOKE-IaC-EastUS-Test-01
          securityRules: []
        }
      ]
      routeTables: [
        {
          name: 'SNET-IaC-EastUS-Test-01-PrivateLink-Route'
          routes: [] // add routes as needed
        }
        {
          name: 'SNET-IaC-EastUS-Test-01-AppsVM-Route'
          routes: []
        }
      ]
      subnets: [
        {
          addressPrefix: cidrSubnet(addressPrefix, 27, 0)
          name: 'SNET-IaC-EastUS-Test-01-PrivateLink'
          networkSecurityGroupName: 'SNET-IaC-EastUS-Test-01-PrivateLink-NSG'
          routeTableName: 'SNET-IaC-EastUS-Test-01-PrivateLink-Route'
        }
        {
          addressPrefix: cidrSubnet(addressPrefix, 27, 1)
          name: 'SNET-IaC-EastUS-Test-01-AppsVM'
          networkSecurityGroupName: 'SNET-IaC-EastUS-Test-01-AppsVM-NSG'
          routeTableName: 'SNET-IaC-EastUS-Test-01-AppsVM-Route'
        }
      ]
      peerings: [
        {
          name: 'PN_SPOKE-IaC-EastUS-Test-01-Spoke'
          remoteVirtualNetworkResourceId: '/subscriptions/4c324251-b16a-4681-b57e-19eea5661e88/resourceGroups/rg-hub-eastus/providers/Microsoft.Network/virtualNetworks/HUB-USEast'
          allowVirtualNetworkAccess: true
          allowForwardedTraffic: false
          allowGatewayTransit: false
          useRemoteGateways: false
          doNotVerifyRemoteGateways: false
          enableOnlyIPv6Peering: false
        }
      ]
    }
  }
]
