#Installing and preparing modules

	[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12   Set-ExecutionPolicy Unrestricted   
	Install-Module PowershellGet -Force    
	Install-Module Microsoft.Graph -Scope AllUsers
	Install-Module Microsoft.Graph.authentication 
	
	#2. Connect to Graph modules with proper permissions
	Connect-MgGraph -Scopes "user.readwrite.all","Group.ReadWrite.All","Directory.AccessAsUser.All"
	
	#Get a csv with users if you don't want everything
	
	# 3. With CSV. File please make sure to notate the location of the file and it must have a column called "UserPrincipalName" 
	$CsvPath = "C:\Temp\usuarios_a_resetear.csv" #location can be changed
	
	 
	# 4. Define common password 
	
	$CommonPassword = "LaClaveCreadaParaLosUsuarios"
	# 5. Prepare password profile
	
	$PasswordProfile = @{
	   Password = $CommonPassword
	   ForceChangePasswordNextSignIn = $true
	}
	
	#6. With csv file, call CSV based on location variable and iterate each UPN
	
	Import-Csv -Path $CsvPath | ForEach-Object {
	   $UPN = $_.UserPrincipalName.Trim()
	   Write-Host "Procesando usuario: $UPN"
	   try {
	       Update-MgUser -UserId $UPN -PasswordProfile $PasswordProfile -Verbose
	       Revoke-MgUserSignInSession -UserId $UPN | Out-Null
	       Write-Host ("  ✓ Contraseña actualizada para {0}" -f $UPN) -ForegroundColor Green
	   }
	   catch {
	       Write-Host ("  ✗ Error actualizando {0}: {1}" -f $UPN, $_) -ForegroundColor Red
	   }
	}
	Write-Host "Proceso completado."
	
	
