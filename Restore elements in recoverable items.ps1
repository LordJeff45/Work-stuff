$params = @{
    StartDate = [datetime]"2025-05-29"
    EndDate   = [datetime]"2025-06-02"
    EmptyGuid = [guid]::Empty.ToString()
}
Connect-ExchangeOnline ;; Connect-IPPSSession -EnableSearchOnlySession

#Assign roles

New-ManagementRoleAssignment -Role "Mailbox Import Export" -SecurityGroup "Organization Management"
 
Add-RoleGroupMember -Identity "OrganizationManagement" -Member "user@yourdomain.com"


$mailboxes = Get-Mailbox -ResultSize Unlimited -RecipientTypeDetails UserMailbox
foreach ($mbx in $mailboxes) {
    $user = $mbx.UserPrincipalName
    $archiveGuid = $mbx.ArchiveGuid.Guid
if ($archiveGuid -eq $params.EmptyGuid -or $mbx.IsInactiveMailbox) {
        Write-Warning "[$user] Omitido - No tiene buzón de archivo o está inactivo"
        continue
    }
Write-Host "[$user] Restaurando elementos del archivo..."
try {
        Restore-RecoverableItems -Identity $archiveGuid `
            -ResultSize Unlimited `
            -FilterItemType IPM.Note `
            -FilterStartTime $params.StartDate `
            -FilterEndTime $params.EndDate
Write-Host "[$user] Restauración completada"
    }
    catch {
        Write-Warning "[$user] Error: $($_.Exception.Message)"
    }
}



