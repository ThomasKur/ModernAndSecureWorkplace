# This script is only for internal Notes on how to get the newest settings
Connect-MSGraph

#Custom Policies
$AllPolicies = Get-DeviceManagement_DeviceConfigurations 
$CustomPolicies = $AllPolicies | Where-Object { $_.'@odata.type' -eq "#microsoft.graph.windows10CustomConfiguration"}
foreach($CustomPolicy in $CustomPolicies){
    $CustomPolicy.omaSettings | Out-File -FilePath ".\Custom\$($CustomPolicy.displayName).json"
}
$EPPolicies = $AllPolicies | Where-Object { $_.'@odata.type' -eq "#microsoft.graph.windows10EndpointProtectionConfiguration"}
foreach($EPPolicy in $EPPolicies){
    $JSON = $EPPolicy | Select-Object -Property * -ExcludeProperty @("deviceConfigurationId","deviceConfigurationODataType","windows10EndpointProtectionConfigurationReferenceUrl","version","displayName","description","createdDateTime","lastModifiedDateTime","id","@odata.type") | ConvertTo-Json 
    $JSON | Out-File -FilePath ".\EndpointProtection\$($EPPolicy.displayName).json"
}
