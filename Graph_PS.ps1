## Initialize variables (do not forget to put your tenant and app ids )

$Cert = (get-childitem 'Cert:\CurrentUser\My\' | Where-Object {$_.Subject -like "*Audit*"})
$TenantID = ""
$ClientID = ""
$authroot = "https://login.microsoftonline.com"
$resourceAppIdURI = "https://graph.microsoft.com"
$authority = "$authroot/$TenantID"

## Loading ADAL library from Azure AD PowerShell Module. 

$AadModule = Get-Module -Name "AzureAD" -ListAvailable
$adal = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
$adalforms = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll"
[System.Reflection.Assembly]::LoadFrom($adal) | Out-Null
[System.Reflection.Assembly]::LoadFrom($adalforms) | Out-Null
$authContext = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext" -ArgumentList $authority
$ClientCred = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.ClientAssertionCertificate" -ArgumentList ($ClientId, $Cert)
$authReturn = $authContext.AcquireTokenAsync($resourceAppIdURI,$ClientCred)
$authResult = $authReturn.Result

                                 $authHeader = @{

                                 'Content-Type'='application/json'

                                 'Authorization'="Bearer " + $authResult.AccessToken

                                 'ExpiresOn'=$authResult.ExpiresOn

                                 }          

## Initializing variables for search                                 
                                 
$BaseURI = "https://graph.microsoft.com/beta"
$SubURI = "/security/alerts"
$URI = "$BaseURI/$SubURI"
$Return = Invoke-RestMethod -Uri $URI -Headers $authHeader -Method Get -Verbose
$Return         

##   ## saving object to disk 
$Return | Export-Clixml -Path .\test.xml