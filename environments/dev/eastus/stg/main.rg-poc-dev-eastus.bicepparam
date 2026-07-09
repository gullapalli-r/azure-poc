using './main.bicep'

param environmentType = 'dev'
param location = 'eastus'
param subnetId = '/subscriptions/4c324251-b16a-4681-b57e-19eea5661e88/resourceGroups/rg-poc-dev-eastus/providers/Microsoft.Network/virtualNetworks/SPOKE-PoC-EastUS-dev-01/subnets/SNET-SPOKE-PoC-EastUS-dev-01-PrivateLink'
param diagnosticLogWorkspaceId = ''
param tags = {
  environment: 'dev'
  region: 'eastus'
  workload: 'poc'
}
