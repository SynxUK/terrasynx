#region Setup
    $ResourceTookitPath = 'C:\Users\hstuadry\PsProj\hl\azure-terrasynx-tests\resource_toolkit'
    $OutputPath = 'C:\Users\hstuadry\Desktop\ResourceRef'
    $StackPath = 'C:\Users\hstuadry\PsProj\hl\azure-tf-infra'
#endregion

#dotsource the required functions
. "$ResourceTookitPath\functions\Get-AzResouceObjectsFromRemoteState.ps1"
. "$ResourceTookitPath\functions\Get-AzResourceRecordNumbers.ps1"
. "$ResourceTookitPath\functions\Get-TfPlanObject.ps1"
. "$ResourceTookitPath\functions\Get-TfPlanRecordNumbers.ps1"
#endregion

#region Get the AzResource objects listed in remote TF state
    $AzResources = Get-AzResouceObjectsFromRemoteState -StackPath $StackPath
    $AzResources | ConvertTo-Json -Depth 99 | Set-Content "$OutputPath\AzResources.json" -Force
    $AzResourceNumbers = Get-AzResourceRecordNumbers -AzResourceRecords $AzResources
    $AzResourceNumbers | Format-Table | Out-String | set-content "$OutputPath\AzResourceNumbers.txt" -Force
#endregion


#region get the TF Plan, filter to objects due to be create, deleted and recreated, or updated
    $TfPlanResourceChanges = (Get-TfPlanObject -StackPath $StackPath).resource_changes | Where-Object {$_.change.actions -in 'delete, create','create','update'}
    $TfPlanResourceChanges | ConvertTo-Json -Depth 99 | Set-Content "$OutputPath\TFResources.json" -Force
    $TfPlanRecordNumbers = Get-TfPlanRecordNumbers -TfPlanResourceChanges $TfPlanResourceChanges
    $TfPlanRecordNumbers | Format-Table | Out-String | Set-Content "$OutputPath\TfResourceNumbers.txt"
#endregion
