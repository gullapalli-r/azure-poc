targetScope = 'resourceGroup'

@description('Deployment location for all VNets.')
param location string = resourceGroup().location

@description('Hub VNet resource ID for peering.')
param hubVnetResourceId string

@description('Base tags applied to all resources.')
param tags object = {}

// Dev-only rule set (logical parameter pattern can be extended later for prod).
var devNsgRules = [
  {
    name: 'allow-http-in'
    properties: {
      access: 'Allow'
      direction: 'Inbound'
      priority: 100
      protocol: 'Tcp'
      sourceAddressPrefix: '*'
      sourcePortRange: '*'
      destinationAddressPrefix: '*'
      destinationPortRange: '80'
      description: 'Allow HTTP inbound'
    }
  }
]

// Configuration set pattern for dev: two VNets.
var devVnetConfig = [
  {
    name: 'SPOKE-PoC-EastUS-dev-01'
    addressPrefixes: [
      '10.0.8.0/23'
    ]
    appSubnetPrefix: '10.0.8.0/24'
    privateLinkSubnetPrefix: '10.0.9.0/24'
  }
  {
    name: 'SPOKE-PoC-EastUS-dev-02'
    addressPrefixes: [
      '10.0.10.0/23'
    ]
    appSubnetPrefix: '10.0.10.0/24'
    privateLinkSubnetPrefix: '10.0.11.0/24'
  }
]

module vnets '../../../../../azure-iac/modules/constructs/virtual-network/main.bicep' = [
  for (vnet, i) in devVnetConfig: {
    name: 'vnet-dev-${i}'
    params: {
      name: vnet.name
      location: location
      addressPrefixes: vnet.addressPrefixes
      tags: union(tags, {
        environment: 'dev'
        region: location
      })
      networkSecurityGroups: [
        {
          name: 'nsg-${vnet.name}-app'
          securityRules: devNsgRules
        }
      ]
      routeTables: [
        {
          name: 'rt-${vnet.name}-app'
          disableBgpRoutePropagation: false
          routes: []
        }
      ]
      subnets: [
        {
          name: 'SNET-${vnet.name}-App'
          addressPrefix: vnet.appSubnetPrefix
          networkSecurityGroupName: 'nsg-${vnet.name}-app'
          routeTableName: 'rt-${vnet.name}-app'
          serviceEndpoints: [
            'Microsoft.Storage'
          ]
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
        {
          name: 'SNET-${vnet.name}-PrivateLink'
          addressPrefix: vnet.privateLinkSubnetPrefix
          networkSecurityGroupName: 'nsg-${vnet.name}-app'
          routeTableName: 'rt-${vnet.name}-app'
          serviceEndpoints: [
            'Microsoft.Storage'
          ]
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      ]
      peerings: [
        {
          name: 'peer-${vnet.name}-to-hub'
          remoteVirtualNetworkResourceId: hubVnetResourceId
          allowVirtualNetworkAccess: true
          allowForwardedTraffic: true
          allowGatewayTransit: false
          useRemoteGateways: false
          doNotVerifyRemoteGateways: true
          enableOnlyIPv6Peering: false
        }
      ]
    }
  }
]

output deployedVnetNames array = [for (v, i) in devVnetConfig: vnets[i].outputs.name]
output deployedVnetIds array = [for (v, i) in devVnetConfig: vnets[i].outputs.resourceId]
