
Connect-ExchangeOnline ;; Connect-IPPSSession -EnableSearchOnlySession

# Ruta del archivo de salida
$outputFile = "C:\RetentionPolicyReport.txt"
# Inicializar el archivo
"================ Retention Policy Report =================" | Out-File $outputFile
"Generated on $(Get-Date)" | Out-File $outputFile -Append
"=========================================================" | Out-File $outputFile -Append
# Configurar manejo global de errores
$ErrorActionPreference = "Stop"
try {
    # Obtener todas las políticas con detalle de distribución
    $policies = Get-RetentionCompliancePolicy -DistributionDetail
    $counter = 1
    foreach ($policy in $policies) {
        try {
            $header = "`nProcessing Policy #${counter}: $($policy.Name)"
            Write-Host $header
            $header | Out-File $outputFile -Append
            
            # Detalles de la política
            $policyDetails = $policy | Format-List Name, Guid, Mode, Enabled, SharePointLocation, OneDriveLocation, ExchangeLocation | Out-String
            $policyDetails | Out-File $outputFile -Append
            
            # ✅ Condición: Solo procesar si tiene SharePoint o OneDrive
            if ($policy.SharePointLocation -or $policy.OneDriveLocation) {
                $retentionRules = Get-RetentionComplianceRule -Policy $policy.Guid
                
                foreach ($retentionRule in $retentionRules) {
                    $ruleHeader = "`nLooking at ComplianceRule for RetentionCompliancePolicy: $($policy.Name)`n"
                    Write-Host $ruleHeader
                    $ruleHeader | Out-File $outputFile -Append
                    
                    # Detalles de la regla
                    $ruleDetails = $retentionRule | Format-List ComplianceTagProperty, ApplyComplianceTag, PublishComplianceTag, RetentionDurationDisplayHint, RetentionDuration, RetentionComplianceAction, Workload, Policy | Out-String
                    $ruleDetails | Out-File $outputFile -Append
                    
                    # ✅ Nueva lógica para Compliance Tags
                    if ($retentionRule.ComplianceTagProperty -or $retentionRule.ApplyComplianceTag) {
                        $tagIds = @()
                        # Si ComplianceTagProperty tiene valores, extraerlos
                        if ($retentionRule.ComplianceTagProperty) {
                            $tagValues = $retentionRule.ComplianceTagProperty -split ","
                            for ($i = 0; $i -lt $tagValues.Count; $i += 2) {
                                $tagId = $tagValues[$i].Trim()
                                if ($tagId) { $tagIds += $tagId }
                            }
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
            $errorMsg = "`n[ERROR] Ocurrió un problema con la política: $($policy.Name). Detalles: $($_.Exception.Message)`n"
            Write-Host $errorMsg -ForegroundColor Red
            $errorMsg | Out-File $outputFile -Append
        }
        
        $counter++
    }
}
catch {
    # Captura errores globales
    $globalError = "`n[CRITICAL ERROR] El script falló. Detalles: $($_.Exception.Message)`n"
       Write-Host $globalError -ForegroundColor Red
    $globalError | Out-File $outputFile -Append
}
