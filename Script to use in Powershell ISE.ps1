$msalPath = [System.IO.Path]::GetDirectoryName((Get-Module ExchangeOnlineManagement).Path);
Add-Type -Path "$msalPath\Microsoft.IdentityModel.Abstractions.dll";
Add-Type -Path "$msalPath\Microsoft.Identity.Client.dll";
[Microsoft.Identity.Client.IPublicClientApplication] $application = [Microsoft.Identity.Client.PublicClientApplicationBuilder]::Create("fb78d390-0c51-40cd-8e17-fdbfab77341b").WithDefaultRedirectUri().Build();
$result = $application.AcquireTokenInteractive([string[]]"https://outlook.office365.com/.default").ExecuteAsync().Result;
Connect-ExchangeOnline -AccessToken $result.AccessToken -UserPrincipalName $result.Account.Username;
Connect-IPPSSession  -AccessToken $result.AccessToken -UserPrincipalName $result.Account.Username -EnableSearchOnlySession

