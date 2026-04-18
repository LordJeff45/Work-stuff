<# Disclaimer:
The sample scripts are not supported under any Microsoft standard support program or service. The sample scripts are provided AS IS without warranty of any kind. Microsoft further disclaims all implied warranties including, without limitation, any implied warranties of merchantability or of fitness for a particular purpose. The entire risk arising out of the use or performance of the sample scripts and documentation remains with you. In no event shall Microsoft, its authors, or anyone else involved in the creation, production, or delivery of the scripts be liable for any damages whatsoever (including, without limitation, damages for loss of business profits, business interruption, loss of business information, or other pecuniary loss) arising out of the use of or inability to use the sample scripts or documentation, even if Microsoft has been advised of the possibility of such damages.


 Keep in mind this command works as long as the sites don't have any kind of retention applied, otherwise, it will fail with error  Error: This list cannot be deleted.

#>

# Define variables
$tenantName = "<tenant name>"  # Replace with your tenant name
$clientId = "clientid of app for connect-pnponline"
$outputFolder = "C:\PnPReports"
$outputCsv = Join-Path $outputFolder "TenantSites.csv"
# Ensure the folder exists
if (-not (Test-Path $outputFolder)) {
    Write-Host "Creating folder $outputFolder..."
    New-Item -ItemType Directory -Path $outputFolder | Out-Null
}
# Step 0: Connect to SharePoint Admin Center
Write-Host "Connecting to SharePoint Admin Center..."
Connect-PnPOnline -Url "https://$tenantName-admin.sharepoint.com/" -Interactive -ClientId $clientId
# Step 1: Get all tenant sites
Write-Host "Retrieving all tenant sites..."
$sites = Get-PnPTenantSite
# Step 2: Export site URLs to CSV
Write-Host "Exporting site URLs to $outputCsv..."
$sites | Select-Object Url | Export-Csv -Path $outputCsv -NoTypeInformation
# Step 3: Read URLs from CSV
$siteUrls = Import-Csv -Path $outputCsv
# Step 4: Iterate through each site URL
foreach ($site in $siteUrls) {
    $siteUrl = $site.Url
    Write-Host "`nConnecting to $siteUrl..."
    # Connect to site and store connection
    $conn = Connect-PnPOnline -Url $siteUrl -Interactive -ClientId $clientId -ReturnConnection
    # Step 5: Get all lists in the site
    $lists = Get-PnPList -Connection $conn
    # Step 6: Check for Preservation Hold Library
    $preservationList = $lists | Where-Object { $_.Title -eq "Preservation Hold Library" }
    if ($preservationList) {
        Write-Host "Preservation Hold Library found in $siteUrl"
        Write-Host "Details: Title=$($preservationList.Title), ID=$($preservationList.Id), Url=$($preservationList.Url)"
        # Step 7: Attempt to delete the list
        try {
            Write-Host "Attempting to delete Preservation Hold Library from $siteUrl..."
            Set-PnPList $preservationList.id -Connection $conn -allowdeletion $true
            Remove-PnPList -Identity $preservationList.Id -Connection $conn -Force
            Write-Host "Preservation Hold Library deleted successfully from $siteUrl"
        }
        catch {
            Write-Host "Failed to delete Preservation Hold Library from $siteUrl. Error: $($_.Exception.Message)"
        }
    } else {
        Write-Host "No Preservation Hold Library in $siteUrl"
    }
} 

<# try if items are so much
try {
        Write-Host "Starting item deletion in batches..."
 
        # Pagination settings
        $batchSize = 4000
        $items = Get-PnPListItem -List $lib -PageSize $batchSize -ScriptBlock {
            param($items)
            foreach ($item in $items) {
                Remove-PnPListItem -List $lib -Identity $item.Id -Force
                Write-Host "Deleted item ID: $($item.Id)"
            }
        }
 
        Write-Host "All items deleted. Attempting to delete the list..."
 
        # Allow deletion and remove the list
        Set-PnPList -Identity $lib -AllowDeletion $true
        Remove-PnPList -Identity $lib -Force
 
        Write-Host "Preservation Hold Library deleted successfully from $siteUrl"
    }
    catch {
        Write-Host "Failed to delete Preservation Hold Library from $siteUrl. Error: $($_.Exception.Message)"
    }
}
else {
    Write-Host "No Preservation Hold Library found in $siteUrl"
}
#>