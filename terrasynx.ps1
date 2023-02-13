#<#
#region Environment
    $CurrentLocation = Get-Location
#endregion
#region functions
    #region Function to convert pester results to JUnitXML (required for gitlab) #todo

    #endregion
    #region function to retrieve backend config from stack
        function Convertfrom-SynxTfBackendConfig
        {
            $BackendConfig = New-Object -TypeName PsObject
            foreach($line in [System.IO.File]::ReadLines("$CurrentLocation/backend.config"))
            {
                $Split = $line.Split(' = ')
                $BackendConfig | Add-Member -MemberType NoteProperty -Name $Split[0].Trim().Trim('"') -Value $Split[1].Trim().Trim('"')
            }
            return $BackendConfig
        }
    #endregion
    #region function to perform a TFPLAN and import it for use
        function Get-SynxTfPlanPsObject
        {
            if (!(Test-Path -Path ".\*.tf")) {throw 'repo does not contain any .tf files'}
            $null = Invoke-Expression -Command 'terraform plan -out="tfplan"'
            if (!(Test-Path "./tfplan")) {throw "No Terraform Plan was created - check validate and init"}
            $TfPlan = Invoke-Expression -Command 'terraform show -json "tfplan"' | ConvertFrom-Json
            Remove-Item -Path "./tfplan" -ErrorAction SilentlyContinue
            return $TfPlan
        }
    #endregion
#endregion


#region TF APPLY testing
    if ($TestStage -ieq 'apply')
    {  
        #region get the backend config
            $BackendConfig = Convertfrom-SynxTfBackendConfig
        #endregion
        #region authenticate to Azure
            Write-Output "Terrasynx> authenticating to Azure"
            $SecretSecure = $env:ARM_CLIENT_SECRET | ConvertTo-SecureString -AsPlainText -Force
            $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $env:ARM_CLIENT_ID, $SecretSecure
            $AzAccount =  Connect-AzAccount -ServicePrincipal -Credential $Credential -TenantId $env:ARM_TENANT_ID -WarningAction SilentlyContinue
            Write-Output $AzAccount
            #endregion

        #region select Azure subscription that contains the TF state file
            $AzSubscriptions = Get-AzSubscription | Where-Object {$_.State -ieq 'Enabled'}
            $AzSubsriptionSelect = $AzSubscriptions | Where-Object {$_.Id -eq $BackendConfig.subscription_id} | Select-AzSubscription
            Write-Output "Terrasynx> Selecting subscription for TF statefile"
            if ($AzSubsriptionSelect) {Write-Output $AzSubsriptionSelect}
            else {throw "Terrasynx> Could not Select-AzSubscription to configured statefile location"}
        #endregion

        #region Get remote TF state file
            #Get Az Storage Account keys and filter to key 1
            $AzStorageAccountKey = Get-AzStorageAccountKey -StorageAccountName $BackendConfig.storage_account_name -ResourceGroupName $BackendConfig.resource_group_name | Where-Object {$_.KeyName -eq 'key1'}
            $StorageAccountKey = $AzStorageAccountKey.Value
            $StorageAccountKeyLength = $StorageAccountKey.Length
            if ($StorageAccountKey) {Write-Output "Terrasynx> Retrieved storage account key 1 ending: .......$($StorageAccountKey.Substring(($StorageAccountKeyLength -10),10))"}
            else {throw "Terrasynx> Could not get storage account key"}

            #Get storage context then then Az blob container info
            $AzStorageContext = New-AzStorageContext -StorageAccountName $BackendConfig.storage_account_name -StorageAccountKey $StorageAccountKey 
            $AzStorageContainerTfState = $AzStorageContext | Get-AzStorageContainer | Where-Object {$_.Name -eq $BackendConfig.container_name}
            if ($AzStorageContext) {Write-Output "Terrasynx> Created storage account context for $($BackendConfig.storage_account_name)"}

            #Copy the statefile from the blob to the stackpath
            $StateFileCopyResult= $AzStorageContainerTfState | Get-AzStorageBlobContent -Blob $BackendConfig.key -Destination .
            if ($StateFileCopyResult) {Write-Output "Terrasynx> Downloaded TF State file"; $StateFileCopyResult | Select-Object Name,BlobType,Length,LastModified}
            elseif (!(Test-Path -Path ".\$($BackendConfig.key)")) {throw "Terrasynx> Could not download state file $($BackendConfig.key)"}
        #endregion

        #region read the state file
            $TfState = Get-Content $BackendConfig.key | ConvertFrom-Json
            if ($TfState) {Write-Output "Terrasynx> Terraform statefile read and imported"}
            else {throw "Terrasynx> Could not import state file (JSON conversion error)"}
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
            write-output 'breakpoint' #!
        #endregion

        #region prepare test object to send into the dark void of parallel processing to collect results
            $ResourceObjects = @()
            $ResourceIds | ForEach-Object `
            {
                $ThisRecord = @{
                    ThisId = $_
                }
                $ResourceObjects += $ThisRecord
            }
            Write-Output 'breakpoint' #!
        #endregion

        #region Do parallel query for AzResource data and add result back to carrier
            $ResourceObjects | ForEach-Object  -ThrottleLimit 25 -Parallel `
            {
                Write-Output "Terrasynx> Processing $($_.ThisId)"
                $WarningPreference = 'SilentlyContinue'
                $_ | Add-Member -MemberType NoteProperty -Name 'AzResource' -Value  (Get-AzResource -ResourceId $_.ThisId) -ErrorAction SilentlyContinue
            }
            #! next line is to get object for reference - search here for object to map
            $ResourceObjects[0..10] | convertto-json -Depth 99 | Set-Content -Path ApplyResourceObjects.json -PassThru | Set-Clipboard
            Write-Output 'breakpoint #!'
        #endregion
#>        #region create TestObjects for each resource extracting the correct information from it.
        $TestObjects = @()    
        $ResourceObjects | ForEach-Object `
            {
                if ($_.AzResource.type -eq 'Microsoft.Network/virtualNetworks')
                {
                    $TestObjects += New-Object PSObject -Property @{
                        Id = $_.AzResource.Id
                        Type = $_.AzResource.Type
                        Location = $_.AzResource.Location
                        Name = $_.AzResource.Name
                    }
                }
            }
        Remove-Item $BackendConfig.key -Force
        #endregion
    }
#endregion
#region TF PLAN testing
    if ($TestStage -ieq 'plan')
    {
        #region get the TF Plan, filter to objects due to be create, deleted and recreated, or updated
            $ResourceObjects = (Get-SynxTfPlanPsObject).resource_changes | Where-Object {$_.change.actions -in 'delete, create','create','update'}
        #endregion
        #region create TestObjects for each resource extracting the correct information from it.
            $TestObjects = @()
            $ResourceObjects | ForEach-Object `
            {
                if ($_.Type -eq 'azurerm_virtual_network')
                {
                    $TestObjects += New-Object PSObject -Property @{
                        Id = $_.address
                        Type = $_.Type
                        Name = $_.change.after.name
                        Location = $_.change.after.location

                    }
                }
                if ($_.Type -eq 'azurerm_resource_group')
                {
                    $TestObjects += New-Object PSObject -Property @{
                        Id = $_.address
                        Type = $_.Type
                        Name = $_.change.after.name
                        Location = $_.change.after.location
                        Tags = $_.change.after.tags
                    }
                }
                if ($_.Type -eq 'azurerm_log_analytics_workspace')
                {
                    $TestObjects += New-Object PSObject -Property @{
                        Id = $_.address
                        Type = $_.Type
                        name = $_.change.after.name
                        location = $_.change.after.location
                        allow_resource_only_permissions = $_.change.after.allow_resource_only_permissions
                        cmk_for_query_forced = $_.change.after.cmk_for_query_forced
                        daily_quota_gb = $_.change.after.daily_quota_gb
                        internet_ingestion_enabled = $_.change.after.internet_ingestion_enabled
                        internet_query_enabled = $_.change.after.internet_query_enabled
                        resource_group_name = $_.change.after.resource_group_name
                        retention_in_days = $_.change.after.retention_in_days
                        sku = $_.change.after.sku
                        tags = $_.change.after.tags
                        timeouts = $_.change.after.timeouts
                    }
                }
                if ($_.Type -eq 'azurerm_key_vault')
                {
                    $TestObjects += New-Object PSObject -Property @{
                        Id = $_.address
                        Type = $_.Type
                        name = $_.change.after.name
                        location = $_.change.after.location
                        access_policy = $_.change.after.access_policy
                        contact = $_.change.after.contact
                        enabled_for_deployment = $_.change.after.enabled_for_deployment
                        enabled_for_disk_encryption = $_.change.after.enabled_for_disk_encryption
                        enabled_for_template_deployment = $_.change.after.enabled_for_template_deployment
                        enable_rbac_authorization = $_.change.after.enable_rbac_authorization
                        network_acls = $_.change.after.network_acls
                        public_network_access_enabled = $_.change.after.public_network_access_enabled
                        purge_protection_enabled = $_.change.after.purge_protection_enabled
                        resource_group_name = $_.change.after.resource_group_name
                        sku_name = $_.change.after.sku_name
                        soft_delete_retention_days = $_.change.after.soft_delete_retention_days
                        tags = $_.change.after.tags
                        tenant_id = $_.change.after.tenant_id
                        timeouts = $_.change.after.timeouts
                        vault_uri = $_.change.after.vault_uri
                    }
                }
            }
        #endregion
    }
#endregion


#region invoke pester, convert the results to JUnitXml format and then clean up
    Write-Output "Terrasynx> Invoking Pester tests to examine collected data"
    $Results = Invoke-Pester -PassThru
    Convert-PesterResultToJUnitXml -PesterResult $Results | Out-File -FilePath ./gitlab-terrasynxresult.xml -Encoding utf8
    
#endregion

