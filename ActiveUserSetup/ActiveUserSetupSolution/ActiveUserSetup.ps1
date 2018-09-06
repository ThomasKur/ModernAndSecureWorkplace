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
    1.0.3: Put task enumeration into a function


#>


## Manual Variable Definition
########################################################
$ScriptVersion = "1.0.3"

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


$HKLMRootKey = "HKLM:\Software\ActiveUserSetup"
$HKCURootKey = "HKCU:\Software\ActiveUserSetup"

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
    The root key which has to be searched for tasks.

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
            $RootChilds = @()
        }
    }
    catch{
        Write-Log "Error reading from $RootKey"  -Type Error -Exception $_.Exception
        Throw "Error reading from $RootKey"
    }
    return $RootChilds
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
}
catch {
    End-Script; Break
}

if ($HKLMRootChilds.count -eq 0) {
    Write-Log "There is nothing to do end script now." -Type Warn
    End-Script
    Break
}
#endregion

    ForEach($HKLMRootChild in $HKLMRootChilds){
        Write-Log "---------Working on $HKLMRootChild---------"
        $TaskNeedsToBeExecuted = $False
        $ProcessExitCode =$null
        $WriteToUserRegistry = $false
        $ProcessWasSuccessful = $false

        #Get Task Information from HKLM
        $CurrentTaskHKLMOptions = Get-ItemProperty -path $HKLMRootChild.PSPath
        $CurrentTaskHKLMVersion = $CurrentTaskHKLMOptions.Version
        $CurrentTaskCommandArgument = $CurrentTaskHKLMOptions.Argument
        $CurrentTaskCommandToExecute = $CurrentTaskHKLMOptions.Execute
        $CurrentTaskName = $CurrentTaskHKLMOptions.Name
        $CurrentTaskWaitOnFinish= $CurrentTaskHKLMOptions.WaitOnFinish
        $CurrentTaskSuccessfulReturnCodes = $CurrentTaskHKLMOptions.SuccessfulReturnCodes
        $CurrentTaskOnlyWhenSuccessful = $CurrentTaskHKLMOptions.OnlyWhenSuccessful

        #Get Task Information from HKLM
        $CurrentTaskHKCUKey = "$HKCURootKey\$HKLMRootChild"


#region Check if Task needs To be Executed
        If($CurrentTaskCommandToExecute){
            If(-not(Test-path $CurrentTaskHKCUKey)){
                Write-Log "$CurrentTaskHKCUKey doesn't already exists. So this Task needs to be executed."
                $TaskNeedsToBeExecuted = $true
            }
            else{
                Write-Log "$CurrentTaskHKCUKey already exists. Check if the task has a version"

                If($CurrentTaskHKLMVersion){
                    Write-Log ("The Task has a Version. I have to check if the User and HKLM Version match.")
                    $HKCUTaskVersion = (Get-ItemProperty $CurrentTaskHKCUKey).Version

                    If($CurrentTaskHKLMVersion -eq $HKCUTaskVersion){
                        Write-Log "The CurrentTaskHKLMVersion is '$CurrentTaskHKLMVersion' this matches the HKCUTaskVersion '$HKCUTaskVersion'. So there is no need to execute the task."
                    }
                    else{
                        Write-Log "The CurrentTaskHKLMVersion is '$CurrentTaskHKLMVersion' this doesn't match HKCUTaskVersion '$HKCUTaskVersion'"

                        #Check if SuccessfulReturnCodes is specified and WaitOnFinish ist set to 1 when OnlyWhenSuccessful is set to 1
                        If($CurrentTaskOnlyWhenSuccessful -eq 1){

                            If($CurrentTaskSuccessfulReturnCodes){                            
                                If($CurrentTaskWaitOnFinish -eq 1){
                                    $TaskNeedsToBeExecuted = $true
                                }
                                else{
                                    Write-Log "The Task is configured as OnlyWhenSuccessful. But WaitOnFinish is not set to 1. I'm skipping it." -Type Error
                                }
                            }
                            else{
                                Write-Log "The Task is configured as OnlyWhenSuccessful. But there are no SuccessfulReturnCodes defined. I'm skipping it." -Type Error
                            }
                        }
                        else{
                            $TaskNeedsToBeExecuted = $true
                        }
                    }
                }
                else{
                    Write-Log "The Task has no Version. So there is no need to execute the task."
                }
            }
        }
        else{
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
            $SecondsCounter = 0
            $TotalSeconds = 0
            If($CurrentTaskName){
                $ToastMessage = $CurrentTaskName
            }
            else{
                $ToastMessage = "$CurrentTaskCommandToExecute $CurrentTaskCommandArgument"
            }

            Show-ToastMessage -Titel "Executing Active User Setup" -Message $ToastMessage -ProgressStatus "Starting"

            try{
                If($CurrentTaskWaitOnFinish -eq 1){
                    If($CurrentTaskCommandArgument){
                        Write-Log "Executing the Command '$CurrentTaskCommandToExecute $CurrentTaskCommandArgument', and waiting for it to finish"

                        $Process = Start-Process -PassThru $CurrentTaskCommandToExecute -ArgumentList $CurrentTaskCommandArgument 

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


                        Write-Log "Executed the Command '$CurrentTaskCommandToExecute $CurrentTaskCommandArgument'. It ended with the Exit Code $ProcessExitCode"
                    }
                    else{
                        Write-Log "Executing the Command $CurrentTaskCommandToExecute, and waiting for it to finish"

                        $Process = Start-Process -PassThru $CurrentTaskCommandToExecute


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


                        Write-Log "Executed the Command $CurrentTaskCommandToExecute. It ended with the Exit Code $ProcessExitCode"
                    }
                }
                else{
                    If($CurrentTaskCommandArgument){
                        Write-Log "Executing the Command '$CurrentTaskCommandToExecute $CurrentTaskCommandArgument', and not waiting for it to finish"
                        Start-Process -PassThru $CurrentTaskCommandToExecute -ArgumentList $CurrentTaskCommandArgument | Out-Null
                    }
                    else{
                        Write-Log "Executing the Command $CurrentTaskCommandToExecute, and not waiting for it to finish"
                        Start-Process -PassThru $CurrentTaskCommandToExecute | Out-Null
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
            Show-ToastMessage -Titel "Executing Active User Setup" -Message $ToastMessage -ProgressStatus "Finished with Exitcode $ProcessExitCode"

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

#region Finishing
########################################################

End-Script

#endregion

