Connect-ExchangeOnline

$mailbox = "user@domain"

Export-MailboxDiagnosticLogs -ComponentName MRM -Identity $mailbox

Export-MailboxDiagnosticLogs -ComponentName MRM -Identity $mailbox | Export-Csv -Path "$HOME\nameofthefile.csv"

#From <https://learn.microsoft.com/en-us/powershell/module/exchange/export-mailboxdiagnosticlogs?view=exchange-ps> 
