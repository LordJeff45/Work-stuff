
#########################################################################################################
# This PowerShell script will prompt you for:
# * Admin credentials for a user who can run the Get-MailboxFolderStatistics cmdlet in Exchange Online
# and who is an eDiscovery Manager in the Purview portal
# The script will then:
# * If an email address is supplied: list the folders for the target mailbox
# * If a SharePoint or OneDrive for Business site is supplied: list the documentlinks (folder paths)
# for the site
# * In both cases, the script supplies the correct search properties (folderid: or documentlink:)
# appended to the folder ID or documentlink to use in a Content Search
#########################################################################################################

$addressOrSite = Read-Host "Enter an email address or a URL for a SharePoint or OneDrive for Business site"
if ($addressOrSite.IndexOf("@") -ge 0) {
$emailAddress = $addressOrSite
Import-Module ExchangeOnlineManagement
Connect-ExchangeOnline -ShowBanner:$false -CommandName Get-MailboxFolderStatistics
$folderStatistics = Get-MailboxFolderStatistics $emailAddress -Archive
foreach ($folderStatistic in $folderStatistics) {
	$folderId = $folderStatistic.FolderId
	$folderPath = $folderStatistic.FolderPath
	$encoding = [System.Text.Encoding]::GetEncoding("us-ascii")
	$nibbler = $encoding.GetBytes("0123456789ABCDEF")
	$folderIdBytes = [Convert]::FromBase64String($folderId)
	$indexIdBytes = New-Object byte[] 48
	$indexIdIdx = 0
	$folderIdBytes | select -skip 23 -First 24 | %{$indexIdBytes[$indexIdIdx++]=$nibbler[$_ -shr 4];$indexIdBytes[$indexIdIdx++]=$nibbler[$_ -band 0xF]}
	$folderQuery = "folderid:$($encoding.GetString($indexIdBytes))"
	Write-Host "Folder Path: $folderPath, Folder Query: $folderQuery"
}
} 
elseif ($addressOrSite.IndexOf("http") -ge 0) {
	Import-Module ExchangeOnlineManagement
	Connect-IPPSSession
	$siteUrl = $addressOrSite
	$complianceSearch = New-ComplianceSearch -Name "SPFoldersSearch" -ContentMatchQuery "contenttype:folder OR contentclass:STS_Web" -SharePointLocation $siteUrl
	Start-ComplianceSearch "SPFoldersSearch"
	do {
		Write-host "Waiting for search to complete..."
		Start-Sleep -s 5
		$complianceSearch = Get-ComplianceSearch "SPFoldersSearch"
	} while ($complianceSearch.Status -ne 'Completed')
	if ($complianceSearch.Items -gt 0) {
	$complianceSearchAction = New-ComplianceSearchAction -SearchName "SPFoldersSearch" -Preview
	do {
		Write-host "Waiting for search action to complete..."
		Start-Sleep -s 5
		$complianceSearchAction = Get-ComplianceSearchAction "SPFoldersSearch_Preview"
	} while ($complianceSearchAction.Status -ne 'Completed')
	$results = $complianceSearchAction.Results
	$matches = Select-String "Data Link:.+[,}]" -InputObject $results -AllMatches
	foreach ($match in $matches.Matches) {
	$rawUrl = $match.Value -replace "Data Link: " -replace "," -replace "}"
	Write-Host "DocumentLink: \"$rawUrl\""
	}
	} else {
		Write-Host "No folders were found for $siteUrl"
	}
	Remove-ComplianceSearch "SPFoldersSearch" -Confirm:$false -ErrorAction 'SilentlyContinue'
	} 
else {
Write-Error "Couldn't recognize $addressOrSite as an email address or a site URL"
}
