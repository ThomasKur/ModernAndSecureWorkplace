<#
.SYNOPSIS
    Create Boundary Report based on the IP Addresses of the devices in the SCCM Site.

.DESCRIPTION
    This Cmdlet retrieves the ConfigMgr Devices and Boundaries and calculates the missing one. It works when you are working with IP Range Boundaries, but not Subnet or AD Site based.
    
    The PowerShell Module of ConfigMgr need to be loaded before this Cmdlet can be executed.


.EXAMPLE
    Automatically Create Boundaries

    $New = Get-BoundaryReport -PSOutput | Where-Object { $_.AssignedBoundary -eq "" } | Select-Object -Property StartIP,EndIP -Unique
    foreach($NewSubnet in $New) {
        New-CMBoundary -Name "NOTDEFINED $($NewSubnet.StartIP)" -Type IPRange -Value "$($NewSubnet.StartIP)-$($NewSubnet.EndIP)"
    }

.EXAMPLE
    Create CSV

    Get-BoundaryReport -CSV -Path c:\temp\BoundaryReport.csv
    
.NOTES
    Version:          1.0.0
    Author:           Dani Schädler / Thomas Kurth
    Creation Date:    5.9.2019 
    Purpose/Change:   Initial script development

.LINK
    
#>

[CmdletBinding()]
Param
(
        
    [Parameter(Mandatory,ParameterSetName='CSV')]
    [switch]$CSV,
    [Parameter(Mandatory,ParameterSetName='HTML')]
    [switch]$HTML,
    [Parameter(Mandatory,ParameterSetName='PSOutput')]
    [switch]$PSOutput,
    [Parameter(Mandatory,ParameterSetName='CSV')]
    [Parameter(Mandatory,ParameterSetName='HTML')]
    [string]$Path,
    [Parameter(ParameterSetName='CSV')]
    [Parameter(ParameterSetName='HTML')]
    [Parameter(ParameterSetName='PSOutput')]
    [string]$SubnetMask = "255.255.255.0"

)
Begin {
    try{
        $site = Get-CMSite
        if($null -eq $site){
            throw ""
        }
    } catch {
        throw "ConfigMgr Module not loaded or not connected to Site."
    }
    function Validate-IP ($strIP)
    {
	    $bValidIP = $true
	    $arrSections = @()
	    $arrSections +=$strIP.split(".")
	    #firstly, make sure there are 4 sections in the IP address
	    if ($arrSections.count -ne 4) {$bValidIP =$false}
	
	    #secondly, make sure it only contains numbers and it's between 0-254
	    if ($bValidIP)
	    {
		    [reflection.assembly]::LoadWithPartialName("'Microsoft.VisualBasic") | Out-Null
		    foreach ($item in $arrSections)
		    {
			    if (!([Microsoft.VisualBasic.Information]::isnumeric($item))) {$bValidIP = $false}
		    }
	    }
	
	    if ($bValidIP)
	    {
		    foreach ($item in $arrSections)
		    {
			    $item = [int]$item
			    if ($item -lt 0 -or $item -gt 254) {$bValidIP = $false}
		    }
	    }
	
	    Return $bValidIP
    }
    function Validate-SubnetMask ($strSubnetMask)
    {
	    $bValidMask = $true
	    $arrSections = @()
	    $arrSections +=$strSubnetMask.split(".")
	    #firstly, make sure there are 4 sections in the subnet mask
	    if ($arrSections.count -ne 4) {$bValidMask =$false}
	
	    #secondly, make sure it only contains numbers and it's between 0-255
	    if ($bValidMask)
	    {
		    [reflection.assembly]::LoadWithPartialName("'Microsoft.VisualBasic") | Out-Null
		    foreach ($item in $arrSections)
		    {
			    if (!([Microsoft.VisualBasic.Information]::isnumeric($item))) {$bValidMask = $false}
		    }
	    }
	
	    if ($bValidMask)
	    {
		    foreach ($item in $arrSections)
		    {
			    $item = [int]$item
			    if ($item -lt 0 -or $item -gt 255) {$bValidMask = $false}
		    }
	    }
	
	    #lastly, make sure it is actually a subnet mask when converted into binary format
	    if ($bValidMask)
	    {
		    foreach ($item in $arrSections)
		    {
			    $binary = [Convert]::ToString($item,2)
			    if ($binary.length -lt 8)
			    {
				    do {
				    $binary = "0$binary"
				    } while ($binary.length -lt 8)
			    }
			    $strFullBinary = $strFullBinary+$binary
		    }
		    if ($strFullBinary.contains("01")) {$bValidMask = $false}
		    if ($bValidMask)
		    {
			    $strFullBinary = $strFullBinary.replace("10", "1.0")
			    if ((($strFullBinary.split(".")).count -ne 2)) {$bValidMask = $false}
		    }
	    }
	    Return $bValidMask
    }

    function ConvertTo-Binary ($strDecimal)
    {
	    $strBinary = [Convert]::ToString($strDecimal, 2)
	    if ($strBinary.length -lt 8)
	    {
		    while ($strBinary.length -lt 8)
		    {
			    $strBinary = "0"+$strBinary
		    }
	    }
	    Return $strBinary
    }
    function Convert-IPToBinary ($strIP)
    {
	    $strBinaryIP = $null
	    if (Validate-IP $strIP)
	    {
		    $arrSections = @()
		    $arrSections += $strIP.split(".")
		    foreach ($section in $arrSections)
		    {
			    if ($strBinaryIP -ne $null)
			    {
				    $strBinaryIP = $strBinaryIP+"."
			    }
				    $strBinaryIP = $strBinaryIP+(ConvertTo-Binary $section)
			
		    }
	    }
	    Return $strBinaryIP
    }

    Function Convert-SubnetMaskToBinary ($strSubnetMask)
    {
		    $strBinarySubnetMask = $null
	    if (Validate-SubnetMask $strSubnetMask)
	    {
		    $arrSections = @()
		    $arrSections += $strSubnetMask.split(".")
		    foreach ($section in $arrSections)
		    {
			    if ($strBinarySubnetMask -ne $null)
			    {
				    $strBinarySubnetMask = $strBinarySubnetMask+"."
			    }
				    $strBinarySubnetMask = $strBinarySubnetMask+(ConvertTo-Binary $section)
			
		    }
	    }
	    Return $strBinarySubnetMask
    }

    Function Convert-BinaryIPAddress ($BinaryIP)
    {
	    $FirstSection = [Convert]::ToInt64(($BinaryIP.substring(0, 8)),2)
	    $SecondSection = [Convert]::ToInt64(($BinaryIP.substring(8,8)),2)
	    $ThirdSection = [Convert]::ToInt64(($BinaryIP.substring(16,8)),2)
	    $FourthSection = [Convert]::ToInt64(($BinaryIP.substring(24,8)),2)
	    $strIP = "$FirstSection`.$SecondSection`.$ThirdSection`.$FourthSection"
	    Return $strIP
    }
    function Test-IpAddressInRange {
        [CmdletBinding()]
        param (
            [Parameter(Position = 0, Mandatory = $true)][ipaddress]$from,
            [Parameter(Position = 1, Mandatory = $true)][ipaddress]$to,
            [Parameter(Position = 2, Mandatory = $true)][ipaddress]$target
        )
        $f=$from.GetAddressBytes()|%{"{0:000}" -f $_}   | & {$ofs='-';"$input"}
        $t=$to.GetAddressBytes()|%{"{0:000}" -f $_}   | & {$ofs='-';"$input"}
        $tg=$target.GetAddressBytes()|%{"{0:000}" -f $_}   | & {$ofs='-';"$input"}
        return ($f -le $tg) -and ($t -ge $tg)
    }

    function Get-BoundaryList {
        foreach ($Boundary in (Get-CMBoundary)) {
            if($Boundary.BoundaryType -eq 0){
                [Net.IPAddress]$StartIP = $Boundary.Value
                [Net.IPAddress]$EndIP = $Boundary.Value.Substring(0,$Boundary.Value.Length) + "255"
                [string]$SiteSystem = $Boundary.SiteSystems -join ';'
                [string]$DisplayName = $Boundary.DisplayName

                [PSCustomObject]@{
                    StartIP = $StartIP
                    EndIP = $EndIP
                    SiteSystem = $SiteSystem.ToUpper()
                    DisplayName = $DisplayName
                    Range = $Boundary.Value
                }
            } elseif($Boundary.BoundaryType -eq 3) {
                [Net.IPAddress]$StartIP = ($Boundary.Value -split '-')[0]
                [Net.IPAddress]$EndIP = ($Boundary.Value -split '-')[1]
                [string]$SiteSystem = $Boundary.SiteSystems -join ';'
                [string]$DisplayName = $Boundary.DisplayName

                [PSCustomObject]@{
                    StartIP = $StartIP
                    EndIP = $EndIP
                    SiteSystem = $SiteSystem.ToUpper()
                    DisplayName = $DisplayName
                    Range = $Boundary.Value
                }
            } else {
                Write-Verbose "Ignoring non IP range or Subnet Boundary '$($Boundary.DisplayName)'"
            }
        }
    }

    function Get-BoundaryAssignment {
        param(
            [string]$SubnetMask
        )
            
        $BoundaryInfo = Get-BoundaryList
            
        foreach ($Device in (Get-WmiObject -Class SMS_R_SYSTEM -Namespace "root\sms\site_$SiteCode")) {
            $IPs = $Device.IPAddresses | Where-Object { (Validate-IP -strIP $_) -and ([string]$_ -notlike "169.254.*") }
            
            if($IPs -ne $null){    
                [string]$IP = @($IPs)[0]
                [string]$Name = $Device.Name
                [string]$FQDN = $Device.ResourceNames -join ";"
                [string]$Domain = $Device.ResourceDomainORWorkgroup
                [string]$AssignedBoundary  = ""
                [string]$StartIP = ""
                [string]$EndIP = ""
                [string]$AssignedSiteSystem = ""

                foreach ($BG in $BoundaryInfo) {
                    if ($IP -ne "") {
                        if (Test-IpAddressInRange -from $bg.StartIP -to $bg.EndIP -target $IP) {
                            $AssignedBoundary = $BG.DisplayName
                            $AssignedSiteSystem = $BG.SiteSystem
                            $StartIP = $BG.StartIP
                            $EndIP = $bg.EndIP

                        }
                    }
                }
                if($StartIP -eq ""){
                    $Range = Get-IPAddressRange -IP $IP -SubnetMask $SubnetMask
                    $StartIP = $Range.StartIP
                    $EndIP = $Range.EndIP
                }
                [PSCustomObject]@{
                    IP = $IP
                    Name = $Name.toUpper()
                    FQDN = $FQDN.ToUpper()
                    Domain = $Domain
                    AssignedBoundary = $AssignedBoundary
                    StartIP = $StartIP
                    EndIP = $EndIP
                    AssignedSiteSystem = $AssignedSiteSystem.ToUpper()
                }
            }
        }
    }

    function Get-IPAddressRange {
        [CmdletBinding()]
        Param (
            [string]$IP, 
            [string]$SubnetMask
        )
        $BinarySubnetMask = (Convert-SubnetMaskToBinary $SubnetMask).replace(".", "")
	    $BinaryNetworkAddressSection = $BinarySubnetMask.replace("1", "")
	    $BinaryNetworkAddressLength = $BinaryNetworkAddressSection.length
	    $CIDR = 32 - $BinaryNetworkAddressLength
	    $iAddressWidth = [System.Math]::Pow(2, $BinaryNetworkLength)
	    $iAddressPool = $iAddressWidth -2
	    $BinaryIP = (Convert-IPToBinary $IP).Replace(".", "")
	    $BinaryIPNetworkSection = $BinaryIP.substring(0, $CIDR)
	    $BinaryIPAddressSection = $BinaryIP.substring($CIDR, $BinaryNetworkAddressLength)
	
	    #Starting IP
	    $FirstAddress = $BinaryNetworkAddressSection -replace "0$", "1"
	    $BinaryFirstAddress = $BinaryIPNetworkSection + $FirstAddress
	    $strFirstIP = Convert-BinaryIPAddress $BinaryFirstAddress
	
	    #End IP
	    $LastAddress = ($BinaryNetworkAddressSection -replace "0", "1") -replace "1$", "0"
	    $BinaryLastAddress = $BinaryIPNetworkSection + $LastAddress
	    $strLastIP = Convert-BinaryIPAddress $BinaryLastAddress
	    
        [PSCustomObject]@{
            StartIP = $strFirstIP
            EndIP = $strLastIP
        }
    }
}
Process {

    $Result = Get-BoundaryAssignment -SubnetMask $SubnetMask
    $Result = $Result | Sort-Object {[Version]$_.IP} -ErrorAction SilentlyContinue

    if ($CSV) {
        Write-Verbose "Writing CSV file"
        $Result| Export-Csv -Delimiter ";" -NoTypeInformation -Encoding UTF8 -Path $Path
    } elseif($PSOutput){
        Write-Verbose "PS Output"
        $Result
    } else {
        Write-Verbose "Writing HTML file"
        $HTMLTable = @()
        foreach ($Item in $Result) {
            if ($Item.IP -eq "") {
                $HTMLTable += "<tr class='itemnoagent'>"
            } else { 
                $HTMLTable += "<tr class='item'>"
            }
            $HTMLTable += "
            <td>$($Item.IP)</td>
            <td>$($Item.Name)</td>
            <td>$($Item.FQDN)</td>
            <td>$($Item.Domain)</td>
            <td>$($Item.AssignedBoundary)</td>
            <td>$($Item.StartIP)</td>
            <td>$($Item.EndIP)</td>
            <td>$($Item.AssignedSiteSystem)</td>
            </tr>
            "
        }
            
        $HTMLTemplate = Get-Content "$($PSScriptRoot)\template.html"
        $HTMLReport = $HTMLTemplate | ForEach-Object {$_.replace('TABLECONTENT',$HTMLTable) }
        $HTMLReport | Set-Content $Path
    }
}
End {
}