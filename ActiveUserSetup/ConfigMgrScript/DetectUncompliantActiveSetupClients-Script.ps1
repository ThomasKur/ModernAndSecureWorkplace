<#
.DESCRIPTION
This Script will compare the default keys of a new Windows 10 device with the one on your device and return compliant if no other than the default one exists. 

.EXAMPLE


.NOTES
Author: Thomas Kurth/baseVISION
Date:   28.04.2018

History
    001: First Version

#>
$Windows1709Default = @("HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Active Setup\Installed Components\>{22d6f312-b0f6-11d0-94ab-0080c74c7e95}",
"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Active Setup\Installed Components\{22d6f312-b0f6-11d0-94ab-0080c74c7e95}",
"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Active Setup\Installed Components\{2C7339CF-2B09-4501-B3F3-F3508C9228ED}",
"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Active Setup\Installed Components\{3af36230-a269-11d1-b5bf-0000f8051515}",
"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Active Setup\Installed Components\{44BBA855-CC51-11CF-AAFA-00AA00B6015F}",
"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Active Setup\Installed Components\{45ea75a0-a269-11d1-b5bf-0000f8051515}",
"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Active Setup\Installed Components\{4f645220-306d-11d2-995d-00c04f98bbc9}",
"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Active Setup\Installed Components\{4FC4FAB8-DD2C-3F8B-B378-F6EF65C0EC05}",
"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Active Setup\Installed Components\{5fd399c0-a70a-11d1-9948-00c04f98bbc9}",
"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Active Setup\Installed Components\{630b1da0-b465-11d1-9948-00c04f98bbc9}",
"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Active Setup\Installed Components\{6BF52A52-394A-11d3-B153-00C04F79FAA6}",
"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Active Setup\Installed Components\{6fab99d0-bab8-11d1-994a-00c04f98bbc9}",
"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Active Setup\Installed Components\{7790769C-0471-11d2-AF11-00C04FA35D02}",
"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Active Setup\Installed Components\{89820200-ECBD-11cf-8B85-00AA005B4340}",
"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Active Setup\Installed Components\{89820200-ECBD-11cf-8B85-00AA005B4383}",
"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Active Setup\Installed Components\{89B4C1CD-B018-4511-B0A1-5476DBF70820}",
"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Active Setup\Installed Components\{9381D8F2-0288-11D0-9501-00AA00B911A5}",
"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Active Setup\Installed Components\{C9E9A340-D1F1-11D0-821E-444553540600}",
"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Active Setup\Installed Components\{de5aed00-a4bf-11d1-9948-00c04f98bbc9}",
"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Active Setup\Installed Components\{E92B03AB-B707-11d2-9CBD-0000F87A369E}",
"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Active Setup\Installed Components\{FEBEF00C-046D-438D-8A88-BF94A6C9E703}",
"HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Active Setup\Installed Components\>{22d6f312-b0f6-11d0-94ab-0080c74c7e95}",
"HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Active Setup\Installed Components\{22d6f312-b0f6-11d0-94ab-0080c74c7e95}",
"HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Active Setup\Installed Components\{3af36230-a269-11d1-b5bf-0000f8051515}",
"HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Active Setup\Installed Components\{44BBA855-CC51-11CF-AAFA-00AA00B6015F}",
"HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Active Setup\Installed Components\{45ea75a0-a269-11d1-b5bf-0000f8051515}",
"HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Active Setup\Installed Components\{4f645220-306d-11d2-995d-00c04f98bbc9}",
"HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Active Setup\Installed Components\{54BDBDCB-ED26-30CA-BFFC-5B5E414C3793}",
"HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Active Setup\Installed Components\{5fd399c0-a70a-11d1-9948-00c04f98bbc9}",
"HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Active Setup\Installed Components\{630b1da0-b465-11d1-9948-00c04f98bbc9}",
"HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Active Setup\Installed Components\{6BF52A52-394A-11d3-B153-00C04F79FAA6}",
"HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Active Setup\Installed Components\{6fab99d0-bab8-11d1-994a-00c04f98bbc9}",
"HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Active Setup\Installed Components\{7790769C-0471-11d2-AF11-00C04FA35D02}",
"HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Active Setup\Installed Components\{7C028AF8-F614-47B3-82DA-BA94E41B1089}",
"HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Active Setup\Installed Components\{89820200-ECBD-11cf-8B85-00AA005B4383}",
"HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Active Setup\Installed Components\{89B4C1CD-B018-4511-B0A1-5476DBF70820}",
"HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Active Setup\Installed Components\{9381D8F2-0288-11D0-9501-00AA00B911A5}",
"HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Active Setup\Installed Components\{C9E9A340-D1F1-11D0-821E-444553540600}",
"HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Active Setup\Installed Components\{de5aed00-a4bf-11d1-9948-00c04f98bbc9}",
"HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Active Setup\Installed Components\{E92B03AB-B707-11d2-9CBD-0000F87A369E}")

$Windows1703Default = @("HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Active Setup\Installed Components\>{22d6f312-b0f6-11d0-94ab-0080c74c7e95}",
"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Active Setup\Installed Components\{22d6f312-b0f6-11d0-94ab-0080c74c7e95}",
"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Active Setup\Installed Components\{2C7339CF-2B09-4501-B3F3-F3508C9228ED}",
"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Active Setup\Installed Components\{3af36230-a269-11d1-b5bf-0000f8051515}",
"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Active Setup\Installed Components\{44BBA840-CC51-11CF-AAFA-00AA00B6015C}",
"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Active Setup\Installed Components\{44BBA855-CC51-11CF-AAFA-00AA00B6015F}",
"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Active Setup\Installed Components\{45ea75a0-a269-11d1-b5bf-0000f8051515}",
"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Active Setup\Installed Components\{4f645220-306d-11d2-995d-00c04f98bbc9}",
"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Active Setup\Installed Components\{5fd399c0-a70a-11d1-9948-00c04f98bbc9}",
"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Active Setup\Installed Components\{630b1da0-b465-11d1-9948-00c04f98bbc9}",
"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Active Setup\Installed Components\{6BF52A52-394A-11d3-B153-00C04F79FAA6}",
"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Active Setup\Installed Components\{6fab99d0-bab8-11d1-994a-00c04f98bbc9}",
"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Active Setup\Installed Components\{7790769C-0471-11d2-AF11-00C04FA35D02}",
"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Active Setup\Installed Components\{89820200-ECBD-11cf-8B85-00AA005B4340}",
"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Active Setup\Installed Components\{89820200-ECBD-11cf-8B85-00AA005B4383}",
"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Active Setup\Installed Components\{89B4C1CD-B018-4511-B0A1-5476DBF70820}",
"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Active Setup\Installed Components\{9381D8F2-0288-11D0-9501-00AA00B911A5}",
"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Active Setup\Installed Components\{C9E9A340-D1F1-11D0-821E-444553540600}",
"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Active Setup\Installed Components\{de5aed00-a4bf-11d1-9948-00c04f98bbc9}",
"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Active Setup\Installed Components\{E087BCD1-F9A5-32C2-811C-5811D0694333}",
"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Active Setup\Installed Components\{E92B03AB-B707-11d2-9CBD-0000F87A369E}",
"HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Active Setup\Installed Components\>{22d6f312-b0f6-11d0-94ab-0080c74c7e95}",
"HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Active Setup\Installed Components\{22d6f312-b0f6-11d0-94ab-0080c74c7e95}",
"HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Active Setup\Installed Components\{3af36230-a269-11d1-b5bf-0000f8051515}",
"HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Active Setup\Installed Components\{44BBA840-CC51-11CF-AAFA-00AA00B6015C}",
"HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Active Setup\Installed Components\{44BBA855-CC51-11CF-AAFA-00AA00B6015F}",
"HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Active Setup\Installed Components\{45ea75a0-a269-11d1-b5bf-0000f8051515}",
"HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Active Setup\Installed Components\{4f645220-306d-11d2-995d-00c04f98bbc9}",
"HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Active Setup\Installed Components\{5fd399c0-a70a-11d1-9948-00c04f98bbc9}",
"HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Active Setup\Installed Components\{630b1da0-b465-11d1-9948-00c04f98bbc9}",
"HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Active Setup\Installed Components\{6BF52A52-394A-11d3-B153-00C04F79FAA6}",
"HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Active Setup\Installed Components\{6fab99d0-bab8-11d1-994a-00c04f98bbc9}",
"HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Active Setup\Installed Components\{7790769C-0471-11d2-AF11-00C04FA35D02}",
"HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Active Setup\Installed Components\{89820200-ECBD-11cf-8B85-00AA005B4383}",
"HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Active Setup\Installed Components\{89B4C1CD-B018-4511-B0A1-5476DBF70820}",
"HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Active Setup\Installed Components\{9381D8F2-0288-11D0-9501-00AA00B911A5}",
"HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Active Setup\Installed Components\{C9E9A340-D1F1-11D0-821E-444553540600}",
"HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Active Setup\Installed Components\{CA8D3B25-8CCF-32BC-BDF5-3C8E3AB24681}",
"HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Active Setup\Installed Components\{de5aed00-a4bf-11d1-9948-00c04f98bbc9}",
"HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Active Setup\Installed Components\{E92B03AB-B707-11d2-9CBD-0000F87A369E}")



$CurrentValues = (Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components").Name + (Get-ChildItem "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Active Setup\Installed Components").Name 

if((Get-WmiObject Win32_OperatingSystem).Version -eq "10.0.16299"){
    #Comppare for Version 1709 
    $DifferentValues = $CurrentValues | Where-Object {$Windows1709Default -notcontains $_}
    if($DifferentValues -ne $null){
        $DifferentValues | ConvertTo-Json
    } else {
        "Compliant" | ConvertTo-Json
    }
} elseif((Get-WmiObject Win32_OperatingSystem).Version -eq "10.0.15063"){
    #Comppare for Version 1703 
    $DifferentValues = $CurrentValues | Where-Object {$Windows1703Default -notcontains $_}
    if($DifferentValues -ne $null){
        $DifferentValues | ConvertTo-Json
    } else {
        "Compliant" | ConvertTo-Json
    }
} else {
    "UnknownOS" | ConvertTo-Json
}

