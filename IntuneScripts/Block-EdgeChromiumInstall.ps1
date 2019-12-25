<#
.Synopsis
This script will block the installation of the chromium based Microsoft Edge Browser.

https://docs.microsoft.com/en-us/DeployEdge/microsoft-edge-blocker-toolkit


.NOTES
  Version:        1.0
  Author:         Thomas Kurth - baseVISION AG
  Creation Date:  2019/12/25
  Purpose/Change: Initial script development

#>

[CmdletBinding()]
Param(
)

## Manual Variable Definition
########################################################
$DebugPreference = "Continue"
$ScriptVersion = "001"
$ScriptName = "Block-EdgeChromiumInstall.ps1"
$ProgressbarPercentage = 0

$LogFilePathFolder = "c:\Windows\Logs"
$FallbackScriptPath = "C:\Windows" # This is only used if the filename could not be resolved(IE running in ISE)

# Log Configuration
$DefaultLogOutputMode = "Console-LogFile" # "Console-LogFile","Console-WindowsEvent","LogFile-WindowsEvent","Console","LogFile","WindowsEvent","All"
$DefaultLogWindowsEventSource = $ScriptName
$DefaultLogWindowsEventLog = "CustomPS"

 
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
        [Parameter(Mandatory = $true, Position = 1)]
        [String]
        $Message
        ,
        [Parameter(Mandatory = $false)]
        [ValidateSet("Info", "Debug", "Warn", "Error")]
        [String]
        $Type = "Debug"
        ,
        [Parameter(Mandatory = $false)]
        [ValidateSet("Console-LogFile", "Console-WindowsEvent", "LogFile-WindowsEvent", "Console", "LogFile", "WindowsEvent", "All")]
        [String]
        $OutputMode = $DefaultLogOutputMode
        ,
        [Parameter(Mandatory = $false)]
        [Exception]
        $Exception
    )
    
    $DateTimeString = Get-Date -Format "yyyy-MM-dd HH:mm:sszz"
    $Output = ($DateTimeString + "`t" + $Type.ToUpper() + "`t" + $Message)
    if ($Exception) {
        $ExceptionString = ("[" + $Exception.GetType().FullName + "] " + $Exception.Message)
        $Output = "$Output - $ExceptionString"
    }
 
    if ($OutputMode -eq "Console" -OR $OutputMode -eq "Console-LogFile" -OR $OutputMode -eq "Console-WindowsEvent" -OR $OutputMode -eq "All") {
        if ($Type -eq "Error") {
            Write-Error $output
        }
        elseif ($Type -eq "Warn") {
            Write-Warning $output
        }
        elseif ($Type -eq "Debug") {
            Write-Debug $output
        }
        else {
            Write-Verbose $output -Verbose
        }
    }
    
    if ($OutputMode -eq "LogFile" -OR $OutputMode -eq "Console-LogFile" -OR $OutputMode -eq "LogFile-WindowsEvent" -OR $OutputMode -eq "All") {
        try {
            Add-Content $LogFilePath -Value $Output -ErrorAction Stop
        }
        catch {
            exit 99001
        }
    }
 
    if ($OutputMode -eq "Console-WindowsEvent" -OR $OutputMode -eq "WindowsEvent" -OR $OutputMode -eq "LogFile-WindowsEvent" -OR $OutputMode -eq "All") {
        try {
            New-EventLog -LogName $DefaultLogWindowsEventLog -Source $DefaultLogWindowsEventSource -ErrorAction SilentlyContinue
            switch ($Type) {
                "Warn" {
                    $EventType = "Warning"
                    break
                }
                "Error" {
                    $EventType = "Error"
                    break
                }
                default {
                    $EventType = "Information"
                }
            }
            Write-EventLog -LogName $DefaultLogWindowsEventLog -Source $DefaultLogWindowsEventSource -EntryType $EventType -EventId 1 -Message $Output -ErrorAction Stop
        }
        catch {
            exit 99002
        }
    }
}
 
function New-Folder {
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
        [Parameter(Mandatory = $True, Position = 1)]
        [string]$Path
    )
    # Check if the folder Exists
 
    if (Test-Path $Path) {
        Write-Log "Folder: $Path Already Exists"
    }
    else {
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
        [Parameter(Mandatory = $True)]
        [string]$Path,
        [Parameter(Mandatory = $True)]
        [string]$Name,
        [Parameter(Mandatory = $True)]
        [AllowEmptyString()]
        [string]$Value,
        [Parameter(Mandatory = $True)]
        [string]$Type
    )
    
    try {
        $ErrorActionPreference = 'Stop' # convert all errors to terminating errors
        Start-Transaction
 
        if (Test-Path $Path -erroraction silentlycontinue) {      
 
        }
        else {
            New-Item -Path $Path -Force
            Write-Log "Registry key $Path created"  
        } 
        $null = New-ItemProperty -Path $Path -Name $Name -PropertyType $Type -Value $Value -Force
        Write-Log "Registry Value $Path, $Name, $Type, $Value set"
        Complete-Transaction
    }
    catch {
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
        [Parameter(Mandatory = $True)]
        [string]$Script = "$ScriptName`_$ScriptVersion`.ps1",
        [Parameter(Mandatory = $False)]
        [string]$LogfileLocation = $LogFilePath,
        [Parameter(Mandatory = $True)]
        [string]$ExitMessage
    )
 
    $DateTime = Get-Date –f o
    #The registry Key into which the information gets written must be checked and if not existing created
    if ((Test-Path "HKLM:\SOFTWARE\_Custom") -eq $False) {
        $null = New-Item -Path "HKLM:\SOFTWARE\_Custom"
    }
    if ((Test-Path "HKLM:\SOFTWARE\_Custom\Scripts") -eq $False) {
        $null = New-Item -Path "HKLM:\SOFTWARE\_Custom\Scripts"
    }
    try { 
        #The new key gets created and the values written into it
        $null = New-Item -Path "HKLM:\SOFTWARE\_Custom\Scripts\$Script" -ErrorAction Stop -Force
        $null = New-ItemProperty -Path "HKLM:\SOFTWARE\_Custom\Scripts\$Script" -Name "Scriptname" -Value "$Script" -ErrorAction Stop -Force
        $null = New-ItemProperty -Path "HKLM:\SOFTWARE\_Custom\Scripts\$Script" -Name "Time" -Value "$DateTime" -ErrorAction Stop -Force
        $null = New-ItemProperty -Path "HKLM:\SOFTWARE\_Custom\Scripts\$Script" -Name "ExitMessage" -Value "$ExitMessage" -ErrorAction Stop -Force
        $null = New-ItemProperty -Path "HKLM:\SOFTWARE\_Custom\Scripts\$Script" -Name "LogfileLocation" -Value "$LogfileLocation" -ErrorAction Stop -Force
    }
    catch { 
        Write-Log "Set-ExitMessageRegistry failed" -Type Error -Exception $_.Exception
        #If the registry keys can not be written the Error Message is returned and the indication which line (therefore which Entry) had the error
        exit 99003
    }
}

#endregion

#region Dynamic Variables and Parameters
########################################################
 
# Try get actual ScriptName
try {
    $CurrentFileNameTemp = $MyInvocation.MyCommand.Name
    If ($CurrentFileNameTemp -eq $null -or $CurrentFileNameTemp -eq "") {
        $CurrentFileName = "NotExecutedAsScript"
    }
    else {
        $CurrentFileName = $CurrentFileNameTemp
    }
}
catch {
    $CurrentFileName = $LogFilePathScriptName
}
$LogFilePath = "$LogFilePathFolder\{0}_{1}_{2}.log" -f ($ScriptName -replace ".ps1", ''), $ScriptVersion, (Get-Date -uformat %Y%m%d%H%M)
# Try get actual ScriptPath
try {
    try { 
        $ScriptPathTemp = Split-Path $MyInvocation.MyCommand.Path
    }
    catch {
 
    }
    if ([String]::IsNullOrWhiteSpace($ScriptPathTemp)) {
        $ScriptPathTemp = Split-Path $MyInvocation.InvocationName
    }
 
    If ([String]::IsNullOrWhiteSpace($ScriptPathTemp)) {
        $ScriptPath = $FallbackScriptPath
    }
    else {
        $ScriptPath = $ScriptPathTemp
    }
}
catch {
    $ScriptPath = $FallbackScriptPath
}
 
#endregion
 
#region Initialization
########################################################
 
New-Folder $LogFilePathFolder
Write-Log "Start Script $Scriptname"
 
 
#endregion
 
#region Main Script
########################################################

Set-RegValue -Path "HKLM:\SOFTWARE\Microsoft\EdgeUpdate" -Name DoNotUpdateToEdgeWithChromium -Value 1 -Type DWord

#endregion