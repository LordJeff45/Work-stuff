<#
Script: Create SecOps Override Policy (if missing) + add UserMailboxes in batches
Enhancements included:
1) Global try/catch/finally to handle errors cleanly and print friendly output.
2) Disconnect-ExchangeOnline in finally so the session closes even if something fails.

 
Behavior:
- If SecOps override policy already exists -> STOP intentionally (no changes).
- If policy does NOT exist -> create policy + rule, then add remaining user mailboxes in batches.
#>

 
# ---------------- CONFIG ----------------
$PolicyIdentity = "SecOpsOverridePolicy"
$RuleName       = "SecOpsOverrideRule"
$BatchSize      = 200

 
try {
    # ---------------- CONNECT ----------------
    Connect-ExchangeOnline

 
    # ---------------- GET ALL USER MAILBOXES ----------------
    $AllUserMailboxes = Get-ExoMailbox -ResultSize Unlimited -RecipientTypeDetails UserMailbox  |
        Select-Object -ExpandProperty PrimarySmtpAddress

 
    if (-not $AllUserMailboxes -or $AllUserMailboxes.Count -eq 0) {
        throw "No UserMailbox recipients found. Nothing to add."
    }

 
    # ---------------- CHECK IF POLICY EXISTS ----------------
    $PolicyExists = $false
    try {
        $null = Get-SecOpsOverridePolicy
        $PolicyExists = $true
    } catch {
        $PolicyExists = $false
    }

 
    # ---------------- CREATE POLICY/RULE ONLY IF MISSING ----------------
    if (-not $PolicyExists) {

 
        # Create the policy with at least one mailbox (required for creation)
        New-SecOpsOverridePolicy -Name $PolicyIdentity -SentTo $AllUserMailboxes[0]

 
        # Create the rule that applies the policy
        New-ExoSecOpsOverrideRule -Name $RuleName -Policy $PolicyIdentity -ErrorAction Stop

 
        # We already added the first mailbox during creation, so skip it here
        $ToAdd = $AllUserMailboxes | Select-Object -Skip 1

 
    } else {

 
        # Policy already exists — stop execution immediately to avoid modifying it
        throw "SecOpsOverridePolicy already exists. Script stopped intentionally (no changes made)."
    }

 
    # ---------------- ADD IN BATCHES ----------------
    for ($i = 0; $i -lt $ToAdd.Count; $i += $BatchSize) {
        $end = [Math]::Min($i + $BatchSize - 1, $ToAdd.Count - 1)
        $batch = $ToAdd[$i..$end]

 
        Set-SecOpsOverridePolicy -Identity $PolicyIdentity -AddSentTo $batch -ErrorAction Stop
        Write-Host ("Added batch {0}-{1} of {2}" -f ($i+1), ($end+1), $ToAdd.Count) -ForegroundColor Green
    }

 
    # ---------------- VERIFY ----------------
    Write-Host "=== SecOps Override Policy ===" -ForegroundColor Cyan
    Get-SecOpsOverridePolicy

 
    Write-Host "=== SecOps Override Rules ===" -ForegroundColor Cyan
    Get-ExoSecOpsOverrideRule

 
    Write-Host "Done." -ForegroundColor Green
}
catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    # If you want more detail, uncomment:
    # Write-Host $_.ScriptStackTrace -ForegroundColor DarkGray
}
finally {
    # ---------------- DISCONNECT (ALWAYS) ----------------
    try {
        Disconnect-ExchangeOnline -Confirm:$false
        Write-Host "Disconnected from Exchange Online." -ForegroundColor Yellow
    } catch {
        # Swallow disconnect errors so they don't hide the real failure
        Write-Host "Warning: Could not disconnect cleanly." -ForegroundColor Yellow
    }
}
