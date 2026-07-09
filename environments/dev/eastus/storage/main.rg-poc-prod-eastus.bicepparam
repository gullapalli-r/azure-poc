using './main.bicep'

param environmentType = 'prod'
param location = 'eastus'
param subnetId = '/subscriptions/4c324251-b16a-4681-b57e-19eea5661e88/resourceGroups/rg-poc-prod-eastus/providers/Microsoft.Network/virtualNetworks/SPOKE-PoC-EastUS-prod-01/subnets/SNET-SPOKE-PoC-EastUS-prod-01-PrivateLink'
param diagnosticLogWorkspaceId = ''
param tags = {
  environment: 'prod'
  region: 'eastus'
  workload: 'poc'
}
