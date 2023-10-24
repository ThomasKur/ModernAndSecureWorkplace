<#
.SYNOPSIS
    This script performs a cleanup for duplicated device entries in Microsoft Intune based on the serial number.

.DESCRIPTION
    The script retrieves all devices from Intune and elaborates all duplicated devices based on the serial number. Only the newest device (Last Synced) will stay in the environment.

.EXAMPLE
    Invoke-IntuneCleanup -Whatif | Out-GridView -OutputMode Multiple | foreach-Object { Remove-DeviceManagement_ManagedDevices -managedDeviceId $_.id }

    Retrieves duplicate devices and displays them first in a Out-Gridview, to select the devices which should be removed.

.EXAMPLE
    Invoke-IntuneCleanup

    This command automatically removes duplicated objects based on the serial number. 

.NOTES
    Version:          1.0.1
    Author:           Thomas Kurth
    Creation Date:    27.3.2020 
    Purpose/Change:   Initial script development
                      Use Get-MSGraphAllPages to work in bigger environments correctly.

.LINK
    https://www.wpninjas.ch/2019/09/cleanup-duplicated-devices-in-intune/
    
#>

function Invoke-IntuneCleanup {
    [CmdletBinding(SupportsShouldProcess=$True)]
    Param()
    Begin {
        Write-Verbose "Checking Intune Connection"
        try{
            $null = Connect-MSGraph
        }catch{
            Throw "Not authenticated.  Please use the `"Connect-MSGraph`" command to authenticate."
        }
    }
    Process {
        $devices = Get-IntuneManagedDevice | Get-MSGraphAllPages
        Write-Verbose "Found $($devices.Count) devices."
        $deviceGroups = $devices | Where-Object { -not [String]::IsNullOrWhiteSpace($_.serialNumber) -and ($_.serialNumber -ne "Defaultstring") } | Group-Object -Property serialNumber
        $duplicatedDevices = $deviceGroups | Where-Object {$_.Count -gt 1 }
        Write-Verbose "Found $($duplicatedDevices.Count) serialNumbers with duplicated entries"
        foreach($duplicatedDevice in $duplicatedDevices){
            # Find device which is the newest.
            $newestDevice = $duplicatedDevice.Group | Sort-Object -Property lastSyncDateTime -Descending | Select-Object -First 1
            Write-Verbose "Serial $($duplicatedDevice.Name)"
            Write-Verbose "# Keep $($newestDevice.deviceName) $($newestDevice.lastSyncDateTime)"
            foreach($oldDevice in ($duplicatedDevice.Group | Sort-Object -Property lastSyncDateTime -Descending | Select-Object -Skip 1)){
                Write-Verbose "# Remove $($oldDevice.deviceName) $($oldDevice.lastSyncDateTime)"
                if($WhatIfPreference){
                    $oldDevice
                } else {
                    Remove-DeviceManagement_ManagedDevices -managedDeviceId $oldDevice.id
                }
            }
        }
    }
    End {
    }
}

Invoke-IntuneCleanup -WhatIf -Verbose
