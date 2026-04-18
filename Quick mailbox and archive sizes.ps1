Connect-ExchangeOnline

$u = "affected account you want to use for the option"
$primary = Get-MailboxStatistics -Identity $u
$archive = Get-MailboxStatistics -Identity $u -Archive
[PSCustomObject]@{
   User                     = $u
   PrimaryMailboxSize       = $primary.TotalItemSize
   PrimaryItemCount         = $primary.ItemCount
   PrimaryDeletedItemSize   = $primary.TotalDeletedItemSize
   ArchiveMailboxSize       = $archive.TotalItemSize
   ArchiveItemCount         = $archive.ItemCount
   ArchiveDeletedItemSize   = $archive.TotalDeletedItemSize
}
