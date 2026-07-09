targetScope = 'resourceGroup'

@description('Deployment location for all VNets.')
param location string = resourceGroup().location

@description('Hub VNet resource ID for peering.')
param hubVnetResourceId string

@description('Base tags applied to all resources.')
param tags object = {}

// Prod rule set: common + stricter HTTPS.
var prodNsgRules = [
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
  {
    name: 'allow-https-in'
    properties: {
      access: 'Allow'
      direction: 'Inbound'
      priority: 110
      protocol: 'Tcp'
      sourceAddressPrefix: '*'
      sourcePortRange: '*'
      destinationAddressPrefix: '*'
      destinationPortRange: '443'
      description: 'Allow HTTPS inbound'
    }
  }
]

// Configuration set pattern for prod: two VNets with two subnets each.
var prodVnetConfig = [
  {
    name: 'SPOKE-PoC-EastUS-prod-01'
    addressPrefixes: [
      '10.30.0.0/16'
    ]
    appSubnetPrefix: '10.30.1.0/24'
    privateLinkSubnetPrefix: '10.30.2.0/24'
  }
  {
    name: 'SPOKE-PoC-EastUS-prod-02'
    addressPrefixes: [
      '10.31.0.0/16'
    ]
    appSubnetPrefix: '10.31.1.0/24'
    privateLinkSubnetPrefix: '10.31.2.0/24'
  }
]

module vnets '../../../../../azure-iac/modules/constructs/virtual-network/main.bicep' = [
  for (vnet, i) in prodVnetConfig: {
    name: 'vnet-prod-${i}'
    params: {
      name: vnet.name
      location: location
      addressPrefixes: vnet.addressPrefixes
      tags: union(tags, {
        environment: 'prod'
        region: location
      })
      networkSecurityGroups: [
        {
          name: 'nsg-${vnet.name}-app'
          securityRules: prodNsgRules
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

output deployedVnetNames array = [for (v, i) in prodVnetConfig: vnets[i].outputs.name]
output deployedVnetIds array = [for (v, i) in prodVnetConfig: vnets[i].outputs.resourceId]
