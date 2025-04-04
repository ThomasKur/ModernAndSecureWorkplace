<#
.DESCRIPTION
This Script will help you build a pilot collection with a good distribution regarding of hardware models and applications.

.EXAMPLE
Invoke-PilotDeviceSelection

.NOTES
Author: Thomas Kurth / baseVISION
Date:   12.3.2021

History
    001: First Version

#>
[CmdletBinding()]
Param(
)
## Manual Variable Definition
########################################################

# MSGraph Access
##############

$clientId = "18851d85-b91b-4dd7-b2d7-a36d7c81cea5"
$tenantId = "d953f17a-73a2-4ccf-9d36-67b8383ab99a"
$authcert = Get-Item Cert:\CurrentUser\My\B6B38C1E0D61B595A8E723F9F61212B9ECC045AF



# Groups
##############

# Define a group which contains all devices which should be
# in focus for the pilot. Only apps installed on these devices and 
# hardware models of these devices will be used for the calculation.
$AADGroupId_InScope = "ee2fbcf2-37e1-4bb6-9892-72f94b3f5cae"

# Define the group where the pilot devices should be added. During testing you can just specify 
# a new empty group.
$AADGroupId_Pilot = "f6bf1821-9ed5-4012-a7fd-a331ac404fb9"

# Optionally you can define a group which contains devises which
# are in earlier stages already targeted. These devices (the apps
# installed and hardware models) will be marked as already tested. 
$AADGroupId_Insider = "7eed8520-dbbb-4c0b-9d0c-7591ffea11ea"



# Model Selection
##############

# How many devices per model should be in Pilot ring?
$DevicesPerModel = 1

# How man devices of a model need to be in use to be in focus for the pilot?
$MinDeviceModelCount = 1


# App Selection
##############

# How many devices per app should be in Pilot ring?
$DevicesPerApp = 1

# How man installations of a app are need to be in focus for the pilot?
$MinInstallCount = 1

# Do you want to exclude specific apps? Specify the exact name as the app is written in the detectedApps.
$ExcludedApps = @("microsoft.windowscommunicationsapps")


# Other Configs
##############
$DefaultLogOutputMode  = "Both"
$DebugPreference = "Continue"

$LogFilePathFolder     = "C:\Windows\Logs\"
$LogFilePathScriptName = "Invoke-PilotDeviceSelection"            # This is only used if the filename could not be resolved(IE running in ISE)
$FallbackScriptPath    = "C:\Program Files\baseVISION" # This is only used if the filename could not be resolved(IE running in ISE)

#region Functions
########################################################

function Write-Log {
    <#
    .DESCRIPTION
    Write text to a logfile with the current time.

    .PARAMETER Message
    Specifies the message to log.

    .PARAMETER Type
    Type of Message ("Info","Debug","Warn","Error").

    .PARAMETER OutputMode
    Specifies where the log should be written. Possible values are "Console","LogFile" and "Both".

    .PARAMETER Exception
    You can write an exception object to the log file if there was an exception.

    .EXAMPLE
    Write-Log -Message "Start process XY"

    .NOTES
    This function should be used to log information to console or log file.
    #>
    param(
        [Parameter(Mandatory=$true,Position=1)]
        [String]
        $Message
    ,
        [Parameter(Mandatory=$false)]
        [ValidateSet("Info","Debug","Warn","Error")]
        [String]
        $Type = "Debug"
    ,
        [Parameter(Mandatory=$false)]
        [ValidateSet("Console","LogFile","Both")]
        [String]
        $OutputMode = $DefaultLogOutputMode
    ,
        [Parameter(Mandatory=$false)]
        [Exception]
        $Exception
    )
    
    $DateTimeString = Get-Date -Format "yyyy-MM-dd HH:mm:sszz"
    $Output = ($DateTimeString + "`t" + $Type.ToUpper() + "`t" + $Message)
    
    if ($OutputMode -eq "Console" -OR $OutputMode -eq "Both") {
        if($Type -eq "Error"){
            Write-Error $output
            if($Exception){
               Write-Error ("[" + $Exception.GetType().FullName + "] " + $Exception.Message)
            }
        } elseif($Type -eq "Warn"){
            Write-Warning $output
            if($Exception){
               Write-Warning ("[" + $Exception.GetType().FullName + "] " + $Exception.Message)
            }
        } elseif($Type -eq "Debug"){
            Write-Debug $output
            if($Exception){
               Write-Debug ("[" + $Exception.GetType().FullName + "] " + $Exception.Message)
            }
        } else{
            Write-Verbose $output -Verbose
            if($Exception){
               Write-Verbose ("[" + $Exception.GetType().FullName + "] " + $Exception.Message) -Verbose
            }
        }
    }
    
    if ($OutputMode -eq "LogFile" -OR $OutputMode -eq "Both") {
        try {
            Add-Content $LogFilePath -Value $Output -ErrorAction Stop
            if($Exception){
               Add-Content $LogFilePath -Value ("[" + $Exception.GetType().FullName + "] " + $Exception.Message) -ErrorAction Stop
            }
        } catch {
        }
    }
}
function New-Folder{
    <#
    .DESCRIPTION
    Creates a Folder if it's not existing.

    .PARAMETER Path
    Specifies the path of the new folder.

    .EXAMPLE
    CreateFolder "c:\temp"

    .NOTES
    This function creates a folder if doesn't exist.
    #>
    param(
        [Parameter(Mandatory=$True,Position=1)]
        [string]$Path
    )
	# Check if the folder Exists

	if (Test-Path $Path) {
		Write-Log "Folder: $Path Already Exists"
	} else {
		New-Item -Path $Path -type directory | Out-Null
		Write-Log "Creating $Path"
	}
}
function Set-RegValue {
    <#
    .DESCRIPTION
    Set registry value and create parent key if it is not existing.

    .PARAMETER Path
    Registry Path

    .PARAMETER Name
    Name of the Value

    .PARAMETER Value
    Value to set

    .PARAMETER Type
    Type = Binary, DWord, ExpandString, MultiString, String or QWord

    #>
    param(
        [Parameter(Mandatory=$True)]
        [string]$Path,
        [Parameter(Mandatory=$True)]
        [string]$Name,
        [Parameter(Mandatory=$True)]
        [AllowEmptyString()]
        $Value,
        [Parameter(Mandatory=$True)]
        [string]$Type
    )
    
    try{
        $ErrorActionPreference = 'Stop' # convert all errors to terminating errors


	   if (Test-Path $Path -erroraction silentlycontinue) {      
 
        } else {
            New-Item -Path $Path -Force -ErrorAction Stop
            Write-Log "Registry key $Path created"  
        } 
    
        $null = New-ItemProperty -Path $Path -Name $Name -PropertyType $Type -Value $Value -Force -ErrorAction Stop
        Write-Log "Registry Value $Path, $Name, $Type, $Value set"
    } catch {
        throw "Registry value not set $Path, $Name, $Value, $Type ($($_.Exception))"
    }
}
function Set-ExitMessageRegistry () {
    <#
    .DESCRIPTION
    Write Time and ExitMessage into Registry. This is used by various reporting scripts and applications like ConfigMgr or the OSI Documentation Script.

    .PARAMETER Scriptname
    The Name of the running Script

    .PARAMETER LogfileLocation
    The Path of the Logfile

    .PARAMETER ExitMessage
    The ExitMessage for the current Script. If no Error set it to Success

    #>
    param(
    [Parameter(Mandatory=$True)]
    [string]$Scriptname,
    [Parameter(Mandatory=$True)]
    [string]$LogfileLocation,
    [Parameter(Mandatory=$True)]
    [string]$ExitMessage
    )

    $DateTime = Get-Date –f o
    #The registry Key into which the information gets written must be checked and if not existing created
    if((Test-Path "HKLM:\SOFTWARE\_Custom") -eq $False)
    {
        $null = New-Item -Path "HKLM:\SOFTWARE\_Custom"
    }
    if((Test-Path "HKLM:\SOFTWARE\_Custom\Scripts") -eq $False)
    {
        $null = New-Item -Path "HKLM:\SOFTWARE\_Custom\Scripts"
    }
    try { 
        #The new key gets created and the values written into it
        $null = New-Item -Path "HKLM:\SOFTWARE\_Custom\Scripts\$Scriptname" -Force -ErrorAction Stop
        $null = New-ItemProperty -Path "HKLM:\SOFTWARE\_Custom\Scripts\$Scriptname" -Name "Scriptname" -Value "$Scriptname" -Force -ErrorAction Stop
        $null = New-ItemProperty -Path "HKLM:\SOFTWARE\_Custom\Scripts\$Scriptname" -Name "Time" -Value "$DateTime" -Force -ErrorAction Stop
        $null = New-ItemProperty -Path "HKLM:\SOFTWARE\_Custom\Scripts\$Scriptname" -Name "ExitMessage" -Value "$ExitMessage" -Force -ErrorAction Stop
        $null = New-ItemProperty -Path "HKLM:\SOFTWARE\_Custom\Scripts\$Scriptname" -Name "LogfileLocation" -Value "$LogfileLocation"  -Force -ErrorAction Stop
    } catch { 
        Write-Log "Set-ExitMessageRegistry failed" -Type Error -Exception $_.Exception
        #If the registry keys can not be written the Error Message is returned and the indication which line (therefore which Entry) had the error
        $Error[0].Exception
        $Error[0].InvocationInfo.PositionMessage
    }
}
Function Invoke-DocGraph(){
    <#
    .SYNOPSIS
    This function Requests information from Microsoft Graph
    .DESCRIPTION
    This function Requests information from Microsoft Graph and returns the value as Object[]
    .EXAMPLE
    Invoke-DocGraph -url ""
    Returns "Type"
    .NOTES
    NAME: Thomas Kurth 3.3.2021
    #>
    [OutputType('System.Object[]')]
    [cmdletbinding()]
    param
    (
        [Parameter(Mandatory=$true,ParameterSetName = "FullPath")]
        $FullUrl,

        [Parameter(Mandatory=$true,ParameterSetName = "Path")]
        [string]$Path,

        [Parameter(Mandatory=$false,ParameterSetName = "Path")]
        [string]$BaseUrl = "https://graph.microsoft.com/",

        [Parameter(Mandatory=$false,ParameterSetName = "Path")]
        [switch]$Beta,

        [Parameter(Mandatory=$false,ParameterSetName = "Path")]
        [Microsoft.Identity.Client.AuthenticationResult]$Token,

        [Parameter(Mandatory=$false,ParameterSetName = "Path")]
        [string]$AcceptLanguage

    )
    if($PSCmdlet.ParameterSetName -eq "Path"){
        if($Beta){
            $version = "beta"
        } else {
            $version = "v1.0"
        }
        $FullUrl = "$BaseUrl$version$Path"
    }

    try{
        $header = @{Authorization = "Bearer $($token.AccessToken)"}
        if($AcceptLanguage){
            $header.Add("Accept-Language",$AcceptLanguage)
        }
        [System.Collections.Generic.List[PSObject]]$Collection = @()
        $NextLink = $FullUrl

        do {
            $Result = Invoke-RestMethod -Headers $header -Uri $NextLink -Method Get -ErrorAction Stop
            if($Result.'@odata.count'){
                $Result.value | ForEach-Object{$Collection.Add($_)}
            } else {
                if($Result.value){
                    $Collection.Add($Result.value)
                } else {
                    $Collection.Add($Result)
                }
            }
            $NextLink = $Result.'@odata.nextLink'
        } while ($NextLink)

    } catch {
        
        if($_.Exception.Response.StatusCode -eq "Forbidden"){
            throw "Used application does not have sufficiant permission to access: $FullUrl"
        } else {
            Write-Error $_
        }
    }

    return $Collection
}
#endregion

#region Dynamic Variables and Parameters
########################################################

# Try get actual ScriptName
try{
    $ScriptNameTemp = $MyInvocation.MyCommand.Name
    If($ScriptNameTemp -eq $null -or $ScriptNameTemp -eq ""){
        $ScriptName = $LogFilePathScriptName
    } else {
        $ScriptName = $ScriptNameTemp
    }
} catch {
    $ScriptName = $LogFilePathScriptName
}
$LogFilePath = "$LogFilePathFolder\{0}_{1}.log" -f ($ScriptName -replace ".ps1", ''),(Get-Date -uformat %Y%m%d%H%M)
# Try get actual ScriptPath
try{
    $ScriptPathTemp = Split-Path $MyInvocation.InvocationName
    If($ScriptPathTemp -eq $null -or $ScriptPathTemp -eq ""){
        $ScriptPath = $FallbackScriptPath
    } else {
        $ScriptPath = $ScriptPathTemp
    }
} catch {
    $ScriptPath = $FallbackScriptPath
}

#endregion

#region Initialization
########################################################

New-Folder $LogFilePathFolder
Write-Log "Start Script $Scriptname"


Write-Log "Start Authentication"
$token = Get-MsalToken -ClientId $clientId -ClientCertificate $authcert -TenantId $tenantId 
Write-Log "Aquired token expires on $($token.ExpiresOn)"

#Collect Data
Write-Log "Start Collecting information from MSGraph"
$detectedApps = Invoke-DocGraph -Token $token -Path "/deviceManagement/detectedApps" -Beta | Where-Object { $ExcludedApps -notcontains $_.displayName -and $_.deviceCount -gt $MinInstallCount }
Write-Log "Found $($detectedApps.Count) detected apps"
$insiderdevices = Invoke-DocGraph -Token $token -Path "/groups/$AADGroupId_Insider/members?`$select=id,model,manufacturer,deviceId" -Beta | Where-Object { $_.'@odata.type' -eq "#microsoft.graph.device" }
Write-Log "Found $($insiderdevices.Count) insider devices"
$existingpilotdevices = Invoke-DocGraph -Token $token -Path "/groups/$AADGroupId_Pilot/members?`$select=id,model,manufacturer,deviceId" -Beta | Where-Object { $_.'@odata.type' -eq "#microsoft.graph.device" }
Write-Log "Found $($existingpilotdevices.Count) existing pilot devices"
$inscopedevices = Invoke-DocGraph -Token $token -Path "/groups/$AADGroupId_InScope/members?`$select=id,model,manufacturer,displayName,deviceId" -Beta | Where-Object { $_.'@odata.type' -eq "#microsoft.graph.device" }
Write-Log "Found $($inscopedevices.Count) in scope devices"
$alldevices = Invoke-DocGraph -Token $token -Path "/deviceManagement/managedDevices" -Beta
Write-Log "Found $($alldevices.Count) managed devcies in the tenant"

#endregion

#region Main Script
########################################################


#Prepare Install Counts
Write-Log "Elaborate Installation Counts"
$appRelationships = @()
foreach($detectedApp in $detectedApps){
    $devices = Invoke-DocGraph -Token $token -Path "/deviceManagement/detectedApps/$($detectedApp.id)/managedDevices" -Beta | Where-Object { $_.operatingSystem -eq "Windows" }
    $detectedApp | Add-Member -Name devices -MemberType NoteProperty -Value @() -Force
    $detectedApp | Add-Member -Name pilotDevicesCount -MemberType NoteProperty -Value 0 -Force
    foreach($device in $devices){
        $d = $alldevices | Where-Object {$_.id -eq $device.id }
        $appRelationships += [PSCustomObject]@{
            DeviceId     = $d.azureADDeviceId
            AppId = $detectedApp.id
        }
        
        $d2 = $inscopedevices | Where-Object {$_.deviceId -eq $d.azureADDeviceId }
        $detectedApp.devices +=$d2
        if($d2.detectedAppCount){
            $d2.detectedAppCount += 1
        } else {
            $d2 | Add-Member -Name detectedAppCount -MemberType NoteProperty -Value 1 -Force
            $d2 | Add-Member -Name ring -MemberType NoteProperty -Value "" -Force
        }
    }
}
Write-Log "Found $($appRelationships.Count) app relationships"

#Prepare Model Counts
Write-Log "Elaborate Models Counts"
$models = $inscopedevices | Group-Object -Property Manufacturer,Model
foreach($model in $models){
    $model | Add-Member -Name pilotDevicesCount -MemberType NoteProperty -Value 0 -Force 
}


# Process Insider Devices
Write-Log "Process insider devices and raise pilot count by 1 on the models and apps"
foreach($insiderdevice in $insiderdevices){
    $model = $models | Where-Object { $_.Values -contains $insiderdevice.Manufacturer -and $_.Values -contains $insiderdevice.Model }
    $model.pilotDevicesCount += 1


    foreach($app in ($appRelationships | Where-Object { $_.DeviceId -eq $insiderdevice.deviceId } )){
        $detectedApp = $detectedApps | Where-Object { $_.id -eq $app.AppId }
        $detectedApp.pilotDevicesCount += 1
    }
    $inscopedevices | Where-Object { $_.id -eq $insiderdevice.id } | Add-Member -Name ring -MemberType NoteProperty -Value "Insider" -Force
}

# Process existing Pilot Devices
Write-Log "Process pilot devices already in the group and raise pilot count by 1 on the models and apps"
foreach($existingpilotdevice in $existingpilotdevices){
    $model = $models | Where-Object { $_.Values -contains $existingpilotdevice.Manufacturer -and $_.Values -contains $existingpilotdevice.Model }
    $model.pilotDevicesCount += 1

    foreach($app in ($appRelationships | Where-Object { $_.DeviceId -eq $existingpilotdevice.deviceId } )){
        $detectedApp = $detectedApps | Where-Object { $_.id -eq $app.AppId }
        $detectedApp.pilotDevicesCount += 1
    }
    $inscopedevices | Where-Object { $_.id -eq $existingpilotdevice.id } | Add-Member -Name ring -MemberType NoteProperty -Value "Pilot" -Force
}


# Search Pilot Devices for HW Models
Write-Log "Search new  pilot devices for hw models"
foreach($model in $models){
    if($model.Count -gt $MinDeviceModelCount){
        
        while($model.pilotDevicesCount -lt $DevicesPerModel){
            Write-Log "The hw model '$($model.Name)' has only $($model.pilotDevicesCount) in the group. Therefore searching new pilot device"
            $x = 0 
            
            $device = $inscopedevices | Where-Object { $_.id -eq $model.Group[$x].id }
            if($device.ring -ne "Insider"){
                Write-Log "Adding pilot device '$($device.diplayName)'"
                foreach($app in ($appRelationships | Where-Object { $_.DeviceId -eq $model.Group[$x].deviceId } )){
                    $detectedApp = $detectedApps | Where-Object { $_.id -eq $app.AppId }
                    $detectedApp.pilotDevicesCount += 1
                }
                $device | Add-Member -Name ring -MemberType NoteProperty -Value "Pilot" -Force
                $model.pilotDevicesCount += 1
            }
        }
    } else {
        Write-Log "$($model.Name) skipped because Count $($model.Count) is lower than $MinDeviceModelCount"
    }
}


# Search Pilot Devices for HW Models
foreach($detectedApp in $detectedApps){
    while($detectedApp.pilotDevicesCount -lt $DevicesPerApp){
        Write-Log "The detected app '$($detectedApp.displayName)' has only $($detectedApp.pilotDevicesCount) represantive in the group. Therefore searching new pilot device"
        $x = 0   
        $device = $inscopedevices | Where-Object { $_.id -eq $detectedApp.Devices[$x].id }
        if($device.ring -ne "Insider" -and $null -ne $device){
            Write-Log "Adding pilot device '$($device.displayName)'"
            foreach($app in ($appRelationships | Where-Object { $_.DeviceId -eq $detectedApp.Devices[$x].deviceId } )){
                $detectedApp = $detectedApps | Where-Object { $_.id -eq $app.AppId }
                $detectedApp.pilotDevicesCount += 1
            }
            $device | Add-Member -Name ring -MemberType NoteProperty -Value "Pilot" -Force
            $detectedApp.pilotDevicesCount += 1
        }
    }
}


$members = ($inscopedevices | Where-Object { $_.ring -eq "Pilot"}).id



#endregion

#region Finishing
########################################################



$header = @{
"Authorization" = "Bearer $($token.AccessToken)"
"Content-Type" = "application/json"
}
foreach($id in $members){
    if($existingpilotdevices.id -notcontains $id){

        $bodyobj = @{
                      "@odata.id" = "https://graph.microsoft.com/v1.0/directoryObjects/$id"
                    }
        $body = $bodyobj | ConvertTo-Json
        try { 
            Write-Log "Adding device $id to pilot group."
            Invoke-RestMethod -Headers $header -Uri "https://graph.microsoft.com/v1.0/groups/$AADGroupId_Pilot/members/`$ref" -UseBasicParsing -Method Post -Body $body 
            
        } catch [System.Net.WebException] { 
            Write-Log "Failed to add member $id to group $AADGroupId_Pilot" -Type Error -Exception $_.Exception
            $_.Exception.Response 
        } 
    }
}


Write-Log "End Script $Scriptname"



#endregion