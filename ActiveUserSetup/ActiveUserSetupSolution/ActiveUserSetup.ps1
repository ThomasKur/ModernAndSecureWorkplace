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
    1.1.1: Added handling for the optional Regkey NoToast. When you set this to 1 no toast notifications will be displayed for this task.


#>


## Manual Variable Definition
########################################################
$ScriptVersion = "1.1.1"

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
    $CurrentTaskNoToast= $CurrentTaskHKLMOptions.NoToast


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
        Write-Log "NoToast = $CurrentTaskNoToast"

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
        If($CurrentTaskNoToast -ne 1){
            Show-ToastMessage -Titel "Executing Active User Setup" -Message $ToastMessage -ProgressStatus "Starting"
        }

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
                        If($CurrentTaskNoToast -ne 1){
                            Show-ToastMessage -Titel "Executing Active User Setup" -Message $ToastMessage -ProgressStatus "It took already $TotalSeconds Seconds"
                        }
                    Write-Log "It took already $TotalSeconds Seconds waiting for it to finish"

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
                If($CurrentTaskNoToast -ne 1){
                    Show-ToastMessage -Titel "Executing Active User Setup" -Message $ToastMessage -ProgressStatus "Finished with Exitcode $ProcessExitCode. It was successful."
                }

            }
            else{
                Write-Log "The Exitcode was $ProcessExitCode, this is not in the List of Succesful Exit Codes $CurrentTaskSuccessfulReturnCodes"  -Type Error
                If($CurrentTaskNoToast -ne 1){
                    Show-ToastMessage -Titel "Executing Active User Setup" -Message $ToastMessage -ProgressStatus "Finished with Exitcode $ProcessExitCode. Something went wrong."
                }
                Start-Sleep -Seconds 5 #This is that the Toast is at least 5 seconds visible, when something returned an unexpected Exit Code. 
            }
        }
        else{
            $WriteToUserRegistry = $true
            If($CurrentTaskNoToast -ne 1){
                Show-ToastMessage -Titel "Executing Active User Setup" -Message $ToastMessage -ProgressStatus "Running"
            }

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
# MIIXxQYJKoZIhvcNAQcCoIIXtjCCF7ICAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUknkPVcHUPeDC/boAXIbtTtPn
# elOgghL4MIID7jCCA1egAwIBAgIQfpPr+3zGTlnqS5p31Ab8OzANBgkqhkiG9w0B
# AQUFADCBizELMAkGA1UEBhMCWkExFTATBgNVBAgTDFdlc3Rlcm4gQ2FwZTEUMBIG
# A1UEBxMLRHVyYmFudmlsbGUxDzANBgNVBAoTBlRoYXd0ZTEdMBsGA1UECxMUVGhh
# d3RlIENlcnRpZmljYXRpb24xHzAdBgNVBAMTFlRoYXd0ZSBUaW1lc3RhbXBpbmcg
# Q0EwHhcNMTIxMjIxMDAwMDAwWhcNMjAxMjMwMjM1OTU5WjBeMQswCQYDVQQGEwJV
# UzEdMBsGA1UEChMUU3ltYW50ZWMgQ29ycG9yYXRpb24xMDAuBgNVBAMTJ1N5bWFu
# dGVjIFRpbWUgU3RhbXBpbmcgU2VydmljZXMgQ0EgLSBHMjCCASIwDQYJKoZIhvcN
# AQEBBQADggEPADCCAQoCggEBALGss0lUS5ccEgrYJXmRIlcqb9y4JsRDc2vCvy5Q
# WvsUwnaOQwElQ7Sh4kX06Ld7w3TMIte0lAAC903tv7S3RCRrzV9FO9FEzkMScxeC
# i2m0K8uZHqxyGyZNcR+xMd37UWECU6aq9UksBXhFpS+JzueZ5/6M4lc/PcaS3Er4
# ezPkeQr78HWIQZz/xQNRmarXbJ+TaYdlKYOFwmAUxMjJOxTawIHwHw103pIiq8r3
# +3R8J+b3Sht/p8OeLa6K6qbmqicWfWH3mHERvOJQoUvlXfrlDqcsn6plINPYlujI
# fKVOSET/GeJEB5IL12iEgF1qeGRFzWBGflTBE3zFefHJwXECAwEAAaOB+jCB9zAd
# BgNVHQ4EFgQUX5r1blzMzHSa1N197z/b7EyALt0wMgYIKwYBBQUHAQEEJjAkMCIG
# CCsGAQUFBzABhhZodHRwOi8vb2NzcC50aGF3dGUuY29tMBIGA1UdEwEB/wQIMAYB
# Af8CAQAwPwYDVR0fBDgwNjA0oDKgMIYuaHR0cDovL2NybC50aGF3dGUuY29tL1Ro
# YXd0ZVRpbWVzdGFtcGluZ0NBLmNybDATBgNVHSUEDDAKBggrBgEFBQcDCDAOBgNV
# HQ8BAf8EBAMCAQYwKAYDVR0RBCEwH6QdMBsxGTAXBgNVBAMTEFRpbWVTdGFtcC0y
# MDQ4LTEwDQYJKoZIhvcNAQEFBQADgYEAAwmbj3nvf1kwqu9otfrjCR27T4IGXTdf
# plKfFo3qHJIJRG71betYfDDo+WmNI3MLEm9Hqa45EfgqsZuwGsOO61mWAK3ODE2y
# 0DGmCFwqevzieh1XTKhlGOl5QGIllm7HxzdqgyEIjkHq3dlXPx13SYcqFgZepjhq
# IhKjURmDfrYwggSjMIIDi6ADAgECAhAOz/Q4yP6/NW4E2GqYGxpQMA0GCSqGSIb3
# DQEBBQUAMF4xCzAJBgNVBAYTAlVTMR0wGwYDVQQKExRTeW1hbnRlYyBDb3Jwb3Jh
# dGlvbjEwMC4GA1UEAxMnU3ltYW50ZWMgVGltZSBTdGFtcGluZyBTZXJ2aWNlcyBD
# QSAtIEcyMB4XDTEyMTAxODAwMDAwMFoXDTIwMTIyOTIzNTk1OVowYjELMAkGA1UE
# BhMCVVMxHTAbBgNVBAoTFFN5bWFudGVjIENvcnBvcmF0aW9uMTQwMgYDVQQDEytT
# eW1hbnRlYyBUaW1lIFN0YW1waW5nIFNlcnZpY2VzIFNpZ25lciAtIEc0MIIBIjAN
# BgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAomMLOUS4uyOnREm7Dv+h8GEKU5Ow
# mNutLA9KxW7/hjxTVQ8VzgQ/K/2plpbZvmF5C1vJTIZ25eBDSyKV7sIrQ8Gf2Gi0
# jkBP7oU4uRHFI/JkWPAVMm9OV6GuiKQC1yoezUvh3WPVF4kyW7BemVqonShQDhfu
# ltthO0VRHc8SVguSR/yrrvZmPUescHLnkudfzRC5xINklBm9JYDh6NIipdC6Anqh
# d5NbZcPuF3S8QYYq3AhMjJKMkS2ed0QfaNaodHfbDlsyi1aLM73ZY8hJnTrFxeoz
# C9Lxoxv0i77Zs1eLO94Ep3oisiSuLsdwxb5OgyYI+wu9qU+ZCOEQKHKqzQIDAQAB
# o4IBVzCCAVMwDAYDVR0TAQH/BAIwADAWBgNVHSUBAf8EDDAKBggrBgEFBQcDCDAO
# BgNVHQ8BAf8EBAMCB4AwcwYIKwYBBQUHAQEEZzBlMCoGCCsGAQUFBzABhh5odHRw
# Oi8vdHMtb2NzcC53cy5zeW1hbnRlYy5jb20wNwYIKwYBBQUHMAKGK2h0dHA6Ly90
# cy1haWEud3Muc3ltYW50ZWMuY29tL3Rzcy1jYS1nMi5jZXIwPAYDVR0fBDUwMzAx
# oC+gLYYraHR0cDovL3RzLWNybC53cy5zeW1hbnRlYy5jb20vdHNzLWNhLWcyLmNy
# bDAoBgNVHREEITAfpB0wGzEZMBcGA1UEAxMQVGltZVN0YW1wLTIwNDgtMjAdBgNV
# HQ4EFgQURsZpow5KFB7VTNpSYxc/Xja8DeYwHwYDVR0jBBgwFoAUX5r1blzMzHSa
# 1N197z/b7EyALt0wDQYJKoZIhvcNAQEFBQADggEBAHg7tJEqAEzwj2IwN3ijhCcH
# bxiy3iXcoNSUA6qGTiWfmkADHN3O43nLIWgG2rYytG2/9CwmYzPkSWRtDebDZw73
# BaQ1bHyJFsbpst+y6d0gxnEPzZV03LZc3r03H0N45ni1zSgEIKOq8UvEiCmRDoDR
# EfzdXHZuT14ORUZBbg2w6jiasTraCXEQ/Bx5tIB7rGn0/Zy2DBYr8X9bCT2bW+IW
# yhOBbQAuOA2oKY8s4bL0WqkBrxWcLC9JG9siu8P+eJRRw4axgohd8D20UaF5Mysu
# e7ncIAkTcetqGVvP6KUwVyyJST+5z3/Jvz4iaGNTmr1pdKzFHTx/kuDDvBzYBHUw
# ggUnMIIED6ADAgECAhAJT00SLqoJkIvAj67NF8OqMA0GCSqGSIb3DQEBCwUAMHIx
# CzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3
# dy5kaWdpY2VydC5jb20xMTAvBgNVBAMTKERpZ2lDZXJ0IFNIQTIgQXNzdXJlZCBJ
# RCBDb2RlIFNpZ25pbmcgQ0EwHhcNMTYwNjA2MDAwMDAwWhcNMTkwNjExMTIwMDAw
# WjBkMQswCQYDVQQGEwJDSDESMBAGA1UECBMJU29sb3RodXJuMREwDwYDVQQHDAhE
# w6RuaWtlbjEWMBQGA1UEChMNYmFzZVZJU0lPTiBBRzEWMBQGA1UEAxMNYmFzZVZJ
# U0lPTiBBRzCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAJ+YpjWmBGJ6
# 6p3mACb/iu1w1oUOFAPZVNSZ8nPOY2MNtzi8d2RRSf16+VVSBhy4wv5sg0QAu76I
# 1B5mwWA73gjDERH4LRvisNLrd5cR/CyS1DLZvHY01g7Ck7MtNSekjPEHIc6LFK/4
# 5gQ28nAPcanR2wo+RPGxu34QXKg3ceBH92POm1GDGGUMsTjP7ME7ZOeLKLScJD/V
# rmMH/B6K7ApfAF2O/szxFXrEo+5VcloWoCRHmbFe7nLnAC8k5I63ZBmiSi6EBc89
# ID+XaVWLYvVCNwI/PVEanmDxBG9SAxRnJtcUAYg62S84ClXNj2y53xPUbdZvz3mC
# RTivIlhjH9ECAwEAAaOCAcUwggHBMB8GA1UdIwQYMBaAFFrEuXsqCqOl6nEDwGD5
# LfZldQ5YMB0GA1UdDgQWBBR6hPT/LYCRb+slld/aUoR4eQYCQDAOBgNVHQ8BAf8E
# BAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwdwYDVR0fBHAwbjA1oDOgMYYvaHR0
# cDovL2NybDMuZGlnaWNlcnQuY29tL3NoYTItYXNzdXJlZC1jcy1nMS5jcmwwNaAz
# oDGGL2h0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9zaGEyLWFzc3VyZWQtY3MtZzEu
# Y3JsMEwGA1UdIARFMEMwNwYJYIZIAYb9bAMBMCowKAYIKwYBBQUHAgEWHGh0dHBz
# Oi8vd3d3LmRpZ2ljZXJ0LmNvbS9DUFMwCAYGZ4EMAQQBMIGEBggrBgEFBQcBAQR4
# MHYwJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBOBggrBgEF
# BQcwAoZCaHR0cDovL2NhY2VydHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0U0hBMkFz
# c3VyZWRJRENvZGVTaWduaW5nQ0EuY3J0MAwGA1UdEwEB/wQCMAAwDQYJKoZIhvcN
# AQELBQADggEBAI5wXkMjGctA2E/fchGVptw2Qzdp1a3C1ApX4STqxhkKaQMMJao7
# cHarrQctdjRo2YHEsEsPpOKpQcB2gEUnhWInaghmq618MC/UYZtL/hUcGraEhRO6
# PEDoM/2Xz1+EJJbgmS812YOih1xXrbzfgKE3Zl01VsoNjPvsD4XtEuD0Utjrwsh/
# Qy3gD9Wb925oYOuIz9hp1+jmnQu7hlRaVr7TtxR4aTtTqQdAv35FKPqJdXXUZ9Y9
# otWAWBgWb8YFqMTw6gig3EUORB+MyPXN/zCdwrbAcXlrMIPHhKsvJ6UkxfQkfb4Z
# oztVtMUBChHanEVcX4bVFQwNnDVcrlt8w6IwggUwMIIEGKADAgECAhAECRgbX9W7
# ZnVTQ7VvlVAIMA0GCSqGSIb3DQEBCwUAMGUxCzAJBgNVBAYTAlVTMRUwEwYDVQQK
# EwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xJDAiBgNV
# BAMTG0RpZ2lDZXJ0IEFzc3VyZWQgSUQgUm9vdCBDQTAeFw0xMzEwMjIxMjAwMDBa
# Fw0yODEwMjIxMjAwMDBaMHIxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2Vy
# dCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xMTAvBgNVBAMTKERpZ2lD
# ZXJ0IFNIQTIgQXNzdXJlZCBJRCBDb2RlIFNpZ25pbmcgQ0EwggEiMA0GCSqGSIb3
# DQEBAQUAA4IBDwAwggEKAoIBAQD407Mcfw4Rr2d3B9MLMUkZz9D7RZmxOttE9X/l
# qJ3bMtdx6nadBS63j/qSQ8Cl+YnUNxnXtqrwnIal2CWsDnkoOn7p0WfTxvspJ8fT
# eyOU5JEjlpB3gvmhhCNmElQzUHSxKCa7JGnCwlLyFGeKiUXULaGj6YgsIJWuHEqH
# CN8M9eJNYBi+qsSyrnAxZjNxPqxwoqvOf+l8y5Kh5TsxHM/q8grkV7tKtel05iv+
# bMt+dDk2DZDv5LVOpKnqagqrhPOsZ061xPeM0SAlI+sIZD5SlsHyDxL0xY4PwaLo
# LFH3c7y9hbFig3NBggfkOItqcyDQD2RzPJ6fpjOp/RnfJZPRAgMBAAGjggHNMIIB
# yTASBgNVHRMBAf8ECDAGAQH/AgEAMA4GA1UdDwEB/wQEAwIBhjATBgNVHSUEDDAK
# BggrBgEFBQcDAzB5BggrBgEFBQcBAQRtMGswJAYIKwYBBQUHMAGGGGh0dHA6Ly9v
# Y3NwLmRpZ2ljZXJ0LmNvbTBDBggrBgEFBQcwAoY3aHR0cDovL2NhY2VydHMuZGln
# aWNlcnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9vdENBLmNydDCBgQYDVR0fBHow
# eDA6oDigNoY0aHR0cDovL2NybDQuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0QXNzdXJl
# ZElEUm9vdENBLmNybDA6oDigNoY0aHR0cDovL2NybDMuZGlnaWNlcnQuY29tL0Rp
# Z2lDZXJ0QXNzdXJlZElEUm9vdENBLmNybDBPBgNVHSAESDBGMDgGCmCGSAGG/WwA
# AgQwKjAoBggrBgEFBQcCARYcaHR0cHM6Ly93d3cuZGlnaWNlcnQuY29tL0NQUzAK
# BghghkgBhv1sAzAdBgNVHQ4EFgQUWsS5eyoKo6XqcQPAYPkt9mV1DlgwHwYDVR0j
# BBgwFoAUReuir/SSy4IxLVGLp6chnfNtyA8wDQYJKoZIhvcNAQELBQADggEBAD7s
# DVoks/Mi0RXILHwlKXaoHV0cLToaxO8wYdd+C2D9wz0PxK+L/e8q3yBVN7Dh9tGS
# dQ9RtG6ljlriXiSBThCk7j9xjmMOE0ut119EefM2FAaK95xGTlz/kLEbBw6RFfu6
# r7VRwo0kriTGxycqoSkoGjpxKAI8LpGjwCUR4pwUR6F6aGivm6dcIFzZcbEMj7uo
# +MUSaJ/PQMtARKUT8OZkDCUIQjKyNookAv4vcn4c10lFluhZHen6dGRrsutmQ9qz
# sIzV6Q3d9gEgzpkxYz0IGhizgZtPxpMQBvwHgfqL2vmCSfdibqFT+hKUGIUukpHq
# aGxEMrJmoecYpJpkUe8xggQ3MIIEMwIBATCBhjByMQswCQYDVQQGEwJVUzEVMBMG
# A1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMTEw
# LwYDVQQDEyhEaWdpQ2VydCBTSEEyIEFzc3VyZWQgSUQgQ29kZSBTaWduaW5nIENB
# AhAJT00SLqoJkIvAj67NF8OqMAkGBSsOAwIaBQCgeDAYBgorBgEEAYI3AgEMMQow
# CKACgAChAoAAMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMBwGCisGAQQBgjcC
# AQsxDjAMBgorBgEEAYI3AgEVMCMGCSqGSIb3DQEJBDEWBBRNb7MthQcSj7Fvsall
# 2XiXcJT7mTANBgkqhkiG9w0BAQEFAASCAQAEoadBQEcVaZVBAJk1rFUhbsRCWWh+
# pv/fltfKJRl6NPgT71awSr4x76rPjXfk43iN9zyITJzoKgVkA7iUh7oVpnC1BNGD
# 2Zko1eVfhgLZiQJSss2hRs6Zd/UlEH7MKU3YozmHYQlhIXxCXmZF1W7xFOJlk3XN
# sehmaLS+tDJ5ccQ+TTQSWVSMbHKcVBjPT1eCOT5WU9/NKOEoVCKScTy+6+Vzkp5Z
# MAoU6ji6R2nKxJRwk6KrT1x9Dn161D52XW7SPRznPvfOSxX0dzryEAxWfgztyMy9
# ivHR/jWCXCEeUtq5dSINfIbfN9Ri9Ouj1Xb2QueGqm/tjuvWCFZ0k2lHoYICCzCC
# AgcGCSqGSIb3DQEJBjGCAfgwggH0AgEBMHIwXjELMAkGA1UEBhMCVVMxHTAbBgNV
# BAoTFFN5bWFudGVjIENvcnBvcmF0aW9uMTAwLgYDVQQDEydTeW1hbnRlYyBUaW1l
# IFN0YW1waW5nIFNlcnZpY2VzIENBIC0gRzICEA7P9DjI/r81bgTYapgbGlAwCQYF
# Kw4DAhoFAKBdMBgGCSqGSIb3DQEJAzELBgkqhkiG9w0BBwEwHAYJKoZIhvcNAQkF
# MQ8XDTE5MDIyNzE2MjEwNlowIwYJKoZIhvcNAQkEMRYEFEHZHv+kgBB+/q1KUNaV
# w3uyTP3fMA0GCSqGSIb3DQEBAQUABIIBADKPjO6msO3HO6AwEhFQIuS19dtVlPG/
# lQy/c39Kzmzec966bsIGu+5kmh39c2SYzsIhz8KIEbnYMF03+lLNcKGKdIr1Kvnp
# hNyr3OQ7YOLZEtUrbbc+MY62xLHTfu6VYCt3mdOZyoHxSlCEDjFYhEs74KMcLfpu
# VOl/yzJAusq9zlGxfCuZVozdtrTMMKf02o5WqtLMok1KbMMCUt6sXHmrEKXZWNAx
# kFh3JciDcLLLUWEOwvb4WC6MWT7nDnVxe8D+EfyCixTav+qt6hg7UVpETdE1LnqT
# Ul+PGq5StVPCXOUK7WCUdPEixIfdakGgX33qNbPtj7mU0OwSy23YNmY=
# SIG # End signature block
