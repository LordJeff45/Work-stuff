
Connect-ExchangeOnline ;; Connect-IPPSSession -EnableSearchOnlySession


# Output file path
$outputFile = "C:\RetentionPolicyReport.txt"
# Initialize the file
"================ Retention Policy Report =================" | Out-File $outputFile
"Generated on: $(Get-Date)" | Out-File $outputFile -Append
"=========================================================" | Out-File $outputFile -Append
# Global error handling
$ErrorActionPreference = "Stop"
try {
    # Get all retention policies with distribution detail
    $policies = Get-RetentionCompliancePolicy -DistributionDetail
    $counter = 1
    foreach ($policy in $policies) {
        try {
            $header = "`nProcessing Policy #${counter}: $($policy.Name)"
            Write-Host $header
            $header | Out-File $outputFile -Append
            
            # Policy details
            $policyDetails = $policy | Format-List Name, Guid, Mode, Enabled, SharePointLocation, OneDriveLocation, ExchangeLocation, TeamsChatLocation, TeamsChannelLocation, ModernGroupLocation  | Out-String
            $policyDetails | Out-File $outputFile -Append
            
            # Process ALL policies (no location filter)
            $retentionRules = Get-RetentionComplianceRule -Policy $policy.Guid
            
            foreach ($retentionRule in $retentionRules) {
                $ruleHeader = "`nLooking at ComplianceRule for RetentionCompliancePolicy: $($policy.Name)`n"
                Write-Host $ruleHeader
                $ruleHeader | Out-File $outputFile -Append
                
                # Retention rule details
                $ruleDetails = $retentionRule | Format-List ComplianceTagProperty, ApplyComplianceTag, PublishComplianceTag, RetentionDurationDisplayHint, RetentionDuration, RetentionComplianceAction, Workload, Policy | Out-String
                $ruleDetails | Out-File $outputFile -Append
                
                if ($retentionRule.ComplianceTagProperty) {
                    $tagValues = $retentionRule.ComplianceTagProperty -split ","
                    
                    for ($i = 0; $i -lt $tagValues.Count; $i += 2) {
                        $tagId = $tagValues[$i].Trim()
                        
                        if ($tagId -and ($tagId -ne "")) {
                            $tagMsg = "Found Compliance Tag ID: $tagId"
                            Write-Host $tagMsg
                            $tagMsg | Out-File $outputFile -Append
                            
                            # Get Compliance Tag details
                            $tagDetails = Get-ComplianceTag -Identity $tagId | Format-List RetentionAction, RetentionType, ReviewerEmail, Regulatory, RetentionDuration, ReadOnly, IsRecordLabel, IsRecordUnlockedAsDefault, IsActiveLabel, IsHardDeleteInSPOandODB, IsReviewTag, IsPDRTag, IsValid, HasRetentionAction | Out-String
                            $tagDetails | Out-File $outputFile -Append
                        }   
# Si ApplyComplianceTag tiene valor, agregarlo
                              if ($retentionRule.ApplyComplianceTag) { 
			$tagIds += ($retentionRule.ApplyComplianceTag.ToString()).Trim()
                                 }
                               # Procesar todos los IDs encontrados
                             if ($tagIds.Count -gt 0) {
                                   foreach ($tagId in $tagIds) {
                                   $tagMsg = "Found Compliance Tag ID: $tagId"
                                   Write-Host $tagMsg
                                  $tagMsg | Out-File $outputFile -Append
                                      # Obtener detalles del Compliance Tag
                                   $tagDetails = Get-ComplianceTag -Identity $tagId | Format-List RetentionAction, RetentionType, ReviewerEmail, Regulatory, RetentionDuration, ReadOnly, IsRecordLabel, IsRecordUnlockedAsDefault, IsActiveLabel, IsHardDeleteInSPOandODB, IsReviewTag, IsPDRTag, IsValid, HasRetentionAction | Out-String
                                    $tagDetails | Out-File $outputFile -Append
                             }
                          } else {
                            "No valid Compliance Tag ID found for this rule." | Out-File $outputFile -Append
                        }
                  }
                }
            }
        }
        catch {
            $errorMsg = "`n[ERROR] Issue with policy: $($policy.Name). Details: $($_.Exception.Message)`n"
            Write-Host $errorMsg -ForegroundColor Red
            $errorMsg | Out-File $outputFile -Append
        }
        
        $counter++
    }
}
catch {
    # Global error handler for critical failures
    $globalError = "`n[CRITICAL ERROR] Script failed. Details: $($_.Exception.Message)`n"
    Write-Host $globalError -ForegroundColor Red
    $globalError | Out-File $outputFile -Append
}
