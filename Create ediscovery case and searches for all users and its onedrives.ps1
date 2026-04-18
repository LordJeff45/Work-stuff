#requires -Modules ExchangeOnlineManagement, Microsoft.Online.SharePoint.PowerShell

Import-Module ExchangeOnlineManagement
Import-Module Microsoft.Online.SharePoint.PowerShell


# -----------------------------
# 1) Conexiones
# -----------------------------
Connect-ExchangeOnline

# IMPORTANTE: para eDiscovery / Compliance Search en Purview
Connect-IPPSSession -EnableSearchOnlySession  # requerido para algunos cmdlets de eDiscovery según cambios recientes [4](https://m365admin.handsontek.net/microsoft-purview-ediscovery-cmdlet-connectivity-change/)

# Conexión a SharePoint Admin para consultar OneDrive sites (personal sites)
# Cambia "tenantname" por tu tenant
$SPOAdminUrl = "https://mngenvmcap696787-admin.sharepoint.com"
Connect-SPOService -Url $SPOAdminUrl -UseSystemBrowser $true
# -----------------------------
# 2) Crear el caso
# -----------------------------
$CaseName = "Caso-eDiscovery-" + (Get-Date -Format "yyyyMMdd-HHmmss")
New-ComplianceCase -Name $CaseName
Write-Host "Caso creado: $CaseName"

# -----------------------------
# 3) Obtener buzones
# -----------------------------
$Mailboxes = Get-ExoMailbox -RecipientTypeDetails UserMailbox -ResultSize Unlimited
Write-Host "Total de buzones: $($Mailboxes.Count)"

# Opcional: cachear la lista de OneDrive sites para no llamar Get-SPOSite por cada usuario (mejor performance)
Write-Host "Cargando lista de OneDrive sites (personal sites)..."
$OneDriveSites = Get-SPOSite -IncludePersonalSite:$true -Limit All `
    -Filter "Url -like '-my.sharepoint.com/personal/'" |
    Select-Object Url, Owner

# Logs
$LogRoot = Join-Path $PWD ("eDiscoveryRun-" + (Get-Date -Format "yyyyMMdd-HHmmss"))
New-Item -ItemType Directory -Path $LogRoot -Force | Out-Null
$MissingOneDriveLog = Join-Path $LogRoot "UsersWithoutOneDrive.csv"
$ErrorsLog         = Join-Path $LogRoot "Errors.csv"

"UserPrincipalName,Alias,Reason" | Out-File $MissingOneDriveLog -Encoding UTF8
"UserPrincipalName,Alias,Stage,Error" | Out-File $ErrorsLog -Encoding UTF8

# -----------------------------
# 4) Crear búsquedas dentro del caso (una por buzón)
#    Exchange + OneDrive (URL personal) del mismo usuario
# -----------------------------
foreach ($mbx in $Mailboxes) {

    $User = $mbx.UserPrincipalName
    $Alias = $mbx.Alias
    $SearchName = "Busqueda-$Alias-" + (Get-Date -Format "yyyyMMddHHmmss")

    Write-Host "`nProcesando: $User"

    try {
        # Buscar el OneDrive URL del usuario (OneDrive = personal SharePoint site)
        $od = $OneDriveSites | Where-Object { $_.Owner -eq $User } | Select-Object -First 1

        if (-not $od -or [string]::IsNullOrWhiteSpace($od.Url)) {
            # No existe OneDrive (aún), crear búsqueda solo Exchange
            Write-Host "  OneDrive no encontrado para $User. Creando búsqueda SOLO Exchange..."
            "$User,$Alias,OneDriveNotFound" | Out-File $MissingOneDriveLog -Append -Encoding UTF8

            New-ComplianceSearch `
                -Name $SearchName `
                -Case $CaseName `
                -ExchangeLocation $User `
                -ContentMatchQuery ""  # vacío = todo el contenido

        } else {
            # Crear búsqueda Exchange + OneDrive URL (en SharePointLocation)
            Write-Host "  OneDrive URL: $($od.Url)"
            Write-Host "  Creando búsqueda Exchange + OneDrive..."

            New-ComplianceSearch `
                -Name $SearchName `
                -Case $CaseName `
                -ExchangeLocation $User `
                -SharePointLocation $od.Url `
                -ContentMatchQuery ""
        }

        Start-ComplianceSearch -Identity $SearchName
        Write-Host "  Búsqueda iniciada: $SearchName"
    }
    catch {
        $err = $_.Exception.Message.Replace("`r"," ").Replace("`n"," ")
        Write-Host "  ERROR: $err" -ForegroundColor Red
        "$User,$Alias,CreateOrStartSearch,""$err""" | Out-File $ErrorsLog -Append -Encoding UTF8
        continue
    }

    Start-Sleep -Milliseconds 300  # opcional: pequeña pausa para evitar throttling
}

Write-Host "`nListo. Logs en: $LogRoot"
Write-Host " - Sin OneDrive: $MissingOneDriveLog"
Write-Host " - Errores:      $ErrorsLog"
