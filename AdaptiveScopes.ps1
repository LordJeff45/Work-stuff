#Gathering Adaptive Scope information and some members
Connect-ExchangeOnline ;; Connect-IPPSSession -EnableSearchOnlySession


$PageSize = 500
$ExportPath = "C:\AllAdaptiveScopeMembers.csv"

$results = @()

foreach ($Scope in (Get-AdaptiveScope)) {

   Write-Host "Processing scope: $($Scope.Name)"

   $cookie = $null

   do {

       try {

           if ($null -eq $cookie) {
               $page = Get-AdaptiveScopeMembers `
                   -Identity $Scope.Guid `
                   -PageResultSize $PageSize
           }
           else {
               $page = Get-AdaptiveScopeMembers `
                   -Identity $Scope.Guid `
                   -PageResultSize $PageSize `
                   -PageCookie $cookie
           }

           if ($null -eq $page) {
               break
           }

           $meta = $page[0]

           if ($meta.CurrentPageMemberCount -gt 0) {

               foreach ($member in $page[1..($page.Count - 1)]) {

                   $results += [PSCustomObject]@{
                       ScopeName = $Scope.Name
                       ScopeGuid = $Scope.Guid
                       Member    = $member
                   }
               }
           }

           if ($meta.IsLastPage) {
               $cookie = $null
           }
           else {
               $cookie = $meta.Watermark
           }

       }
       catch {
           Write-Warning "Failed scope '$($Scope.Name)': $($_.Exception.Message)"
           break
       }

   } while ($cookie)
}

$results | Export-Csv `
   -Path $ExportPath `
   -NoTypeInformation `
   -Encoding UTF8
