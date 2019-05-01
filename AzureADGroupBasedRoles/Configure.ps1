# Enter your Run as account Service Principal ID
$SPId = "EnterYourServicePrincipalId"

# Connect to Azure AD
Connect-AzureAD 

# Get the associated Service Principal for the Azure Run As Account
$runAsServicePrincipal = Get-AzureADServicePrincipal -ObjectId $SPId


# Add the Service Principal to the Global Administrator Role
Add-AzureADDirectoryRoleMember -ObjectId (Get-AzureADDirectoryRole | where-object {$_.DisplayName -eq "Company Administrator"}).Objectid -RefObjectId $runAsServicePrincipal.ObjectId
