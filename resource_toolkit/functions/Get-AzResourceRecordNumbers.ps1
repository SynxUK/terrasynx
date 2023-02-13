function Get-AzResourceRecordNumbers ($AzResourceRecords)
{
    $RecordNumber = 0
    $Results = @()
    $AzResourceRecords.AzResource | ForEach-Object `
    {
        $Results += New-Object -TypeName pscustomobject -Property @{
            RecordNumber = $RecordNumber
            Type = $_.type
            Name = $_.Name

        }
        $RecordNumber += 1
    }
    return $Results
}