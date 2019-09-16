<#
.SYNOPSIS
    This script cleans up duplicated device entries in the intune environment based on the serial number.

.DESCRIPTION
    The script retrieves all devices from Intune and elaborates all old devices per serial number. Only the newest device (Last Synced) will stay in the environment.


.EXAMPLE
    Retrieve devices to remove and displays them first in a Out-Gridview, to select the one which should be removed.

    Connect-MSGraph
    Invoke-IntuneCleanup -Whatif | Out-GridView -OutputMode Multiple | foreach-Object { Remove-DeviceManagement_ManagedDevices -managedDeviceId $_.id }

.EXAMPLE
    This command automatically removes duplicated objects based on the serial number. 

    Connect-MSGraph
    Invoke-IntuneCleanup
    
.NOTES
    Version:          1.0.0
    Author:           Thomas Kurth
    Creation Date:    14.9.2019 
    Purpose/Change:   Initial script development

.LINK
    
#>
[CmdletBinding(SupportsShouldProcess=$True)]
Param
()
Begin {
    Write-Verbose "Check Intune Connection"
    $GraphConnection = Get-MSGraphEnvironment
    if($null -eq $GraphConnection){
        throw "Not connected to MS Graph please invoke 'Connect-MSGraph' before invoking this Cmdlet."
    }
}
Process {
    $devices = Get-IntuneManagedDevice
    Write-Verbose "Found $($devices.Count) devices."
    $deviceGroups = $devices | Where-Object { -not [String]::IsNullOrWhiteSpace($_.serialNumber) } | Group-Object -Property serialNumber
    $duplicatedDevices = $deviceGroups | Where-Object {$_.Count -gt 1 }
    Write-Verbose "Found $($duplicatedDevices.Count) serialNumbers with duplicated entries"
    foreach($duplicatedDevice in $duplicatedDevices){
        # Find device which is the newest.
        $newestDevice = $duplicatedDevice.Group | Sort-Object -Property lastSyncDateTime -Descending | Select-Object -First 1
        Write-Verbose "Group $($duplicatedDevice.Name)"
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