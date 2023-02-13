function Get-TfPlanObject ($StackPath)
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
    #region perform a TFPLAN and import it for use
        $CurrentLocation = Get-Location
        Set-Location $StackPath
        $null = Invoke-Expression -Command "terraform plan -out=`"$StackPath\tfplan`""
        $TfPlan = Invoke-Expression -Command "terraform show -json `"$StackPath\tfplan`"" | ConvertFrom-Json
        Remove-Item -Path "$StackPath/tfplan" -ErrorAction SilentlyContinue
        Set-Location $CurrentLocation
    #endregion
    return $TfPlan
}