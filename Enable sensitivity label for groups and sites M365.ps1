Connect-IPPSSession -EnableSearchOnlySession ;; Execute-AzureAdLabelSync

#In case this fails, run this:

Install-Module Microsoft.Graph -Scope CurrentUser
Install-Module Microsoft.Graph.Beta -Scope CurrentUser

$grpUnifiedSetting = Get-MgBetaDirectorySetting | Where-Object { $_.Values.Name -eq "EnableMIPLabels" }
$grpUnifiedSetting.Values

#if the commands provide no output, run this:

Get-MgBetaDirectorySettingTemplate
$TemplateId = (Get-MgBetaDirectorySettingTemplate | where { $_.DisplayName -eq "Group.Unified" }).Id
$Template = Get-MgBetaDirectorySettingTemplate | where -Property Id -Value $TemplateId -EQ
#keep this as exact as possible
$params = @{
   templateId = "$TemplateId"
   values = @(
      @{
         name = "UsageGuidelinesUrl"
         value = "https://guideline.example.com"
      }
      @{
         name = "EnableMIPLabels"
         value = "True"
      }
   )
}
New-MgBetaDirectorySetting -BodyParameter $params
$Setting = Get-MgBetaDirectorySetting | where { $_.DisplayName -eq "Group.Unified"}
$Setting.Values

#in case it is not empty, run this:
$params = @{
     Values = @(
 	    @{
 		    Name = "EnableMIPLabels"
 		    Value = "True"
 	    }
     )
}

Update-MgBetaDirectorySetting -DirectorySettingId $grpUnifiedSetting.Id -BodyParameter $params

$Setting = Get-MgBetaDirectorySetting -DirectorySettingId $grpUnifiedSetting.Id
$Setting.Values