<#
.SYNOPSIS
    Blocks specified domains in all user mailboxes for a specific domain.
.DESCRIPTION
    This script reads a list of domains from a file and adds them to the BlockedSendersAndDomains list
    for all user mailboxes in the specified domain.
.NOTES
    File Name      : Block-DomainsForMailboxes.ps1
    Prerequisite   : Exchange Online PowerShell module or Exchange Management Shell
    Version       : 1.1
#>

# Parameters
param (
    [string]$DomainFile = "C:\pruebadominios.txt", #change this as per txt location
    [string]$TargetDomain = "@lordjeffcorps.onmicrosoft.com"
)

# Error handling setup
$ErrorActionPreference = "Stop"

try {
    # Validate input file
    if (-not (Test-Path -Path $DomainFile)) {
        throw "Domain file not found at: $DomainFile"
    }

    # Read and clean domains from file
    Write-Host "Reading domains from file..." -ForegroundColor Cyan
    $BlockedDomains = Get-Content -Path $DomainFile | 
        Where-Object { $_ -and $_ -notmatch "^#" } |  # Skip comments
        ForEach-Object { $_.Trim() } |               # Remove whitespace
        Where-Object { $_ -and $_ -notmatch "^\\s*$" } |  # Remove empty lines
        Select-Object -Unique                        # Remove duplicates

    if (-not $BlockedDomains) {
        throw "No valid domains found in the input file."
    }

    Write-Host "Found $($BlockedDomains.Count) unique domains to block." -ForegroundColor Green

    # Get all target mailboxes
    Write-Host "Retrieving mailboxes for domain $TargetDomain..." -ForegroundColor Cyan
    $AllMailboxes = Get-Mailbox -RecipientTypeDetails UserMailbox -ResultSize Unlimited | 
        Where-Object { $_.PrimarySmtpAddress -like "*$TargetDomain" }

    if (-not $AllMailboxes) {
        throw "No mailboxes found for domain $TargetDomain."
    }

    Write-Host "Found $($AllMailboxes.Count) mailboxes to process." -ForegroundColor Green

    # Process mailboxes
    $counter = 0
    $totalMailboxes = $AllMailboxes.Count
    $startTime = Get-Date

    foreach ($Mailbox in $AllMailboxes) {
        $counter++
        $percentComplete = ($counter / $totalMailboxes) * 100
        $elapsedTime = (Get-Date) - $startTime
        $remainingTime = ($elapsedTime.TotalSeconds / $counter) * ($totalMailboxes - $counter)

        Write-Progress -Activity "Processing mailboxes" -Status "$counter of $totalMailboxes ($([math]::Round($percentComplete,1))%)" `
            -PercentComplete $percentComplete `
            -SecondsRemaining $remainingTime

        try {
            # Get current blocked senders to avoid duplicates
            $currentConfig = Get-MailboxJunkEmailConfiguration -Identity $Mailbox.Identity
            $existingDomains = $currentConfig.BlockedSendersAndDomains
            
            # Filter out domains already blocked
            $domainsToAdd = $BlockedDomains | Where-Object { $_ -notin $existingDomains }
            
            if ($domainsToAdd) {
                Write-Host "Adding $($domainsToAdd.Count) domains to $($Mailbox.PrimarySmtpAddress)" -ForegroundColor DarkGray
                Set-MailboxJunkEmailConfiguration -Identity $Mailbox.Identity -BlockedSendersAndDomains @{Add=$domainsToAdd} -ErrorAction Stop
            } else {
                Write-Host "All domains already blocked for $($Mailbox.PrimarySmtpAddress)" -ForegroundColor DarkGray
            }
        }
        catch {
            Write-Warning "Failed to update mailbox $($Mailbox.PrimarySmtpAddress): $_"
            # Continue with next mailbox
            continue
        }
    }

    Write-Host "Operation completed successfully!" -ForegroundColor Green
    Write-Host "Total mailboxes processed: $counter" -ForegroundColor Green
    Write-Host "Total time taken: $($elapsedTime.ToString('hh\:mm\:ss'))" -ForegroundColor Green
}
catch {
    Write-Host "ERROR: $_" -ForegroundColor Red
    exit 1
}
pause
