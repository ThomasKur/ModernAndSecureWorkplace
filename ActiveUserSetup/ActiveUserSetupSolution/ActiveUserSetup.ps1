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
    1.1.2: Fixed a Problem that on french computers 64-Bit detection dident work correctly.


#>


## Manual Variable Definition
########################################################
$ScriptVersion = "1.1.2"

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
    if ((Get-CimInstance -ClassName Win32_OperatingSystem).OSArchitecture -like '64*') {
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
# MIIjjgYJKoZIhvcNAQcCoIIjfzCCI3sCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDimEspa+2OE2Lg
# RPJPQui2793lGQa23Jg8/lA/MqOP5aCCHYcwggUwMIIEGKADAgECAhAECRgbX9W7
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
# aGxEMrJmoecYpJpkUe8wggVCMIIEKqADAgECAhAD/SCAVAQOGx46UbQEe5/RMA0G
# CSqGSIb3DQEBCwUAMHIxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJ
# bmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xMTAvBgNVBAMTKERpZ2lDZXJ0
# IFNIQTIgQXNzdXJlZCBJRCBDb2RlIFNpZ25pbmcgQ0EwHhcNMjAxMTE3MDAwMDAw
# WhcNMjMxMTIxMjM1OTU5WjB/MQswCQYDVQQGEwJDSDESMBAGA1UECBMJU29sb3Ro
# dXJuMREwDwYDVQQHDAhEw6RuaWtlbjEWMBQGA1UEChMNYmFzZVZJU0lPTiBBRzEZ
# MBcGA1UECxMQSW50ZXJuYWwgU2NyaXB0czEWMBQGA1UEAxMNYmFzZVZJU0lPTiBB
# RzCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAOplOljeTAT2oR6TnQEo
# 0zv1fVaRzmA4HKdckeZQFF4UTM7WkuofDEV++69GXR+LIkq5M8u4jKzMyhe0PtFY
# MpH03/e7ouC1SGb+LOHa7RSdwNnhui7DfpWcPXtefc7HTtJHMGn1RWKek3r23a3V
# L880yU0tIcOcUDq0+nhf2McRMvTWreeR27B5g4CMGZKEbADf4x1ZNStbxukOJBEf
# zTHAkoE20GOnKvuQgMNqX7wCL0D/PB7PogDWU4kjkTimpI+bMk6vPWTE1vEGXk4Q
# b/Yn4u6VjbbU5rebrwE9Fr7Qowbz3DIr9Yulre3aaClmcbwRR1tBhqHUfZM6NKCn
# b3kCAwEAAaOCAcUwggHBMB8GA1UdIwQYMBaAFFrEuXsqCqOl6nEDwGD5LfZldQ5Y
# MB0GA1UdDgQWBBSA78VurPX97gGLresGDYzdR6G7oDAOBgNVHQ8BAf8EBAMCB4Aw
# EwYDVR0lBAwwCgYIKwYBBQUHAwMwdwYDVR0fBHAwbjA1oDOgMYYvaHR0cDovL2Ny
# bDMuZGlnaWNlcnQuY29tL3NoYTItYXNzdXJlZC1jcy1nMS5jcmwwNaAzoDGGL2h0
# dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9zaGEyLWFzc3VyZWQtY3MtZzEuY3JsMEwG
# A1UdIARFMEMwNwYJYIZIAYb9bAMBMCowKAYIKwYBBQUHAgEWHGh0dHBzOi8vd3d3
# LmRpZ2ljZXJ0LmNvbS9DUFMwCAYGZ4EMAQQBMIGEBggrBgEFBQcBAQR4MHYwJAYI
# KwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBOBggrBgEFBQcwAoZC
# aHR0cDovL2NhY2VydHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0U0hBMkFzc3VyZWRJ
# RENvZGVTaWduaW5nQ0EuY3J0MAwGA1UdEwEB/wQCMAAwDQYJKoZIhvcNAQELBQAD
# ggEBAJIR7cJPoVMP9T/V4Vj5vqF2HeL8JL/X5z21jnliCRv3kfoS3I4PF6VyTWCI
# AQkMALsCqqWebcpBLAOYmgke8PRjj2HZIwvgCYVkYnGx9xFEh02KKMMpuN7EDRwY
# EDT26+HokPdj8Fs1h/pVr5hu0ATtXyR1Fsh7DDEPw1wpeCAKtLbzDMuw00XwGCyA
# 9BeGJinVYy9Lyg+blzmTI7A2jGbCHkQnX/TvG49Si+B/A5ZQpOkKG79qKoUJdGtI
# tjjcImUH0qtw/TY9QLWQlcGXjr2P4N7g+lLbJItuIcvcIYHSaEAN5NO3drUQTiFt
# gl+iwDkPnt+WUQcl2Sr/J9yRyw0wggWNMIIEdaADAgECAhAOmxiO+dAt5+/bUOII
# QBhaMA0GCSqGSIb3DQEBDAUAMGUxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdp
# Q2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xJDAiBgNVBAMTG0Rp
# Z2lDZXJ0IEFzc3VyZWQgSUQgUm9vdCBDQTAeFw0yMjA4MDEwMDAwMDBaFw0zMTEx
# MDkyMzU5NTlaMGIxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMx
# GTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xITAfBgNVBAMTGERpZ2lDZXJ0IFRy
# dXN0ZWQgUm9vdCBHNDCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAL/m
# kHNo3rvkXUo8MCIwaTPswqclLskhPfKK2FnC4SmnPVirdprNrnsbhA3EMB/zG6Q4
# FutWxpdtHauyefLKEdLkX9YFPFIPUh/GnhWlfr6fqVcWWVVyr2iTcMKyunWZanMy
# lNEQRBAu34LzB4TmdDttceItDBvuINXJIB1jKS3O7F5OyJP4IWGbNOsFxl7sWxq8
# 68nPzaw0QF+xembud8hIqGZXV59UWI4MK7dPpzDZVu7Ke13jrclPXuU15zHL2pNe
# 3I6PgNq2kZhAkHnDeMe2scS1ahg4AxCN2NQ3pC4FfYj1gj4QkXCrVYJBMtfbBHMq
# bpEBfCFM1LyuGwN1XXhm2ToxRJozQL8I11pJpMLmqaBn3aQnvKFPObURWBf3JFxG
# j2T3wWmIdph2PVldQnaHiZdpekjw4KISG2aadMreSx7nDmOu5tTvkpI6nj3cAORF
# JYm2mkQZK37AlLTSYW3rM9nF30sEAMx9HJXDj/chsrIRt7t/8tWMcCxBYKqxYxhE
# lRp2Yn72gLD76GSmM9GJB+G9t+ZDpBi4pncB4Q+UDCEdslQpJYls5Q5SUUd0vias
# tkF13nqsX40/ybzTQRESW+UQUOsxxcpyFiIJ33xMdT9j7CFfxCBRa2+xq4aLT8LW
# RV+dIPyhHsXAj6KxfgommfXkaS+YHS312amyHeUbAgMBAAGjggE6MIIBNjAPBgNV
# HRMBAf8EBTADAQH/MB0GA1UdDgQWBBTs1+OC0nFdZEzfLmc/57qYrhwPTzAfBgNV
# HSMEGDAWgBRF66Kv9JLLgjEtUYunpyGd823IDzAOBgNVHQ8BAf8EBAMCAYYweQYI
# KwYBBQUHAQEEbTBrMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdpY2VydC5j
# b20wQwYIKwYBBQUHMAKGN2h0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdp
# Q2VydEFzc3VyZWRJRFJvb3RDQS5jcnQwRQYDVR0fBD4wPDA6oDigNoY0aHR0cDov
# L2NybDMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9vdENBLmNybDAR
# BgNVHSAECjAIMAYGBFUdIAAwDQYJKoZIhvcNAQEMBQADggEBAHCgv0NcVec4X6Cj
# dBs9thbX979XB72arKGHLOyFXqkauyL4hxppVCLtpIh3bb0aFPQTSnovLbc47/T/
# gLn4offyct4kvFIDyE7QKt76LVbP+fT3rDB6mouyXtTP0UNEm0Mh65ZyoUi0mcud
# T6cGAxN3J0TU53/oWajwvy8LpunyNDzs9wPHh6jSTEAZNUZqaVSwuKFWjuyk1T3o
# sdz9HNj0d1pcVIxv76FQPfx2CWiEn2/K2yCNNWAcAgPLILCsWKAOQGPFmCLBsln1
# VWvPJ6tsds5vIy30fnFqI2si/xK4VC0nftg62fC2h5b9W9FcrBjDTZ9ztwGpn1eq
# XijiuZQwggauMIIElqADAgECAhAHNje3JFR82Ees/ShmKl5bMA0GCSqGSIb3DQEB
# CwUAMGIxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNV
# BAsTEHd3dy5kaWdpY2VydC5jb20xITAfBgNVBAMTGERpZ2lDZXJ0IFRydXN0ZWQg
# Um9vdCBHNDAeFw0yMjAzMjMwMDAwMDBaFw0zNzAzMjIyMzU5NTlaMGMxCzAJBgNV
# BAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjE7MDkGA1UEAxMyRGlnaUNl
# cnQgVHJ1c3RlZCBHNCBSU0E0MDk2IFNIQTI1NiBUaW1lU3RhbXBpbmcgQ0EwggIi
# MA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQDGhjUGSbPBPXJJUVXHJQPE8pE3
# qZdRodbSg9GeTKJtoLDMg/la9hGhRBVCX6SI82j6ffOciQt/nR+eDzMfUBMLJnOW
# bfhXqAJ9/UO0hNoR8XOxs+4rgISKIhjf69o9xBd/qxkrPkLcZ47qUT3w1lbU5ygt
# 69OxtXXnHwZljZQp09nsad/ZkIdGAHvbREGJ3HxqV3rwN3mfXazL6IRktFLydkf3
# YYMZ3V+0VAshaG43IbtArF+y3kp9zvU5EmfvDqVjbOSmxR3NNg1c1eYbqMFkdECn
# wHLFuk4fsbVYTXn+149zk6wsOeKlSNbwsDETqVcplicu9Yemj052FVUmcJgmf6Aa
# RyBD40NjgHt1biclkJg6OBGz9vae5jtb7IHeIhTZgirHkr+g3uM+onP65x9abJTy
# UpURK1h0QCirc0PO30qhHGs4xSnzyqqWc0Jon7ZGs506o9UD4L/wojzKQtwYSH8U
# NM/STKvvmz3+DrhkKvp1KCRB7UK/BZxmSVJQ9FHzNklNiyDSLFc1eSuo80VgvCON
# WPfcYd6T/jnA+bIwpUzX6ZhKWD7TA4j+s4/TXkt2ElGTyYwMO1uKIqjBJgj5FBAS
# A31fI7tk42PgpuE+9sJ0sj8eCXbsq11GdeJgo1gJASgADoRU7s7pXcheMBK9Rp61
# 03a50g5rmQzSM7TNsQIDAQABo4IBXTCCAVkwEgYDVR0TAQH/BAgwBgEB/wIBADAd
# BgNVHQ4EFgQUuhbZbU2FL3MpdpovdYxqII+eyG8wHwYDVR0jBBgwFoAU7NfjgtJx
# XWRM3y5nP+e6mK4cD08wDgYDVR0PAQH/BAQDAgGGMBMGA1UdJQQMMAoGCCsGAQUF
# BwMIMHcGCCsGAQUFBwEBBGswaTAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGln
# aWNlcnQuY29tMEEGCCsGAQUFBzAChjVodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5j
# b20vRGlnaUNlcnRUcnVzdGVkUm9vdEc0LmNydDBDBgNVHR8EPDA6MDigNqA0hjJo
# dHRwOi8vY3JsMy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkUm9vdEc0LmNy
# bDAgBgNVHSAEGTAXMAgGBmeBDAEEAjALBglghkgBhv1sBwEwDQYJKoZIhvcNAQEL
# BQADggIBAH1ZjsCTtm+YqUQiAX5m1tghQuGwGC4QTRPPMFPOvxj7x1Bd4ksp+3CK
# Daopafxpwc8dB+k+YMjYC+VcW9dth/qEICU0MWfNthKWb8RQTGIdDAiCqBa9qVbP
# FXONASIlzpVpP0d3+3J0FNf/q0+KLHqrhc1DX+1gtqpPkWaeLJ7giqzl/Yy8ZCaH
# bJK9nXzQcAp876i8dU+6WvepELJd6f8oVInw1YpxdmXazPByoyP6wCeCRK6ZJxur
# JB4mwbfeKuv2nrF5mYGjVoarCkXJ38SNoOeY+/umnXKvxMfBwWpx2cYTgAnEtp/N
# h4cku0+jSbl3ZpHxcpzpSwJSpzd+k1OsOx0ISQ+UzTl63f8lY5knLD0/a6fxZsNB
# zU+2QJshIUDQtxMkzdwdeDrknq3lNHGS1yZr5Dhzq6YBT70/O3itTK37xJV77Qpf
# MzmHQXh6OOmc4d0j/R0o08f56PGYX/sr2H7yRp11LB4nLCbbbxV7HhmLNriT1Oby
# F5lZynDwN7+YAN8gFk8n+2BnFqFmut1VwDophrCYoCvtlUG3OtUVmDG0YgkPCr2B
# 2RP+v6TR81fZvAT6gt4y3wSJ8ADNXcL50CN/AAvkdgIm2fBldkKmKYcJRyvmfxqk
# hQ/8mJb2VVQrH4D6wPIOK+XW+6kvRBVK5xMOHds3OBqhK/bt1nz8MIIGxjCCBK6g
# AwIBAgIQCnpKiJ7JmUKQBmM4TYaXnTANBgkqhkiG9w0BAQsFADBjMQswCQYDVQQG
# EwJVUzEXMBUGA1UEChMORGlnaUNlcnQsIEluYy4xOzA5BgNVBAMTMkRpZ2lDZXJ0
# IFRydXN0ZWQgRzQgUlNBNDA5NiBTSEEyNTYgVGltZVN0YW1waW5nIENBMB4XDTIy
# MDMyOTAwMDAwMFoXDTMzMDMxNDIzNTk1OVowTDELMAkGA1UEBhMCVVMxFzAVBgNV
# BAoTDkRpZ2lDZXJ0LCBJbmMuMSQwIgYDVQQDExtEaWdpQ2VydCBUaW1lc3RhbXAg
# MjAyMiAtIDIwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQC5KpYjply8
# X9ZJ8BWCGPQz7sxcbOPgJS7SMeQ8QK77q8TjeF1+XDbq9SWNQ6OB6zhj+TyIad48
# 0jBRDTEHukZu6aNLSOiJQX8Nstb5hPGYPgu/CoQScWyhYiYB087DbP2sO37cKhyp
# vTDGFtjavOuy8YPRn80JxblBakVCI0Fa+GDTZSw+fl69lqfw/LH09CjPQnkfO8eT
# B2ho5UQ0Ul8PUN7UWSxEdMAyRxlb4pguj9DKP//GZ888k5VOhOl2GJiZERTFKwyg
# M9tNJIXogpThLwPuf4UCyYbh1RgUtwRF8+A4vaK9enGY7BXn/S7s0psAiqwdjTuA
# aP7QWZgmzuDtrn8oLsKe4AtLyAjRMruD+iM82f/SjLv3QyPf58NaBWJ+cCzlK7I9
# Y+rIroEga0OJyH5fsBrdGb2fdEEKr7mOCdN0oS+wVHbBkE+U7IZh/9sRL5IDMM4w
# t4sPXUSzQx0jUM2R1y+d+/zNscGnxA7E70A+GToC1DGpaaBJ+XXhm+ho5GoMj+vk
# sSF7hmdYfn8f6CvkFLIW1oGhytowkGvub3XAsDYmsgg7/72+f2wTGN/GbaR5Sa2L
# f2GHBWj31HDjQpXonrubS7LitkE956+nGijJrWGwoEEYGU7tR5thle0+C2Fa6j56
# mJJRzT/JROeAiylCcvd5st2E6ifu/n16awIDAQABo4IBizCCAYcwDgYDVR0PAQH/
# BAQDAgeAMAwGA1UdEwEB/wQCMAAwFgYDVR0lAQH/BAwwCgYIKwYBBQUHAwgwIAYD
# VR0gBBkwFzAIBgZngQwBBAIwCwYJYIZIAYb9bAcBMB8GA1UdIwQYMBaAFLoW2W1N
# hS9zKXaaL3WMaiCPnshvMB0GA1UdDgQWBBSNZLeJIf5WWESEYafqbxw2j92vDTBa
# BgNVHR8EUzBRME+gTaBLhklodHRwOi8vY3JsMy5kaWdpY2VydC5jb20vRGlnaUNl
# cnRUcnVzdGVkRzRSU0E0MDk2U0hBMjU2VGltZVN0YW1waW5nQ0EuY3JsMIGQBggr
# BgEFBQcBAQSBgzCBgDAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQu
# Y29tMFgGCCsGAQUFBzAChkxodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGln
# aUNlcnRUcnVzdGVkRzRSU0E0MDk2U0hBMjU2VGltZVN0YW1waW5nQ0EuY3J0MA0G
# CSqGSIb3DQEBCwUAA4ICAQANLSN0ptH1+OpLmT8B5PYM5K8WndmzjJeCKZxDbwEt
# qzi1cBG/hBmLP13lhk++kzreKjlaOU7YhFmlvBuYquhs79FIaRk4W8+JOR1wcNlO
# 3yMibNXf9lnLocLqTHbKodyhK5a4m1WpGmt90fUCCU+C1qVziMSYgN/uSZW3s8zF
# p+4O4e8eOIqf7xHJMUpYtt84fMv6XPfkU79uCnx+196Y1SlliQ+inMBl9AEiZcfq
# XnSmWzWSUHz0F6aHZE8+RokWYyBry/J70DXjSnBIqbbnHWC9BCIVJXAGcqlEO2lH
# EdPu6cegPk8QuTA25POqaQmoi35komWUEftuMvH1uzitzcCTEdUyeEpLNypM81zc
# toXAu3AwVXjWmP5UbX9xqUgaeN1Gdy4besAzivhKKIwSqHPPLfnTI/KeGeANlCig
# 69saUaCVgo4oa6TOnXbeqXOqSGpZQ65f6vgPBkKd3wZolv4qoHRbY2beayy4eKpN
# cG3wLPEHFX41tOa1DKKZpdcVazUOhdbgLMzgDCS4fFILHpl878jIxYxYaa+rPeHP
# zH0VrhS/inHfypex2EfqHIXgRU4SHBQpWMxv03/LvsEOSm8gnK7ZczJZCOctkqEa
# Ef4ymKZdK5fgi9OczG21Da5HYzhHF1tvE9pqEG4fSbdEW7QICodaWQR2EaGndwIT
# HDGCBV0wggVZAgEBMIGGMHIxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2Vy
# dCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xMTAvBgNVBAMTKERpZ2lD
# ZXJ0IFNIQTIgQXNzdXJlZCBJRCBDb2RlIFNpZ25pbmcgQ0ECEAP9IIBUBA4bHjpR
# tAR7n9EwDQYJYIZIAWUDBAIBBQCggYQwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKA
# ADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYK
# KwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQgimeDT/mejDxnOSYWhnIhWgHvmeqf
# zkX9fd4N0SJPJtUwDQYJKoZIhvcNAQEBBQAEggEAdMVn9p9lkzWtxxhJUA43Sr7r
# PbTLhTK8tlUidVwWxHW20YvaJOpMxAQNL07Z/rxdotsbaEYRAYW47SK/FiN8U1UQ
# gvYJlqf+gmEwmy/BI00sMv+32S0D2gKvGyNuCdzFdyWvizn4T8YAeVCiJ8qiOM3y
# MtcKgNlk+cXlgG2OhnwI0pMFG3j9oUoXHPrXLOYvhAQhU7mQtZMgw0M0Xm5KMKrP
# i+haymRz4NsQ9ibFW93PSb3acTO0fsN1QLUyJf7Umkte5HamOQnBL4Oif3kSufux
# NHaTC/9hws/e6VU/pjBeOxREenSkklKRNxYeF7Wa/yyLAUL8gT1C+wldhWdM86GC
# AyAwggMcBgkqhkiG9w0BCQYxggMNMIIDCQIBATB3MGMxCzAJBgNVBAYTAlVTMRcw
# FQYDVQQKEw5EaWdpQ2VydCwgSW5jLjE7MDkGA1UEAxMyRGlnaUNlcnQgVHJ1c3Rl
# ZCBHNCBSU0E0MDk2IFNIQTI1NiBUaW1lU3RhbXBpbmcgQ0ECEAp6SoieyZlCkAZj
# OE2Gl50wDQYJYIZIAWUDBAIBBQCgaTAYBgkqhkiG9w0BCQMxCwYJKoZIhvcNAQcB
# MBwGCSqGSIb3DQEJBTEPFw0yMjA4MjUxNTUwMTVaMC8GCSqGSIb3DQEJBDEiBCAn
# KieE58GBsJNPYJAF8DXv47rIzPajW80+qojnCjYTeTANBgkqhkiG9w0BAQEFAASC
# AgA4FXk5Psomlckyf1fgCU3GRVtGgTX04PApT+sewhfoqEuPeUHnf6jzvhN2Ia7n
# /UlcInXVsSKOVKMgarNOlTaX7Aie1AVUZe5eFFk9SgnYmy4z03RP9EY/O7aj8IA7
# PvxpSzLtw5azwRVvX+0KYNkc2EUbvCntc/3rO1JoSnvMgK5HSNxs5t+IQo9zw3ke
# ARTiNPsEOtfy6AN/O9YlEF3mDBdnYbRSYenNkHXC3Ope3d50n1xU4JOR3A/M9FJz
# 82szkn2gdkcqA49PmEWdPy0i9eYcmToP7jn3R01rYbQFLcjIcLAt20Usk9Dncnza
# KdMUz2qJkywIC3wAu+N14ppOuKPSD3sV1iWltly+6wEcuMvm1ChziWZAOAC12Ziw
# 7GbD3TScLuw8L7xzK8Myh0A3bDM6zvZCKfP4mN35VRnWdLKravvvNBwlXGcfRPbN
# BESy+yUTChDWR9Ceo5HhXq1Ue1BTGOGPyoXVKMtdWDba/V6eqQJm7gbbLcd2gNRC
# DAdLs5WR10oaE+ulNjda4OOer7nOjTNcJrSv+BIJLncEaOr/rBRhhLYw+tQ09GOH
# s9PuGmnB//5NdLofVBsqWedpaSKYMeS90a+tyVYbpbM1z2HHZxznsdk/1vm+oSGU
# 1v0cOkAil77FH5UzEFGBcq9rBIfZ0RzKTSCYAjduvPAmEQ==
# SIG # End signature block
