<#

Powershell modul for adding, modifing and removing ActiveUserSetup tasks.
To use this module you have to import it in your script with:

    Import-Module <PathToModul>\ActiveUserSetupModule.psd1



Author: Christof Rothen
Date:   08.09.2018

History
    1.0.0.0: First Version

#>

$activeSetupPath = 'HKLM:\SOFTWARE\ActiveUserSetup'

function Get-RegWindowStyle {
    Param (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Normal', 'Maximized', 'Minimized', 'Hidden')]
        [string]$WindowStyle
    )

    switch ($WindowStyle) {
        Maximized {$regWindowStyle = 1}
        Minimized {$regWindowStyle = 2}
        Hidden {$regWindowStyle = 3}
        default {$regWindowStyle = 0}
    }

    return $regWindowStyle
}

function New-ActiveUserSetupTask {
    <#
    .SYNOPSIS
        Creates a new ActiveUserSetup task.
    .DESCRIPTION
        Use New-ActiveUserSetupTask to create a new ActiveUserSetup task.

    .PARAMETER Name
        The name of the task.

    .PARAMETER Version
        The version of the task.

    .PARAMETER Execute
        The comand to execute.

    .PARAMETER Argument
        The argument to pass to the execute command.

    .PARAMETER WaitOnFinish
        Indicates if ActiveUserSetup should wati till the task is finished.

    .PARAMETER OnlyWhenSuccessful
        Indicates if the task should be considered done only if it succedes. This requires the WaitOnFinish to be set to true.

    .PARAMETER SuccessCodes
        Return codes wich indicates a successfule processing.

    .PARAMETER WindowStyle
        Indicates how the task window should be shown
 
    .EXAMPLE
        Creates a ActiveUserSetup task whit syncron processing and check for return code 0.

        New-ActiveUserSetupTask -Name 'Test' -Version '1.2' -Execute 'cmd.exe'

    .LINK
        Set-ActiveUserSetupTask
        Test-ActiveUserSetupTask
        Remove-ActiveUserSetupTask


    #>

    Param (
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $false)]
        [string]$Version,
        [Parameter(Mandatory = $true)]
        [string]$Execute,
        [Parameter(Mandatory = $false)]
        [string]$Argument,
        [Parameter(Mandatory = $false)]
        [switch]$WaitOnFinish=$true,
        [Parameter(Mandatory = $false)]
        [switch]$OnlyWhenSuccessful=$false,
        [Parameter(Mandatory = $false)]
        [string]$SuccessCode='0',
        [Parameter(Mandatory = $false)]
        [ValidateSet('Normal', 'Maximized', 'Minimized', 'Hidden')]
        [string]$WindowStyle='Normal'
    )

    if ($OnlyWhenSuccessful -and !$WaitOnFinish) {
        Throw "The combination of the parameters OnlyWhenSuccessful=$OnlyWhenSuccessful and WaitOnFinish=$WaitOnFinish is not allowed!"
    }

    try {
        New-Item -Path $activeSetupPath -Name $Name -ErrorAction Stop | Out-Null
        New-ItemProperty -Path "$activeSetupPath\$Name" -PropertyType String -Name 'Name' -Value $Name -ErrorAction Stop | Out-Null
        if ($Version) {
            New-ItemProperty -Path "$activeSetupPath\$Name" -PropertyType String -Name 'Version' -Value $Version -ErrorAction Stop | Out-Null
        }
        New-ItemProperty -Path "$activeSetupPath\$Name" -PropertyType String -Name 'Execute' -Value $Execute -ErrorAction Stop | Out-Null
        if ($Argument) {
            New-ItemProperty -Path "$activeSetupPath\$Name" -PropertyType String -Name 'Argument' -Value $Argument -ErrorAction Stop | Out-Null
        }
        if ($WaitOnFinish) {
            New-ItemProperty -Path "$activeSetupPath\$Name" -PropertyType DWORD -Name 'WaitOnFinish' -Value 1 -ErrorAction Stop | Out-Null
        } else {
            New-ItemProperty -Path "$activeSetupPath\$Name" -PropertyType DWORD -Name 'WaitOnFinish' -Value 0 -ErrorAction Stop | Out-Null
        }
        if ($OnlyWhenSuccessful) {
            New-ItemProperty -Path "$activeSetupPath\$Name" -PropertyType DWORD -Name 'OnlyWhenSuccessful' -Value 1 -ErrorAction Stop | Out-Null
        } else {
            New-ItemProperty -Path "$activeSetupPath\$Name" -PropertyType DWORD -Name 'OnlyWhenSuccessful' -Value 0 -ErrorAction Stop | Out-Null
        }
        New-ItemProperty -Path "$activeSetupPath\$Name" -PropertyType String -Name 'SuccessfulReturnCodes' -Value $SuccessCode -ErrorAction Stop | Out-Null

        New-ItemProperty -Path "$activeSetupPath\$Name" -PropertyType DWORD -Name 'WindowStyle' -Value (Get-RegWindowStyle -WindowStyle $WindowStyle) -ErrorAction Stop | Out-Null
    }
    catch {
        Throw "New-ActiveUserSetupTask failed: $_"
    }
}

function Set-ActiveUserSetupTask {
    <#
    .SYNOPSIS
        Updates a ActiveUserSetup task.
    .DESCRIPTION
        Use Set-ActiveUserSetupTask to update the information of a ActiveUserSetup task.

    .PARAMETER Name
        The name of the task.

    .PARAMETER Version
        The version of the task.

    .PARAMETER Execute
        The comand to execute.

    .PARAMETER Argument
        The argument to pass to the execute command.

    .PARAMETER WaitOnFinish
        Indicates if ActiveUserSetup should wati till the task is finished.

    .PARAMETER OnlyWhenSuccessful
        Indicates if the task should be considered done only if it succedes. This requires the WaitOnFinish to be set to true.

    .PARAMETER SuccessCodes
        Return codes wich indicates a successfule processing.

    .PARAMETER WindowStyle
        Indicates how the task window should be shown
 
    .EXAMPLE
        Updates the version of an ActiveUserSetup task.

        Set-ActiveUserSetupTask -Name 'Test' -Version '1.3'

    .EXAMPLE
        Remove argument from the ActiveUserSetup task.

        Set-ActiveUserSetupTask -Name 'Test' -Argument ''

    .LINK
        New-ActiveUserSetupTask
        Test-ActiveUserSetupTask
        Remove-ActiveUserSetupTask

    #>

    Param (
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $false)]
        [string]$Version,
        [Parameter(Mandatory = $false)]
        [string]$Execute=$null,
        [Parameter(Mandatory = $false)]
        $Argument,
        [Parameter(Mandatory = $false)]
        [Nullable[switch]]$WaitOnFinish,
        [Parameter(Mandatory = $false)]
        [Nullable[switch]]$OnlyWhenSuccessful,
        [Parameter(Mandatory = $false)]
        [string]$SuccessCodes=$null,
        [Parameter(Mandatory = $false)]
        [ValidateSet('Normal', 'Maximized', 'Minimized', 'Hidden')]
        [string]$WindowStyle
    )

    try {
        if (Test-ActiveUserSetupTask -Name $Name) {
            if ($WaitOnFinish -eq $null) {
                $testWaitOnFinish = $false
                $regWaitOnFinish = Get-ItemProperty -Path "$activeSetupPath\$Name" -Name 'WaitOnFinish' -ErrorAction SilentlyContinue
                if ($regWaitOnFinish -ne $null) {
                    if ($regWaitOnFinish.WaitOnFinish -eq 1) {
                        $testWaitOnFinish = $true
                    }
                }
            } else {
                $testWaitOnFinish = $WaitOnFinish
            }

            if ($OnlyWhenSuccessful -eq $null) {
                $testOnlyWhenSuccessful = $false
                $regOnlyWhenSuccessful = Get-ItemProperty -Path "$activeSetupPath\$Name" -Name 'OnlyWhenSuccessful' -ErrorAction SilentlyContinue
                if ($regOnlyWhenSuccessful -ne $null) {
                    if ($regOnlyWhenSuccessful.OnlyWhenSuccessful -eq 1) {
                        $testOnlyWhenSuccessful = $true
                    }
                }
            } else {
                $testOnlyWhenSuccessful = $OnlyWhenSuccessful
            }

            if ($testOnlyWhenSuccessful -and !$testWaitOnFinish) {
                Throw "The combination of the parameters OnlyWhenSuccessful=$testOnlyWhenSuccessful and WaitOnFinish=$testWaitOnFinish is not allowed!"
            }

            if ($Version) {
                Set-ItemProperty -Path "$activeSetupPath\$Name" -Name 'Version' -Value $Version -ErrorAction Stop
            }

            if ($Execute) {
                Set-ItemProperty -Path "$activeSetupPath\$Name" -Name 'Execute' -Value $Execute -ErrorAction Stop
            }

            if ($Argument -ne $null) {
                $item = Get-ItemProperty -Path "$activeSetupPath\$Name" -Name 'Argument' -ErrorAction SilentlyContinue
                if ($item) {
                    Set-ItemProperty -Path "$activeSetupPath\$Name" -Name 'Argument' -Value $Argument -ErrorAction Stop
                } else {
                    New-ItemProperty -Path "$activeSetupPath\$Name" -PropertyType String -Name 'Argument' -Value $Argument -ErrorAction Stop | Out-Null
                }
            }

            if ($WaitOnFinish -ne $null) {
                if ($WaitOnFinish) {
                    Set-ItemProperty -Path "$activeSetupPath\$Name" -Name 'WaitOnFinish' -Value 1 -ErrorAction Stop
                } else {
                    Set-ItemProperty -Path "$activeSetupPath\$Name" -Name 'WaitOnFinish' -Value 0 -ErrorAction Stop
                }
            }

            if ($OnlyWhenSuccessful -ne $null) {
                if ($OnlyWhenSuccessful) {
                    Set-ItemProperty -Path "$activeSetupPath\$Name" -Name 'OnlyWhenSuccessful' -Value 1 -ErrorAction Stop
                } else {
                    Set-ItemProperty -Path "$activeSetupPath\$Name" -Name 'OnlyWhenSuccessful' -Value 0 -ErrorAction Stop
                }
            }

            if ($SuccessCodes) {
                Set-ItemProperty -Path "$activeSetupPath\$Name" -Name 'SuccessfulReturnCodes' -Value $SuccessCodes -ErrorAction Stop
            }

            if ($WindowStyle) {
                Set-ItemProperty -Path "$activeSetupPath\$Name" -Name 'WindowStyle' -Value (Get-RegWindowStyle -WindowStyle $WindowStyle) -ErrorAction Stop
            }

        } else {
            Throw "No task with the name $Name found to update."
        }
    }
    catch {
       Throw "Set-ActiveUserSetupTask failed: $_"
    }
}

function Test-ActiveUserSetupTask {
    <#
    .SYNOPSIS
        Test if an ActiveUserSetup task exist.
    .DESCRIPTION
        Use Test-ActiveUserSetupTask to test if an ActiveUserSetup task exist on the system.

    .PARAMETER Name
        The name of the task.

    .PARAMETER Version
        The version of the task.

    .EXAMPLE
        Test if an ActiveUserSetup task of any version exist.

        Test-ActiveUserSetupTask -Name 'Test'

    .EXAMPLE
        Test if an ActiveUserSetup task of the version 1.2 exist.

        Test-ActiveUserSetupTask -Name 'Test' -Version '1.2'

    .LINK
        New-ActiveUserSetupTask
        Set-ActiveUserSetupTask
        Remove-ActiveUSerSetupTask

    #>

    Param (
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $false)]
        [string]$Version
    )

    try {
        $item = Get-Item -Path "$activeSetupPath\$Name" -ErrorAction SilentlyContinue
        if ($item) {
            if ($Version) {
                $setVersion = (Get-ItemProperty -Path "$activeSetupPath\$Name" -Name 'Version' -ErrorAction Stop).Version
                if ($setVersion -and $Version -eq $setVersion) {
                    return $true
                } else {
                    return $false
                }
            } else {
                return $true
            }
        } else {
            return $false
        }
    }
    catch {
        Throw "Test-ActiveUserSetupTask failed: $_"
    }
}

function Remove-ActiveUserSetupTask {
    <#
    .SYNOPSIS
        Removes a ActiveUserSetup task form the system.

    .DESCRIPTION
        Use Remove-ActiveUserSetupTask to remove a ActiveUserSetup task from the system.

    .PARAMETER Name
        The name of the task.

    .PARAMETER Version
        The version of the task.

    .EXAMPLE
        Removes the ActiveUserSetup task of any version.

        Remove-ActiveUserSetupTask -Name 'Test'

    .EXAMPLE
        Removes the ActiveUserSetup task of version 1.2.

        Remove-ActiveUserSetupTask -Name 'Test' -Version '1.2'

    .LINK
        New-ActiveUserSetupTask
        Set-ActiveUserSetupTask
        Test-ActiveUserSetupTask

    #>

    Param (
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $false)]
        [string]$Version
    )

    try {
        if (Test-ActiveUserSetup -Name $Name -Version $Version) {
            Remove-Item -Path "$activeSetupPath\$Name" -ErrorAction Stop
        }
    }
    catch {
        Throw "Remove-ActiveUserSetupTask failed: $_"
    }
}

# SIG # Begin signature block
# MIIgwgYJKoZIhvcNAQcCoIIgszCCIK8CAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUqW4a21Oe4Wl7jhO2XGlJUc9M
# 9SGgghsdMIIGajCCBVKgAwIBAgIQAwGaAjr/WLFr1tXq5hfwZjANBgkqhkiG9w0B
# AQUFADBiMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYD
# VQQLExB3d3cuZGlnaWNlcnQuY29tMSEwHwYDVQQDExhEaWdpQ2VydCBBc3N1cmVk
# IElEIENBLTEwHhcNMTQxMDIyMDAwMDAwWhcNMjQxMDIyMDAwMDAwWjBHMQswCQYD
# VQQGEwJVUzERMA8GA1UEChMIRGlnaUNlcnQxJTAjBgNVBAMTHERpZ2lDZXJ0IFRp
# bWVzdGFtcCBSZXNwb25kZXIwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIB
# AQCjZF38fLPggjXg4PbGKuZJdTvMbuBTqZ8fZFnmfGt/a4ydVfiS457VWmNbAklQ
# 2YPOb2bu3cuF6V+l+dSHdIhEOxnJ5fWRn8YUOawk6qhLLJGJzF4o9GS2ULf1ErNz
# lgpno75hn67z/RJ4dQ6mWxT9RSOOhkRVfRiGBYxVh3lIRvfKDo2n3k5f4qi2LVkC
# YYhhchhoubh87ubnNC8xd4EwH7s2AY3vJ+P3mvBMMWSN4+v6GYeofs/sjAw2W3rB
# erh4x8kGLkYQyI3oBGDbvHN0+k7Y/qpA8bLOcEaD6dpAoVk62RUJV5lWMJPzyWHM
# 0AjMa+xiQpGsAsDvpPCJEY93AgMBAAGjggM1MIIDMTAOBgNVHQ8BAf8EBAMCB4Aw
# DAYDVR0TAQH/BAIwADAWBgNVHSUBAf8EDDAKBggrBgEFBQcDCDCCAb8GA1UdIASC
# AbYwggGyMIIBoQYJYIZIAYb9bAcBMIIBkjAoBggrBgEFBQcCARYcaHR0cHM6Ly93
# d3cuZGlnaWNlcnQuY29tL0NQUzCCAWQGCCsGAQUFBwICMIIBVh6CAVIAQQBuAHkA
# IAB1AHMAZQAgAG8AZgAgAHQAaABpAHMAIABDAGUAcgB0AGkAZgBpAGMAYQB0AGUA
# IABjAG8AbgBzAHQAaQB0AHUAdABlAHMAIABhAGMAYwBlAHAAdABhAG4AYwBlACAA
# bwBmACAAdABoAGUAIABEAGkAZwBpAEMAZQByAHQAIABDAFAALwBDAFAAUwAgAGEA
# bgBkACAAdABoAGUAIABSAGUAbAB5AGkAbgBnACAAUABhAHIAdAB5ACAAQQBnAHIA
# ZQBlAG0AZQBuAHQAIAB3AGgAaQBjAGgAIABsAGkAbQBpAHQAIABsAGkAYQBiAGkA
# bABpAHQAeQAgAGEAbgBkACAAYQByAGUAIABpAG4AYwBvAHIAcABvAHIAYQB0AGUA
# ZAAgAGgAZQByAGUAaQBuACAAYgB5ACAAcgBlAGYAZQByAGUAbgBjAGUALjALBglg
# hkgBhv1sAxUwHwYDVR0jBBgwFoAUFQASKxOYspkH7R7for5XDStnAs0wHQYDVR0O
# BBYEFGFaTSS2STKdSip5GoNL9B6Jwcp9MH0GA1UdHwR2MHQwOKA2oDSGMmh0dHA6
# Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJRENBLTEuY3JsMDig
# NqA0hjJodHRwOi8vY3JsNC5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURD
# QS0xLmNybDB3BggrBgEFBQcBAQRrMGkwJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3Nw
# LmRpZ2ljZXJ0LmNvbTBBBggrBgEFBQcwAoY1aHR0cDovL2NhY2VydHMuZGlnaWNl
# cnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEQ0EtMS5jcnQwDQYJKoZIhvcNAQEFBQAD
# ggEBAJ0lfhszTbImgVybhs4jIA+Ah+WI//+x1GosMe06FxlxF82pG7xaFjkAneNs
# hORaQPveBgGMN/qbsZ0kfv4gpFetW7easGAm6mlXIV00Lx9xsIOUGQVrNZAQoHuX
# x/Y/5+IRQaa9YtnwJz04HShvOlIJ8OxwYtNiS7Dgc6aSwNOOMdgv420XEwbu5AO2
# FKvzj0OncZ0h3RTKFV2SQdr5D4HRmXQNJsQOfxu19aDxxncGKBXp2JPlVRbwuwqr
# HNtcSCdmyKOLChzlldquxC5ZoGHd2vNtomHpigtt7BIYvfdVVEADkitrwlHCCkiv
# sNRu4PQUCjob4489yq9qjXvc2EQwggZ9MIIEZaADAgECAgMCx70wDQYJKoZIhvcN
# AQELBQAwVDEUMBIGA1UEChMLQ0FjZXJ0IEluYy4xHjAcBgNVBAsTFWh0dHA6Ly93
# d3cuQ0FjZXJ0Lm9yZzEcMBoGA1UEAxMTQ0FjZXJ0IENsYXNzIDMgUm9vdDAeFw0x
# ODA4MDQxMDU2MzBaFw0yMDA4MDMxMDU2MzBaMD4xGDAWBgNVBAMTD0NocmlzdG9m
# IFJvdGhlbjEiMCAGCSqGSIb3DQEJARYTY2hyaXN0b2ZAcm90aGVuLmNvbTCCAiIw
# DQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAOnbQY/kJcdGAbF68gxyPJj47zDk
# mQqXjOZS3iPfIkvKXEs+F88Y55g26x57ZkbIDPVxf44ZuoCKVz8qfyU6ZFffNaEA
# dEqpOr2UQ6qkowy0Yu1zIXRtw6rAUeA4yS9akP7QezA9HtcFgciIHJSvM2espm9p
# n8FfMKBkw5PA2hLFZ4HZVu/6nsSoJWsgWj6+HmN6SbhHfSDriIN2bEkDvywe93zM
# 0PzJiXzNiDUm0ZPwS7xsRiG0/EZ3O+FY74nHRdwSDtSBRz2l228/wNda8azyliE3
# on/NluDlQRh+MBAHnHRksTVWowFs/0pki/BlKpFy2FocV3X8W8drhWMYY2YMx/25
# aD2gvVj1YILgg9YioBaWTMMdW1SDRdsVL0rT12H/4bTR+fjCe/Kwn/FAKn8IEat9
# t125AhpNCeITdBISuXnyKII0zZKSSKorTfh/wNRGDLvTRD5qssOT0ZrKwX+KA/0A
# Kw9UwAu6cgPokriEhIGWNypuIW5mVDD8TmoDb/krIuLzTZ7UnxI/gAeReiPYggir
# m8cfje0s+2+ayeQhMiJV6zn+T915eLI/bSkuYRRevz/+yT3GFszA7rL2ptLJ5VOW
# dW8hxBYER010eniHP+0nn+IFXSnF8vySIEpAEuzVSlxuWR+DMDox8CgrprBYhjQE
# 1UbwLVB81NYfliFbAgMBAAGjggFsMIIBaDAMBgNVHRMBAf8EAjAAMFYGCWCGSAGG
# +EIBDQRJFkdUbyBnZXQgeW91ciBvd24gY2VydGlmaWNhdGUgZm9yIEZSRUUgaGVh
# ZCBvdmVyIHRvIGh0dHA6Ly93d3cuQ0FjZXJ0Lm9yZzAOBgNVHQ8BAf8EBAMCA6gw
# YgYDVR0lBFswWQYIKwYBBQUHAwQGCCsGAQUFBwMCBggrBgEFBQcDAwYKKwYBBAGC
# NwIBFQYKKwYBBAGCNwIBFgYKKwYBBAGCNwoDBAYKKwYBBAGCNwoDAwYJYIZIAYb4
# QgQBMDIGCCsGAQUFBwEBBCYwJDAiBggrBgEFBQcwAYYWaHR0cDovL29jc3AuY2Fj
# ZXJ0Lm9yZzA4BgNVHR8EMTAvMC2gK6AphidodHRwOi8vY3JsLmNhY2VydC5vcmcv
# Y2xhc3MzLXJldm9rZS5jcmwwHgYDVR0RBBcwFYETY2hyaXN0b2ZAcm90aGVuLmNv
# bTANBgkqhkiG9w0BAQsFAAOCAgEAMDgFhF/Qu0ECp0B3AULRE+CNqE7dAVf8Dcyf
# i6Xr2s4ZkZNfm7qOrCwHQ2YDA7XiMltu6JyxAAQa7dmUi8+sQGcNC7hq0c/B8hQE
# /fusQtHswZvSQop7/o8UrGqteuuEEIluV+wpBpcFG00xB9dAo9jQVlE8+ilOUNv1
# ptw4yIlCNfseL88vL9Mn80u+hIJZn+ICJD8h+NbvrRVvXISe2VxCLjK5RxMNW5GO
# FZHa5xnb0QnKpl3GM53K69wqah9E2Exw0x3UL44T3fZJmDiyp6AuEtvuorhzL3tF
# uN+Jk8lMGjz5cVegkqf91PBII/t3yYeuvZDFBQbDNz2AoG9tn1bVxd45xm9IdncW
# 5t+D5zDuuATTBcyz+1ED4/LHolVdmkJsd7Oe1ZTzQFEQ9tQjnXKiNWyf8xZROOgq
# bfx4C55GM06zos/PjJkHTZYSUt3wXR0IlGCOAD5eBYuIMYhibaaknFzoOClC54fd
# f6y/YFFao5WJ4cWoW5iR5EFDfKxajDkzoGL+GBlg2j8vsWPNUAnGAl8vvZtYRE9K
# uCGeCVScEESbLq5YYX8P6F9YyUg4IvmVFM74jlBmi3Q06x/Oc7h5Co6SOQ9NTYRn
# l6fRih8LnrnESth7jcSOU6PmSCV+B7v8AqXqy2ZgzdMvSjL6QDZnCea0y2uhSSjY
# bVtxoQwwggbNMIIFtaADAgECAhAG/fkDlgOt6gAK6z8nu7obMA0GCSqGSIb3DQEB
# BQUAMGUxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNV
# BAsTEHd3dy5kaWdpY2VydC5jb20xJDAiBgNVBAMTG0RpZ2lDZXJ0IEFzc3VyZWQg
# SUQgUm9vdCBDQTAeFw0wNjExMTAwMDAwMDBaFw0yMTExMTAwMDAwMDBaMGIxCzAJ
# BgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5k
# aWdpY2VydC5jb20xITAfBgNVBAMTGERpZ2lDZXJ0IEFzc3VyZWQgSUQgQ0EtMTCC
# ASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAOiCLZn5ysJClaWAc0Bw0p5W
# VFypxNJBBo/JM/xNRZFcgZ/tLJz4FlnfnrUkFcKYubR3SdyJxArar8tea+2tsHEx
# 6886QAxGTZPsi3o2CAOrDDT+GEmC/sfHMUiAfB6iD5IOUMnGh+s2P9gww/+m9/ui
# zW9zI/6sVgWQ8DIhFonGcIj5BZd9o8dD3QLoOz3tsUGj7T++25VIxO4es/K8DCuZ
# 0MZdEkKB4YNugnM/JksUkK5ZZgrEjb7SzgaurYRvSISbT0C58Uzyr5j79s5AXVz2
# qPEvr+yJIvJrGGWxwXOt1/HYzx4KdFxCuGh+t9V3CidWfA9ipD8yFGCV/QcEogkC
# AwEAAaOCA3owggN2MA4GA1UdDwEB/wQEAwIBhjA7BgNVHSUENDAyBggrBgEFBQcD
# AQYIKwYBBQUHAwIGCCsGAQUFBwMDBggrBgEFBQcDBAYIKwYBBQUHAwgwggHSBgNV
# HSAEggHJMIIBxTCCAbQGCmCGSAGG/WwAAQQwggGkMDoGCCsGAQUFBwIBFi5odHRw
# Oi8vd3d3LmRpZ2ljZXJ0LmNvbS9zc2wtY3BzLXJlcG9zaXRvcnkuaHRtMIIBZAYI
# KwYBBQUHAgIwggFWHoIBUgBBAG4AeQAgAHUAcwBlACAAbwBmACAAdABoAGkAcwAg
# AEMAZQByAHQAaQBmAGkAYwBhAHQAZQAgAGMAbwBuAHMAdABpAHQAdQB0AGUAcwAg
# AGEAYwBjAGUAcAB0AGEAbgBjAGUAIABvAGYAIAB0AGgAZQAgAEQAaQBnAGkAQwBl
# AHIAdAAgAEMAUAAvAEMAUABTACAAYQBuAGQAIAB0AGgAZQAgAFIAZQBsAHkAaQBu
# AGcAIABQAGEAcgB0AHkAIABBAGcAcgBlAGUAbQBlAG4AdAAgAHcAaABpAGMAaAAg
# AGwAaQBtAGkAdAAgAGwAaQBhAGIAaQBsAGkAdAB5ACAAYQBuAGQAIABhAHIAZQAg
# AGkAbgBjAG8AcgBwAG8AcgBhAHQAZQBkACAAaABlAHIAZQBpAG4AIABiAHkAIABy
# AGUAZgBlAHIAZQBuAGMAZQAuMAsGCWCGSAGG/WwDFTASBgNVHRMBAf8ECDAGAQH/
# AgEAMHkGCCsGAQUFBwEBBG0wazAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGln
# aWNlcnQuY29tMEMGCCsGAQUFBzAChjdodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5j
# b20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3J0MIGBBgNVHR8EejB4MDqgOKA2
# hjRodHRwOi8vY3JsMy5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290
# Q0EuY3JsMDqgOKA2hjRodHRwOi8vY3JsNC5kaWdpY2VydC5jb20vRGlnaUNlcnRB
# c3N1cmVkSURSb290Q0EuY3JsMB0GA1UdDgQWBBQVABIrE5iymQftHt+ivlcNK2cC
# zTAfBgNVHSMEGDAWgBRF66Kv9JLLgjEtUYunpyGd823IDzANBgkqhkiG9w0BAQUF
# AAOCAQEARlA+ybcoJKc4HbZbKa9Sz1LpMUerVlx71Q0LQbPv7HUfdDjyslxhopyV
# w1Dkgrkj0bo6hnKtOHisdV0XFzRyR4WUVtHruzaEd8wkpfMEGVWp5+Pnq2LN+4st
# kMLA0rWUvV5PsQXSDj0aqRRbpoYxYqioM+SbOafE9c4deHaUJXPkKqvPnHZL7V/C
# SxbkS3BMAIke/MV5vEwSV/5f4R68Al2o/vsHOE8Nxl2RuQ9nRc3Wg+3nkg2NsWmM
# T/tZ4CMP0qquAHzunEIOz5HXJ7cW7g/DvXwKoO4sCFWFIrjrGBpN/CohrUkxg0eV
# d3HcsRtLSxwQnHcUwZ1PL1qVCCkQJjCCB1kwggVBoAMCAQICAwpBijANBgkqhkiG
# 9w0BAQsFADB5MRAwDgYDVQQKEwdSb290IENBMR4wHAYDVQQLExVodHRwOi8vd3d3
# LmNhY2VydC5vcmcxIjAgBgNVBAMTGUNBIENlcnQgU2lnbmluZyBBdXRob3JpdHkx
# ITAfBgkqhkiG9w0BCQEWEnN1cHBvcnRAY2FjZXJ0Lm9yZzAeFw0xMTA1MjMxNzQ4
# MDJaFw0yMTA1MjAxNzQ4MDJaMFQxFDASBgNVBAoTC0NBY2VydCBJbmMuMR4wHAYD
# VQQLExVodHRwOi8vd3d3LkNBY2VydC5vcmcxHDAaBgNVBAMTE0NBY2VydCBDbGFz
# cyAzIFJvb3QwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQCrSTURSHzS
# Jn5TlM9Dqd0o10Iqi/OHeBlYfA+e2ol94fvrcpANdKGWZKufoCSZc9riVXbHF3v1
# BKxGuMO+f2SNEGwk82GcwPKQ+lHm9WkBY8MPVuJKQs/iRIwlKKjFeQl9RrmK8+nz
# NCkIReQcn8uUBByBqBSzmGXEQ+xOgo0J0b2qW42S0OzekMV/CsLj6+YxWl50Ppcz
# WejDAz1gM7/30W9HxM3uYoNSbi4ImqTZFRiRpoWSR7CuSOtttyHshRpocjWr//AQ
# XcD0lKdq1TuSfkyQBX6TwSyLpI5idBVxbgtxA+qvFTia1NIFcm+M+SvrWnIl+TlG
# 43IbPgTDZCciECqKT1inA62+tC4T7V2qSNfVfdQqe1z6RgRQ5MwOQluM7dvyz/yW
# k+DbETZUYjQ4jwxgmzuXVjit89Jbi6Bb6k6WuHzX1aCGcEDTkSm3ojyt9Yy7zxqS
# iuQ0e8DYbF/pCsLDpyCaWt8sXVJcukfVm+8kKHA4IC/VfynAskEDaJLM4JzMl0tF
# 7zoQCqtwOpiVcK01seqFK6QcgCExqa5geoAmSAC4AcCTY1UikTxW56/bOiXzjzFU
# 6iaLgVn5odFTEcV7nQP2dBHgbbEsPyyGkZlxmqZ3izRg0RS0LKydr4wQ05/Eavhv
# E/xzWfdmQnQeiuP43NJvmJzLR5iVQAX76QIDAQABo4ICDTCCAgkwHQYDVR0OBBYE
# FHWocWBMiBPweNmJd7VtxYnfvLF6MIGjBgNVHSMEgZswgZiAFBa1MhvUx/Pg5o7z
# vdKwOu6yORjRoX2kezB5MRAwDgYDVQQKEwdSb290IENBMR4wHAYDVQQLExVodHRw
# Oi8vd3d3LmNhY2VydC5vcmcxIjAgBgNVBAMTGUNBIENlcnQgU2lnbmluZyBBdXRo
# b3JpdHkxITAfBgkqhkiG9w0BCQEWEnN1cHBvcnRAY2FjZXJ0Lm9yZ4IBADAPBgNV
# HRMBAf8EBTADAQH/MF0GCCsGAQUFBwEBBFEwTzAjBggrBgEFBQcwAYYXaHR0cDov
# L29jc3AuQ0FjZXJ0Lm9yZy8wKAYIKwYBBQUHMAKGHGh0dHA6Ly93d3cuQ0FjZXJ0
# Lm9yZy9jYS5jcnQwSgYDVR0gBEMwQTA/BggrBgEEAYGQSjAzMDEGCCsGAQUFBwIB
# FiVodHRwOi8vd3d3LkNBY2VydC5vcmcvaW5kZXgucGhwP2lkPTEwMDQGCWCGSAGG
# +EIBCAQnFiVodHRwOi8vd3d3LkNBY2VydC5vcmcvaW5kZXgucGhwP2lkPTEwMFAG
# CWCGSAGG+EIBDQRDFkFUbyBnZXQgeW91ciBvd24gY2VydGlmaWNhdGUgZm9yIEZS
# RUUsIGdvIHRvIGh0dHA6Ly93d3cuQ0FjZXJ0Lm9yZzANBgkqhkiG9w0BAQsFAAOC
# AgEAKSiFrkSpua+keRPwqKMrl2DzXO7jL8H24magEa42Nzp2FQRT6kL1+erAFdim
# gtnkYa5yCylckEPoQbLhd9sCE0R4R1WvWPzMmPZFudEg+NghB/5tqnPUs8YH6QmF
# zDvytr4sHCXVcYw5tS7qvhiBurCTuA/j5tcmjDFacgOEUuam9TMiRQrICw2KuDZv
# kAmhq73X1U4ucaLUrvqnVCvrNY1at1SIL+50n+1IFsoNSNCU06ykovYk35LjvetD
# QJFuHBiOVrSCEvOpk5/UvJytnHXuWpcbled0LRwPsCyXn/upMzl65wM6ko4i9owN
# 5Nl+DXYY9wH575aWolVzwDxxtB0aVkO3wwqNcvziEAkLQc6MlKD5A/1xc0uKVzPl
# jnR+FQEA5sxKHOd/lRktxaUMi7u17YWzXNPfuLnyyscNARSscFjFjI0z1J1moxpQ
# lSP8SOAGQxLZzaeGOS82cqOAEOTh89HLWxrA5ICafBNzBk/bo2skCrqzHLxKeLvl
# 43U4pUinoh6vdtRe9ziGVlqJztbDp3myUqDG8YW0JYzyP5azENmNbFc7n2+GOhiC
# IjbIsJE42yqhk6qEP/UnZa5z1cjV03fqS53HQbvHwOOgP+R9pI1z5hJL36Fzc3M6
# gOjVy44vy+oTp9ZBi6z6PInXJPVOtOBhkrfzN5jEvpajt4oxggUPMIIFCwIBATBb
# MFQxFDASBgNVBAoTC0NBY2VydCBJbmMuMR4wHAYDVQQLExVodHRwOi8vd3d3LkNB
# Y2VydC5vcmcxHDAaBgNVBAMTE0NBY2VydCBDbGFzcyAzIFJvb3QCAwLHvTAJBgUr
# DgMCGgUAoHgwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMx
# DAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFjAjBgkq
# hkiG9w0BCQQxFgQUTXe+h3wpeXiNT+HxgV8Itad2+YYwDQYJKoZIhvcNAQEBBQAE
# ggIAIJa7UsUytGgcZ9LfWcCjpsyiCtfHUkAqjcGXqt5bvhWMzQ42FjGhg4tTrDQp
# LaDEHMBL9TkP0csnmcxleCKw+Ow+YeIDQXgYvP3AYGVoz+7kK9qzlfI01Y4ZNFbu
# 1JPRX78ikqD59WP/cIyssSQ/pKcUCagpPu+26f5aJMaUsveMSW4dVAGOHHX2PAvS
# 2dvPJIOhtKqcUUReyQpkHPkngaZlORkwfW391uXcKo0nKXLgDbadUWnFhmLAy67N
# pQ6SYNo4w066jM+sV73/FOinOJahDKUS+/PLNKnKu6QQnvG1MuTJWkxWY1DQfvGJ
# /xj1DD7wfcS5PQ43dXaDGXwA0/GdmBYMcXjqb0s71ggtA3HDag3uwfS0SMUa53s3
# rLxCllZ3mJHfbQOYV2Tl4skADUdCdV9Hf8ur7j9HF5kLMnT4cDJVXhjKSaCPRgET
# I4ypTklo/JwQHyl6GDn89GeruzVhTkhv+vQGxuJVdtvMN9j1pZZ7fjY0eZkbl2Gd
# UbPsUYY3HuFb00S3iT8depki5WUihJCpC76VKPCrrHma6mPBu57LQyWOhMq88Cco
# vJR59oUdruKFa3lrDFZ8csTdDQ8mab4RzFF3TppnuzF4smUnh3fkHXVVN/4cbbGC
# AtB2REiZk5DlQFcARzL0LNG25xRqIrQ67jwEPhEK9eJ+/sqhggIPMIICCwYJKoZI
# hvcNAQkGMYIB/DCCAfgCAQEwdjBiMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGln
# aUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMSEwHwYDVQQDExhE
# aWdpQ2VydCBBc3N1cmVkIElEIENBLTECEAMBmgI6/1ixa9bV6uYX8GYwCQYFKw4D
# AhoFAKBdMBgGCSqGSIb3DQEJAzELBgkqhkiG9w0BBwEwHAYJKoZIhvcNAQkFMQ8X
# DTE4MDkwOTE4MTEwNFowIwYJKoZIhvcNAQkEMRYEFNdPG5/dxqtsPOeXYSL4iwvS
# Av6aMA0GCSqGSIb3DQEBAQUABIIBACoBsm/DXGeYMle31mq2cW6NW2Iu8/6su9d1
# XYDcMSTn3efWjDmbqgmhxanNgTPPkFcpO/UuWdF5T3KqXDnVoBot5XIUIJ0SNTlt
# 51MaS4EMrHGmnSsFg+glt5VuznCHuCt3vdrbGfSgSOXrkqDUnrqg/6m4wZWLJkFl
# Qe1sFyd8ZTFgvbw3FzgWBdR0BlhkyaxSIle0khvSW5S2B2JvNPlE09V5X1NxzQwL
# 1O2hUSd4f4OE1M/8fQFslkh4p0oJN0Vg4aC1VHClpnkgB95rCiJ7Vx6upKZXa3Fp
# ciSbeFC/rQIkTxSHHS4J2NaAHErrOWGC6fBil89/jnN1XvpSRiA=
# SIG # End signature block
