<# O365 Security Best Practices - Policy and Rule creation

Authors:
Nick Brizzolara
Robert Wadowski

Tested to work with Powershell 5.1 and 7.1

Requirements:
* Powershell 5.1 or newer or 7.1 or newer
* EXO V2 Module

Latest Version or to report bugs, issue, or feature requests, please go to: https://github.com/GabrialGF/Powerhsell-Automation-Scripts.git
#>

#Start logging of script
if (-not (Test-Path  'C:\Temp\PowerShell Script Logs')){
    New-Item -ItemType Directory -Force -Path 'C:\Temp\PowerShell Script Logs'
}
Stop-Transcript -erroraction 'silentlycontinue'
$LogPath = "C:\Temp\PowerShell Script Logs\ M365 SecBP $(get-date -f 'yyyy-MM-dd HH:mm').log"  
Start-Transcript -Path $LogPath

Write-Host "Logging to file " $LogPath
Start-Sleep -s 5

#Connect to Exchange Online
try{
    Connect-ExchangeOnline
} Catch [System.Management.Automation.CommandNotFoundException] {
    Write-Host -ForegroundColor Red -BackgroundColor Black "An Error Has Occured:"
    Write-Host $_
    Write-Host""
    Write-Host -ForegroundColor Red -BackgroundColor Black "Please make sure to have the EXO V2 module installed. This can be downlaoded at:"
    Write-Host -ForegroundColor Red -BackgroundColor Black "https://www.powershellgallery.com/packages/ExchangeOnlineManagement/"
    Exit
} Catch [System.AggregateException]{
    Write-Host -ForegroundColor Red -BackgroundColor Black "You have exited the login window or the window expired. Please rerun the script again"
    Exit
}
#Domains to have policies applied agaianst
Do{
    $domains = $null
    $answer = $null
    Clear-Host

    Write-Host '============DOMAINS============'
    Write-Host 'Press "1" for All Domains'
    Write-Host 'Press "2" for All Authoratative Domains'
    Write-Host 'Press "3" for Manual Entry'
    $answer = Read-Host "Please Make Your Selection"
}until ($answer -match "[123]") 

If ($answer -eq 1) {
    $domains = Get-AcceptedDomain |  select -ExpandProperty domainname
    Write-Host 'The following domains will have the Security policies Applied:'
    Write-Host $domains
    Write-Host ""
    Read-Host "Press any key to continue"
}

If ($answer -eq 2) {
    $domains = Get-AcceptedDomain | Where{$_.Default -eq 'True'} | select -ExpandProperty domainname
    Write-Host 'The following domains will have the Security policies Applied:'
    Write-Host $domains
    Write-Host ""
    Read-Host "Press any key to continue"
}


If ($answer -eq 3){    
    Do{
        $answer=$null
        $domains=Read-Host -Prompt 'Please list all domains that you need to apply this policy to seperating them with a ","'
        Write-Host "The following Domains will have policies applied to them: " $domains
        Do{
            Write-Host ""
            $answer = Read-Host -Prompt "Are the Domains listed above correct? [Y/N]"
            If ($answer -notmatch "[YyNn]" ) {Write-Host -ForegroundColor Red -BackgroundColor Black 'Please type "Y" or "N"'}
        }while ($answer -notmatch "[YyNn]")
    }while ($answer -ne "Y")
}

#Begin Applying Policies
#$steps = ([System.Management.Automation.PsParser]::Tokenize((Get-Content "$PSScriptRoot\$($MyInvocation.MyCommand.Name)"), [ref]$null) | Where-Object { $_.Type -eq 'Command' -and $_.Content -eq 'Write-Progress' }).Count
$steps = 14
$stepCounter = 0

#Created new antiphish policy with all recommended settings per MSFT
Write-Progress -Activity 'Applying Policies' -Status 'Creating AntiPhish Policy' -PercentComplete ((($stepCounter++) / $steps) * 100)
New-AntiPhishPolicy -Name "M365 AntiPhish Best Practice" -AdminDisplayName "M365 Best Practice Policy - Global" -ImpersonationProtectionState Manual -EnableTargetedUserProtection $true -EnableMailboxIntelligenceProtection $true -EnableTargetedDomainsProtection $true -EnableOrganizationDomainsProtection $true -EnableMailboxIntelligence $true -EnableFirstContactSafetyTips $true -EnableSimilarUsersSafetyTips $true -EnableSimilarDomainsSafetyTips $true -EnableUnusualCharactersSafetyTips $true -TargetedUserProtectionAction Quarantine -MailboxIntelligenceProtectionAction MoveToJmf -TargetedDomainProtectionAction Quarantine -AuthenticationFailAction MoveToJmf -EnableSpoofIntelligence $true -EnableViaTag $true -EnableUnauthenticatedSender $true

#Create AntiPhish rule to apply a policy to, also specify targeted domains or users
Write-Progress -Activity 'Applying Policies' -Status 'Applying AntiPhish Policy' -PercentComplete ((($stepCounter++) / $steps) * 100)
New-AntiPhishRule -Name "M365 AntiPhish Best Practice Default Rules" -AntiPhishPolicy "M365 AntiPhish Best Practice" #-RecipientDomainIs $domains

#Create New AntiSpam inbound policy
Write-Progress -Activity 'Applying Policies' -Status 'Creating AntiSpam Inbound Policy' -PercentComplete ((($stepCounter++) / $steps) * 100)
New-HostedContentFilterPolicy -Name "M365 AntiSpam Inbound Best Practice Policy" -BulkThreshold 6 -MarkAsSpamBulkMail On -EnableLanguageBlockList $false -EnableRegionBlockList $false -SpamAction MoveToJmf -HighConfidenceSpamAction Quarantine -PhishSpamAction Quarantine -HighConfidencePhishAction Quarantine -BulkSpamAction MoveToJmf -QuarantineRetentionPeriod 30 -InlineSafetyTipsEnabled $True -PhishZapEnabled $true -SpamZapEnabled $True -EnableEndUserSpamNotifications $True -EndUserSpamNotificationLimit 3

#Create new AntiSpam inbound Rule and apply policy to it
Write-Progress -Activity 'Applying Policies' -Status 'Applying AntiSpam Inbound Policy' -PercentComplete ((($stepCounter++) / $steps) * 100)
New-HostedContentFilterRule -Name "M365 AntiSpam Best Practice Inbound Rule" -HostedContentFilterPolicy "M365 AntiSpam Inbound Best Practice Policy" -RecipientDomainIs $domains

#Create new AntiSpam outbound policy
Write-Progress -Activity 'Applying Policies' -Status 'Creating AntiSpam Outbound Policy' -PercentComplete ((($stepCounter++) / $steps) * 100)
New-HostedOutboundSpamFilterPolicy -Name "M365 AntiSpam Best Practice Outbound Policy" -RecipientLimitExternalPerHour 500 -RecipientLimitInternalPerHour 1000 -RecipientLimitPerDay 1000 -ActionWhenThresholdReached BlockUser -AutoForwardingMode Automatic -BccSuspiciousOutboundMail $false -NotifyOutboundSpam $false

#Create new AntiSpam outbound rule and apply policy to it
Write-Progress -Activity 'Applying Policies' -Status 'Applying AntiSpam Outbound Policy' -PercentComplete ((($stepCounter++) / $steps) * 100)
New-HostedOutboundSpamFilterRule -Name "M365 AntiSpam Best Practice Outbound Rule" -HostedOutboundSpamFilterPolicy "M365 AntiSpam Best Practice Outbound Policy" -SenderDomainIs $domains

#Create new AntiMalware Policy
Write-Progress -Activity 'Applying Policies' -Status 'Creating AntiMalware Policy' -PercentComplete ((($stepCounter++) / $steps) * 100)
New-MalwareFilterPolicy -Name "M365 AntiMalware Best Practice Policy" -EnableFileFilter $True -ZapEnabled $true -Action DeleteMessage -EnableInternalSenderAdminNotifications $false -EnableExternalSenderAdminNotifications $false -CustomInternalSubject $null -CustomInternalBody $null -CustomExternalSubject $null -CustomExternalBody $null

#Create new AntiMalware Rule and apply policy to it
Write-Progress -Activity 'Applying Policies' -Status 'Applying AntiMalware Policy' -PercentComplete ((($stepCounter++) / $steps) * 100)
New-MalwareFilterRule -Name "M365 AntiMalware Best Practice Rule" -MalwareFilterPolicy "M365 AntiMalware Best Practice Policy" -RecipientDomainIs $domains

#Turn on Safe Attachments
Write-Progress -Activity 'Applying Policies' -Status 'Enabling Safe Attachments' -PercentComplete ((($stepCounter++) / $steps) * 100)
Set-AtpPolicyForO365 -EnableATPForSPOTeamsODB $true -EnableSafeDocs $true

#Create new Safe Attachments policy
Write-Progress -Activity 'Applying Policies' -Status 'Creating Safe Attachments Policy' -PercentComplete ((($stepCounter++) / $steps) * 100)
New-SafeAttachmentPolicy -Name "M365 Safe Attachments Best Practice Policy" -Enable $true -Action Block -Redirect $false -ActionOnError $true

#Create new Safe Attachments rule and apply policy to it
Write-Progress -Activity 'Applying Policies' -Status 'Applying Safe Attachment Policy' -PercentComplete ((($stepCounter++) / $steps) * 100)
New-SafeAttachmentRule -Name "M365 Safe Attachments Best Practice Rule" -SafeAttachmentPolicy "M365 Safe Attachments Best Practice Policy" -RecipientDomainIs $domains

#Set Safe Link global settings
Write-Progress -Activity 'Applying Policies' -Status 'Enabling Safe Link' -PercentComplete ((($stepCounter++) / $steps) * 100)
Set-AtpPolicyForO365 -EnableSafeLinksForO365Clients $true -TrackClicks $true -AllowClickThrough $false

#Create new Safe Links policy
Write-Progress -Activity 'Applying Policies' -Status 'Creating Safe Link Policy' -PercentComplete ((($stepCounter++) / $steps) * 100)
New-SafeLinksPolicy -Name "M365 Safe Links Best Practice Policy" -IsEnabled $true -EnableSafeLinksForTeams $true -ScanUrls $true -DeliverMessageAfterScan $true -EnableForInternalSenders $true -DoNotTrackUserClicks $false -DoNotAllowClickThrough $true -EnableOrganizationBranding $false 

#Create new Safe Links rule and apply policy to it
Write-Progress -Activity 'Applying Policies' -Status 'Applying Safe Link Policy' -PercentComplete ((($stepCounter++) / $steps) * 100)
New-SafeLinksRule -Name "M365 Safe Links Best Practice Rule" -SafeLinksPolicy "M365 Safe Links Best Practice Policy" -RecipientDomainIs $domains

#Signout From O365
Disconnect-ExchangeOnline -Confirm:$false

#Stops Logging
Stop-Transcript -erroraction 'silentlycontinue'