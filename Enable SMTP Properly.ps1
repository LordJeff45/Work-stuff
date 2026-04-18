#To perform the configuration, the following PowerShell commands are executed:

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Set-ExecutionPolicy Unrestricted
Install-Module PowershellGet -Force
Install-Module ExchangeOnlineManagement -force
Connect-ExchangeOnline
Set-CASMailbox -Identity <correo> -SmtpClientAuthenticationDisabled $false
Get-CASMailbox -Identity <correo> | FL SmtpClientAuthenticationDisabled
$cred = Get-Credential
Send-MailMessage -From $cred. UserName -To "user@domain.com" -SmtpServer smtp.office365.com -Port 587 -UseSsl -Body "test body" -Subject "test using SMTP client submission" -Credential $cred

