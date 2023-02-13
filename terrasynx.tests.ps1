

#region Do Pester tests
Describe "Region" {
    $TestObjects | ForEach-Object `
    {
        if ($_.Location -ne $null)
        {
            It "Region: $($_.Name)" {
                $_.Location | Should -BeIn @('uksouth','ukwest')
            }
        }
    }
}



