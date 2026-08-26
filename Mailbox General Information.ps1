
Jeffry
5:30 PM
# Connect first if not already connected
# Connect-ExchangeOnline

# Output file
$Output = "C:\MailboxStatisticsReport.csv"

# Get all mailboxes once
$Mailboxes = Get-Mailbox -ResultSize Unlimited -RecipientTypeDetails UserMailbox

# Initialize a collection
$Results = @()

foreach ($mbx in $Mailboxes) {
    try {
        # Get mailbox location(s) (handles archive, primary, aux)
        $locations = Get-MailboxLocation -User $mbx.guid

        foreach ($loc in $locations) {
            $stats = Get-MailboxStatistics -Identity $loc

            $Results += [PSCustomObject]@{
                DisplayName          = $mbx.DisplayName
                UserPrincipalName    = $mbx.UserPrincipalName
                MailboxGuid          = $stats.MailboxGuid
                MailboxType          = $stats.MailboxTypeDetail
                TotalItemSize        = $stats.TotalItemSize
                ItemCount            = $stats.ItemCount
                TotalItemDeletedSize = $stats.TotalDeletedItemSize
                Database             = $stats.Database
            }
        }
    }
    catch {
        Write-Warning "Failed for $($mbx.UserPrincipalName): $_"
    }
}

# Export to CSV
$Results | Export-Csv -Path $Output -NoTypeInformation -Encoding UTF8

Write-Host "Report saved to $Output"