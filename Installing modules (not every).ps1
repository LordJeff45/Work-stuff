#Allowng execution of command in BYOD
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Unrestricted -Force


#Allwoing connections when firewall is on 
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

#updating/installing Powershell app
winget install --id Microsoft.Powershell --source winget

#installing Exchange and IPPSSession modules
Install-Module ExchangeOnlineManagement -Force -AllowClobber

#Install this module: https://www.microsoft.com/en-us/download/details.aspx?id=53018&msockid=096f64adeed46ccd017a715fead46a7f
Install-Module -Name AIPService

#Install SPO module
Install-Module -Name Microsoft.Online.SharePoint.PowerShell

#Install Azure  module
Install-Module -Name Az -Repository PSGallery -Force

#Install Entra module:
Install-Module Microsoft.Entra -force -AllowClobber

#Install Graph Module
Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber 

#Install PnP module
Install-Module PnP.PowerShell  -Force -AllowClobber  #please check their documentation as they require more things

#Install Microsoft Teams module
Install-Module -Name MicrosoftTeams  -Force -AllowClobber  #I am surprised an app has a module

Update-Help
