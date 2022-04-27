<#
.DESCRIPTION
This script maps or remove printers
When executed under SYSTEM authority a scheduled task is created to ensure recurring script execution on each user logon.

.NOTES
    Version:          1.0
    Author:           Thomas Kurth/baseVISION AG / https://www.wpninjas.ch
    Creation Date:    07.02.2022

    Modifications
    Purpose/Change:   07.02.2022 - Initial script development

	Initial script taken from Nicola Suter, nicolonsky tech: https://tech.nicolonsky.ch


#>
[CmdletBinding()]
Param()

###########################################################################################
# Start transcript for logging
###########################################################################################

Start-Transcript -Path $(Join-Path $env:temp "PrinterMapping.log")

## Manual Variable Definition
########################################################


$printers = @()
$printers += [pscustomobject]@{PrinterName="HPOffice";PrintServer="\\ps01\HPOffice";ADGroup="";Default="1"}
$printers += [pscustomobject]@{PrinterName="BrotherOffice";PrintServer="\\ps01\BrotherOffice";ADGroup="KURCONTOSO\DLG-FS-IT-Modify";Default="0"}


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
		
	}
}
catch {
	#nothing we can do
}


###########################################################################################
#region Map Printer
###########################################################################################


# Add printer Only when executed as user
if (-not (Test-RunningAsSystem)) {
    $PrintersForUser = @()
    foreach ($printer in $Printers) { 
        if($printer.ADGroup -ne $null -and $printer.ADGroup.Contains(",")) { 
            $Agroups = $printer.ADGroup.Split(",") 
            foreach ($Agroup in $Agroups) { 
                if ($groupMemberships -contains $Agroup) {  
                    $PrintersForUser += $printer
                    break 
                } 
            } 
        } else { 
            if ($groupMemberships -contains $printer.ADGroup -or [String]::IsNullOrWhiteSpace($printer.ADGroup)) { 
                $PrintersForUser += $printer
            } 
        }
    } 
    Write-Output "Found the following printers to map:"
	Write-Output $PrintersForUser
    
	Foreach ($Printer in $PrintersForUser){
		Try {
			Write-Output "Get the status of the printer '$($Printer.PrintServer)' on the print server"
			$PrinterServerStatus = (Get-Printer -ComputerName (([URI]($Printer.PrintServer)).host) -Name $Printer.PrinterName).PrinterStatus
			# Only perform check if the printer on the print server is not offline
			If ($PrinterServerStatus -ne "Offline") {
				# Throw error is printer doesn't exist
				If (!(Get-Printer -Name $Printer.PrintServer -ErrorAction SilentlyContinue)){
					Write-Output "Printer not mapped, adding '$($Printer.PrintServer)'"
					Add-Printer -ConnectionName $Printer.PrintServer
					if($Printer.Default -eq 1){
						$printer = Get-CimInstance -Class Win32_Printer -Filter "Name='$($Printer.PrinterServer)'"
						Invoke-CimMethod -InputObject $printer -MethodName SetDefaultPrinter
					}
				}
			} else {
				Write-Output "Printer is offline or Sppoler not running"
				$Printer
			}
		} Catch {
			Write-Output "Failed to map the printer"
			$Printer
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

	Start-Transcript -Path $(Join-Path -Path $env:temp -ChildPath "IntunePrinterMappingScheduledTask.log")
	Write-Output "Running as System --> creating scheduled task which will run on user logon"

	###########################################################################################
	# Get the current script path and content and save it to the client
	###########################################################################################

	$currentScript = Get-Content -Path $($PSCommandPath)

	$schtaskScript = $currentScript[(0) .. ($currentScript.IndexOf("#!SCHTASKCOMESHERE!#") - 1)]

	$scriptSavePath = $(Join-Path -Path $env:ProgramData -ChildPath "intune-printer-mapping-generator")

	if (-not (Test-Path $scriptSavePath)) {

		New-Item -ItemType Directory -Path $scriptSavePath -Force
	}

	$scriptSavePathName = "PrinterMapping.ps1"

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

	$scriptSavePathName = "IntunePrinterMapping-VBSHelper.vbs"

	$dummyScriptPath = $(Join-Path -Path $scriptSavePath -ChildPath $scriptSavePathName)

	$vbsDummyScript | Out-File -FilePath $dummyScriptPath -Force

	$wscriptPath = Join-Path $env:SystemRoot -ChildPath "System32\wscript.exe"

	###########################################################################################
	# Register a scheduled task to run for all users and execute the script on logon
	###########################################################################################

	$schtaskName = "IntunePrinterMapping"
	$schtaskDescription = "Map printers from intune-printer-mapping-generator."

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