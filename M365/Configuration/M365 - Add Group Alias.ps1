<# M365 - Add group Aliases

Authors:
Robert Wadowski

Tested to work with Powershell 5.1 and 7.1

Requirements:
* Powershell 5.1 or newer or 7.1 or newer
* EXO V2 Module

Latest Version or to report bugs, issue, or feature requests, please go to: https://github.com/GabrialGF/Powerhsell-Automation-Scripts.git
#>

Write-Host "Connecting to exchange Online"
Connect-ExchangeOnline

#Get list of unified groups and Distribution Lists
Write-Host "Building CSVs"
Get-UnifiedGroup -ResultSize Unlimited | Select-Object Name,DisplayName,PrimarySmtpAddress, @{Name="Aliases";Expression={($_.EmailAddresses | Where-Object {$_ -clike "smtp:*"}) -join '","' }} | Sort-Object DisplayName | Export-CSV "C:\temp\List_M365_Groups.csv" -NoTypeInformation -Encoding UTF8
Get-DistributionGroup -ResultSize Unlimited | Select-Object Name,DisplayName,PrimarySmtpAddress,@{Name="Aliases";Expression={($_.EmailAddresses | Where-Object {$_ -clike "smtp:*"}) -join '","' }} | Sort-Object DisplayName | Export-CSV "C:\temp\List_M365_Distibution_Groups.csv" -NoTypeInformation -Encoding UTF8

#Loop to added new alias
#Import Unified Group CSV
Write-Host "Importing and Processing Unified Groups" -BackgroundColor DarkGreen
Write-Host 'It is safe to ignore any "There is no Primary SMTP Address" errors you may see' -BackgroundColor DarkGreen
Start-Sleep -Seconds 2

$File = Import-CSV -Path 'C:\temp\List_M365_Groups.csv'

#ForEach loop that splits the proxy addresses into multiple lines and adds them to their respective user accounts
$File | ForEach-Object { 

    $PA = $_.PrimarySmtpAddress
    $ReferenceNumber = $PA.Indexof("@")
    $Name = $PA.Substring(0,$ReferenceNumber)
    $NewPrimary = $Name + '@lazerlogistics.com'
    $EmailAlias = $_.Aliases
    $NewEmailAlias = '"' + $EmailAlias + '","' + 'smtp:' + $PA + '","' + 'SMTP:' + $NewPrimary + '"'


    $NewPrimary
    #$EmailAlias
    #$NewEmailAlias

    Set-UnifiedGroup -Identity $_.Name -PrimarySmtpAddress $NewPrimary
    Set-UnifiedGroup -Identity $_.Name -EmailAddresses $NewEmailAlias

}
$File = $null
Write-Host "Importing and Processing Distribution Groups" -BackgroundColor DarkGreen
Write-Host "Importing and Processing Unified Groups" -BackgroundColor DarkGreen
Write-Host 'It is safe to ignore any "There is no Primary SMTP Address" errors you may see' -BackgroundColor DarkGreen
Start-Sleep -Seconds 2
#Import Distribution group CSV
$File = Import-CSV -Path 'C:\temp\List_M365_Distibution_Groups.csv'

#ForEach loop that splits the proxy addresses into multiple lines and adds them to their respective user accounts
$File | ForEach-Object { 

    $PA = $_.PrimarySmtpAddress
    $ReferenceNumber = $PA.Indexof("@")
    $Name = $PA.Substring(0,$ReferenceNumber)
    $NewPrimary = $Name + '@lazerlogistics.com'
    $EmailAlias = $_.Aliases
    $NewEmailAlias = '"' + $EmailAlias + '","' + 'smtp:' + $PA + '","' + 'SMTP:' + $NewPrimary + '"'


    $NewPrimary
    #$EmailAlias
    #$NewEmailAlias

    Set-DistributionGroup -Identity $_.Name -PrimarySmtpAddress $NewPrimary
    Set-DistributionGroup -Identity $_.Name -EmailAddresses $NewEmailAlias

}