Connect-ExchangeOnline ;; Connect-IPPSSession -EnableSearchOnlySession

#Assign roles

New-ManagementRoleAssignment -Role "Mailbox Import Export" -SecurityGroup "Organization Management"
 
Add-RoleGroupMember -Identity "OrganizationManagement" -Member "user@yourdomain.com"


$mailbox = "user@domain"

Get-RecoverableItems -Identity $mailbox  -FilterItemType IPM.Note -ResultSize Unlimited | Where-Object { $_.LastParentPath -match "Inbox" } | Restore-RecoverableItems