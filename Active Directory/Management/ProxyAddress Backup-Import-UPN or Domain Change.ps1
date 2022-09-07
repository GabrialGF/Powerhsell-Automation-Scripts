#Script used to generate CSV's of ADObjects that contains ProxyAddressses attribute and import them post exchange decom or to update Domain/UPN/Primary SMTP
#Feel Free to comment or uncomment sections as needed

Get-ADUser -Filter * -Properties proxyaddresses | Select-Object sAMAccountName, @{L = "ProxyAddresses"; E = { $_.ProxyAddresses -join ";"}} | Export-Csv -Path "C:\Temp\ProxyAddresses.csv" -NoTypeInformation

Get-ADGroup -filter 'groupcategory -eq "distribution"' -Properties proxyaddresses | Select-Object sAMAccountName, @{L = "ProxyAddresses"; E = { $_.ProxyAddresses -join ";"}} | Export-Csv -Path "C:\Temp\proxyaddresses-Groups.csv" -NoTypeInformation

Get-ADObject -LDAPFilter "objectClass=Contact" -Properties proxyaddresses | Select-Object objectGUID, name, @{L = "ProxyAddresses"; E = { $_.ProxyAddresses -join ";"}} | Export-Csv -Path "C:\Temp\proxyaddresses-contacts.csv" -NoTypeInformation


#Import ProxyAddresses CSV
$File = Import-CSV -Path "C:\Temp\proxyaddresses-test.csv"

#ForEach loop that splits the proxy addresses into multiple lines and adds them to their respective user accounts
$File | ForEach { 

#Variable needed to split proxyaddresses into multiple items
$pa = $_.proxyaddresses -split ';'
#Setting users Proxy Addresses
Write-Host "Setting" $_.samaccountname "proxyaddresses to" $pa
Set-ADUser -Identity $_.sAMAccountName -Replace @{Proxyaddresses=$pa}
#Adding new Primary SMTP
$pri= "SMTP:" + $_.sAMAccountName + "INSET DOMAIN HERE"
Write-Host "Setting" $_.samaccountname "Primary SMTP to" $pri
Set-ADUser -Identity $_.sAMAccountName -Add @{Proxyaddresses=$pri}

#Setting UPN to New SMTP
$address = $_.sAMAccountName + "INSERT DOMAIN HERE"
Write-Host "Setting" $_.samaccountname "UPN to" $address
Set-ADUser -Identity $_.sAMAccountName -UserPrincipalName $address

#Setting Mail Attribute to new SMTP
Write-Host "Setting" $_.samaccountname "Mail Attribute to" $address
Set-ADUser -Identity $_.sAMAccountName -EmailAddress $address
}

<#Import ProxyAddresses-Groups CSV
$GroupFile = Import-Csv -Path "C:\Temp\proxyaddresses-Groups.csv"

$GroupFile | ForEach { 

    #Variable needed to split proxyaddresses into multiple items
    $pa = $_.proxyaddresses -split ';'
    Write-Host "Setting" $_.samaccountname "proxyaddresses to" $pa
    Set-ADGroup -Identity $_.sAMAccountName -Add @{Proxyaddresses=$pa}
    
    }
#>
<#Import ProxyAddresses-Groups CSV
$ContactFile = Import-Csv -Path "C:\temp\proxyaddresses-Contacts.csv"

$ContactFile | ForEach { 

    #Variable needed to split proxyaddresses into multiple items
    $pa = $_.proxyaddresses -split ';'
    Write-Host "Setting" $_.objectguid "proxyaddresses to" $pa
    Set-ADObject -Identity $_.objectguid -Add @{Proxyaddresses=$pa}
    
    }
    #>