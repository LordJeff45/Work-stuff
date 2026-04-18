Connect-IPPSSession -EnableSearchOnlySession

#Check if audit is enabled
Get-AdminAuditLogConfig | Format-List UnifiedAuditLogIngestionEnabled

#Enabling Purview Unified Audit

Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled $true

#Enabling audit for all mailboxes, required for a Defender Score
Get-Mailbox -ResultSize Unlimited | Set-Mailbox -AuditEnabled $true
 
 
Get-Mailbox -ResultSize Unlimited -Filter{RecipientTypeDetails -eq "DiscoveryMailbox"} | Set-Mailbox -AuditEnabled:$true
Get-Mailbox -ResultSize Unlimited -Filter{RecipientTypeDetails -eq "SharedMailbox"} | Set-Mailbox -AuditEnabled:$true
Get-Mailbox -ResultSize Unlimited -Filter{RecipientTypeDetails -eq "SchedulingMailbox"} | Set-Mailbox -AuditEnabled:$true
Get-Mailbox -ResultSize Unlimited -Filter{RecipientTypeDetails -eq "RoomMailbox"} | Set-Mailbox -AuditEnabled:$true
Get-Mailbox -ResultSize Unlimited -Filter{RecipientTypeDetails -eq "EquipmentMailbox"} | Set-Mailbox -AuditEnabled:$true
Get-Mailbox -ResultSize Unlimited -Filter{AuditEnabled -eq "false"} | fl Name, RecipientTypeDetails,*Audit* 
Get-Mailbox -ResultSize Unlimited -Filter{AuditEnabled -eq "False"} | ft Name, RecipientTypeDetails,AuditEnabled
Get-Mailbox -ResultSize Unlimited -Filter{AuditEnabled -eq "true"} | ft Name, RecipientTypeDetails,AuditEnabled