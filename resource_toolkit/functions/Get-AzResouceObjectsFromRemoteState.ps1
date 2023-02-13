function Get-AzResouceObjectsFromRemoteState ($StackPath)
{
    #region functions
        #region helper function to retrieve backend config from stack
            function Convertfrom-SynxTfBackendConfig
            {
                $BackendConfig = New-Object -TypeName PsObject
                foreach($line in [System.IO.File]::ReadLines("$StackPath/backend.config"))
                {
                    $Split = $line.Split(' = ')
                    $BackendConfig | Add-Member -MemberType NoteProperty -Name $Split[0].Trim().Trim('"') -Value $Split[1].Trim().Trim('"')
                }
                return $BackendConfig
            }
        #endregion
    #endregion
    #region Return AzResource objects listed in remote state
        #region get the backend config
            $BackendConfig = Convertfrom-SynxTfBackendConfig
        #endregion
        #region authenticate to Azure
            $SecretSecure = $env:ARM_CLIENT_SECRET | ConvertTo-SecureString -AsPlainText -Force
            $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $env:ARM_CLIENT_ID, $SecretSecure
            $AzAccount =  Connect-AzAccount -ServicePrincipal -Credential $Credential -TenantId $env:ARM_TENANT_ID -WarningAction SilentlyContinue
        #endregion

        #region select Azure subscription that contains the TF state file
            $AzSubscriptions = Get-AzSubscription | Where-Object {$_.State -ieq 'Enabled'}
            $AzSubsriptionSelect = $AzSubscriptions | Where-Object {$_.Id -eq $BackendConfig.subscription_id} | Select-AzSubscription
        #endregion

        #region Get remote TF state file
            #Get Az Storage Account keys and filter to key 1
            $AzStorageAccountKey = Get-AzStorageAccountKey -StorageAccountName $BackendConfig.storage_account_name -ResourceGroupName $BackendConfig.resource_group_name | Where-Object {$_.KeyName -eq 'key1'}
            $StorageAccountKey = $AzStorageAccountKey.Value

            #Get storage context then then Az blob container info
            $AzStorageContext = New-AzStorageContext -StorageAccountName $BackendConfig.storage_account_name -StorageAccountKey $StorageAccountKey 
            $AzStorageContainerTfState = $AzStorageContext | Get-AzStorageContainer | Where-Object {$_.Name -eq $BackendConfig.container_name}
           
            #Copy the statefile from the blob to the stackpath
            $StateFileCopyResult= $AzStorageContainerTfState | Get-AzStorageBlobContent -Blob $BackendConfig.key -Destination $StackPath
        #endregion

        #region read the state file
            $TfState = Get-Content "$StackPath\$($BackendConfig.key)" | ConvertFrom-Json
        #endregion

        #region build a workable list of resource Ids (exclude data calls, RGs and other problematic resources)
            $ResourceIds = @()
            $TfState.resources | ForEach-Object `
            {
                if (($_.type -ine 'azurerm_resource_group') `
                -and ($_.type -ine 'azurerm_subscription') `
                -and ($_.type -ine 'azurerm_key_vault_secret') `
                -and ($_.type -ine 'azurerm_key_vault_access_policy') `
                -and ($_.mode -ine 'data'))
                {
                    $ResourceIds += $_.instances.attributes.id.TrimStart('/')
                }
            }
        #endregion

        #region prepare ResourceObjects to send into the dark void of parallel processing to collect results
            $ResourceObjects = @()
            $ResourceIds | ForEach-Object `
            {
                $ThisRecord = @{
                    ThisId = $_
                }
                $ResourceObjects += $ThisRecord
            }
        #endregion

        #region Do parallel query for AzResource data and add result back to ResourceObject
            $ResourceObjects | ForEach-Object  -ThrottleLimit 25 -Parallel `
            {
                $WarningPreference = 'SilentlyContinue'
                $_ | Add-Member -MemberType NoteProperty -Name 'AzResource' -Value  (Get-AzResource -ResourceId $_.ThisId) -ErrorAction SilentlyContinue
            }
        #endregion
    #endregion
    if (Test-Path -Path "$StackPath\$($BackendConfig.key)") {Remove-Item "$StackPath\$($BackendConfig.key)"}
    return $ResourceObjects
}

