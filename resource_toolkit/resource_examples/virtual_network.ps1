# #! This file is not valid powershell.  It is names .ps1 to give it the best highlighting in code editors.
# # Object structure of a resource type in TF Plan and AzResource, mapping both into a Terrasynx testing object.
# # The objective is to create a common $TestObject(s) object from both so that one set of tests can be applied to each.


# # $TfPlanResourceChanges[65].change.after | ConvertTo-Json -Depth 99 | Set-Clipboard
# {
#     "address": "azurerm_virtual_network.[VNetName]",
#     "mode": "managed",
#     "type": "azurerm_virtual_network",
#     "name": "[VNetName]",
#     "provider_name": "registry.terraform.io/hashicorp/azurerm",
#     "change": {
#       "after": {
#         "address_space": [
#           "10.112.1.0/25"
#         ],
#         "bgp_community": "",
#         "ddos_protection_plan": [],
#         "dns_servers": [],
#         "edge_zone": "",
#         "flow_timeout_in_minutes": 0,
#         "guid": "[GUID]",
#         "id": "/subscriptions/[SubscriptionId GUID]/resourceGroups/[ResourceGroupName]/providers/Microsoft.Network/virtualNetworks/[VNetName]",
#         "location": "uksouth",
#         "name": "[VnetName]",
#         "resource_group_name": "[ResourceGroupName]",
#         "subnet": [
#           {
#             "address_prefix": "10.112.1.16/28",
#             "id": "/subscriptions/[SubscriptionId GUID]/resourceGroups/[ResourceGroupName]/providers/Microsoft.Network/virtualNetworks/[VNetName]/subnets/[SubnetName]",
#             "name": "[SubnetName]",
#             "security_group": "/subscriptions/[SubscriptionId GUID]/resourceGroups/[ResourceGroupName]/providers/Microsoft.Network/networkSecurityGroups/[NsgName]"
#           }
#         ],
#         "tags": {
#           "TagName1": "TagValue1",
#           "TagName2": "TagValue2"
#         },
#         "timeouts": null
#       }
#     }
#   }


# # $AzResources[65].AzResource | ConvertTo-Json -Depth 99 | Set-Clipboard
# {
#     "ResourceId": "/subscriptions/[SubscriptionId GUID]/resourceGroups/[ResourceGroupName]/providers/Microsoft.Network/virtualNetworks/[VNet Name]",
#     "Id": "/subscriptions/[SubscriptionId GUID]/resourceGroups/[ResourceGroupName]/providers/Microsoft.Network/virtualNetworks/[VnetName]",
#     "Identity": null,
#     "Kind": null,
#     "Location": "uksouth",
#     "ManagedBy": null,
#     "ResourceName": "[ResourceGroupName]",
#     "Name": "[VNetName]",
#     "ExtensionResourceName": null,
#     "ParentResource": null,
#     "Plan": null,
#     "Properties": {
#       "provisioningState": "Succeeded",
#       "resourceGuid": "[GUID]",
#       "addressSpace": {
#         "addressPrefixes": [
#           "10.112.1.0/25"
#         ]
#       },
#       "dhcpOptions": {
#         "dnsServers": []
#       },
#       "subnets": [
#         {
#           "name": "[SubnetName]",
#           "id": "/subscriptions/[SubscriptionID GUID]/resourceGroups/[ResourceGroupName]/providers/Microsoft.Network/virtualNetworks/[VNetName]/subnets/[SubnetName]",
#           "etag": "W/\"[GUID]\"",
#           "properties": {
#             "provisioningState": "Succeeded",
#             "addressPrefix": "10.112.1.16/28",
#             "networkSecurityGroup": {
#               "id": "/subscriptions/[SubscriptionId GUID]/resourceGroups/[ResourceGroupName]/providers/Microsoft.Network/networkSecurityGroups/[NSG Name]"
#             },
#             "ipConfigurations": [
#               {
#                 "id": "/subscriptions/[SubscriptioId GUID]/resourceGroups/[ResourceGroupName]/providers/Microsoft.Network/networkInterfaces/[NetworkInterfaceName]/ipConfigurations/privateEndpointIpConfig.[GUID]"
#               }
#             ]
#           },
#           "type": "Microsoft.Network/virtualNetworks/subnets"
#         },
#         {
#           "name": "snet-aznamingweb-uksouth-001",
#           "id": "/subscriptions/5dddeb30-a129-4d3d-9387-5e356517c80f/resourceGroups/rg-mgmtvnet-shared-001/providers/Microsoft.Network/virtualNetworks/vnet-mgmt-uksouth-001/subnets/snet-aznamingweb-uksouth-001",
#           "etag": "W/\"545238a7-00f0-42d8-9f27-3b684947e604\"",
#           "properties": {
#             "provisioningState": "Succeeded",
#             "addressPrefix": "10.112.1.0/28",
#             "networkSecurityGroup": {
#               "id": "/subscriptions/5dddeb30-a129-4d3d-9387-5e356517c80f/resourceGroups/rg-mgmtvnet-shared-001/providers/Microsoft.Network/networkSecurityGroups/nsg-aznamingweb-uksouth-001"
#             }
#           },
#           "type": "Microsoft.Network/virtualNetworks/subnets"
#         },
#         {
#           "name": "snet-keyvault-uksouth-001",
#           "id": "/subscriptions/5dddeb30-a129-4d3d-9387-5e356517c80f/resourceGroups/rg-mgmtvnet-shared-001/providers/Microsoft.Network/virtualNetworks/vnet-mgmt-uksouth-001/subnets/snet-keyvault-uksouth-001",
#           "etag": "W/\"545238a7-00f0-42d8-9f27-3b684947e604\"",
#           "properties": {
#             "provisioningState": "Succeeded",
#             "addressPrefix": "10.112.1.64/27",
#             "networkSecurityGroup": {
#               "id": "/subscriptions/5dddeb30-a129-4d3d-9387-5e356517c80f/resourceGroups/rg-mgmtvnet-shared-001/providers/Microsoft.Network/networkSecurityGroups/nsg-keyvault-uksouth-001"
#             },
#             "ipConfigurations": [
#               {
#                 "id": "/subscriptions/5dddeb30-a129-4d3d-9387-5e356517c80f/resourceGroups/rg-mgmtkv-shared-001/providers/Microsoft.Network/networkInterfaces/nic-keyvault-uksouth-001/ipConfigurations/privateEndpointIpConfig.64236072-0a19-408d-b9e5-ec29f5814760"
#               }
#             ]
#           },
#           "type": "Microsoft.Network/virtualNetworks/subnets"
#         }
#       ],
#       "virtualNetworkPeerings": []
#     },
#     "ResourceGroupName": "[ResourceGroupName]",
#     "Type": "Microsoft.Network/virtualNetworks",
#     "ResourceType": "Microsoft.Network/virtualNetworks",
#     "ExtensionResourceType": null,
#     "Sku": null,
#     "Tags": {
#       "TagName1": "TagValue1",
#       "TagName2": "TagValue2"
#     },
#     "TagsTable": "DO NOT USE",
#     "SubscriptionId": "[GUID]",
#     "CreatedTime": null,
#     "ChangedTime": null,
#     "ETag": null
#   }


#todo complete mapping
# Terrasynx $TestObject(s) built from TF Plan resource record
TfName = $_.address
TfType = $_.Type
Location = $_.change.after.location
Name = $_.change.after.name

# Terrasynx $TestObjects(s) built from AzResource resource record
TfName = $_.address
TfType = $_.Type
Location = $_.Location
Name = $_.Name
