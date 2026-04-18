#For bulk deletion, use PowerShell: Connect to the site using 

Connect-pnponline "sharepoint site" -Interactive -ClientId "id from app created in entra"
Get-PnPList
Set-pnplist -identity "id of preservationhold or Preservation Hold Library"  -allowdeletion $true
Remove-PnPList -Identity  "id of preservationhold or Preservation Hold Library" -Force
