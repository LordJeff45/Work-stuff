#steps explained in https://learn.microsoft.com/en-us/exchange/recipients-in-exchange-online/delete-or-restore-mailboxes 

Connect-ExchangeOnline
Get-Mailbox -softdeletedmailbox | Format-List Name, DistinguishedName, Exchangeguid, PrimarySmtpaddress 
Get-Mailbox -Identity "<upn>" | Format-List Name, DistinguishedName, Exchangeguid, PrimarySmtpaddress 
New-Mailbox -SourceMailbox "oldmailbox exchange guid" -TargetMailbox "newmailbox exchange guid" -AllowLegacyDNMismatch