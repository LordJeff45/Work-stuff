<#
Creates:
- "No-action / infinite" tags for most ElcFolderType values (official list), excluding:
  Personal, All, JunkEmail, DeletedItems, SyncIssues (and RecoverableItems by default).
- A DPT (Type=All) that PermanentlyDelete after 900 days.
- A retention policy that links all tags.

ElcFolderType official values are documented by Microsoft. 【2-3f4a52】【3-bcf6b9】
#>

# ----------------------------
# Settings
# ----------------------------
$TagPrefix       = "EMRG"
$PolicyName      = "EMRG-InfiniteRPTs-Delete900D"
$DeleteAfterDays = 900

# User-requested exclusions + safety exclusion for RecoverableItems
$ExcludedTypes   = @("Personal","All","JunkEmail","DeletedItems","SyncIssues","RecoverableItems")

$NoActionSuffix  = "NoAction-Infinite"
$DptDeleteName   = "$TagPrefix-All-PermDelete-$DeleteAfterDays" + "d"

# ----------------------------
# Official ElcFolderType list from Microsoft docs (do not add Archive/Clutter/LegacyArchiveJournals here)
# ----------------------------
$AllElcTypes = @(
  "Calendar","Contacts","DeletedItems","Drafts","Inbox","JunkEmail","Journal","Notes","Outbox","SentItems","Tasks",
  "All","ManagedCustomFolder","RssSubscriptions","SyncIssues","ConversationHistory","Personal","RecoverableItems","NonIpmRoot"
)

$TargetTypes = $AllElcTypes | Where-Object { $_ -notin $ExcludedTypes }

Write-Host "Official ElcFolderType values (known): $($AllElcTypes.Count)"
Write-Host "Creating NO-ACTION tags for: $($TargetTypes.Count)"
Write-Host ("Excluded: " + ($ExcludedTypes -join ", "))

# ----------------------------
# Create the "no action / infinite" tags
# ----------------------------
$TagLinks = New-Object System.Collections.Generic.List[string]

foreach ($t in $TargetTypes) {

    $tagName = "$TagPrefix-$t-$NoActionSuffix"

    $existing = Get-RetentionPolicyTag -Identity $tagName -ErrorAction SilentlyContinue
    if ($null -eq $existing) {
        Write-Host "Creating NO-ACTION tag: $tagName (Type=$t)"
        try {
            New-RetentionPolicyTag `
                -Name $tagName `
                -Type $t `
                -RetentionEnabled $false `
                -Comment "Emergency: no retention action (infinite/no-expire behavior)."
        } catch {
            Write-Warning "Failed to create tag '$tagName' with Type '$t'. Error: $($_.Exception.Message)"
            continue
        }
    } else {
        Write-Host "Tag already exists, reusing: $tagName"
    }

    [void]$TagLinks.Add($tagName)
}

# ----------------------------
# Create the DPT delete tag (Type=All) PermanentlyDelete after 900 days
# ----------------------------
$existingDpt = Get-RetentionPolicyTag -Identity $DptDeleteName -ErrorAction SilentlyContinue
if ($null -eq $existingDpt) {
    Write-Host "Creating DPT delete tag: $DptDeleteName (Type=All, PermanentlyDelete after $DeleteAfterDays days)"
    New-RetentionPolicyTag `
        -Name $DptDeleteName `
        -Type All `
        -RetentionEnabled $true `
        -AgeLimitForRetention $DeleteAfterDays `
        -RetentionAction PermanentlyDelete `
        -Comment "Emergency: DPT to permanently delete items older than $DeleteAfterDays days."
} else {
    Write-Host "DPT already exists, reusing: $DptDeleteName"
}

[void]$TagLinks.Add($DptDeleteName)

# ----------------------------
# Create or update the retention policy with tag links
# ----------------------------
$existingPolicy = Get-RetentionPolicy -Identity $PolicyName -ErrorAction SilentlyContinue
if ($null -eq $existingPolicy) {
    Write-Host "Creating retention policy: $PolicyName"
    New-RetentionPolicy -Name $PolicyName -RetentionPolicyTagLinks $TagLinks
} else {
    Write-Host "Retention policy exists. Updating links: $PolicyName"
    Set-RetentionPolicy -Identity $PolicyName -RetentionPolicyTagLinks $TagLinks
}

Write-Host "Done. Policy '$PolicyName' links $($TagLinks.Count) tags total."
Write-Host ""
Write-Host "Next steps:"
Write-Host "  Set-Mailbox user@domain.com -RetentionPolicy `"$PolicyName`""
Write-Host "  Start-ManagedFolderAssistant -Identity user@domain.com"
