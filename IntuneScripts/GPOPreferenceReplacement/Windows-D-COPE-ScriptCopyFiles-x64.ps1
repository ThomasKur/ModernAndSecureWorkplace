<#
.DESCRIPTION
This script copies file son logon
When executed under SYSTEM authority a scheduled task is created to ensure recurring script execution on each user logon.

.NOTES
    Version:          1.0
    Author:           Thomas Kurth/baseVISION AG / https://www.wpninjas.ch
    Creation Date:    15.02.2022

    Modifications
    Purpose/Change:   07.02.2022 - Initial script development

	Initial script taken from Nicola Suter, nicolonsky tech: https://tech.nicolonsky.ch


#>
[CmdletBinding()]
Param()

###########################################################################################
# Start transcript for logging
###########################################################################################

Start-Transcript -Path $(Join-Path $env:temp "FileCopyMapping.log")

## Manual Variable Definition
########################################################

$appdata = [Environment]::GetFolderPath("ApplicationData")

$FileCopys = @()
$FileCopys += [pscustomobject]@{Source="filesystem::\\sigvaris-group.com\NETLOGON\SAP\740\";Destination="$appdata\SAP\Common\";ADGroup=""}


# Override with your Active Directory Domain Name e.g. 'ds.wpninjas.ch' if you haven't configured the domain name as DHCP option
$searchRoot = ""


###########################################################################################
# Helper function to determine a users group membership
###########################################################################################

# Kudos for Tobias Renstrm who showed me this!
function Get-ADGroupMembership {
	param(
		[parameter(Mandatory = $true)]
		[string]$UserPrincipalName
	)

	process {

		try {

			if ([string]::IsNullOrEmpty($env:USERDNSDOMAIN) -and [string]::IsNullOrEmpty($searchRoot)) {
				Write-Error "Security group filtering won't work because `$env:USERDNSDOMAIN is not available!"
				Write-Warning "You can override your AD Domain in the `$overrideUserDnsDomain variable"
			}
			else {

				# if no domain specified fallback to PowerShell environment variable
				if ([string]::IsNullOrEmpty($searchRoot)) {
					$searchRoot = $env:USERDNSDOMAIN
				}

				$searcher = New-Object -TypeName System.DirectoryServices.DirectorySearcher
				$searcher.Filter = "(&(userprincipalname=$UserPrincipalName))"
				$searcher.SearchRoot = "LDAP://$searchRoot"
				$distinguishedName = $searcher.FindOne().Properties.distinguishedname
				$searcher.Filter = "(member:1.2.840.113556.1.4.1941:=$distinguishedName)"

				[void]$searcher.PropertiesToLoad.Add("name")

				$list = [System.Collections.Generic.List[String]]@()

				$results = $searcher.FindAll()

				foreach ($result in $results) {
					$resultItem = $result.Properties
					[void]$List.add($resultItem.name)
				}

				$list
			}
		}
		catch {
			#Nothing we can do
			Write-Warning $_.Exception.Message
		}
	}
}

#check if running as system
function Test-RunningAsSystem {
	[CmdletBinding()]
	param()
	process {
		return [bool]($(whoami -user) -match "S-1-5-18")
	}
}

###########################################################################################
# Get current group membership for the group filter capabilities
###########################################################################################

Write-Output "Running as SYSTEM: $(Test-RunningAsSystem)"
try {
	#check if running as user and not system
	if (-not (Test-RunningAsSystem)) {

		$groupMemberships = Get-ADGroupMembership -UserPrincipalName $(whoami -upn)
	} else {
		# No remediation required as executed as System
		exit 0
	}
}
catch {
	#nothing we can do
}


###########################################################################################
#region Copy FIles
###########################################################################################


# Add file copy processes only when executed as user
if (-not (Test-RunningAsSystem)) {
    $FileCopysForUser = @()
    foreach ($FileCopy in $FileCopys) { 
        if($FileCopy.ADGroup -ne $null -and $FileCopy.ADGroup.Contains(",")) { 
            $Agroups = $FileCopy.ADGroup.Split(",") 
            foreach ($Agroup in $Agroups) { 
                if ($groupMemberships -contains $Agroup) {  
                    $FileCopysForUser += $FileCopy
                    break 
                } 
            } 
        } else { 
            if ($groupMemberships -contains $FileCopy.ADGroup -or [String]::IsNullOrWhiteSpace($FileCopy.ADGroup)) { 
                $FileCopysForUser += $FileCopy
            } 
        }
    } 
    
    
	Foreach ($FileCopy in $FileCopysForUser){
			try{
				$source = Get-ChildItem -Recurse -path $FileCopy.Source
				if($null -eq $source){
					Write-Output "No Connection to source"
					$FileCopy
					$_
				}
			} catch {
				Write-Output "Failed to check source Folder"
				$FileCopy
				$_
			}

			try{
				$destination = Get-ChildItem -Recurse -path $FileCopy.Destination -Depth 0
				if($null -eq $destination){
					$destination = New-Item -ItemType Directory -Force -Path $FileCopy.Destination
				}
			} catch {
				Write-Output "Failed to create Destination Folder"
				$FileCopy
				$_
			}



			try{
				if (Compare-Object -ReferenceObject $source -DifferenceObject $destination -Property @("Name","LastWriteTime")) {
					## Folders have different files
					Copy-Item -Path $FileCopy.Source -Destination $FileCopy.Destination -Force
				} else {
					Write-Output "Folder is up to date"
				}
			} catch {
				# Something went wrong, display the error details and write an error to the event log
				Write-Output "Copy Process failed"
				$FileCopy
				$_
			}
			
	}
    
}
#end region

###########################################################################################
# End & finish transcript
###########################################################################################

Stop-transcript

###########################################################################################
# Done
###########################################################################################

#!SCHTASKCOMESHERE!#

###########################################################################################
# If this script is running under system (IME) scheduled task is created  (recurring)
###########################################################################################

if (Test-RunningAsSystem) {

	Start-Transcript -Path $(Join-Path -Path $env:temp -ChildPath "IntuneFileCopyScheduledTask.log")
	Write-Output "Running as System --> creating scheduled task which will run on user logon"

	###########################################################################################
	# Get the current script path and content and save it to the client
	###########################################################################################

	$currentScript = Get-Content -Path $($PSCommandPath)

	$schtaskScript = $currentScript[(0) .. ($currentScript.IndexOf("#!SCHTASKCOMESHERE!#") - 1)]

	$scriptSavePath = $(Join-Path -Path $env:ProgramData -ChildPath "intune-file-copy-generator")

	if (-not (Test-Path $scriptSavePath)) {

		New-Item -ItemType Directory -Path $scriptSavePath -Force
	}

	$scriptSavePathName = "IntuneFileCopy.ps1"

	$scriptPath = $(Join-Path -Path $scriptSavePath -ChildPath $scriptSavePathName)

	$schtaskScript | Out-File -FilePath $scriptPath -Force

	###########################################################################################
	# Create dummy vbscript to hide PowerShell Window popping up at logon
	###########################################################################################

	$vbsDummyScript = "
	Dim shell,fso,file

	Set shell=CreateObject(`"WScript.Shell`")
	Set fso=CreateObject(`"Scripting.FileSystemObject`")

	strPath=WScript.Arguments.Item(0)

	If fso.FileExists(strPath) Then
		set file=fso.GetFile(strPath)
		strCMD=`"powershell -nologo -executionpolicy ByPass -command `" & Chr(34) & `"&{`" &_
		file.ShortPath & `"}`" & Chr(34)
		shell.Run strCMD,0
	End If
	"

	$scriptSavePathName = "IntuneFileCopy-VBSHelper.vbs"

	$dummyScriptPath = $(Join-Path -Path $scriptSavePath -ChildPath $scriptSavePathName)

	$vbsDummyScript | Out-File -FilePath $dummyScriptPath -Force

	$wscriptPath = Join-Path $env:SystemRoot -ChildPath "System32\wscript.exe"

	###########################################################################################
	# Register a scheduled task to run for all users and execute the script on logon
	###########################################################################################

	$schtaskName = "IntuneFileCopy"
	$schtaskDescription = "Copies files as defined from intune-file-copy-generator."

	$trigger = New-ScheduledTaskTrigger -AtLogOn
	#Execute task in users context
	$principal = New-ScheduledTaskPrincipal -GroupId "S-1-5-32-545" -Id "Author"
	#call the vbscript helper and pass the PosH script as argument
	$action = New-ScheduledTaskAction -Execute $wscriptPath -Argument "`"$dummyScriptPath`" `"$scriptPath`""
	$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

	$null = Register-ScheduledTask -TaskName $schtaskName -Trigger $trigger -Action $action  -Principal $principal -Settings $settings -Description $schtaskDescription -Force

	Start-ScheduledTask -TaskName $schtaskName

	Stop-Transcript
}

###########################################################################################
# Done
###########################################################################################