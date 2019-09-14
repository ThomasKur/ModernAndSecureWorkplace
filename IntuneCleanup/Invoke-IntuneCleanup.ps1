Connect-MSGraph
$devices = Get-IntuneManagedDevice

$deviceGroups = $devices | Group-Object -Property serialNumber
$duplicatedDevices = $deviceGroups | Where-Object {$_.Count -gt 1 }
$DeviceToDelete = @()
foreach($duplicatedDevice in $duplicatedDevices){
    #Find device which is the newest.
    $newestDevice = $duplicatedDevice.Group | Sort-Object -Property lastSyncDateTime -Descending | Select-Object -First 1
    Write-Host "Group $($duplicatedDevice.Name)"
    Write-Host "# Keep $($newestDevice.deviceName) $($newestDevice.lastSyncDateTime)"
    foreach($oldDevice in ($duplicatedDevice.Group | Sort-Object -Property lastSyncDateTime -Descending | Select-Object -Skip 1)){
        Write-Host "# Remove $($oldDevice.deviceName) $($oldDevice.lastSyncDateTime)"
        $DeviceToDelete += $oldDevice
    }
}
$DeviceToDelete | Out-GridView -OutputMode Multiple | foreach-Object { Remove-DeviceManagement_ManagedDevices -managedDeviceId $_.id }