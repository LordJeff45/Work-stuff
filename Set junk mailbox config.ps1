Connect-ExchangeOnline ;; Connect-IPPSSession

$AllMailboxes = Get-Mailbox -RecipientTypeDetails UserMailbox -ResultSize Unlimited
# Add the trusted sender domain to each mailbox
foreach ($Mailbox in $AllMailboxes) {
   Set-MailboxJunkEmailConfiguration -Identity $Mailbox.Identity -TrustedSendersAndDomains @{Add="senderaddress@domain"}
}
```
```
$AllMailboxes = Get-Mailbox -RecipientTypeDetails UserMailbox -ResultSize Unlimited
# Add the trusted sender domain to each mailbox
foreach ($Mailbox in $AllMailboxes) {
   Set-MailboxJunkEmailConfiguration -Identity $Mailbox.Identity -TrustedSendersAndDomains @{Remove="senderaddress@domain"}
}
