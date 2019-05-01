# Specify Group Prefix
$GroupPrefix = "sg-Role-"
# Get Azure Run As Connection Name
$connectionName = "AzureRunAsConnection"
# Exclude specific Roles from Assignment
$ExcludeRoles = @("User","Guest User")
# Exclude specific Roles from Assignment for example exclude your emergency account, so that it will never be removed through this script.
$ExcludeUsers = @("admin@aaaaaaa.onmicrosoft.com")
# Get the Service Principal connection details for the Connection name
$servicePrincipalConnection = Get-AutomationConnection -Name $connectionName         

# Logging in to Azure AD with Service Principal
"Logging in to Azure AD..."
Connect-AzureAD -TenantId $servicePrincipalConnection.TenantId `
    -ApplicationId $servicePrincipalConnection.ApplicationId `
    -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint


# Generate Groups if new Roles are available
$Roles = Get-AzureADDirectoryRole | Where-Object { $ExcludeRoles -notcontains $_.DisplayName }
foreach($Role in $Roles){
    "# $($Role.DisplayName)"
    $GroupName = "$GroupPrefix$($Role.DisplayName -replace " ", "`")"
    $CheckGrup = Get-AzureADGroup -Filter "DisplayName eq '$GroupName'" -ErrorAction SilentlyContinue
    if($null -eq $CheckGrup){
        Write-Warning "AAD Group '$GroupName' is missing."
    } else {
        $Members = Get-AzureADGroupMember -ObjectId $CheckGrup.ObjectId 
        $RoleMembers = Get-AzureADDirectoryRoleMember -ObjectId $Role.ObjectId
        #Add new accounts
        $NewMembers = $Members | Where-Object { ($RoleMembers.ObjectId) -notcontains $_.ObjectId }
        "New Members"
        ForEach($NewMember in $NewMembers) { 
            $NewMember
            Add-AzureADDirectoryRoleMember -ObjectId $Role.ObjectId -RefObjectId $NewMember.ObjectId 
        }
        #Remove old accounts
        "Remove Members"
        $RemoveMembers = $RoleMembers | Where-Object { ($Members.ObjectId) -notcontains $_.ObjectId -and $_.ObjectType -ne "ServicePrincipal" }
        foreach($RemoveMember in $RemoveMembers){ 
            #Only Remove member if it is not in the exclude list.
            if($ExcludeUsers -notcontains $RemoveMember.UserPrincipalName){
                $RemoveMember
                Remove-AzureADDirectoryRoleMember -ObjectId $Role.ObjectId -MemberId $RemoveMember.ObjectId 
            }
        }
    }
}


# Generate Groups if new Roles are available
$Roles = Get-AzureADDirectoryRoleTemplate | Where-Object { $ExcludeRoles -notcontains $_.DisplayName -and $_.Description -notlike "*do not use*" }
foreach($Role in $Roles){
    $GroupName = "$GroupPrefix$($Role.DisplayName -replace " ", "`")"
    $CheckGrup = Get-AzureADGroup -Filter "DisplayName eq '$GroupName'" -ErrorAction SilentlyContinue
    if($null -eq $CheckGrup){
        Enable-AzureADDirectoryRole -RoleTemplateId $Role.ObjectId
        new-azureadgroup -DisplayName $GroupName -SecurityEnabled $true -MailEnabled:$false -MailNickName $GroupName -Description $ROle.Description
    } 
}