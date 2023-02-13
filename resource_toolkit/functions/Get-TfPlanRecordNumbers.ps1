function Get-TfPlanRecordNumbers ($TfPlanResourceChanges)
{
    $RecordNumber = 0
    $Results = @()
    $TfPlanResourceChanges | ForEach-Object `
    {
        $Results += New-Object -TypeName pscustomobject -Property @{
            RecordNumber = $RecordNumber
            Type = $_.type
            Name = $_.change.after.name

        }
        $RecordNumber += 1
    }
    return $Results
}