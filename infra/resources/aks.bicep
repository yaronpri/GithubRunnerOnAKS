@description('Azure region of the deployment')
param location string = resourceGroup().location

@description('AKS resource name')
param clusterName string

@description('AKS dns prefix')
param clusterDNSPrefix string

@description('Admin user name for AKS node')
param adminusername string

@description('User Managed Identity Name')
param managedidname string


@description('AKS node ssh public key')
@secure()
param sshPubKey string

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' existing = {
  name: managedidname
}

resource akscluster 'Microsoft.ContainerService/managedClusters@2022-05-02-preview' = {
  name: clusterName
  location: location
  identity: {
    type:'UserAssigned' 
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  properties: {
    dnsPrefix: clusterDNSPrefix
    aadProfile: {
      managed: true
      enableAzureRBAC: true
      tenantID: subscription().tenantId
    }
    agentPoolProfiles: [
      {
        name: 'agentpool'
        osDiskSizeGB: 30
        count: 1
        vmSize: 'Standard_DS2_v2'
        osType: 'Linux'
        mode: 'System'
      }
      {
        name: 'simulator'
        count: 1
        vmSize: 'Standard_B4ms'
        osType: 'Linux'
        mode: 'User'
        nodeLabels:{
          type: 'application'
        }
      }      
    ]
    linuxProfile: {
      adminUsername: adminusername
      ssh: {
        publicKeys: [
          {
            keyData: sshPubKey
          }
        ]
      }
    }    
  }
}

output aksclusterfqdn string = akscluster.properties.fqdn
output aksresourceid string = akscluster.id
output aksresourcename string = akscluster.name
