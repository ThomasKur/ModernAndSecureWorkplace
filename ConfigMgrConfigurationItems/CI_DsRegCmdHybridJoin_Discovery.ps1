
<#
.Synopsis
   CI_DsRegCmdHybridJoin_Discovery
.DESCRIPTION
    Script for Configuration Manager - Configuration Item

   CI_DsRegCmdHybridJoin_Discovery checks if a device is Hybrid joined. 
   If not it returns the diagnostic data output returned by dsregcmd /status
   
.NOTES
    v1.0, 31.5.2020, Thomas Kurth
#>
function Get-DsRegStatus {
    <#
    .Synopsis
    Returns the output of dsregcmd /status as a PSObject.

    .Description
    Returns the output of dsregcmd /status as a PSObject. All returned values are accessible by their property name. Now per section as a subobject.

    .Example
    # Displays a full output of dsregcmd / status.
    Get-DsRegStatus
    #>
    $dsregcmd = dsregcmd /status
    $o = New-Object -TypeName PSObject
    foreach($line in $dsregcmd){
          if($line -like "| *"){
               if(-not [String]::IsNullOrWhiteSpace($currentSection) -and $null -ne $so){
                    Add-Member -InputObject $o -MemberType NoteProperty -Name $currentSection -Value $so -ErrorAction SilentlyContinue
               }
               $currentSection = $line.Replace("|","").Replace(" ","").Trim()
               $so = New-Object -TypeName PSObject
          } elseif($line -match " *[A-z]+ : [A-z]+ *"){
               Add-Member -InputObject $so -MemberType NoteProperty -Name (([String]$line).Trim() -split " : ")[0] -Value (([String]$line).Trim() -split " : ")[1] -ErrorAction SilentlyContinue
          }
    }
    if(-not [String]::IsNullOrWhiteSpace($currentSection) -and $null -ne $so){
        Add-Member -InputObject $o -MemberType NoteProperty -Name $currentSection -Value $so -ErrorAction SilentlyContinue
    }
    return $o
}


$dsregcmd = Get-DsRegStatus

if($dsregcmd.DeviceState.AzureAdJoined -eq "YES" -and $dsregcmd.DeviceState.DomainJoined -eq "YES"){
    return "OK"
} else {
    if($null -ne $dsregcmd.DiagnosticData){
        return $dsregcmd.DiagnosticData | ConvertTo-Html -Fragment
    } else {
        return "Error" 
    }
}
