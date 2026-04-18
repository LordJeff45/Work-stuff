#from <https://learn.microsoft.com/en-us/powershell/exchange/find-exchange-cmdlet-permissions?view=exchange-ps> 

# $cmdlet_to_check = "Write cmdlet before running" #<Cmdlet> [-CmdletParameters <Parameter1>,<Parameter2>,...]

Connect-ExchangeOnline
$Perms = Get-ManagementRole -Cmdlet $cmdlet_to_check
$Perms | foreach {Get-ManagementRoleAssignment -Role $_.Name -Delegating $false | Format-Table -Auto Role,RoleAssigneeType,RoleAssigneeName}


