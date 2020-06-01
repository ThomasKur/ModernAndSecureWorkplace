

<#
.Synopsis
   CI_DsRegCmdTpmProtected_Discovery
.DESCRIPTION
    Script for Configuration Manager - Configuration Item

   CI_DsRegCmdTpmProtected_Discovery checks if the device private key is stored in a Hardware TPM.
   by checking the status of the TpmProtected property returned by dsregcmd /status
   
   
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
    return $o
}


$dsregcmd = Get-DsRegStatus

return ($dsregcmd.DeviceDetails.TpmProtected -eq "YES")