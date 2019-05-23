## Initialize variables (do not forget to put your tenant and app ids )

$Cert = (get-childitem 'Cert:\CurrentUser\My\' | Where-Object {$_.Subject -like "*Audit*"})
$TenantID = ""
$ClientID = ""
$authroot = "https://login.windows.net/$TenantID/OAuth2/token"
$resourceAppIdURI = "https://manage.office.com"
$authority = "$authroot/$TenantID"

## Loading ADAL library from Azure AD PowerShell Module. 

$AadModule = Get-Module -Name "AzureAD" -ListAvailable
$adal = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
$adalforms = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll"
[System.Reflection.Assembly]::LoadFrom($adal) | Out-Null
[System.Reflection.Assembly]::LoadFrom($adalforms) | Out-Null

## getting Auth token

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
                                 
$Return = ""
$Content = ""

$source = ("Audit.AzureActiveDirectory","Audit.Exchange","Audit.SharePoint","Audit.General","DLP.All")     

$result = @()                            

$BaseURI = "https://manage.office.com/api/v1.0/$TenantID/activity/feed"

$source | ForEach-Object {
    for ($i = 0; $i -lt "6";$i++)
        {
        $startday = (Get-Date (Get-Date).AddDays(-$i-1) -UFormat %d)
        $endday = (Get-Date (Get-Date).AddDays(-$i) -UFormat %d)
        $SubURI = "subscriptions/content?contentType="+$_+"&startTime=2019-05-"+$startday+"&endTime=2019-05-"+$endday
        $URI = "$BaseURI/$SubURI"
        $Return = Invoke-RestMethod -Uri $URI -Headers $authHeader -Method Get 
        if ($Return) 
            { $Return | ForEach-Object {
                $Content = Invoke-RestMethod -Uri $_.ContentUri -Headers $authHeader -Method get -Verbose
                $result = $result+$Content 
                }
            }
        }
    }

    $result.Count
   
   ## saving object to disk 

   $result | Export-Clixml -Path .\result.xml
