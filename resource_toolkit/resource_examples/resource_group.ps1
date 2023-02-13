# #! This file is not valid powershell.  It is names .ps1 to give it the best highlighting in code editors.
# # Object structure of a resource type in TF Plan and AzResource, mapping both into a Terrasynx testing object.
# # The objective is to create a common $TestObject(s) object from both so that one set of tests can be applied to each.


# $TfPlanResourceChanges[0].change.after | ConvertTo-Json -Depth 99 | Set-Clipboard
# {
#     'id': '/subscriptions/[id]/resourceGroups/[rg name]',
#     'location': 'uksouth',
#     'name': '[name]',
#     'tags': {
#         'TagName1': 'TagValue1',
#         'TagName2': 'TagValue2'
#     },
#     'timeouts': null
# }

# # JSON of AzResource Object
#     #! No AzResource is queried in this version - does not conform to the same standards as other objects


# # Terrasynx $TestObject(s) built from TF Plan resource record
# TfName = $_.address
# type = $_.Type
# location = $_.change.after.location
# name = $_.change.after.name

# # Terrasynx $TestObjects(s) built from AzResource resource record
#     #! No AzResource is queried in this version - does not conform to the same standards as other objects

