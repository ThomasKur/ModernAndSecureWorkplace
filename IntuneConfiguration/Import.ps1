$Prefix = "W10-SecBaseline1909-"
$Version = "001"
$JsonLocation = "."


$obj = Get-DeviceManagement_DeviceConfigurations | Out-GridView -OutputMode Single
$obj.omaSettings | Out-File -FilePath "$JsonLocation\WinSecBaseline1909-AuditPolicy.json"

Update-MSGraphEnvironment -SchemaVersion 'beta'
Connect-MSGraph
$CustomPolicies = Get-ChildItem ".\Custom\*.json" -File
foreach($CustomPolicy in $CustomPolicies){
    $Json = Get-Content -Path $CustomPolicy.FullName
    New-DeviceManagement_DeviceConfigurations -windows10CustomConfiguration -displayName $CustomPolicy.Name.Replace('.json','') -omaSettings $Json
}

$EPPolicies = Get-ChildItem ".\EndpointProtection\*.json" -File
foreach($EPPolicy in $EPPolicies){
    $Json = Get-Content -Path $EPPolicy.FullName
    $ht2 = @{}
    ($Json | ConvertFrom-Json).psobject.properties | Foreach-Object { if($null -ne $_.Value){$ht2[$_.Name] = $_.Value} }
    if($null -ne $ht2["defenderExploitProtectionXml"]){
        [Object[]]$ht2["defenderExploitProtectionXml"] = [System.Convert]::FromBase64String($ht2["defenderExploitProtectionXml"])
    }
    New-DeviceManagement_DeviceConfigurations -windows10EndpointProtectionConfiguration -displayName "$($EPPolicy.Name.Replace('.json',''))2" @ht2
}

Update-MSGraphEnvironment -SchemaVersion 'beta'
$Policies = Invoke-MSGraphRequest -HttpMethod GET -Url "/deviceManagement/groupPolicyConfigurations"

foreach($Policy in $Policies){
    $return = @()
    $values = Invoke-MSGraphRequest -HttpMethod GET -Url "/deviceManagement/groupPolicyConfigurations/$($Policy.Value.Id)/definitionValues"
    foreach($value in $values.value){
        $definition = (Invoke-MSGraphRequest -HttpMethod GET -Url "/deviceManagement/groupPolicyConfigurations/$($Policy.Value.Id)/definitionValues/$($value.id)/definition")
        $value
        $res = Invoke-MSGraphRequest -HttpMethod GET -Url "/deviceManagement/groupPolicyConfigurations/$($Policy.Value.Id)/definitionValues/$($value.id)/presentationValues"
        $res.value
        $return += [PSCustomObject]@{ 
            DisplayName = $definition.displayName
            ExplainText = $definition.explainText
            Scope = $definition.classType
            Path = $definition.categoryPath
            SupportedOn = $definition.supportedOn
            Value = $res.value.value
            Enabled = $value.enabled
        }
    }
}
Update-MSGraphEnvironment -SchemaVersion v1.0