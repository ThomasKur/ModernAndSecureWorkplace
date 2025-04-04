<#
.DESCRIPTION
This script can be used to capture to local GPO Settings and to create a MSI File. This script has to be started with elvated priviledge. 

The created MSI can be found in the same directory as this script is. 

When the script is executed without parameters it creates a x64 MSI with Version 1.0.0. 

.EXAMPLE 
BuildMsiWithLocalGPO.ps1

.EXAMPLE
BuildMsiWithLocalGPO.ps1 -MSIVersion 1.0.1

.NOTES
Author: Thomas Kurth/baseVISION
Date:   08.11.2016

History
    001: First Version
    002: Now has the possibility to also copy the admx files to the destination computer to get there nicer reports.

ExitCodes:
    99001: Could not Write to LogFile
    99002: Could not Write to Windows Log
    99003: The user doesn't has the needed local Admin Token. Please restart the Script as Administrator.
    99004: Failed to Cleanup Capturing Folder
    99005: Error Capturing Local GPO
    99006: Failed to modify main wix config file
    99007: Error Harvesting files
    99008: Error Candle MSI
    99009: Error Compiling MSI
#>
[CmdletBinding()]
Param(
    [ValidateSet("x64", "x86", "ia64",ignorecase=$true)]
    $MSIArchitecture="x64",
    [Version]$MSIVersion="1.0.0",
    [switch]$HarvestADMX
)

## Manual Variable Definition
########################################################
$DebugPreference = "Continue"
$ScriptVersion = "001"
$ScriptName = "BuildMsiWithLocalGPO"

$LogFilePathFolder     = "C:\Windows\Logs"
$FallbackScriptPath    = "C:\Windows" # This is only used if the filename could not be resolved(IE running in ISE)

# Log Configuration
$DefaultLogOutputMode  = "Console" # "Console-LogFile","Console-WindowsEvent","LogFile-WindowsEvent","Console","LogFile","WindowsEvent","All"
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
        [ValidateSet("Console-LogFile","Console-WindowsEvent","LogFile-WindowsEvent","Console","LogFile","WindowsEvent","All")]
        [String]
        $OutputMode = $DefaultLogOutputMode
    ,
        [Parameter(Mandatory=$false)]
        [Exception]
        $Exception
    )
    
    $DateTimeString = Get-Date -Format "yyyy-MM-dd HH:mm:sszz"
    $Output = ($DateTimeString + "`t" + $Type.ToUpper() + "`t" + $Message)
    if($Exception){
        $ExceptionString =  ("[" + $Exception.GetType().FullName + "] " + $Exception.Message)
        $Output = "$Output - $ExceptionString"
    }

    if ($OutputMode -eq "Console" -OR $OutputMode -eq "Console-LogFile" -OR $OutputMode -eq "Console-WindowsEvent" -OR $OutputMode -eq "All") {
        if($Type -eq "Error"){
            Write-Error $output -ErrorAction Continue
        } elseif($Type -eq "Warn"){
            Write-Warning $output
        } elseif($Type -eq "Debug"){
            Write-Debug $output
        } else{
            Write-Verbose $output -Verbose
        }
    }
    
    if ($OutputMode -eq "LogFile" -OR $OutputMode -eq "Console-LogFile" -OR $OutputMode -eq "LogFile-WindowsEvent" -OR $OutputMode -eq "All") {
        try {
            Add-Content $LogFilePath -Value $Output -ErrorAction Stop
        } catch {
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
        } catch {
            exit 99002
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


#endregion

#region Dynamic Variables and Parameters
########################################################

# Try get actual ScriptName
try{
    $CurrentFileNameTemp = $MyInvocation.MyCommand.Name
    If($CurrentFileNameTemp -eq $null -or $CurrentFileNameTemp -eq ""){
        $CurrentFileName = "NotExecutedAsScript"
    } else {
        $CurrentFileName = $CurrentFileNameTemp
    }
} catch {
    $CurrentFileName = $LogFilePathScriptName
}
$LogFilePath = "$LogFilePathFolder\{0}_{1}_{2}.log" -f ($ScriptName -replace ".ps1", ''),$ScriptVersion,(Get-Date -uformat %Y%m%d%H%M)
# Try get actual ScriptPath
try{
    try{ 
        $ScriptPathTemp = Split-Path $MyInvocation.MyCommand.Path
    } catch {

    }
    if([String]::IsNullOrWhiteSpace($ScriptPathTemp)){
        $ScriptPathTemp = Split-Path $MyInvocation.InvocationName
    }

    If([String]::IsNullOrWhiteSpace($ScriptPathTemp)){
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
Write-Log "Start Script $Scriptname" -Type Info
Write-Log "MSI Version to create: $($MSIVersion.Major).$($MSIVersion.Minor).$($MSIVersion.Build)" -Type Debug
Write-Log "MSI Architecture to create: $($MSIArchitecture)" -Type Debug

# Cleanup GPO Backup Directory
Write-Log "Cleanup Local GPO Capture" -Type Info
try{
    Get-ChildItem -Path "$ScriptPath\GPOBackup" -ErrorAction Stop | Remove-Item -Recurse -Force -ErrorAction Stop
} catch {
    Write-Log "Cleanup Local GPO Capture failed" -Type Error -Exception $_.Exception
    exit 99004
}


# Check RunAs Admin Right
Write-Log "Check if the Script was started with the correct Rights." -Type Info
If ( ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator"))
{
    Write-Log "The user has the needed local Admin Token." -Type Info
} else {
    Write-Log "The user doesn't has the needed local Admin Token. Please restart the Script as Administrator." -Type Error
    exit 99003
}

#endregion

#region Main Script
########################################################


Write-Log "Capturing Local GPO ($ScriptPath\lgpo\lgpo.exe /b `"$ScriptPath\GPOBackup`""  -Type Info
$lgpoProcess = Start-Process -FilePath "$ScriptPath\lgpo\lgpo.exe" -ArgumentList "/b `"$ScriptPath\GPOBackup`"" -Wait -PassThru

while($lgpoProcess.HasExited -eq $false){ 
    Write-Log "Capturing Local GPO" -Type Info
    Start-Sleep -Seconds 1
}
if($lgpoProcess.ExitCode -eq 0){
    Write-Log "Successfully Captured Local GPO"  -Type Info
    if($lgpoProcess.StandardOutput -ne $null){
        Write-Log "Output:"
        Write-Log $lgpoProcess.StandardOutput.ReadToEnd()
    }
} else {
    Write-Log "Error($($lgpoProcess.ExitCode)) Capturing Local GPO with the following Output:" -Type Error
    if($lgpoProcess.StandardOutput -ne $null){
        Write-Log $lgpoProcess.StandardOutput.ReadToEnd()
    }
    if($lgpoProcess.StandardError -ne $null){
        Write-Log $lgpoProcess.StandardError.ReadToEnd() -Type Error
    }
    exit 99005
}

Write-Log "Copy Main Wix File and Modify Version" -Type Info
try{
    if($HarvestADMX){
        $mainWixFile = "$ScriptPath\wix-config\main.$MSIArchitecture.wxs"
    } else {
        $mainWixFile = "$ScriptPath\wix-config\main.$MSIArchitecture.wxs"
    }
    (Get-Content $mainWixFile -ErrorAction Stop).replace('CUSTOMMSIVERSION', "$($MSIVersion.Major).$($MSIVersion.Minor).$($MSIVersion.Build)") | Set-Content "$ScriptPath\GPOBackup\main.$MSIArchitecture.wxs" -Force -ErrorAction Stop
} catch {
    Write-Log "Failed to modify main wix config file" -Type Error -Exception $_.Exception
    exit 99006
}

Write-Log "Harvest files to include in MSI"  -Type Info
$heatProcess = Start-Process -FilePath "$ScriptPath\wix-binaries\heat.exe" -ArgumentList "dir .\GPOBackup -o .\GPOBackup\GPOFiles.wxs -cg GPOFiles -dr ProductFolder -sfrag -gg -g1" -WorkingDirectory $ScriptPath -Wait -PassThru
while($heatProcess.HasExited -eq $false){ 
    Write-Log "Harvesting files" -Type Info
    Start-Sleep -Seconds 1 
}
if($heatProcess.ExitCode -eq 0){
    Write-Log "Successfully Harvested files"  -Type Info
    if($heatProcess.StandardOutput -ne $null){
        Write-Log "Output:"
        Write-Log $heatProcess.StandardOutput.ReadToEnd()
    }
} else {
    Write-Log "Error Harvesting files with the following Output:" -Type Error
    if($heatProcess.StandardOutput -ne $null){
        Write-Log $heatProcess.StandardOutput.ReadToEnd()
    }
    if($heatProcess.StandardError -ne $null){
        Write-Log $heatProcess.StandardError.ReadToEnd() -Type Error
    }
    exit 99007
}
if($HarvestADMX){
    Write-Log "Harvest ADMX files to include in MSI"  -Type Info
    $heatProcess = Start-Process -FilePath "$ScriptPath\wix-binaries\heat.exe" -ArgumentList "dir .\ADMXToInclude -o .\GPOBackup\ADMXFiles.wxs -cg ADMXFiles -dr PolicyDefinitions -sfrag -gg -g1" -WorkingDirectory $ScriptPath -Wait -PassThru
    while($heatProcess.HasExited -eq $false){ 
        Write-Log "Harvesting ADMX files" -Type Info
        Start-Sleep -Seconds 1 
    }
    if($heatProcess.ExitCode -eq 0){
        Write-Log "Successfully Harvested ADMX files"  -Type Info
        if($heatProcess.StandardOutput -ne $null){
            Write-Log "Output:"
            Write-Log $heatProcess.StandardOutput.ReadToEnd()
        }
    } else {
        Write-Log "Error Harvesting ADMX files with the following Output:" -Type Error
        if($heatProcess.StandardOutput -ne $null){
            Write-Log $heatProcess.StandardOutput.ReadToEnd()
        }
        if($heatProcess.StandardError -ne $null){
            Write-Log $heatProcess.StandardError.ReadToEnd() -Type Error
        }
        exit 99007
    }

    (Get-Content "$ScriptPath\GPOBackup\ADMXFiles.wxs").replace('SourceDir\', 'SourceDir\ADMXToInclude\') | Set-Content "$ScriptPath\GPOBackup\ADMXFiles.wxs"
}
Write-Log "Candle MSI($MSIArchitecture)" -Type Info
if($HarvestADMX){
    $candleParam = "-ext WixUIExtension.dll -arch $MSIArchitecture -out .\GPOBackup\ .\GPOBackup\main.$MSIArchitecture.wxs .\GPOBackup\GPOFiles.wxs .\GPOBackup\ADMXFiles.wxs"
} else {
    $candleParam = "-ext WixUIExtension.dll -arch $MSIArchitecture -out .\GPOBackup\ .\GPOBackup\main.$MSIArchitecture.wxs .\GPOBackup\GPOFiles.wxs"
}
$candleProcess = Start-Process -FilePath "$ScriptPath\wix-binaries\candle.exe" -ArgumentList $candleParam -WorkingDirectory $ScriptPath -Wait -PassThru
while($candleProcess.HasExited -eq $false){ 
    Write-Log "Candle files" -Type Info
    Start-Sleep -Seconds 1 
}
if($candleProcess.ExitCode -eq 0){
    Write-Log "Successfully Candle files"  -Type Info
    if($candleProcess.StandardOutput -ne $null){
        Write-Log "Output:"
        Write-Log $candleProcess.StandardOutput.ReadToEnd()
    }
} else {
    Write-Log "Error Candle with the following Output:" -Type Error
    if($candleProcess.StandardOutput -ne $null){
        Write-Log $candleProcess.StandardOutput.ReadToEnd()
    }
    if($candleProcess.StandardError -ne $null){
        Write-Log $candleProcess.StandardError.ReadToEnd() -Type Error
    }
    exit 99008
}


Write-Log "Compile MSI" -Type Info
if($HarvestADMX){
    $lightParam = "-b . -nologo -ext WixUIExtension.dll -out .\Result\output.$MSIArchitecture.msi .\GPOBackup\main.$MSIArchitecture.wixobj .\GPOBackup\GPOFiles.wixobj .\GPOBackup\ADMXFiles.wixobj"
} else {
    $lightParam = "-b . -nologo -ext WixUIExtension.dll -out .\Result\output.$MSIArchitecture.msi .\GPOBackup\main.$MSIArchitecture.wixobj .\GPOBackup\GPOFiles.wixobj"
}
$lightProcess = Start-Process -FilePath "$ScriptPath\wix-binaries\light.exe" -ArgumentList $lightParam -WorkingDirectory $ScriptPath -Wait -PassThru
while($lightProcess.HasExited -eq $false){ 
    Write-Log "Compiling files" -Type Info
    Start-Sleep -Seconds 1 
}
if($lightProcess.ExitCode -eq 0){
    Write-Log "Successfully Compiled files"  -Type Info
    if($lightProcess.StandardOutput -ne $null){
        Write-Log "Output:"
        Write-Log $lightProcess.StandardOutput.ReadToEnd()
    }
} else {
    Write-Log "Error Compiling MSI with the following Output:" -Type Error
    if($lightProcess.StandardOutput -ne $null){
        Write-Log $lightProcess.StandardOutput.ReadToEnd()
    }
    if($lightProcess.StandardError -ne $null){
        Write-Log $lightProcess.StandardError.ReadToEnd() -Type Error
    }
    exit 99009
}
#>

#endregion

#region Finishing
########################################################

Write-Log "End Script $Scriptname"

#endregion