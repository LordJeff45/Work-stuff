<# 
  =========================
  Connect to Microsoft Graph
  =========================
#>
Import-Module Microsoft.Graph

Connect-MgGraph -Scopes "Policy.ReadWrite.ConditionalAccess","Application.Read.All"

<# 
  =========================
  Get Data Classification Service AppId
  =========================
#>
$dcsSp = Get-MgServicePrincipal -Filter "displayName eq 'Data Classification Service'" -ConsistencyLevel eventual

if (-not $dcsSp) {
    throw "Service principal 'Microsoft Data Classification Service' not found. Adjust display name filter."
}

$dcsAppId = $dcsSp.AppId
Write-Host "Data Classification Service AppId: $dcsAppId"
Write-Host ""

<# 
 =========================
 Get all Conditional Access Policies
  =========================
#>
$policies = Get-MgIdentityConditionalAccessPolicy -All

foreach ($p in $policies) {

    Write-Host "------------------------------"
    Write-Host "Processing: $($p.DisplayName)"

    <# 
      =========================
     OPTIONAL (required here): Skip policies NOT targeting "All cloud apps"
      =========================
    #>
    $includeApps = @($p.Conditions.Applications.IncludeApplications)

    if (-not ($includeApps -contains "All")) {
        Write-Host "SKIP (Not targeting 'All cloud apps')"
        continue
    }

    <# 
      =========================
      OPTIONAL: Skip policies that use password reset control (avoid your error)
       =========================
    if ($p.GrantControls -and ($p.GrantControls.BuiltInControls -contains "passwordReset")) {
        Write-Host "SKIP (passwordReset control present - known Graph validation issue)"
        continue
    }#>

    <# 
       =========================
       Build exclusion list
       =========================
    #>
    $excludeApps = @()

    if ($p.Conditions.Applications.ExcludeApplications) {
        $excludeApps = @($p.Conditions.Applications.ExcludeApplications)
    }

    if ($excludeApps -contains $dcsAppId) {
        Write-Host "SKIP (Already excluded)"
        continue
    }

    $newExclude = $excludeApps + $dcsAppId

    Write-Host "Updating policy..."

    <# 
     =========================
     PATCH (Minimal payload only)
      =========================
    #>
    $body = @{
        conditions = @{
            applications = @{
                excludeApplications = $newExclude
            }
        }
    } | ConvertTo-Json -Depth 10

    $uri = "https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies/$($p.Id)"

    try {
        Invoke-MgGraphRequest -Method PATCH -Uri $uri -Body $body -ContentType "application/json"
        Write-Host "SUCCESS"
    }
    catch {
        Write-Host "FAILED"
        Write-Host $_.Exception.Message
    }
}