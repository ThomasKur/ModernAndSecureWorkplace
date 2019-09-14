# Only monitor these types of devices ("mdm","eas","easMdm")
$managementAgents = @("mdm")


$VerbosePreference = "Continue"

#######
##
## Execution Engine
##
#######

# Where is the Script Executed (AzAutomation or PSScript local)
$global:ExecutionType = "PSScript"

## Config when AzAutomation
$global:AutomationAccountName = ""
$global:ResourceGroup = ""
$global:CredentialName = ""


## Config when PSScript
$Username = "admin@kurcontoso.onmicrosoft.com" 
# As SecureString "Read-Host -AsSecureString | ConvertFrom-SecureString"
$Password = "01000000d08c9ddf0115d1118c7a00c04fc297eb01000000583f3ebf0455b14980dee9283b6f5d400000000002000000000010660000000100002000000001b3623373333fc3ba9a86d8a908a1d63ab06a3ef6285f3e2d49dfa7fb3b6eac000000000e80000000020000200000002acb3aee6e518ae7f9c82b03a60c4dcc0e585385e8c3498753a2641a49dfcd0d20000000be7bd979005afa4c05cc816ef72db4ce696fb68279257c8b4f6613c4663ee46040000000a8613faca4c5a03e1d90cc079dca1da1517ed176c06154f51b642c55173e5694615949325799704e7d447bcf20a1d40bbae6a8f5fb97848f26b1dafbaba8ff78"
$RegistryKey = "HKLM:\SOFTWARE\Customer\IntuneAlert"

#######
##
## Action
##
#######

## Splunk Event
$token = "C3ABEA0B-1439-4070-AA51-7216E2DB3105"
$url = "http://SERVER:PORT/services/collector/event"

## Invoke Webrequest
## Sends complete Device Object a



$CurrentExecutionTime = (Get-Date).ToUniversalTime()
Write-Verbose "Use current execution time ($CurrentExecutionTime)"

#Get Last Execution 
$LastExecutionTime = Get-AlertLastExecutionTime -CurrentExecutionTime $CurrentExecutionTime

# Get Credentials
if($global:ExecutionType -eq "PSScript"){
    Write-Verbose "Generating PSCred from Password and Username"
    $creds = New-Object System.Management.Automation.PSCredential ($Username,($Password | ConvertTo-SecureString))
} else {
    Write-Verbose "Load PSCred $global:CredentialName"
    $creds = Get-AutomationPSCredential -Name $global:CredentialName
}


Write-Verbose "Connecting to Intune"
$Tenant = Connect-MSGraph -PSCredential $creds

Write-Verbose "Connected to $($Tenant.TenantId) with $($Tenan.UPN)"

Write-Verbose "Loading non-compliant devices"
$NonCompliantDevices = ,(Get-IntuneManagedDevice -Filter "complianceState eq 'noncompliant'")
Write-Verbose "Found $($NonCompliantDevices.Count) non-compliant devices"
Write-Verbose "Filter on ManagementAgent and Timerange"
$NewAlerts = ,($NonCompliantDevices | Where-Object { $managementAgents -contains $_.managementAgent -and $_.complianceGracePeriodExpirationDateTime -gt $LastexecutionTime -and $_.complianceGracePeriodExpirationDateTime -le $CurrentExecutionTime })
Write-Verbose "$($NewAlerts.Count) new alerts to raise" 

ForEach($alert in $NewAlerts){
    $alert
}

 
Set-AlertLastExecutionTime -CurrentExecutionTime $CurrentExecutionTime

function Get-AlertLastExecutionTime {
    param(
        [DateTime]$CurrentExecutionTime
    )
    if($global:ExecutionType  -eq "PSScript"){
        $LastExecutionTime = Get-ItemPropertyValue -Path HKLM:\SOFTWARE\Customer\IntuneAlert -Name "LastExecutionTime" -ErrorAction SilentlyContinue
    } else { 
        try{
            $LastExecutionTime = Get-AzureRmAutomationVariable -AutomationAccountName $global:AutomationAccountName -Name "IntuneMonitoring-LastExecution" -ResourceGroupName $global:ResourceGroup
        } catch {
            Write-Error "Failed to get Last Execution" 
        }
        if($null -eq $LastExecutionTime){
            New-AzureRmAutomationVariable -AutomationAccountName $global:AutomationAccountName -Name "IntuneMonitoring-LastExecution" -ResourceGroupName $global:ResourceGroup -Encrypted $False -Value $CurrentExecutionTime.AddMinutes(-5)
        }
    }

    if($null -eq $LastExecutionTime){
        $LastExecutionTime = $CurrentExecutionTime.AddMinutes(-5)
        Write-Verbose "Last Execution not found, using current datetime minus 5 minutes ($LastExecutionTime)."
    }
    Write-Verbose "Use last execution time ($LastExecutionTime)"
    return [DateTime]$LastExecutionTime
}

function Set-AlertLastExecutionTime {
    param(
        [DateTime]$CurrentExecutionTime
    )
    if($global:ExecutionType  -eq "PSScript"){
        if(-not (Test-Path $RegistryKey)){
            New-Item -Path $RegistryKey -Force
        }
        Set-ItemProperty -Path $RegistryKey -Name "LastExecutionTime" -Value $CurrentExecutionTime -Force -ErrorAction Stop
    } else { 
        Set-AzureRmAutomationVariable -AutomationAccountName $global:AutomationAccountName -Name "IntuneMonitoring-LastExecution" -ResourceGroupName $global:ResourceGroup -Value $CurrentExecutionTime -ErrorAction Stop
    }
    Write-Verbose "Successfully set last execution time ($CurrentExecutionTime)"
}

function Add-AlertToSplunk {
    param(
        $IntuneDevice
    )  
    $eventObj = @{
        host = $IntuneDevice.deviceName
        source = "Intune"
        sourcetype = "Compliance"
        event = $IntuneDevice
        }
    $header = @{Authorization = "Splunk $token"}
    $event = $eventObj | ConvertTo-Json -Depth 2
    Invoke-RestMethod -Method Post -Uri $url -Headers $header -Body $event

 }