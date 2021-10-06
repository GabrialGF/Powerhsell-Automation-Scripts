#Created by Nick Brizzolara
#O365 Security Best Practices - Policy and Rule creation

#Connect to Exchange Online
Connect-ExchangeOnline

#Variable declaration
$domains = "popcornopolis.com, Popcornopolis.onmicrosoft.com, Popcornopolis.mail.onmicrosoft.com"
$RedirectEmail = "admin@popcornopolis.com"

#Created new antiphish policy with all recommended settings per MSFT
New-AntiPhishPolicy -Name "M365 AntiPhish Best Practice" -AdminDisplayName "M365 Best Practice Policy - Global" -ImpersonationProtectionState Manual -EnableTargetedUserProtection $true -EnableMailboxIntelligenceProtection $true -EnableTargetedDomainsProtection $true -EnableOrganizationDomainsProtection $true -EnableMailboxIntelligence $true -EnableFirstContactSafetyTips $true -EnableSimilarUsersSafetyTips $true -EnableSimilarDomainsSafetyTips $true -EnableUnusualCharactersSafetyTips $true -TargetedUserProtectionAction Quarantine -MailboxIntelligenceProtectionAction MoveToJmf -TargetedDomainProtectionAction Quarantine -AuthenticationFailAction MoveToJmf -EnableSpoofIntelligence $true -EnableViaTag $true -EnableUnauthenticatedSender $true
#Create AntiPhish rule to apply a policy to, also specify targeted domains or users
New-AntiPhishRule -Name "M365 AntiPhish Best Practice Default Rules" -AntiPhishPolicy "M365 AntiPhish Best Practice" -RecipientDomainIs $domains

#Create New AntiSpam inbound policy
New-HostedContentFilterPolicy -Name "M365 AntiSpam Inbound Best Practice Policy" -BulkThreshold 6 -MarkAsSpamBulkMail On -EnableLanguageBlockList $false -EnableRegionBlockList $false -SpamAction MoveToJmf -HighConfidenceSpamAction Quarantine -PhishSpamAction Quarantine -HighConfidencePhishAction Quarantine -BulkSpamAction MoveToJmf -QuarantineRetentionPeriod 30 -InlineSafetyTipsEnabled $True -PhishZapEnabled $true -SpamZapEnabled $True -EnableEndUserSpamNotifications $True -EndUserSpamNotificationLimit 3
#Create new AntiSpam inbound Rule and apply policy to it
New-HostedContentFilterRule -Name "M365 AntiSpam Best Practice Inbound Rule" -HostedContentFilterPolicy "M365 AntiSpam Inbound Best Practice Policy" -RecipientDomainIs $domains

#Create new AntiSpam outbound policy
New-HostedOutboundSpamFilterPolicy -Name "M365 AntiSpam Best Practice Outbound Policy" -RecipientLimitExternalPerHour 500 -RecipientLimitInternalPerHour 1000 -RecipientLimitPerDay 1000 -ActionWhenThresholdReached BlockUser -AutoForwardingMode Automatic -BccSuspiciousOutboundMail $false -NotifyOutboundSpam $false
#Create new AntiSpam outbound rule and apply policy to it
New-HostedOutboundSpamFilterRule -Name "M365 AntiSpam Best Practice Outbound Rule" -HostedOutboundSpamFilterPolicy "M365 AntiSpam Best Practice Outbound Policy" -SenderDomainIs $domains

#Create new AntiMalware Policy
New-MalwareFilterPolicy -Name "M365 AntiMalware Best Practice Policy" -EnableFileFilter $True -ZapEnabled $true -Action DeleteMessage -EnableInternalSenderAdminNotifications $false -EnableExternalSenderAdminNotifications $false -CustomInternalSubject $null -CustomInternalBody $null -CustomExternalSubject $null -CustomExternalBody $null
#Create new AntiMalware Rule and apply policy to it
New-MalwareFilterRule -Name "M365 AntiMalware Best Practice Rule" -MalwareFilterPolicy "M365 AntiMalware Best Practice Policy" -RecipientDomainIs $domains

#Turn on Safe Attachments
Set-AtpPolicyForO365 -EnableATPForSPOTeamsODB $true -EnableSafeDocs $true
#Create new Safe Attachments policy
New-SafeAttachmentPolicy -Name "M365 Safe Attachments Best Practice Policy" -Enable $true -Action Block -Redirect $true -RedirectAddress $RedirectEmail -ActionOnError $true
#Create new Safe Attachments rule and apply policy to it
New-SafeAttachmentRule -Name "M365 Safe Attachments Best Practice Rule" -SafeAttachmentPolicy "M365 Safe Attachments Best Practice Policy" -RecipientDomainIs $domains

#Set Safe Link global settings
Set-AtpPolicyForO365 -EnableSafeLinksForO365Clients $true -TrackClicks $true -AllowClickThrough $false
#Create new Safe Links policy
New-SafeLinksPolicy -Name "M365 Safe Links Best Practice Policy" -IsEnabled $true -EnableSafeLinksForTeams $true -ScanUrls $true -DeliverMessageAfterScan $true -EnableForInternalSenders $true -DoNotTrackUserClicks $false -DoNotAllowClickThrough $true -EnableOrganizationBranding $false 
#Create new Safe Links rule and apply policy to it
New-SafeLinksRule -Name "M365 Safe Links Best Practice Rule" -SafeLinksPolicy "M365 Safe Links Best Practice Policy" -RecipientDomainIs $domains
