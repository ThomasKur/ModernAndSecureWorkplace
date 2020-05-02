###########
#
#  Settings
#
###########

$global:ServerName = Read-Host "Enter FQDN Server Name"
$global:SiteCode = Read-Host "Enter SiteCode"

###########
#
#  Functions
#
###########

Function Move-SCCMItem{
    Param(
    $TargetContainerNodeID,
    $ObjectID,
    $Type)
    $MovePackage = @{
    InstanceKey = $ObjectID;
    ObjectType = $Type;
    ContainerNodeID = $TargetContainerNodeID
    }
    Set-WmiInstance -Class SMS_ObjectContainerItem -arguments $MovePackage -ComputerName $global:ServerName -Namespace "root\SMS\Site_$global:SiteCode"          
}
Function Create-SCCMFolder($FolderName, $ParentId, $Type)
{
    if((Get-SccmFolder -Name $FolderName -Type $Type) -eq $null){
    $CollectionFolderArgs = @{
    Name = $FolderName;    
    ObjectType = $Type;         # 5000 means Collection_Device, 5001 means Collection_User    
    ParentContainerNodeid = $ParentId     
    }    
    Write-Host "Name: $FolderName, ObjectType: $Type, ParentContainerNodeid: $ParentId" -ForegroundColor Yellow
    Set-WmiInstance -ComputerName $global:ServerName -Class SMS_ObjectContainerNode -arguments $CollectionFolderArgs -namespace "root\SMS\Site_$global:SiteCode" 
    }
}
    
Function Get-SccmFolder($Name, $Type)
{
    try{
        $folder = Get-WmiObject -ComputerName $global:ServerName -Namespace "root\SMS\Site_$global:SiteCode" -Query "select * from SMS_ObjectContainerNode where Name = '$Name' And ObjectType = '$Type'"
        return $folder.ContainerNodeID
    } catch{
        return $null
    }
}


###########
#
#  Error Handling einstellen
#
###########

$ErrorActionPreference = "Continue"

###########
#
#  Device Collection Folder erstellen
#
###########
cd ($global:SiteCode + ":")
# Software Ordner erstellen
Create-SCCMFolder "Software" "0" "5000"
$DeviceSoftwareFolderId = Get-SccmFolder "Software" "5000"
Create-SCCMFolder "Required Software" $DeviceSoftwareFolderId "5000"
Create-SCCMFolder "Available Software" $DeviceSoftwareFolderId "5000"
Create-SCCMFolder "Required Profile" $DeviceSoftwareFolderId "5000"
Create-SCCMFolder "Available Profile" $DeviceSoftwareFolderId "5000"

# Settings Management Ordner erstellen
Create-SCCMFolder "Settings Management" "0" "5000"

# Endpoint Protection Ordner erstellen
Create-SCCMFolder "Windows Defender" "0" "5000"

# Client Settings Ordner erstellen
Create-SCCMFolder "Client Settings" "0" "5000"

# Power Management Ordner erstellen
Create-SCCMFolder "Power Management" "0" "5000"

# Software Updates Ordner erstellen
Create-SCCMFolder "Software Updates" "0" "5000"

# Maintenance Windows Ordner erstellen
Create-SCCMFolder "Maintenance Windows" "0" "5000"
# OSD Ordner erstellen
Create-SCCMFolder "Operating System Deployment" "0" "5000"

# OSI Ordner erstellen
Create-SCCMFolder "Operating System Imaging" "0" "5000"

# Development Ordner erstellen
Create-SCCMFolder "Development" "0" "5000"

###########
#
#  User Collection Folder erstellen
#
###########

# Software Ordner erstellen
Create-SCCMFolder "Software" "0" "5001"
$UserSoftwareFolderId = Get-SccmFolder "Software" "5001" 
Create-SCCMFolder "Required Software" $UserSoftwareFolderId "5001"
Create-SCCMFolder "Available Software" $UserSoftwareFolderId "5001"
Create-SCCMFolder "Required Profile" $UserSoftwareFolderId "5001"
Create-SCCMFolder "Available Profile" $UserSoftwareFolderId "5001"

# Settings Management Ordner erstellen
Create-SCCMFolder "Settings Management" "0" "5001"

# Development Ordner erstellen
Create-SCCMFolder "Development" "0" "5001"
