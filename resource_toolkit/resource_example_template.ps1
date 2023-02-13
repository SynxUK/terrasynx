#! This file is not valid powershell.  It is names .ps1 to give it the best highlighting in code editors.
# Object structure of a resource type in TF Plan and AzResource, mapping both into a Terrasynx testing object.
# The objective is to create a common $TestObject(s) object from both so that one set of tests can be applied to each.


# $TfPlanResourceChanges[0].change.after | ConvertTo-Json -Depth 99 | Set-Clipboard

# JSON of AzResource Object


# Terrasynx $TestObject(s) built from TF Plan resource record
TfName = $_.address
type = $_.Type
location = $_.change.after.location
name = $_.change.after.name

# Terrasynx $TestObjects(s) built from AzResource resource record
TfName = $_.address
type = $_.Type

