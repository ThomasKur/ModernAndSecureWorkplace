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
$printers += [pscustomobject]@{PrinterName="PAN01";PrintServer="\\SIUKANPS01.sigvaris-group.com\PAN01";ADGroup="DL-EMWESV-PS-Printers-PAN01";Default="0"}
$printers += [pscustomobject]@{PrinterName="PAN02";PrintServer="\\SIUKANPS01.sigvaris-group.com\PAN02";ADGroup="DL-EMWESV-PS-Printers-PAN02";Default="0"}
$printers += [pscustomobject]@{PrinterName="PAN03";PrintServer="\\SIUKANPS01.sigvaris-group.com\PAN03";ADGroup="DL-EMWESV-PS-Printers-PAN03";Default="0"}
$printers += [pscustomobject]@{PrinterName="PAN04";PrintServer="\\SIUKANPS01.sigvaris-group.com\PAN04";ADGroup="DL-EMWESV-PS-Printers-PAN04";Default="0"}
$printers += [pscustomobject]@{PrinterName="PAN05";PrintServer="\\SIUKANPS01.sigvaris-group.com\PAN05";ADGroup="DL-EMWESV-PS-Printers-PAN05";Default="0"}
$printers += [pscustomobject]@{PrinterName="PAN06";PrintServer="\\SIUKANPS01.sigvaris-group.com\PAN06";ADGroup="DL-EMWESV-PS-Printers-PAN06";Default="0"}
$printers += [pscustomobject]@{PrinterName="PAN07";PrintServer="\\SIUKANPS01.sigvaris-group.com\PAN07";ADGroup="DL-EMWESV-PS-Printers-PAN07";Default="0"}
$printers += [pscustomobject]@{PrinterName="PAN08";PrintServer="\\SIUKANPS01.sigvaris-group.com\PAN08";ADGroup="DL-EMWESV-PS-Printers-PAN08";Default="0"}
$printers += [pscustomobject]@{PrinterName="PAN09";PrintServer="\\SIUKANPS01.sigvaris-group.com\PAN09";ADGroup="DL-EMWESV-PS-Printers-PAN09";Default="0"}
$printers += [pscustomobject]@{PrinterName="PAN10";PrintServer="\\SIUKANPS01.sigvaris-group.com\PAN10";ADGroup="DL-EMWESV-PS-Printers-PAN10";Default="0"}
$printers += [pscustomobject]@{PrinterName="PAN11";PrintServer="\\SIUKANPS01.sigvaris-group.com\PAN11";ADGroup="DL-EMWESV-PS-Printers-PAN11";Default="0"}
$printers += [pscustomobject]@{PrinterName="J103";PrintServer="\\SIFRSJSV0016.sigvaris-group.com\J103";ADGroup="DL-EMWESV-PS-Printers-J103";Default="0"}
$printers += [pscustomobject]@{PrinterName="J108";PrintServer="\\SIFRSJSV0016.sigvaris-group.com\J108";ADGroup="DL-EMWESV-PS-Printers-J108";Default="0"}
$printers += [pscustomobject]@{PrinterName="JVP01";PrintServer="\\SIFRSJSV0016.sigvaris-group.com\JVP01";ADGroup="DL-EMWESV-PS-Printers-JVP01";Default="0"}
$printers += [pscustomobject]@{PrinterName="JVP01";PrintServer="\\SIFRSJSV0016.sigvaris-group.com\JVP01";ADGroup="DL-EMWESV-PS-Printers-JVP01DEF";Default="1"}
$printers += [pscustomobject]@{PrinterName="HVP01";PrintServer="\\SIFRHUSV02.sigvaris-group.com\HVP01";ADGroup="DL-EMWESV-PS-Printers-LVP01";Default="0"}
$printers += [pscustomobject]@{PrinterName="HVP01";PrintServer="\\SIFRHUSV02.sigvaris-group.com\HVP01";ADGroup="DL-EMWESV-PS-Printers-LVP01DEF";Default="1"}
$printers += [pscustomobject]@{PrinterName="J112";PrintServer="\\SIFRSJSV0016.sigvaris-group.com\J112";ADGroup="DL-EMWESV-PS-Printers-J112DEF";Default="1"}
$printers += [pscustomobject]@{PrinterName="J112";PrintServer="\\SIFRSJSV0016.sigvaris-group.com\J112";ADGroup="DL-EMWESV-PS-Printers-J112";Default="0"}
$printers += [pscustomobject]@{PrinterName="J115";PrintServer="\\SIFRSJSV0016.sigvaris-group.com\J115";ADGroup="DL-EMWESV-PS-Printers-J115DEF";Default="1"}
$printers += [pscustomobject]@{PrinterName="J115";PrintServer="\\SIFRSJSV0016.sigvaris-group.com\J115";ADGroup="DL-EMWESV-PS-Printers-J115";Default="0"}
$printers += [pscustomobject]@{PrinterName="J116";PrintServer="\\SIFRSJSV0016.sigvaris-group.com\J116";ADGroup="DL-EMWESV-PS-Printers-J116DEF";Default="1"}
$printers += [pscustomobject]@{PrinterName="J116";PrintServer="\\SIFRSJSV0016.sigvaris-group.com\J116";ADGroup="DL-EMWESV-PS-Printers-J116";Default="0"}
$printers += [pscustomobject]@{PrinterName="J117";PrintServer="\\SIFRSJSV0016.sigvaris-group.com\J117";ADGroup="DL-EMWESV-PS-Printers-J117DEF";Default="1"}
$printers += [pscustomobject]@{PrinterName="J117";PrintServer="\\SIFRSJSV0016.sigvaris-group.com\J117";ADGroup="DL-EMWESV-PS-Printers-J117";Default="0"}
$printers += [pscustomobject]@{PrinterName="J118";PrintServer="\\SIFRSJSV0016.sigvaris-group.com\J118";ADGroup="DL-EMWESV-PS-Printers-J118DEF";Default="1"}
$printers += [pscustomobject]@{PrinterName="J118";PrintServer="\\SIFRSJSV0016.sigvaris-group.com\J118";ADGroup="DL-EMWESV-PS-Printers-J118";Default="0"}
$printers += [pscustomobject]@{PrinterName="J119";PrintServer="\\SIFRSJSV0016.sigvaris-group.com\J119";ADGroup="DL-EMWESV-PS-Printers-J119DEF";Default="1"}
$printers += [pscustomobject]@{PrinterName="J119";PrintServer="\\SIFRSJSV0016.sigvaris-group.com\J119";ADGroup="DL-EMWESV-PS-Printers-J119";Default="0"}
$printers += [pscustomobject]@{PrinterName="J120";PrintServer="\\SIFRSJSV0016.sigvaris-group.com\J120";ADGroup="DL-EMWESV-PS-Printers-J120DEF";Default="1"}
$printers += [pscustomobject]@{PrinterName="J120";PrintServer="\\SIFRSJSV0016.sigvaris-group.com\J120";ADGroup="DL-EMWESV-PS-Printers-J120";Default="0"}
$printers += [pscustomobject]@{PrinterName="J121";PrintServer="\\SIFRSJSV0016.sigvaris-group.com\J121";ADGroup="DL-EMWESV-PS-Printers-J121DEF";Default="1"}
$printers += [pscustomobject]@{PrinterName="J121";PrintServer="\\SIFRSJSV0016.sigvaris-group.com\J121";ADGroup="DL-EMWESV-PS-Printers-J121";Default="0"}
$printers += [pscustomobject]@{PrinterName="J122";PrintServer="\\SIFRSJSV0016.sigvaris-group.com\J122";ADGroup="DL-EMWESV-PS-Printers-J122DEF";Default="1"}
$printers += [pscustomobject]@{PrinterName="J122";PrintServer="\\SIFRSJSV0016.sigvaris-group.com\J122";ADGroup="DL-EMWESV-PS-Printers-J122";Default="0"}
$printers += [pscustomobject]@{PrinterName="J123";PrintServer="\\SIFRSJSV0016.sigvaris-group.com\J123";ADGroup="DL-EMWESV-PS-Printers-J123DEF";Default="1"}
$printers += [pscustomobject]@{PrinterName="J123";PrintServer="\\SIFRSJSV0016.sigvaris-group.com\J123";ADGroup="DL-EMWESV-PS-Printers-J123";Default="0"}
$printers += [pscustomobject]@{PrinterName="J124";PrintServer="\\SIFRSJSV0016.sigvaris-group.com\J124";ADGroup="DL-EMWESV-PS-Printers-J124DEF";Default="1"}
$printers += [pscustomobject]@{PrinterName="J124";PrintServer="\\SIFRSJSV0016.sigvaris-group.com\J124";ADGroup="DL-EMWESV-PS-Printers-J124";Default="0"}
$printers += [pscustomobject]@{PrinterName="J125";PrintServer="\\SIFRSJSV0016.sigvaris-group.com\J125";ADGroup="DL-EMWESV-PS-Printers-J125DEF";Default="1"}
$printers += [pscustomobject]@{PrinterName="J125";PrintServer="\\SIFRSJSV0016.sigvaris-group.com\J125";ADGroup="DL-EMWESV-PS-Printers-J125";Default="0"}
$printers += [pscustomobject]@{PrinterName="J126";PrintServer="\\SIFRSJSV0016.sigvaris-group.com\J126";ADGroup="DL-EMWESV-PS-Printers-J126DEF";Default="1"}
$printers += [pscustomobject]@{PrinterName="J126";PrintServer="\\SIFRSJSV0016.sigvaris-group.com\J126";ADGroup="DL-EMWESV-PS-Printers-J126";Default="0"}
$printers += [pscustomobject]@{PrinterName="J127";PrintServer="\\SIFRSJSV0016.sigvaris-group.com\J127";ADGroup="DL-EMWESV-PS-Printers-J127DEF";Default="1"}
$printers += [pscustomobject]@{PrinterName="J127";PrintServer="\\SIFRSJSV0016.sigvaris-group.com\J127";ADGroup="DL-EMWESV-PS-Printers-J127";Default="0"}
$printers += [pscustomobject]@{PrinterName="J128";PrintServer="\\SIFRSJSV0016.sigvaris-group.com\J128";ADGroup="DL-EMWESV-PS-Printers-J128DEF";Default="1"}
$printers += [pscustomobject]@{PrinterName="J128";PrintServer="\\SIFRSJSV0016.sigvaris-group.com\J128";ADGroup="DL-EMWESV-PS-Printers-J128";Default="0"}
$printers += [pscustomobject]@{PrinterName="J129";PrintServer="\\SIFRSJSV0016.sigvaris-group.com\J129";ADGroup="DL-EMWESV-PS-Printers-J129DEF";Default="1"}
$printers += [pscustomobject]@{PrinterName="J129";PrintServer="\\SIFRSJSV0016.sigvaris-group.com\J129";ADGroup="DL-EMWESV-PS-Printers-J129";Default="0"}
$printers += [pscustomobject]@{PrinterName="J130";PrintServer="\\SIFRSJSV0016.sigvaris-group.com\J130";ADGroup="DL-EMWESV-PS-Printers-J130DEF";Default="1"}
$printers += [pscustomobject]@{PrinterName="J130";PrintServer="\\SIFRSJSV0016.sigvaris-group.com\J130";ADGroup="DL-EMWESV-PS-Printers-J130";Default="0"}
$printers += [pscustomobject]@{PrinterName="J131";PrintServer="\\SIFRSJSV0016.sigvaris-group.com\J131";ADGroup="DL-EMWESV-PS-Printers-J131DEF";Default="1"}
$printers += [pscustomobject]@{PrinterName="J131";PrintServer="\\SIFRSJSV0016.sigvaris-group.com\J131";ADGroup="DL-EMWESV-PS-Printers-J131";Default="0"}
$printers += [pscustomobject]@{PrinterName="J133";PrintServer="\\SIFRSJSV0016.sigvaris-group.com\J133";ADGroup="DL-EMWESV-PS-Printers-J133DEF";Default="1"}
$printers += [pscustomobject]@{PrinterName="J133";PrintServer="\\SIFRSJSV0016.sigvaris-group.com\J133";ADGroup="DL-EMWESV-PS-Printers-J133";Default="0"}
$printers += [pscustomobject]@{PrinterName="J134";PrintServer="\\SIFRSJSV0016.sigvaris-group.com\J134";ADGroup="DL-EMWESV-PS-Printers-J134DEF";Default="1"}
$printers += [pscustomobject]@{PrinterName="J134";PrintServer="\\SIFRSJSV0016.sigvaris-group.com\J134";ADGroup="DL-EMWESV-PS-Printers-J134";Default="0"}
$printers += [pscustomobject]@{PrinterName="J135";PrintServer="\\SIFRSJSV0016.sigvaris-group.com\J135";ADGroup="DL-EMWESV-PS-Printers-J135DEF";Default="1"}
$printers += [pscustomobject]@{PrinterName="J135";PrintServer="\\SIFRSJSV0016.sigvaris-group.com\J135";ADGroup="DL-EMWESV-PS-Printers-J135";Default="0"}
$printers += [pscustomobject]@{PrinterName="J136";PrintServer="\\SIFRSJSV0016.sigvaris-group.com\J136";ADGroup="DL-EMWESV-PS-Printers-J136DEF";Default="1"}
$printers += [pscustomobject]@{PrinterName="J136";PrintServer="\\SIFRSJSV0016.sigvaris-group.com\J136";ADGroup="DL-EMWESV-PS-Printers-J136";Default="0"}
$printers += [pscustomobject]@{PrinterName="J137";PrintServer="\\SIFRSJSV0016.sigvaris-group.com\J137";ADGroup="DL-EMWESV-PS-Printers-J137DEF";Default="1"}
$printers += [pscustomobject]@{PrinterName="J137";PrintServer="\\SIFRSJSV0016.sigvaris-group.com\J137";ADGroup="DL-EMWESV-PS-Printers-J137";Default="0"}
$printers += [pscustomobject]@{PrinterName="J138";PrintServer="\\SIFRSJSV0016.sigvaris-group.com\J138";ADGroup="DL-EMWESV-PS-Printers-J138DEF";Default="1"}
$printers += [pscustomobject]@{PrinterName="J138";PrintServer="\\SIFRSJSV0016.sigvaris-group.com\J138";ADGroup="DL-EMWESV-PS-Printers-J138";Default="0"}
$printers += [pscustomobject]@{PrinterName="J139";PrintServer="\\SIFRSJSV0016.sigvaris-group.com\J139";ADGroup="DL-EMWESV-PS-Printers-J139DEF";Default="1"}
$printers += [pscustomobject]@{PrinterName="J139";PrintServer="\\SIFRSJSV0016.sigvaris-group.com\J139";ADGroup="DL-EMWESV-PS-Printers-J139";Default="0"}
$printers += [pscustomobject]@{PrinterName="J140";PrintServer="\\SIFRSJSV0016.sigvaris-group.com\J140";ADGroup="DL-EMWESV-PS-Printers-J140DEF";Default="1"}
$printers += [pscustomobject]@{PrinterName="J140";PrintServer="\\SIFRSJSV0016.sigvaris-group.com\J140";ADGroup="DL-EMWESV-PS-Printers-J140";Default="0"}
$printers += [pscustomobject]@{PrinterName="J141";PrintServer="\\SIFRSJSV0016.sigvaris-group.com\J141";ADGroup="DL-EMWESV-PS-Printers-J141DEF";Default="1"}
$printers += [pscustomobject]@{PrinterName="J141";PrintServer="\\SIFRSJSV0016.sigvaris-group.com\J141";ADGroup="DL-EMWESV-PS-Printers-J141";Default="0"}
$printers += [pscustomobject]@{PrinterName="J142";PrintServer="\\SIFRSJSV0016.sigvaris-group.com\J142";ADGroup="DL-EMWESV-PS-Printers-J142DEF";Default="1"}
$printers += [pscustomobject]@{PrinterName="J142";PrintServer="\\SIFRSJSV0016.sigvaris-group.com\J142";ADGroup="DL-EMWESV-PS-Printers-J142";Default="0"}
$printers += [pscustomobject]@{PrinterName="J143";PrintServer="\\SIFRSJSV0016.sigvaris-group.com\J143";ADGroup="DL-EMWESV-PS-Printers-J143DEF";Default="1"}
$printers += [pscustomobject]@{PrinterName="J143";PrintServer="\\SIFRSJSV0016.sigvaris-group.com\J143";ADGroup="DL-EMWESV-PS-Printers-J143";Default="0"}
$printers += [pscustomobject]@{PrinterName="J144";PrintServer="\\SIFRSJSV0016.sigvaris-group.com\J144";ADGroup="DL-EMWESV-PS-Printers-J144DEF";Default="1"}
$printers += [pscustomobject]@{PrinterName="J144";PrintServer="\\SIFRSJSV0016.sigvaris-group.com\J144";ADGroup="DL-EMWESV-PS-Printers-J144";Default="0"}
$printers += [pscustomobject]@{PrinterName="J145";PrintServer="\\SIFRSJSV0016.sigvaris-group.com\J145";ADGroup="DL-EMWESV-PS-Printers-J145DEF";Default="1"}
$printers += [pscustomobject]@{PrinterName="J145";PrintServer="\\SIFRSJSV0016.sigvaris-group.com\J145";ADGroup="DL-EMWESV-PS-Printers-J145";Default="0"}
$printers += [pscustomobject]@{PrinterName="J146";PrintServer="\\SIFRSJSV0016.sigvaris-group.com\J146";ADGroup="DL-EMWESV-PS-Printers-J146DEF";Default="1"}
$printers += [pscustomobject]@{PrinterName="J146";PrintServer="\\SIFRSJSV0016.sigvaris-group.com\J146";ADGroup="DL-EMWESV-PS-Printers-J146";Default="0"}
$printers += [pscustomobject]@{PrinterName="J147";PrintServer="\\SIFRSJSV0016.sigvaris-group.com\J147";ADGroup="DL-EMWESV-PS-Printers-J147DEF";Default="1"}
$printers += [pscustomobject]@{PrinterName="J147";PrintServer="\\SIFRSJSV0016.sigvaris-group.com\J147";ADGroup="DL-EMWESV-PS-Printers-J147";Default="0"}
$printers += [pscustomobject]@{PrinterName="J148";PrintServer="\\SIFRSJSV0016.sigvaris-group.com\J148";ADGroup="DL-EMWESV-PS-Printers-J148DEF";Default="1"}
$printers += [pscustomobject]@{PrinterName="J148";PrintServer="\\SIFRSJSV0016.sigvaris-group.com\J148";ADGroup="DL-EMWESV-PS-Printers-J148";Default="0"}
$printers += [pscustomobject]@{PrinterName="J149";PrintServer="\\SIFRSJSV0016.sigvaris-group.com\J149";ADGroup="DL-EMWESV-PS-Printers-J149DEF";Default="1"}
$printers += [pscustomobject]@{PrinterName="J149";PrintServer="\\SIFRSJSV0016.sigvaris-group.com\J149";ADGroup="DL-EMWESV-PS-Printers-J149";Default="0"}
$printers += [pscustomobject]@{PrinterName="J150";PrintServer="\\SIFRSJSV0016.sigvaris-group.com\J150";ADGroup="DL-EMWESV-PS-Printers-J150DEF";Default="1"}
$printers += [pscustomobject]@{PrinterName="J150";PrintServer="\\SIFRSJSV0016.sigvaris-group.com\J150";ADGroup="DL-EMWESV-PS-Printers-J150";Default="0"}
$printers += [pscustomobject]@{PrinterName="PAN01";PrintServer="\\SIUKANPS01.sigvaris-group.com\PAN01";ADGroup="DL-EMWESV-PS-Printers-PAN01DEF";Default="1"}
$printers += [pscustomobject]@{PrinterName="PAN02";PrintServer="\\SIUKANPS01.sigvaris-group.com\PAN02";ADGroup="DL-EMWESV-PS-Printers-PAN02DEF";Default="1"}
$printers += [pscustomobject]@{PrinterName="PAN03";PrintServer="\\SIUKANPS01.sigvaris-group.com\PAN03";ADGroup="DL-EMWESV-PS-Printers-PAN03DEF";Default="1"}
$printers += [pscustomobject]@{PrinterName="PAN04";PrintServer="\\SIUKANPS01.sigvaris-group.com\PAN04";ADGroup="DL-EMWESV-PS-Printers-PAN04DEF";Default="1"}
$printers += [pscustomobject]@{PrinterName="PAN05";PrintServer="\\SIUKANPS01.sigvaris-group.com\PAN05";ADGroup="DL-EMWESV-PS-Printers-PAN05DEF";Default="1"}
$printers += [pscustomobject]@{PrinterName="PAN06";PrintServer="\\SIUKANPS01.sigvaris-group.com\PAN06";ADGroup="DL-EMWESV-PS-Printers-PAN06DEF";Default="1"}
$printers += [pscustomobject]@{PrinterName="PAN07";PrintServer="\\SIUKANPS01.sigvaris-group.com\PAN07";ADGroup="DL-EMWESV-PS-Printers-PAN07DEF";Default="1"}
$printers += [pscustomobject]@{PrinterName="PAN08";PrintServer="\\SIUKANPS01.sigvaris-group.com\PAN08";ADGroup="DL-EMWESV-PS-Printers-PAN08DEF";Default="1"}
$printers += [pscustomobject]@{PrinterName="PAN09";PrintServer="\\SIUKANPS01.sigvaris-group.com\PAN09";ADGroup="DL-EMWESV-PS-Printers-PAN09DEF";Default="1"}
$printers += [pscustomobject]@{PrinterName="PAN10";PrintServer="\\SIUKANPS01.sigvaris-group.com\PAN10";ADGroup="DL-EMWESV-PS-Printers-PAN10DEF";Default="1"}
$printers += [pscustomobject]@{PrinterName="PAN11";PrintServer="\\SIUKANPS01.sigvaris-group.com\PAN11";ADGroup="DL-EMWESV-PS-Printers-PAN11-DEF";Default="1"}
$printers += [pscustomobject]@{PrinterName="JET06";PrintServer="\\SIFRSJSV0016.sigvaris-group.com\JET06";ADGroup="DL-EMWESV-PS-Printers-JET06";Default="0"}
$printers += [pscustomobject]@{PrinterName="JET06";PrintServer="\\SIFRSJSV0016.sigvaris-group.com\JET06";ADGroup="DL-EMWESV-PS-Printers-JET06DEF";Default="1"}



$printers += [pscustomobject]@{PrinterName="H002";PrintServer="\\siemps01.sigvaris-group.com\H002";ADGroup="DL-GLSE-PS-Printer-H002-DEF";Default="1"}
$printers += [pscustomobject]@{PrinterName="H003";PrintServer="\\sichwips01\H003";ADGroup="DL-EMCESV-PS-Printers-H003";Default="0"}
$printers += [pscustomobject]@{PrinterName="H004";PrintServer="\\siemps01.sigvaris-group.com\H004";ADGroup="DL-GLSE-PS-Printer-H004-DEF";Default="1"}
$printers += [pscustomobject]@{PrinterName="H008";PrintServer="\\siemps01.sigvaris-group.com\H008";ADGroup="DL-GLSE-PS-Printer-H008-DEF";Default="1"}
$printers += [pscustomobject]@{PrinterName="H001";PrintServer="\\siemps01.sigvaris-group.com\H001";ADGroup="DL-GLSE-PS-Printer-H001";Default="0"}
$printers += [pscustomobject]@{PrinterName="H001";PrintServer="\\siemps01.sigvaris-group.com\H001";ADGroup="DL-GLSE-PS-Printer-H001-DEF";Default="1"}
$printers += [pscustomobject]@{PrinterName="W002";PrintServer="\\siemps01.sigvaris-group.com\W002";ADGroup="DL-GLSE-PS-Printer-W002-D";Default="1"}
$printers += [pscustomobject]@{PrinterName="W002";PrintServer="\\siemps01.sigvaris-group.com\W002";ADGroup="DL-GLSE-PS-Printer-W002";Default="0"}
$printers += [pscustomobject]@{PrinterName="H011";PrintServer="\\siemps01.sigvaris-group.com\H011";ADGroup="DL-GLSE-PS-Printer-H011-DEF";Default="1"}
$printers += [pscustomobject]@{PrinterName="ME001";PrintServer="\\siemps01.sigvaris-group.com\ME001";ADGroup="DL-GLSE-PS-Printer-ME001-DEF";Default="1"}
$printers += [pscustomobject]@{PrinterName="W001";PrintServer="\\siemps01.sigvaris-group.com\W001";ADGroup="DL-GLSE-PS-Printer-W001";Default="0"}
$printers += [pscustomobject]@{PrinterName="GZ60";PrintServer="\\siemps01.sigvaris-group.com\GZ60";ADGroup="DL-GLSE-PS-Printer-GZ60";Default="0"}
$printers += [pscustomobject]@{PrinterName="GZ61";PrintServer="\\siemps01.sigvaris-group.com\GZ61";ADGroup="DL-GLSE-PS-Printer-GZ61";Default="0"}
$printers += [pscustomobject]@{PrinterName="GZ64";PrintServer="\\siemps01.sigvaris-group.com\GZ64";ADGroup="DL-GLSE-PS-Printer-GZ64";Default="0"}
$printers += [pscustomobject]@{PrinterName="GZ65";PrintServer="\\siemps01.sigvaris-group.com\GZ65";ADGroup="DL-GLSE-PS-Printer-GZ65";Default="0"}
$printers += [pscustomobject]@{PrinterName="GZ68";PrintServer="\\siemps01.sigvaris-group.com\GZ68";ADGroup="DL-GLSE-PS-Printer-GZ68";Default="0"}
$printers += [pscustomobject]@{PrinterName="GZ69";PrintServer="\\siemps01.sigvaris-group.com\GZ69";ADGroup="DL-GLSE-PS-Printer-GZ69";Default="0"}
$printers += [pscustomobject]@{PrinterName="GZ71";PrintServer="\\siemps01.sigvaris-group.com\GZ71";ADGroup="DL-GLSE-PS-Printer-GZ71";Default="0"}
$printers += [pscustomobject]@{PrinterName="GZ72";PrintServer="\\siemps01.sigvaris-group.com\GZ72";ADGroup="DL-GLSE-PS-Printer-GZ72";Default="0"}
$printers += [pscustomobject]@{PrinterName="M001";PrintServer="\\siemps01.sigvaris-group.com\M001";ADGroup="DL-GLSE-PS-Printer-M001";Default="0"}
$printers += [pscustomobject]@{PrinterName="M002";PrintServer="\\siemps01.sigvaris-group.com\M002";ADGroup="DL-GLSE-PS-Printer-M002";Default="0"}
$printers += [pscustomobject]@{PrinterName="M005";PrintServer="\\siemps01.sigvaris-group.com\M005";ADGroup="DL-GLSE-PS-Printer-M005";Default="0"}
$printers += [pscustomobject]@{PrinterName="SICHSGPR006";PrintServer="\\siemps01.sigvaris-group.com\SICHSGPR006";ADGroup="DL-GLSE-PS-Printer-SICHSGPR006";Default="0"}
$printers += [pscustomobject]@{PrinterName="SICHSGPR001";PrintServer="\\siemps01.sigvaris-group.com\SICHSGPR001";ADGroup="DL-GLSE-PS-Printer-SICHSGPR001";Default="0"}
$printers += [pscustomobject]@{PrinterName="SICHSGPR002";PrintServer="\\siemps01.sigvaris-group.com\SICHSGPR002";ADGroup="DL-GLSE-PS-Pinter-SICHSGPR002";Default="0"}
$printers += [pscustomobject]@{PrinterName="SICHSGPR003";PrintServer="\\siemps01.sigvaris-group.com\SICHSGPR003";ADGroup="DL-GLSE-PS-Pinter-SICHSGPR003";Default="0"}
$printers += [pscustomobject]@{PrinterName="SICHSGPR004";PrintServer="\\siemps01.sigvaris-group.com\SICHSGPR004";ADGroup="DL-GLSE-PS-Pinter-SICHSGPR004";Default="0"}
$printers += [pscustomobject]@{PrinterName="SICHSGPR007";PrintServer="\\siemps01.sigvaris-group.com\SICHSGPR007";ADGroup="DL-GLSE-PS-Pinter-SICHSGPR007";Default="0"}
$printers += [pscustomobject]@{PrinterName="H003";PrintServer="\\siemps01.sigvaris-group.com\h003";ADGroup="DL-GLSE-PS-Printer-H003-DEF";Default="1"}
$printers += [pscustomobject]@{PrinterName="GZ65";PrintServer="\\siemps01.sigvaris-group.com\GZ65";ADGroup="DL-GLSE-PS-Printer-GZ65-DEF";Default="1"}
$printers += [pscustomobject]@{PrinterName="M001";PrintServer="\\siemps01.sigvaris-group.com\M001";ADGroup="DL-GLSE-PS-Printer-M001-DEF";Default="1"}
$printers += [pscustomobject]@{PrinterName="GZ72";PrintServer="\\siemps01.sigvaris-group.com\GZ72";ADGroup="DL-GLSE-PS-Printer-GZ72-DEF";Default="1"}
$printers += [pscustomobject]@{PrinterName="GZ68";PrintServer="\\siemps01.sigvaris-group.com\GZ68";ADGroup="DL-GLSE-PS-Printer-GZ68-DEF";Default="1"}
$printers += [pscustomobject]@{PrinterName="GZ60";PrintServer="\\siemps01.sigvaris-group.com\GZ60";ADGroup="DL-GLSE-PS-Printer-GZ60-DEF";Default="1"}
$printers += [pscustomobject]@{PrinterName="GZ69";PrintServer="\\siemps01.sigvaris-group.com\GZ69";ADGroup="DL-GLSE-PS-Printer-GZ69-DEF";Default="1"}
$printers += [pscustomobject]@{PrinterName="M005";PrintServer="\\siemps01.sigvaris-group.com\M005";ADGroup="DL-GLSE-PS-Printer-M005-DEF";Default="1"}
$printers += [pscustomobject]@{PrinterName="GZ61";PrintServer="\\siemps01.sigvaris-group.com\GZ61";ADGroup="DL-GLSE-PS-Printer-GZ61-DEF";Default="1"}
$printers += [pscustomobject]@{PrinterName="GZ64";PrintServer="\\siemps01.sigvaris-group.com\GZ64";ADGroup="DL-GLSE-PS-Printer-GZ64-DEF";Default="1"}


$printers += [pscustomobject]@{PrinterName="BR01";PrintServer="\\sibrspfs02.sigvaris-group.com\BR01";ADGroup="DL-AMSOSV-PS-BR01";Default="0"}
$printers += [pscustomobject]@{PrinterName="BR03";PrintServer="\\sibrspfs02.sigvaris-group.com\BR03";ADGroup="DL-AMSOSV-PS-BR03";Default="0"}
$printers += [pscustomobject]@{PrinterName="BR04";PrintServer="\\sibrspfs02.sigvaris-group.com\BR04";ADGroup="DL-AMSOSV-PS-BR04";Default="1"}
$printers += [pscustomobject]@{PrinterName="BR05";PrintServer="\\sibrspfs02.sigvaris-group.com\BR05";ADGroup="DL-AMSOSV-PS-BR05";Default="0"}
$printers += [pscustomobject]@{PrinterName="BR06";PrintServer="\\sibrspfs02.sigvaris-group.com\BR06";ADGroup="DL-AMSOSV-PS-BR06";Default="0"}
$printers += [pscustomobject]@{PrinterName="BR07";PrintServer="\\sibrspfs02.sigvaris-group.com\BR07";ADGroup="DL-AMSOSV-PS-BR07";Default="0"}
$printers += [pscustomobject]@{PrinterName="BR08";PrintServer="\\sibrspfs02.sigvaris-group.com\BR08";ADGroup="DL-AMSOSV-PS-BR08";Default="0"}
$printers += [pscustomobject]@{PrinterName="BR09";PrintServer="\\sibrspfs02.sigvaris-group.com\BR09";ADGroup="DL-AMSOSV-PS-BR09";Default="0"}
$printers += [pscustomobject]@{PrinterName="BR10";PrintServer="\\sibrspfs02.sigvaris-group.com\BR10";ADGroup="DL-AMSOSV-PS-BR10";Default="0"}
$printers += [pscustomobject]@{PrinterName="BR11";PrintServer="\\sibrspfs02.sigvaris-group.com\BR11";ADGroup="DL-AMSOSV-PS-BR11";Default="0"}
$printers += [pscustomobject]@{PrinterName="BR12";PrintServer="\\sibrspfs02.sigvaris-group.com\BR12";ADGroup="DL-AMSOSV-PS-BR12";Default="0"}
$printers += [pscustomobject]@{PrinterName="BR13";PrintServer="\\sibrspfs02.sigvaris-group.com\BR13";ADGroup="DL-AMSOSV-PS-BR13";Default="0"}
$printers += [pscustomobject]@{PrinterName="BR14";PrintServer="\\sibrspfs02.sigvaris-group.com\BR14";ADGroup="DL-AMSOSV-PS-BR14";Default="0"}
$printers += [pscustomobject]@{PrinterName="BR15";PrintServer="\\sibrspfs02.sigvaris-group.com\BR15";ADGroup="DL-AMSOSV-PS-BR15";Default="0"}
$printers += [pscustomobject]@{PrinterName="BR16";PrintServer="\\sibrspfs02.sigvaris-group.com\BR16";ADGroup="DL-AMSOSV-PS-BR16";Default="0"}
$printers += [pscustomobject]@{PrinterName="BR17";PrintServer="\\sibrspfs02.sigvaris-group.com\BR17";ADGroup="DL-AMSOSV-PS-BR17";Default="0"}
$printers += [pscustomobject]@{PrinterName="BR18";PrintServer="\\sibrspfs02.sigvaris-group.com\BR18";ADGroup="DL-AMSOSV-PS-BR18";Default="0"}
$printers += [pscustomobject]@{PrinterName="BR20";PrintServer="\\sibrspfs02.sigvaris-group.com\BR20";ADGroup="DL-AMSOSV-PS-BR20";Default="0"}
$printers += [pscustomobject]@{PrinterName="BR21";PrintServer="\\sibrspfs02.sigvaris-group.com\BR21";ADGroup="DL-AMSOSV-PS-BR21";Default="0"}
$printers += [pscustomobject]@{PrinterName="BR22";PrintServer="\\sibrspfs02.sigvaris-group.com\BR22";ADGroup="DL-AMSOSV-PS-BR22";Default="0"}
$printers += [pscustomobject]@{PrinterName="BR23";PrintServer="\\sibrspfs02.sigvaris-group.com\BR23";ADGroup="DL-AMSOSV-PS-BR23";Default="0"}
$printers += [pscustomobject]@{PrinterName="BR24";PrintServer="\\sibrspfs02.sigvaris-group.com\BR24";ADGroup="DL-AMSOSV-PS-BR24";Default="0"}
$printers += [pscustomobject]@{PrinterName="BR25";PrintServer="\\sibrspfs02.sigvaris-group.com\BR25";ADGroup="DL-AMSOSV-PS-BR25";Default="0"}
$printers += [pscustomobject]@{PrinterName="BR26";PrintServer="\\sibrspfs02.sigvaris-group.com\BR26";ADGroup="DL-AMSOSV-PS-BR26";Default="0"}
$printers += [pscustomobject]@{PrinterName="BR27";PrintServer="\\sibrspfs02.sigvaris-group.com\BR27";ADGroup="DL-AMSOSV-PS-BR27";Default="0"}
$printers += [pscustomobject]@{PrinterName="BR28";PrintServer="\\sibrspfs02.sigvaris-group.com\BR28";ADGroup="DL-AMSOSV-PS-BR28";Default="0"}
$printers += [pscustomobject]@{PrinterName="BR29";PrintServer="\\sibrspfs02.sigvaris-group.com\BR29";ADGroup="DL-AMSOSV-PS-BR29";Default="0"}



$printers += [pscustomobject]@{PrinterName="PUSGA01";PrintServer="\\SIUSGAPS01\PUSGA01";ADGroup="DL-Servers-PS-Printers-PUSGA01";Default="0"}
$printers += [pscustomobject]@{PrinterName="PUSGA02";PrintServer="\\SIUSGAPS01\PUSGA02";ADGroup="DL-Servers-PS-Printers-PUSGA02";Default="0"}
$printers += [pscustomobject]@{PrinterName="PUSGA03-FAX";PrintServer="\\SIUSGAPS01\PUSGA03-FAX";ADGroup="DL-AMNOSV-PS-Printers-PUSGA03-FAX";Default="0"}
$printers += [pscustomobject]@{PrinterName="PUSGA04";PrintServer="\\SIUSGAPS01\PUSGA04";ADGroup="DL-Servers-PS-Printers-PUSGA04";Default="0"}
$printers += [pscustomobject]@{PrinterName="PUSGA05";PrintServer="\\SIUSGAPS01\PUSGA05";ADGroup="DL-Servers-PS-Printers-PUSGA05";Default="0"}
$printers += [pscustomobject]@{PrinterName="PUSGA06";PrintServer="\\SIUSGAPS01\PUSGA06";ADGroup="DL-Servers-PS-Printers-PUSGA06";Default="0"}
$printers += [pscustomobject]@{PrinterName="PUSGA07";PrintServer="\\SIUSGAPS01\PUSGA07";ADGroup="DL-Servers-PS-Printers-PUSGA07";Default="0"}
$printers += [pscustomobject]@{PrinterName="PUSGA08";PrintServer="\\SIUSGAPS01\PUSGA08";ADGroup="DL-Servers-PS-Printers-PUSGA08";Default="0"}
$printers += [pscustomobject]@{PrinterName="PUSGA09";PrintServer="\\SIUSGAPS01\PUSGA09";ADGroup="DL-Servers-PS-Printers-PUSGA09";Default="0"}
$printers += [pscustomobject]@{PrinterName="PUSGA10";PrintServer="\\SIUSGAPS01\PUSGA10";ADGroup="DL-Servers-PS-Printers-PUSGA10";Default="0"}
$printers += [pscustomobject]@{PrinterName="PUSGA11";PrintServer="\\SIUSGAPS02\PUSGA11";ADGroup="DL-AMNOSV-PS-Printers-PUSGA11";Default="0"}
$printers += [pscustomobject]@{PrinterName="PUSGA12";PrintServer="\\SIUSGAPS01\PUSGA12";ADGroup="DL-AMNOSV-PS-Printers-PUSGA12";Default="0"}
$printers += [pscustomobject]@{PrinterName="PUSGA13";PrintServer="\\SIUSGAPS01\PUSGA13";ADGroup="DL-AMNOSV-PS-Printers-PUSGA13";Default="0"}
$printers += [pscustomobject]@{PrinterName="PUSGA14";PrintServer="\\SIUSGAPS01\PUSGA14";ADGroup="DL-AMNOSV-PS-Printers-PUSGA14";Default="0"}
$printers += [pscustomobject]@{PrinterName="PUSGA01";PrintServer="\\SIUSGAPS02\PUSGA01";ADGroup="DL-Servers-PS-Printers-PUSGA01";Default="0"}
$printers += [pscustomobject]@{PrinterName="PUSGA02";PrintServer="\\SIUSGAPS02\PUSGA02";ADGroup="DL-Servers-PS-Printers-PUSGA02";Default="0"}
$printers += [pscustomobject]@{PrinterName="PUSGA03-FAX";PrintServer="\\SIUSGAPS02\PUSGA03-FAX";ADGroup="DL-AMNOSV-PS-Printers-PUSGA03-FAX";Default="0"}
$printers += [pscustomobject]@{PrinterName="PUSGA04";PrintServer="\\SIUSGAPS02\PUSGA04";ADGroup="DL-Servers-PS-Printers-PUSGA04";Default="0"}
$printers += [pscustomobject]@{PrinterName="PUSGA05";PrintServer="\\SIUSGAPS02\PUSGA05";ADGroup="DL-Servers-PS-Printers-PUSGA05";Default="0"}
$printers += [pscustomobject]@{PrinterName="PUSGA06";PrintServer="\\SIUSGAPS02\PUSGA06";ADGroup="DL-Servers-PS-Printers-PUSGA06";Default="0"}
$printers += [pscustomobject]@{PrinterName="PUSGA07";PrintServer="\\SIUSGAPS02\PUSGA07";ADGroup="DL-Servers-PS-Printers-PUSGA07";Default="0"}
$printers += [pscustomobject]@{PrinterName="PUSGA08";PrintServer="\\SIUSGAPS02\PUSGA08";ADGroup="DL-Servers-PS-Printers-PUSGA08";Default="0"}
$printers += [pscustomobject]@{PrinterName="PUSGA09";PrintServer="\\SIUSGAPS02\PUSGA09";ADGroup="DL-Servers-PS-Printers-PUSGA09";Default="0"}
$printers += [pscustomobject]@{PrinterName="PUSGA10";PrintServer="\\SIUSGAPS02\PUSGA10";ADGroup="DL-Servers-PS-Printers-PUSGA10";Default="0"}
$printers += [pscustomobject]@{PrinterName="PUSGA11";PrintServer="\\SIUSGAPS02\PUSGA11";ADGroup="DL-AMNOSV-PS-Printers-PUSGA11";Default="0"}
$printers += [pscustomobject]@{PrinterName="PUSGA12";PrintServer="\\SIUSGAPS02\PUSGA12";ADGroup="DL-AMNOSV-PS-Printers-PUSGA12";Default="0"}
$printers += [pscustomobject]@{PrinterName="PUSGA13";PrintServer="\\SIUSGAPS02\PUSGA13";ADGroup="DL-AMNOSV-PS-Printers-PUSGA13";Default="0"}
$printers += [pscustomobject]@{PrinterName="PUSGA14";PrintServer="\\SIUSGAPS02\PUSGA14";ADGroup="DL-AMNOSV-PS-Printers-PUSGA14";Default="0"}
$printers += [pscustomobject]@{PrinterName="PUSGA15";PrintServer="\\SIUSGAPS02\PUSGA15";ADGroup="DL-AMNOSV-PS-Printers-PUSGA15";Default="0"}
$printers += [pscustomobject]@{PrinterName="PUSGA16";PrintServer="\\SIUSGAPS02\PUSGA16";ADGroup="DL-AMNOSV-PS-Printers-PUSGA16";Default="0"}
$printers += [pscustomobject]@{PrinterName="PUSMI01";PrintServer="\\SIUSMIPS01\PUSMI01";ADGroup="DL-AMNOSV-PS-Printers-PUSMI01";Default="0"}
$printers += [pscustomobject]@{PrinterName="PUSMI02";PrintServer="\\SIUSMIPS01\PUSMI02";ADGroup="DL-AMNOSV-PS-Printers-PUSMI02";Default="0"}
$printers += [pscustomobject]@{PrinterName="PUSMI03";PrintServer="\\SIUSMIPS01\PUSMI03";ADGroup="DL-AMNOSV-PS-Printers-PUSMI03";Default="0"}
$printers += [pscustomobject]@{PrinterName="PUSMI04";PrintServer="\\SIUSMIPS01\PUSMI04";ADGroup="DL-AMNOSV-PS-Printers-PUSMI04";Default="0"}
$printers += [pscustomobject]@{PrinterName="PUSMI05";PrintServer="\\SIUSMIPS01\PUSMI05";ADGroup="DL-AMNOSV-PS-Printers-PUSMI05";Default="0"}
$printers += [pscustomobject]@{PrinterName="PUSMI06";PrintServer="\\SIUSMIPS01\PUSMI06";ADGroup="DL-AMNOSV-PS-Printers-PUSMI06";Default="0"}
$printers += [pscustomobject]@{PrinterName="PCAMO01";PrintServer="\\SICAMOPS01\PCAMO01";ADGroup="DL-AMNOSV-PS-Printers-PCAMO01";Default="0"}
$printers += [pscustomobject]@{PrinterName="PCAMO02";PrintServer="\\SICAMOPS01\PCAMO02";ADGroup="DL-AMNOSV-PS-Printers-PCAMO02";Default="0"}
$printers += [pscustomobject]@{PrinterName="PCAMO03";PrintServer="\\SICAMOPS01\PCAMO03";ADGroup="DL-AMNOSV-PS-Printers-PCAMO03";Default="0"}
$printers += [pscustomobject]@{PrinterName="PCAMO04";PrintServer="\\SICAMOPS01\PCAMO04";ADGroup="DL-AMNOSV-PS-Printers-PCAMO04";Default="0"}
$printers += [pscustomobject]@{PrinterName="PCAMO05";PrintServer="\\SICAMOPS01\PCAMO05";ADGroup="DL-AMNOSV-PS-Printers-PCAMO05";Default="0"}
$printers += [pscustomobject]@{PrinterName="PCAMO06-FAX";PrintServer="\\SICAMOPS01\PCAMO06-FAX";ADGroup="DL-AMNOSV-PS-Printers-PCAMO06-FAX";Default="0"}
$printers += [pscustomobject]@{PrinterName="PCAMO07";PrintServer="\\SICAMOPS01\PCAMO07";ADGroup="DL-AMNOSV-PS-Printers-PCAMO07";Default="0"}
$printers += [pscustomobject]@{PrinterName="PCAMO08";PrintServer="\\SICAMOPS01\PCAMO08";ADGroup="DL-AMNOSV-PS-Printers-PCAMO08";Default="0"}
$printers += [pscustomobject]@{PrinterName="PCAMO09";PrintServer="\\SICAMOPS01\PCAMO09";ADGroup="DL-AMNOSV-PS-Printers-PCAMO09";Default="0"}
$printers += [pscustomobject]@{PrinterName="PCAMO10";PrintServer="\\SICAMOPS01\PCAMO10";ADGroup="DL-AMNOSV-PS-Printers-PCAMO10";Default="0"}
$printers += [pscustomobject]@{PrinterName="PCAMO11";PrintServer="\\SICAMOPS01\PCAMO11";ADGroup="DL-AMNOSV-PS-Printers-PCAMO11";Default="0"}
$printers += [pscustomobject]@{PrinterName="PCAMO12";PrintServer="\\SICAMOPS01\PCAMO12";ADGroup="DL-AMNOSV-PS-Printers-PCAMO12";Default="0"}
$printers += [pscustomobject]@{PrinterName="PUSGAEDI";PrintServer="\\SIUSGAPS02\PUSGAEDI";ADGroup="DL-AMNOSV-PS-Printers-PUSGAEDI";Default="0"}
$printers += [pscustomobject]@{PrinterName="PDFCreator Invoice PDF to Neopost";PrintServer="\\SIUSGAPS02\PDFCreator Invoice PDF to Neopost";ADGroup="DL-AMNOSV-PS-Printers-PDFCreator Invoice";Default="0"}


$printers += [pscustomobject]@{PrinterName="pmxmc01";PrintServer="\\simxmcfs001\pmxmc01";ADGroup="DL-AMCESE-PS-Printers-PMXMC01";Default="1"}
$printers += [pscustomobject]@{PrinterName="pmxmc02";PrintServer="\\simxmcfs001\pmxmc02";ADGroup="DL-AMCESE-PS-Printers-PMXMC01";Default="1"}
$printers += [pscustomobject]@{PrinterName="pmxmc01";PrintServer="\\simxmcfs01\pmxmc01";ADGroup="DL-AMCESE-PS-Printers-PMXMC01";Default="1"}
$printers += [pscustomobject]@{PrinterName="pmxmc02";PrintServer="\\simxmcfs01\pmxmc02";ADGroup="DL-AMCESE-PS-Printers-PMXMC01";Default="1"}

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
    
    
	Foreach ($Printer in $PrintersForUser){
		Try {
			Write-Output "Get the status of the printer '$($Printer.PrintServer)' on the print server"
			$PrinterServerStatus = (Get-Printer -ComputerName ([URI]($Printer.PrintServer).host) -Name $Printer.PrinterName).PrinterStatus
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
			}
			}
		Catch {
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