Connect-IPPSSession -EnableSearchOnlySession
#keep in mind to use connect-ippssession -EnableSearchOnlySession for this
$AllCases = Get-ComplianceCase
$AllCases.count
$AllSearches = $AllCases | ForEach-Object { Get-ComplianceSearch -ResultSize Unlimited -Case $_.Name | ForEach-Object { Write-Host "Search: $($_.Name)"; $_ } }
$AllSearches.count
$AllSearches += Get-ComplianceSearch -ResultSize Unlimited | ForEach-Object { Write-Host "ContentSearch: $($_.Name)"; $_ }
$AllSearches.count
foreach ($srch in $AllSearches) { set-compliancesearch -identity $srch.name}
