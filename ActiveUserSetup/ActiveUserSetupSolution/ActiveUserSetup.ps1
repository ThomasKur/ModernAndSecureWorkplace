<#
.DESCRIPTION
    Execute Things as the User once. This is a alternative to ActiveSetup

.EXAMPLE


.NOTES
Author: PAB/baseVISION
Date:   09.03.2018

History
    1.0.0: First Version
    1.0.1: Added Toast Notifications and improved Wait behavior
    1.0.2: Changes in the duration that the Toast Message is shown
    1.1.0: Added support for 32bit task entrys on 64bit OS and a flag for the task window style


#>


## Manual Variable Definition
########################################################
$ScriptVersion = "1.1.0"

$DefaultLogOutputMode  = "LogFile"
$DebugPreference = "Continue"

$Script:ThisScriptParentPath = $MyInvocation.MyCommand.Path -replace $myInvocation.MyCommand.Name,""

#If the Script gets executed as EXE we need another way to get ThisScriptParentPath
If(-not($script:ThisScriptParentPath)){
    $Script:ThisScriptParentPath = ([System.Diagnostics.Process]::GetCurrentProcess() | Select-Object -ExpandProperty Path | Split-Path)+"\"
}

$LogFilePathFolder     = $ENV:TEMP
$LogFilePathScriptName = "StartGeneration_001"            # This is only used if the filename could not be resolved(IE running in ISE)
$FallbackScriptPath    = "C:\Program Files\baseVISION" # This is only used if the filename could not be resolved(IE running in ISE)
$MaximumLogSize = "0.5" #in MB
$LogFilePath = "$LogFilePathFolder\ActiveUserSetup.log"


$ReturnCodesDelimiter = ";"


$HKLMRootKey = "HKLM:\SOFTWARE\ActiveUserSetup"
$HKLMRootKey32 = "HKLM:\SOFTWARE\WOW6432Node\ActiveUserSetup"
$HKCURootKey = "HKCU:\Software\ActiveUserSetup"
$HKCURootKey32 = "HKCU:\SOFTWARE\WOW6432Node\ActiveUserSetup"

#region Functions
########################################################

Function End-Script {
    Write-Log "----------------------------------------------------------------End Script $Scriptname----------------------------------------------------------------"
}
Function Show-ToastMessage{
    <#
    .DESCRIPTION
    This Function can show a Windows 10 Toast Notification

    .PARAMETER Titel
    Specifies the Titel of the Toast Message (The First Line that is written in Boald)

    .PARAMETER Message
    The Text of the Toast

    .PARAMETER ProgressStatus
    Specifiesthe the Text of the 3rd row
    
    .EXAMPLE
       Show-ToastMessage -Titel "Executing Active User Setup" -Message "IE Configurtation" -ProgressStatus "Starting"

    .NOTES
    This function .
    #>
    param(
        [Parameter(Mandatory=$true,Position=1)]
        [String]
        $Titel
    ,
        [Parameter(Mandatory=$true)]
        [String]
        $Message
    ,
        [Parameter(Mandatory=$false)]
        [String]
        $ProgressStatus = ""
    )

    Try
    {
    
        $Image =$ThisScriptParentPath+"ToastIco.ico"
        write-log "Image to use as Toast Ico $Image"
        [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] > $null
        $template = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent([Windows.UI.Notifications.ToastTemplateType]::ToastText01)

        #Convert to .NET type for XML manipuration
        $toastXml = [xml] $template.GetXml()
        $toastXml.GetElementsByTagName("text").AppendChild($toastXml.CreateTextNode($notificationTitle)) > $null

        #Convert back to WinRT type

        $xml = New-Object Windows.Data.Xml.Dom.XmlDocument
        $xml.LoadXml(
            "<?xml version=""1.0""?>
            <toast duration=""long"">
                <visual>
                    <binding template=""ToastGeneric"">
                        <text>$Titel</text>
                        <text>$Message</text>
                        <text>$ProgressStatus</text>
                        <image placement=""appLogoOverride"" src=""$Image"" />
                    </binding>
                </visual>
            </toast>"
        )

        $toast = [Windows.UI.Notifications.ToastNotification]::new($xml)
        $toast.Tag = "18364"
        $toast.Group = "wallPosts"
        $toast.ExpirationTime = [DateTimeOffset]::Now.AddMinutes(5)
    

        $AppId = "{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe"
        $notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($AppId)
    
        $data = [Windows.UI.Notifications.NotificationData]::new()
        $toast.Data = $data


        $notifier.Show($toast)
        Write-Log "Created Toast Notification $Title / $Message"
    }
    Catch
    {
        Write-Log "Failed to create Toast Notification $Title / $Message"  -Type Error -Exception $_.Exception
    }


}


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
            Write-Error $output -ErrorAction Continue
            if($Exception){
               Write-Error ("[" + $Exception.GetType().FullName + "] " + $Exception.Message)  -ErrorAction Continue
            }
        } elseif($Type -eq "Warn"){
            Write-Warning $output -WarningAction Continue
            if($Exception){
               Write-Warning ("[" + $Exception.GetType().FullName + "] " + $Exception.Message) -WarningAction Continue
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
        [string]$Value,
        [Parameter(Mandatory=$True)]
        [string]$Type
    )
    
    try {
        $ErrorActionPreference = 'Stop' # convert all errors to terminating errors
        Start-Transaction

	   if (Test-Path $Path -erroraction silentlycontinue) {      
 
        } else {
            New-Item -Path $Path -Force |Out-Null
            Write-Log "Registry key $Path created"  
        } 
    
        $null = New-ItemProperty -Path $Path -Name $Name -PropertyType $Type -Value $Value -Force
        Write-Log "Registry Value $Path, $Name, $Type, $Value set"
        Complete-Transaction
    } catch {
        Undo-Transaction
        Write-Log "Registry value not set $Path, $Name, $Value, $Type" -Type Error -Exception $_.Exception
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

    $DateTime = Get-Date -f o
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
        $null = New-Item -Path "HKLM:\SOFTWARE\_Custom\Scripts\$Scriptname" -ErrorAction Stop
        $null = New-ItemProperty -Path "HKLM:\SOFTWARE\_Custom\Scripts\$Scriptname" -Name "Scriptname" -Value "$Scriptname" -ErrorAction Stop
        $null = New-ItemProperty -Path "HKLM:\SOFTWARE\_Custom\Scripts\$Scriptname" -Name "Time" -Value "$DateTime" -ErrorAction Stop
        $null = New-ItemProperty -Path "HKLM:\SOFTWARE\_Custom\Scripts\$Scriptname" -Name "ExitMessage" -Value "$ExitMessage" -ErrorAction Stop
        $null = New-ItemProperty -Path "HKLM:\SOFTWARE\_Custom\Scripts\$Scriptname" -Name "LogfileLocation" -Value "$LogfileLocation" -ErrorAction Stop
    } catch { 
        Write-Log "Set-ExitMessageRegistry failed" -Type Error -Exception $_.Exception
        #If the registry keys can not be written the Error Message is returned and the indication which line (therefore which Entry) had the error
        $Error[0].Exception
        $Error[0].InvocationInfo.PositionMessage
    }
}


function Check-LogFileSize {
    <#
    .DESCRIPTION
    Check if the Logfile exceds a defined Size and if yes rolles id over to a .old.log.

    .PARAMETER Log
    Specifies the the Path to the Log.

    .PARAMETER MaxSize
    MaxSize in MB for the Maximum Log Size

    .EXAMPLE
    Check-LogFileSize -Log "C:\Temp\Super.log" -Size 1

    #>
    param(
        [Parameter(Mandatory=$true,Position=1)]
        [String]
        $Log
    ,
        [Parameter(Mandatory=$true)]
        [String]
        $MaxSize

    )

    
    
    #Create the old.log File
    $LogOld = $Log.Insert(($Log.LastIndexOf(".")),".old")
        
	if (Test-Path $Log) {
		Write-Log "The Log $Log exists"
        $FileSizeInMB= ((Get-ItemProperty -Path $Log).Length)/1MB
        Write-Log "The Logs Size is $FileSizeInMB MB"
        #Compare the File Size
        If($FileSizeInMB -ge $MaxSize){
            Write-Log "The definde Maximum Size is $MaxSize MB I need to rollover the Log"
            #If the old.log File already exists remove it
            if (Test-Path $LogOld) {
                Write-Log "The Rollover File $LogOld already exists. I will remove it first"
                Remove-Item -path $LogOld -Force
            }
            #Rename the Log
            Rename-Item -Path $Log -NewName $LogOld -Force
            Write-Log "Rolled the Log file over to $LogOld"

        }
        else{
            Write-Log "The definde Maximum Size is $MaxSize MB no need to rollover"
        }

	} else {
	    Write-Log "The Log $Log doesn't exists"
	}
}


function Get-ActiveUserSetupTask {
    <#
    .DESCRIPTION
    Enumerate the ActiveUserSetup tasks from the registry.

    .PARAMETER RootKey
    The root key, which has to be searched for tasks.

    .EXAMPLE
    Get-ActiveUserSetupTask -RootKey $HKLMRootKey
    #>

    Param (
        [Parameter(Mandatory = $true)]
        [string]$RootKey
    )

    Try{
        If(Test-Path $RootKey){
            Write-Log "Found the Key $RootKey"
            $RootChilds =Get-ChildItem -Name -Path $RootKey
            If($RootChilds.count -gt 0){
                Write-Log ("$RootKey has " +$RootChilds.count + " Childs")
            }
            else{
                Write-Log "$RootKey has no Childs. So there is nothing to do."  -Type Warn
            }
        }
        else{
            Write-Log "The Key $RootKey doesn't exist"  -Type Warn
            $RootChilds = $null
        }
    }
    catch{
        Write-Log "Error reading from $RootKey"  -Type Error -Exception $_.Exception
        Throw "Error reading from $RootKey"
    }
    return $RootChilds
}


function Start-ChildProcessing {
    <#
    .DESCRIPTION
    Processes the ActiveUserSetup task.

    .PARAMETER Child
    A child object to process.

    .EXAMPLE
    Start-ChildProcessing -Child $HKLMRootChild
    #>

    Param (
        [Parameter(Mandatory = $true)]
        [object]$Child
    )

    Write-Log "---------Working on $HKLMRootChild---------"
    $TaskNeedsToBeExecuted = $False
    $ProcessExitCode =$null
    $WriteToUserRegistry = $false
    $ProcessWasSuccessful = $false

    #Get Task Information from HKLM
    $CurrentTaskHKLMOptions = Get-ItemProperty -path $Child.PSPath
    $CurrentTaskHKLMVersion = $CurrentTaskHKLMOptions.Version
    $CurrentTaskCommandArgument = $CurrentTaskHKLMOptions.Argument
    $CurrentTaskCommandToExecute = $CurrentTaskHKLMOptions.Execute
    $CurrentTaskName = $CurrentTaskHKLMOptions.Name
    $CurrentTaskWaitOnFinish= $CurrentTaskHKLMOptions.WaitOnFinish
    $CurrentTaskSuccessfulReturnCodes = $CurrentTaskHKLMOptions.SuccessfulReturnCodes
    $CurrentTaskOnlyWhenSuccessful = $CurrentTaskHKLMOptions.OnlyWhenSuccessful
    $CurrentTaskWindowStyle = $CurrentTaskHKLMOptions.WindowStyle

    #Get Task Information from HKCU
    if ($Child.PSPath.ToLower() -like '*\wow6432node\*') {
    	$CurrentTaskHKCUKey = "$HKCURootKey32\$Child"
    } else {
        $CurrentTaskHKCUKey = "$HKCURootKey\$Child"
    }


    #region Check if Task needs To be Executed
    If($CurrentTaskCommandToExecute){
        If(-not(Test-path $CurrentTaskHKCUKey)){
            Write-Log "$CurrentTaskHKCUKey doesn't already exists. So this Task needs to be executed."
            $TaskNeedsToBeExecuted = $true
        } else{
            Write-Log "$CurrentTaskHKCUKey already exists. Check if the task has a version"

            If($CurrentTaskHKLMVersion){
                Write-Log ("The Task has a Version. I have to check if the User and HKLM Version match.")
                $HKCUTaskVersion = (Get-ItemProperty $CurrentTaskHKCUKey).Version

                If($CurrentTaskHKLMVersion -eq $HKCUTaskVersion){
                    Write-Log "The CurrentTaskHKLMVersion is '$CurrentTaskHKLMVersion' this matches the HKCUTaskVersion '$HKCUTaskVersion'. So there is no need to execute the task."
                } else{
                    Write-Log "The CurrentTaskHKLMVersion is '$CurrentTaskHKLMVersion' this doesn't match HKCUTaskVersion '$HKCUTaskVersion'"

                    #Check if SuccessfulReturnCodes is specified and WaitOnFinish ist set to 1 when OnlyWhenSuccessful is set to 1
                    If($CurrentTaskOnlyWhenSuccessful -eq 1){

                        If($CurrentTaskSuccessfulReturnCodes){                            
                            If($CurrentTaskWaitOnFinish -eq 1){
                                $TaskNeedsToBeExecuted = $true
                            } else{
                                Write-Log "The Task is configured as OnlyWhenSuccessful. But WaitOnFinish is not set to 1. I'm skipping it." -Type Error
                            }
                        } else{
                            Write-Log "The Task is configured as OnlyWhenSuccessful. But there are no SuccessfulReturnCodes defined. I'm skipping it." -Type Error
                        }
                    } else{
                        $TaskNeedsToBeExecuted = $true
                    }
                }
            } else{
                Write-Log "The Task has no Version. So there is no need to execute the task."
            }
        }
    } else{
        Write-Log "The Task has no 'Execute' Command. In this case i can't execute it!" -Type Warn
    }
    #endregion


    If($TaskNeedsToBeExecuted){
    #region Execute the Task
        Write-Log "The current Task has the following Options:"
        Write-Log "Name = $CurrentTaskName"
        Write-Log "Execute = $CurrentTaskCommandToExecute"
        Write-Log "Argument = $CurrentTaskCommandArgument"
        Write-Log "Version =  $CurrentTaskHKLMVersion"
        Write-Log "WaitOnFinish = $CurrentTaskWaitOnFinish"
        Write-Log "SuccessfulReturnCodes= $CurrentTaskSuccessfulReturnCodes"
        Write-Log "OnlyWhenSuccessful = $CurrentTaskOnlyWhenSuccessful"
        Write-Log "WindowStyle = $CurrentTaskWindowStyle"
        $SecondsCounter = 0
        $TotalSeconds = 0
        If($CurrentTaskName){
            $ToastMessage = $CurrentTaskName
        } else{
            $ToastMessage = "$CurrentTaskCommandToExecute $CurrentTaskCommandArgument"
        }

	if ($CurrentTaskWindowStyle -eq $null) {
            $CurrentTaskWindowStyle = 0
        }

        switch ($CurrentTaskWindowStyle) {
            1 {$WindowStyle = 'Maximized'}
            2 {$WindowStyle = 'Minimized'}
            3 {$WindowStyle = 'Hidden'}
            default {$WindowStyle = 'Normal'}
        }

        Show-ToastMessage -Titel "Executing Active User Setup" -Message $ToastMessage -ProgressStatus "Starting"

        try{
            If($CurrentTaskWaitOnFinish -eq 1){
                If($CurrentTaskCommandArgument){
                    $LogCommand = "`'$CurrentTaskCommandToExecute $CurrentTaskCommandArgument`'"
                    Write-Log "Executing the Command $LogCommand, and waiting for it to finish"

                    $Process = Start-Process -PassThru $CurrentTaskCommandToExecute -ArgumentList $CurrentTaskCommandArgument -WindowStyle $WindowStyle
                } else{
                    $LogCommand = $CurrentTaskCommandToExecute
                    Write-Log "Executing the Command $LogCommand, and waiting for it to finish"

                    $Process = Start-Process -PassThru $CurrentTaskCommandToExecute -WindowStyle $WindowStyle
                }

                do{
                    start-sleep -seconds 1
                    $SecondsCounter = $SecondsCounter +1
                    $TotalSeconds = $TotalSeconds +1
                    If($SecondsCounter -eq 10){
                        $SecondsCounter = 0
                        Show-ToastMessage -Titel "Executing Active User Setup" -Message $ToastMessage -ProgressStatus "It took already $TotalSeconds Seconds"
                    }
                }
                until ($Process.HasExited)                        

                $ProcessExitCode = $Process.ExitCode

                Write-Log "Executed the Command $LogCommand. It ended with the Exit Code $ProcessExitCode"
            } else{
                If($CurrentTaskCommandArgument){
                    Write-Log "Executing the Command '$CurrentTaskCommandToExecute $CurrentTaskCommandArgument'"
                    Start-Process -PassThru $CurrentTaskCommandToExecute -ArgumentList $CurrentTaskCommandArgument -WindowStyle $WindowStyle | Out-Null
                } else{
                    Write-Log "Executing the Command $CurrentTaskCommandToExecute"
                    Start-Process -PassThru $CurrentTaskCommandToExecute -WindowStyle $WindowStyle | Out-Null
                }            
            }
        }
        catch{
            Write-Log "Executing the Command failed"  -Type Error -Exception $_.Exception
        }
    #endregion

    #region Check if Process was Succesfull
        If($CurrentTaskOnlyWhenSuccessful -eq 1){
        
            $SuccessfulReturnCodesList = $CurrentTaskSuccessfulReturnCodes.Split(";")

            #Check if the Exitcode is in the List of Succesful exit Codes
            ForEach($SuccessfulReturnCode in $SuccessfulReturnCodesList){
                If($ProcessExitCode -eq $SuccessfulReturnCode){
                    $ProcessWasSuccessful = $true
                }
            }

            If($ProcessWasSuccessful){
                Write-Log "The Exitcode was $ProcessExitCode, this is in the List of Succesful Exit Codes $CurrentTaskSuccessfulReturnCodes"
                $WriteToUserRegistry = $true
                Show-ToastMessage -Titel "Executing Active User Setup" -Message $ToastMessage -ProgressStatus "Finished with Exitcode $ProcessExitCode. It was successful."

            }
            else{
                Write-Log "The Exitcode was $ProcessExitCode, this is not in the List of Succesful Exit Codes $CurrentTaskSuccessfulReturnCodes"  -Type Error
                Show-ToastMessage -Titel "Executing Active User Setup" -Message $ToastMessage -ProgressStatus "Finished with Exitcode $ProcessExitCode. Something went wrong."
                Start-Sleep -Seconds 5 #This is that the Toast is at least 5 seconds visible, when something returned an unexpected Exit Code. 
            }
        }
        else{
            $WriteToUserRegistry = $true
            Show-ToastMessage -Titel "Executing Active User Setup" -Message $ToastMessage -ProgressStatus "Running"

        }
        
    #endregion

    #region Write to User Registry

        Try{
            If($WriteToUserRegistry){
                Set-RegValue -Path $CurrentTaskHKCUKey -Name "Version" -Value $CurrentTaskHKLMVersion -Type String
            }
        }
        catch{
            Write-Log "Error writing to $CurrentTaskHKCUKey"  -Type Error -Exception $_.Exception
        }


    #endregion
    }
}
#endregion


#region Initialization
########################################################
New-Folder $LogFilePathFolder


Write-Log "----------------------------------------------------------------Start Script for User $ENV:USERNAME----------------------------------------------------------------"
Write-Log "This is the Scriptversion '$ScriptVersion'"
#endregion

#region Main Script
########################################################


    #Check if the Log is to big
    Check-LogFileSize -Log $LogFilePath -MaxSize $MaximumLogSize
    

#region  Get Tasks from HKLM Key
try {
    $HKLMRootChilds = Get-ActiveUserSetupTask -RootKey $HKLMRootKey
    if ((Get-CimInstance -ClassName Win32_OperatingSystem).OSArchitecture -eq '64-Bit') {
        $HKLMRootChilds32 = Get-ActiveUserSetupTask -RootKey $HKLMRootKey32
    } else {
        $HKLMRootChilds32 = $null
    }
}
catch {
    End-Script; Break
}

if ($HKLMRootChilds -eq $null -and $HKLMRootChilds32 -eq $null) {
    Write-Log "There is nothing to do end script now." -Type Warn
    End-Script
    Break
}
#endregion

if ($HKLMRootChilds -ne $null) {
    ForEach($HKLMRootChild in $HKLMRootChilds){
        Start-ChildProcessing -Child $HKLMRootChild
    }
}

if ($HKLMRootChilds32 -ne $null) {
    ForEach($HKLMRootChild in $HKLMRootChilds32) {
        Start-ChildProcessing -Child $HKLMRootChild
    }
}


#endregion

#region Finishing
########################################################

End-Script

#endregion


# SIG # Begin signature block
# MIIgwgYJKoZIhvcNAQcCoIIgszCCIK8CAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUGkw7Arzx/O9P91jngCfefh8Y
# bZKgghsdMIIGajCCBVKgAwIBAgIQAwGaAjr/WLFr1tXq5hfwZjANBgkqhkiG9w0B
# AQUFADBiMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYD
# VQQLExB3d3cuZGlnaWNlcnQuY29tMSEwHwYDVQQDExhEaWdpQ2VydCBBc3N1cmVk
# IElEIENBLTEwHhcNMTQxMDIyMDAwMDAwWhcNMjQxMDIyMDAwMDAwWjBHMQswCQYD
# VQQGEwJVUzERMA8GA1UEChMIRGlnaUNlcnQxJTAjBgNVBAMTHERpZ2lDZXJ0IFRp
# bWVzdGFtcCBSZXNwb25kZXIwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIB
# AQCjZF38fLPggjXg4PbGKuZJdTvMbuBTqZ8fZFnmfGt/a4ydVfiS457VWmNbAklQ
# 2YPOb2bu3cuF6V+l+dSHdIhEOxnJ5fWRn8YUOawk6qhLLJGJzF4o9GS2ULf1ErNz
# lgpno75hn67z/RJ4dQ6mWxT9RSOOhkRVfRiGBYxVh3lIRvfKDo2n3k5f4qi2LVkC
# YYhhchhoubh87ubnNC8xd4EwH7s2AY3vJ+P3mvBMMWSN4+v6GYeofs/sjAw2W3rB
# erh4x8kGLkYQyI3oBGDbvHN0+k7Y/qpA8bLOcEaD6dpAoVk62RUJV5lWMJPzyWHM
# 0AjMa+xiQpGsAsDvpPCJEY93AgMBAAGjggM1MIIDMTAOBgNVHQ8BAf8EBAMCB4Aw
# DAYDVR0TAQH/BAIwADAWBgNVHSUBAf8EDDAKBggrBgEFBQcDCDCCAb8GA1UdIASC
# AbYwggGyMIIBoQYJYIZIAYb9bAcBMIIBkjAoBggrBgEFBQcCARYcaHR0cHM6Ly93
# d3cuZGlnaWNlcnQuY29tL0NQUzCCAWQGCCsGAQUFBwICMIIBVh6CAVIAQQBuAHkA
# IAB1AHMAZQAgAG8AZgAgAHQAaABpAHMAIABDAGUAcgB0AGkAZgBpAGMAYQB0AGUA
# IABjAG8AbgBzAHQAaQB0AHUAdABlAHMAIABhAGMAYwBlAHAAdABhAG4AYwBlACAA
# bwBmACAAdABoAGUAIABEAGkAZwBpAEMAZQByAHQAIABDAFAALwBDAFAAUwAgAGEA
# bgBkACAAdABoAGUAIABSAGUAbAB5AGkAbgBnACAAUABhAHIAdAB5ACAAQQBnAHIA
# ZQBlAG0AZQBuAHQAIAB3AGgAaQBjAGgAIABsAGkAbQBpAHQAIABsAGkAYQBiAGkA
# bABpAHQAeQAgAGEAbgBkACAAYQByAGUAIABpAG4AYwBvAHIAcABvAHIAYQB0AGUA
# ZAAgAGgAZQByAGUAaQBuACAAYgB5ACAAcgBlAGYAZQByAGUAbgBjAGUALjALBglg
# hkgBhv1sAxUwHwYDVR0jBBgwFoAUFQASKxOYspkH7R7for5XDStnAs0wHQYDVR0O
# BBYEFGFaTSS2STKdSip5GoNL9B6Jwcp9MH0GA1UdHwR2MHQwOKA2oDSGMmh0dHA6
# Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJRENBLTEuY3JsMDig
# NqA0hjJodHRwOi8vY3JsNC5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURD
# QS0xLmNybDB3BggrBgEFBQcBAQRrMGkwJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3Nw
# LmRpZ2ljZXJ0LmNvbTBBBggrBgEFBQcwAoY1aHR0cDovL2NhY2VydHMuZGlnaWNl
# cnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEQ0EtMS5jcnQwDQYJKoZIhvcNAQEFBQAD
# ggEBAJ0lfhszTbImgVybhs4jIA+Ah+WI//+x1GosMe06FxlxF82pG7xaFjkAneNs
# hORaQPveBgGMN/qbsZ0kfv4gpFetW7easGAm6mlXIV00Lx9xsIOUGQVrNZAQoHuX
# x/Y/5+IRQaa9YtnwJz04HShvOlIJ8OxwYtNiS7Dgc6aSwNOOMdgv420XEwbu5AO2
# FKvzj0OncZ0h3RTKFV2SQdr5D4HRmXQNJsQOfxu19aDxxncGKBXp2JPlVRbwuwqr
# HNtcSCdmyKOLChzlldquxC5ZoGHd2vNtomHpigtt7BIYvfdVVEADkitrwlHCCkiv
# sNRu4PQUCjob4489yq9qjXvc2EQwggZ9MIIEZaADAgECAgMCx70wDQYJKoZIhvcN
# AQELBQAwVDEUMBIGA1UEChMLQ0FjZXJ0IEluYy4xHjAcBgNVBAsTFWh0dHA6Ly93
# d3cuQ0FjZXJ0Lm9yZzEcMBoGA1UEAxMTQ0FjZXJ0IENsYXNzIDMgUm9vdDAeFw0x
# ODA4MDQxMDU2MzBaFw0yMDA4MDMxMDU2MzBaMD4xGDAWBgNVBAMTD0NocmlzdG9m
# IFJvdGhlbjEiMCAGCSqGSIb3DQEJARYTY2hyaXN0b2ZAcm90aGVuLmNvbTCCAiIw
# DQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAOnbQY/kJcdGAbF68gxyPJj47zDk
# mQqXjOZS3iPfIkvKXEs+F88Y55g26x57ZkbIDPVxf44ZuoCKVz8qfyU6ZFffNaEA
# dEqpOr2UQ6qkowy0Yu1zIXRtw6rAUeA4yS9akP7QezA9HtcFgciIHJSvM2espm9p
# n8FfMKBkw5PA2hLFZ4HZVu/6nsSoJWsgWj6+HmN6SbhHfSDriIN2bEkDvywe93zM
# 0PzJiXzNiDUm0ZPwS7xsRiG0/EZ3O+FY74nHRdwSDtSBRz2l228/wNda8azyliE3
# on/NluDlQRh+MBAHnHRksTVWowFs/0pki/BlKpFy2FocV3X8W8drhWMYY2YMx/25
# aD2gvVj1YILgg9YioBaWTMMdW1SDRdsVL0rT12H/4bTR+fjCe/Kwn/FAKn8IEat9
# t125AhpNCeITdBISuXnyKII0zZKSSKorTfh/wNRGDLvTRD5qssOT0ZrKwX+KA/0A
# Kw9UwAu6cgPokriEhIGWNypuIW5mVDD8TmoDb/krIuLzTZ7UnxI/gAeReiPYggir
# m8cfje0s+2+ayeQhMiJV6zn+T915eLI/bSkuYRRevz/+yT3GFszA7rL2ptLJ5VOW
# dW8hxBYER010eniHP+0nn+IFXSnF8vySIEpAEuzVSlxuWR+DMDox8CgrprBYhjQE
# 1UbwLVB81NYfliFbAgMBAAGjggFsMIIBaDAMBgNVHRMBAf8EAjAAMFYGCWCGSAGG
# +EIBDQRJFkdUbyBnZXQgeW91ciBvd24gY2VydGlmaWNhdGUgZm9yIEZSRUUgaGVh
# ZCBvdmVyIHRvIGh0dHA6Ly93d3cuQ0FjZXJ0Lm9yZzAOBgNVHQ8BAf8EBAMCA6gw
# YgYDVR0lBFswWQYIKwYBBQUHAwQGCCsGAQUFBwMCBggrBgEFBQcDAwYKKwYBBAGC
# NwIBFQYKKwYBBAGCNwIBFgYKKwYBBAGCNwoDBAYKKwYBBAGCNwoDAwYJYIZIAYb4
# QgQBMDIGCCsGAQUFBwEBBCYwJDAiBggrBgEFBQcwAYYWaHR0cDovL29jc3AuY2Fj
# ZXJ0Lm9yZzA4BgNVHR8EMTAvMC2gK6AphidodHRwOi8vY3JsLmNhY2VydC5vcmcv
# Y2xhc3MzLXJldm9rZS5jcmwwHgYDVR0RBBcwFYETY2hyaXN0b2ZAcm90aGVuLmNv
# bTANBgkqhkiG9w0BAQsFAAOCAgEAMDgFhF/Qu0ECp0B3AULRE+CNqE7dAVf8Dcyf
# i6Xr2s4ZkZNfm7qOrCwHQ2YDA7XiMltu6JyxAAQa7dmUi8+sQGcNC7hq0c/B8hQE
# /fusQtHswZvSQop7/o8UrGqteuuEEIluV+wpBpcFG00xB9dAo9jQVlE8+ilOUNv1
# ptw4yIlCNfseL88vL9Mn80u+hIJZn+ICJD8h+NbvrRVvXISe2VxCLjK5RxMNW5GO
# FZHa5xnb0QnKpl3GM53K69wqah9E2Exw0x3UL44T3fZJmDiyp6AuEtvuorhzL3tF
# uN+Jk8lMGjz5cVegkqf91PBII/t3yYeuvZDFBQbDNz2AoG9tn1bVxd45xm9IdncW
# 5t+D5zDuuATTBcyz+1ED4/LHolVdmkJsd7Oe1ZTzQFEQ9tQjnXKiNWyf8xZROOgq
# bfx4C55GM06zos/PjJkHTZYSUt3wXR0IlGCOAD5eBYuIMYhibaaknFzoOClC54fd
# f6y/YFFao5WJ4cWoW5iR5EFDfKxajDkzoGL+GBlg2j8vsWPNUAnGAl8vvZtYRE9K
# uCGeCVScEESbLq5YYX8P6F9YyUg4IvmVFM74jlBmi3Q06x/Oc7h5Co6SOQ9NTYRn
# l6fRih8LnrnESth7jcSOU6PmSCV+B7v8AqXqy2ZgzdMvSjL6QDZnCea0y2uhSSjY
# bVtxoQwwggbNMIIFtaADAgECAhAG/fkDlgOt6gAK6z8nu7obMA0GCSqGSIb3DQEB
# BQUAMGUxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNV
# BAsTEHd3dy5kaWdpY2VydC5jb20xJDAiBgNVBAMTG0RpZ2lDZXJ0IEFzc3VyZWQg
# SUQgUm9vdCBDQTAeFw0wNjExMTAwMDAwMDBaFw0yMTExMTAwMDAwMDBaMGIxCzAJ
# BgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5k
# aWdpY2VydC5jb20xITAfBgNVBAMTGERpZ2lDZXJ0IEFzc3VyZWQgSUQgQ0EtMTCC
# ASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAOiCLZn5ysJClaWAc0Bw0p5W
# VFypxNJBBo/JM/xNRZFcgZ/tLJz4FlnfnrUkFcKYubR3SdyJxArar8tea+2tsHEx
# 6886QAxGTZPsi3o2CAOrDDT+GEmC/sfHMUiAfB6iD5IOUMnGh+s2P9gww/+m9/ui
# zW9zI/6sVgWQ8DIhFonGcIj5BZd9o8dD3QLoOz3tsUGj7T++25VIxO4es/K8DCuZ
# 0MZdEkKB4YNugnM/JksUkK5ZZgrEjb7SzgaurYRvSISbT0C58Uzyr5j79s5AXVz2
# qPEvr+yJIvJrGGWxwXOt1/HYzx4KdFxCuGh+t9V3CidWfA9ipD8yFGCV/QcEogkC
# AwEAAaOCA3owggN2MA4GA1UdDwEB/wQEAwIBhjA7BgNVHSUENDAyBggrBgEFBQcD
# AQYIKwYBBQUHAwIGCCsGAQUFBwMDBggrBgEFBQcDBAYIKwYBBQUHAwgwggHSBgNV
# HSAEggHJMIIBxTCCAbQGCmCGSAGG/WwAAQQwggGkMDoGCCsGAQUFBwIBFi5odHRw
# Oi8vd3d3LmRpZ2ljZXJ0LmNvbS9zc2wtY3BzLXJlcG9zaXRvcnkuaHRtMIIBZAYI
# KwYBBQUHAgIwggFWHoIBUgBBAG4AeQAgAHUAcwBlACAAbwBmACAAdABoAGkAcwAg
# AEMAZQByAHQAaQBmAGkAYwBhAHQAZQAgAGMAbwBuAHMAdABpAHQAdQB0AGUAcwAg
# AGEAYwBjAGUAcAB0AGEAbgBjAGUAIABvAGYAIAB0AGgAZQAgAEQAaQBnAGkAQwBl
# AHIAdAAgAEMAUAAvAEMAUABTACAAYQBuAGQAIAB0AGgAZQAgAFIAZQBsAHkAaQBu
# AGcAIABQAGEAcgB0AHkAIABBAGcAcgBlAGUAbQBlAG4AdAAgAHcAaABpAGMAaAAg
# AGwAaQBtAGkAdAAgAGwAaQBhAGIAaQBsAGkAdAB5ACAAYQBuAGQAIABhAHIAZQAg
# AGkAbgBjAG8AcgBwAG8AcgBhAHQAZQBkACAAaABlAHIAZQBpAG4AIABiAHkAIABy
# AGUAZgBlAHIAZQBuAGMAZQAuMAsGCWCGSAGG/WwDFTASBgNVHRMBAf8ECDAGAQH/
# AgEAMHkGCCsGAQUFBwEBBG0wazAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGln
# aWNlcnQuY29tMEMGCCsGAQUFBzAChjdodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5j
# b20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3J0MIGBBgNVHR8EejB4MDqgOKA2
# hjRodHRwOi8vY3JsMy5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290
# Q0EuY3JsMDqgOKA2hjRodHRwOi8vY3JsNC5kaWdpY2VydC5jb20vRGlnaUNlcnRB
# c3N1cmVkSURSb290Q0EuY3JsMB0GA1UdDgQWBBQVABIrE5iymQftHt+ivlcNK2cC
# zTAfBgNVHSMEGDAWgBRF66Kv9JLLgjEtUYunpyGd823IDzANBgkqhkiG9w0BAQUF
# AAOCAQEARlA+ybcoJKc4HbZbKa9Sz1LpMUerVlx71Q0LQbPv7HUfdDjyslxhopyV
# w1Dkgrkj0bo6hnKtOHisdV0XFzRyR4WUVtHruzaEd8wkpfMEGVWp5+Pnq2LN+4st
# kMLA0rWUvV5PsQXSDj0aqRRbpoYxYqioM+SbOafE9c4deHaUJXPkKqvPnHZL7V/C
# SxbkS3BMAIke/MV5vEwSV/5f4R68Al2o/vsHOE8Nxl2RuQ9nRc3Wg+3nkg2NsWmM
# T/tZ4CMP0qquAHzunEIOz5HXJ7cW7g/DvXwKoO4sCFWFIrjrGBpN/CohrUkxg0eV
# d3HcsRtLSxwQnHcUwZ1PL1qVCCkQJjCCB1kwggVBoAMCAQICAwpBijANBgkqhkiG
# 9w0BAQsFADB5MRAwDgYDVQQKEwdSb290IENBMR4wHAYDVQQLExVodHRwOi8vd3d3
# LmNhY2VydC5vcmcxIjAgBgNVBAMTGUNBIENlcnQgU2lnbmluZyBBdXRob3JpdHkx
# ITAfBgkqhkiG9w0BCQEWEnN1cHBvcnRAY2FjZXJ0Lm9yZzAeFw0xMTA1MjMxNzQ4
# MDJaFw0yMTA1MjAxNzQ4MDJaMFQxFDASBgNVBAoTC0NBY2VydCBJbmMuMR4wHAYD
# VQQLExVodHRwOi8vd3d3LkNBY2VydC5vcmcxHDAaBgNVBAMTE0NBY2VydCBDbGFz
# cyAzIFJvb3QwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQCrSTURSHzS
# Jn5TlM9Dqd0o10Iqi/OHeBlYfA+e2ol94fvrcpANdKGWZKufoCSZc9riVXbHF3v1
# BKxGuMO+f2SNEGwk82GcwPKQ+lHm9WkBY8MPVuJKQs/iRIwlKKjFeQl9RrmK8+nz
# NCkIReQcn8uUBByBqBSzmGXEQ+xOgo0J0b2qW42S0OzekMV/CsLj6+YxWl50Ppcz
# WejDAz1gM7/30W9HxM3uYoNSbi4ImqTZFRiRpoWSR7CuSOtttyHshRpocjWr//AQ
# XcD0lKdq1TuSfkyQBX6TwSyLpI5idBVxbgtxA+qvFTia1NIFcm+M+SvrWnIl+TlG
# 43IbPgTDZCciECqKT1inA62+tC4T7V2qSNfVfdQqe1z6RgRQ5MwOQluM7dvyz/yW
# k+DbETZUYjQ4jwxgmzuXVjit89Jbi6Bb6k6WuHzX1aCGcEDTkSm3ojyt9Yy7zxqS
# iuQ0e8DYbF/pCsLDpyCaWt8sXVJcukfVm+8kKHA4IC/VfynAskEDaJLM4JzMl0tF
# 7zoQCqtwOpiVcK01seqFK6QcgCExqa5geoAmSAC4AcCTY1UikTxW56/bOiXzjzFU
# 6iaLgVn5odFTEcV7nQP2dBHgbbEsPyyGkZlxmqZ3izRg0RS0LKydr4wQ05/Eavhv
# E/xzWfdmQnQeiuP43NJvmJzLR5iVQAX76QIDAQABo4ICDTCCAgkwHQYDVR0OBBYE
# FHWocWBMiBPweNmJd7VtxYnfvLF6MIGjBgNVHSMEgZswgZiAFBa1MhvUx/Pg5o7z
# vdKwOu6yORjRoX2kezB5MRAwDgYDVQQKEwdSb290IENBMR4wHAYDVQQLExVodHRw
# Oi8vd3d3LmNhY2VydC5vcmcxIjAgBgNVBAMTGUNBIENlcnQgU2lnbmluZyBBdXRo
# b3JpdHkxITAfBgkqhkiG9w0BCQEWEnN1cHBvcnRAY2FjZXJ0Lm9yZ4IBADAPBgNV
# HRMBAf8EBTADAQH/MF0GCCsGAQUFBwEBBFEwTzAjBggrBgEFBQcwAYYXaHR0cDov
# L29jc3AuQ0FjZXJ0Lm9yZy8wKAYIKwYBBQUHMAKGHGh0dHA6Ly93d3cuQ0FjZXJ0
# Lm9yZy9jYS5jcnQwSgYDVR0gBEMwQTA/BggrBgEEAYGQSjAzMDEGCCsGAQUFBwIB
# FiVodHRwOi8vd3d3LkNBY2VydC5vcmcvaW5kZXgucGhwP2lkPTEwMDQGCWCGSAGG
# +EIBCAQnFiVodHRwOi8vd3d3LkNBY2VydC5vcmcvaW5kZXgucGhwP2lkPTEwMFAG
# CWCGSAGG+EIBDQRDFkFUbyBnZXQgeW91ciBvd24gY2VydGlmaWNhdGUgZm9yIEZS
# RUUsIGdvIHRvIGh0dHA6Ly93d3cuQ0FjZXJ0Lm9yZzANBgkqhkiG9w0BAQsFAAOC
# AgEAKSiFrkSpua+keRPwqKMrl2DzXO7jL8H24magEa42Nzp2FQRT6kL1+erAFdim
# gtnkYa5yCylckEPoQbLhd9sCE0R4R1WvWPzMmPZFudEg+NghB/5tqnPUs8YH6QmF
# zDvytr4sHCXVcYw5tS7qvhiBurCTuA/j5tcmjDFacgOEUuam9TMiRQrICw2KuDZv
# kAmhq73X1U4ucaLUrvqnVCvrNY1at1SIL+50n+1IFsoNSNCU06ykovYk35LjvetD
# QJFuHBiOVrSCEvOpk5/UvJytnHXuWpcbled0LRwPsCyXn/upMzl65wM6ko4i9owN
# 5Nl+DXYY9wH575aWolVzwDxxtB0aVkO3wwqNcvziEAkLQc6MlKD5A/1xc0uKVzPl
# jnR+FQEA5sxKHOd/lRktxaUMi7u17YWzXNPfuLnyyscNARSscFjFjI0z1J1moxpQ
# lSP8SOAGQxLZzaeGOS82cqOAEOTh89HLWxrA5ICafBNzBk/bo2skCrqzHLxKeLvl
# 43U4pUinoh6vdtRe9ziGVlqJztbDp3myUqDG8YW0JYzyP5azENmNbFc7n2+GOhiC
# IjbIsJE42yqhk6qEP/UnZa5z1cjV03fqS53HQbvHwOOgP+R9pI1z5hJL36Fzc3M6
# gOjVy44vy+oTp9ZBi6z6PInXJPVOtOBhkrfzN5jEvpajt4oxggUPMIIFCwIBATBb
# MFQxFDASBgNVBAoTC0NBY2VydCBJbmMuMR4wHAYDVQQLExVodHRwOi8vd3d3LkNB
# Y2VydC5vcmcxHDAaBgNVBAMTE0NBY2VydCBDbGFzcyAzIFJvb3QCAwLHvTAJBgUr
# DgMCGgUAoHgwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMx
# DAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFjAjBgkq
# hkiG9w0BCQQxFgQUY4qvGXYdsNc2qUQACJhSYEjgoQMwDQYJKoZIhvcNAQEBBQAE
# ggIA00H+AY/LjB4GzJc+qaomH//K8Ot4oIgLJ2/zkSjNqGRePlxdAJt4ljwhjsxO
# PR3DIsxp//GWBp5LIsSmm2sDe0buyBICmUu+XPA6nqTeEJ1kqM4d02eyZI8H3yww
# RFWXUiJ4AaJxtjhoAQr+OtuptNqb8rWMVWa46iqeelsU8NKRPAQrqCKUcb1MufY+
# QjuBQvsbuqE35RKHbppiTBU3eORBaEJWkFCHaeLsaPn4+YZnNEtiPKO3BZyLIMMz
# ncHp8szz5XilzlORraZGwmkC69zWEmnUrjCC85dMwe4ShPWdfxtkJ+7ymbhBVLDN
# 2mehbG909KTwn0MXfYVhnyrdkghn0Mf7XBN+qs6tEW/PEAmx58XAvFoH+/OacgIN
# VFmdR9zssC4HmeuBjReXg5IFsUWRzdol2cuFjVXb0muGdp/XErXK1NE0dHlyVBtD
# cbWTOZO/RRBBB/MwE99r3ATRBNxiGMRHeEZD5cPBY4hIYH9kZ+JPUMGiChZ60v8P
# XSeSoRd/C1tbW+/VMiUK9xoK96ogT+nlZrWbMJZfqxBeYloAY3zsjnlVcC0Rr843
# POLiq9PNggR5Um9hQe0MytK4harizPpAuK1B7VDnnttVps7HkYjBW0bn2USad/E8
# 7ttkbOYJ5nhn2IatT5IjaXVzE7wDRCxehhGuf+WGK5jB1+qhggIPMIICCwYJKoZI
# hvcNAQkGMYIB/DCCAfgCAQEwdjBiMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGln
# aUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMSEwHwYDVQQDExhE
# aWdpQ2VydCBBc3N1cmVkIElEIENBLTECEAMBmgI6/1ixa9bV6uYX8GYwCQYFKw4D
# AhoFAKBdMBgGCSqGSIb3DQEJAzELBgkqhkiG9w0BBwEwHAYJKoZIhvcNAQkFMQ8X
# DTE4MDkwOTE4MjQ1MFowIwYJKoZIhvcNAQkEMRYEFIfIS8SKBPlwGotVwee2HSck
# VQFoMA0GCSqGSIb3DQEBAQUABIIBAJgCNf5pt0AKH3BY8HJ5ONdgBPj3jMVJU/22
# K9ip33GjQc8QytpWAy40Vnb4p08R428IBDUWd8qxOfVQsM9zM9dwSI7ZKxD2oQxT
# WXLLc6fdxlO7Awqaxh6yZrcKWq25yg68VGsVgjTqh/nruJ3AW9sZBjq1SsEEQT3h
# 2kpAwzQQSYA1INr47v/uyojN5Ks7yyr1aHJUsIL/1v0DTA0NlCcnvw3eYVtq9rGq
# NmQGaAlyv5+By2hyWaTJbl8JhSwgShLVXuhWprXw+3DZjCcV82YuH9a8zcFIpaD3
# MnW0M2qkSFd4OvyoVRQzoOsPoLXD0+7J8BmPXhLZs+UvtSXFIw8=
# SIG # End signature block
