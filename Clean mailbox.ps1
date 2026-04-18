#Connecting to modules
Connect-ExchangeOnline ;; Connect-IppSSession -EnableSearchOnlySession

#Check mailbox-only holds, follow this documentation for InPlaceHolds (if any) https://learn.microsoft.com/en-us/purview/edisc-hold-types-mailboxes#get-mailbox
Get-mailbox -identity user@contoso.com | FL *HOLD*,*elcprocessing*, *item*, *archive*

#Check retention holds, check locations and if it says All for Exchange, Teams or Groups, you  will have issues with Recoverable Items or even deleting mailbox
Get-RetentionCompliancePolicy -DistributionDetail | fl Name, guid, *location, *exception* 

#and based on findings, I will ask the customer to execute any of these commands:

#for Mailboxes
depending on the retentions, exclude the users by making these steps:
Set-Mailbox -Identity usuario@contoso.com -RemoveComplianceTagHoldApplied ;;
Set-Mailbox -Identity usuario@contoso.com -RemoveDelayHoldApplied ;;
Set-Mailbox -Identity usuario@contoso.com -LitigationHoldEnabled $false ;;
Set-Mailbox -Identity usuario@contoso.com -RetentionHoldEnabled $false ;;
Set-Mailbox -Identity usuario@contoso.com -RemoveDelayReleaseHoldApplied ;;
Set-Mailbox -Identity usuario@contoso.com -RemoveComplianceTagHoldApplied;;
Set-Mailbox -Identity usuario@contoso.com -Retaindeleteditemsfor 0 ;; 
Set-Mailbox -Identity usuario@contoso.com -Singleitemrecoveryenabled $false 
Set-Mailbox -Identity usuario@contoso.com -elcprocessingdisabled $false


<# and then
Remove-Mailbox -Identity user@contoso.com -PermanentlyDelete:$true

Or if necessary: 
Start-ManagedFolderAssistant -Identity user@domain -FullCrawl 
#>

#PExclude mailbox from retention policies depending on findings
Set-RetentionCompliancePolicy  -Identity "retention name"  -AddExchangeLocationException "mailbox"
Set-RetentionCompliancePolicy  -Identity "retention name"  -AddTeamsChatLocationException "mailbox"
Set-RetentionCompliancePolicy  -Identity "retention name"  -AddModernGroupLocationException "group mailbox"

#In case Groups are all or unknown, try this
Set-RetentionCompliancePolicy  -Identity "retention name"  -RemoveModernGroupLocation "All"
