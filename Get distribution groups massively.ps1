
# Connect to Exchange Online
Connect-ExchangeOnline -UserPrincipalName your.email@domain.com
 
# Get all distribution groups
$DLs = Get-DistributionGroup
 
# Create an array to store results
$Results = @()
 
foreach ($DL in $DLs) {
    # Get members of each distribution group
    $Members = Get-DistributionGroupMember -Identity $DL.Identity | Select-Object -ExpandProperty PrimarySmtpAddress
 
    # Add to results
    $Results += [PSCustomObject]@{
        DistributionList = $DL.PrimarySmtpAddress
        Members          = ($Members -join "; ")
    }
}
 
# Export to CSV
$Results | Export-Csv -Path "C:\Temp\DistributionLists.csv" -NoTypeInformation
 
# Disconnect session
Disconnect-ExchangeOnline
