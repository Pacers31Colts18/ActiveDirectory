﻿# Script to copy group memberships from a source user to a target user.

Param ($Source, $Target)
If ($Source -ne $Null -and $Target -eq $Null)
{
    $Target = Read-Host "Enter logon name of target user"
}
If ($Source -eq $Null)
{
    $Source = Read-Host "Enter logon name of source user"
    $Target = Read-Host "Enter logon name of target user"
}

# Retrieve group memberships.
$SourceUser = Get-ADUser $Source -Properties memberOf
$TargetUser = Get-ADUser $Target -Properties memberOf

# Hash table of source user groups.
$List = @{}

#Enumerate direct group memberships of source user.
ForEach ($SourceDN In $SourceUser.memberOf)
{
    # Add this group to hash table.
    $List.Add($SourceDN, $True)
    # Bind to group object.
    $SourceGroup = [ADSI]"LDAP://$SourceDN"
    # Check if target user is already a member of this group.
            If ($SourceDN.tolower().StartsWith("cn=iu-iusm-") -or
            $SourceDN.tolower().StartsWith("cn=in-psyc-") -or
            $SourceDN.tolower().StartsWith("cn=in-dent-") -or
            $SourceDN.tolower().StartsWith("cn=iu-iusd-") -or
            $SourceDN.tolower().StartsWith("cn=deansoffice") -or
            $SourceDN.tolower().StartsWith("cn=caits deans office") -or
            $SourceDN.tolower().StartsWith("cn=istm clients") -or
            $SourceDN.tolower().StartsWith("cn=caits clients") -or 
            $SourceDN.tolower().StartsWith("cn=iu-regi-") -or
            $SourceDN.tolower().StartsWith("cn=istm deans office") -or
            $SourceDN.tolower().StartsWith("cn=in-regi-") -or
            $SourceDN.tolower().StartsWith("cn=bl-opt") -or
            $SourceDN.tolower().StartsWith("cn=iu-opt") -or
            $SourceDN.tolower().StartsWith("cn=istm staff"))
    {
        # Add the target user to this group.
        Add-ADGroupMember -Identity $SourceDN -Members $Target
    }
}

# Enumerate direct group memberships of target user.
ForEach ($TargetDN In $TargetUser.memberOf)
{
    # Check if source user is a member of this group.
    If ($List.ContainsKey($TargetDN) -eq $False)
    {
        # Source user not a member of this group.
        # Remove target user from this group.
        Remove-ADGroupMember $TargetDN $Target
    }
}
# SIG # Begin signature block
# MIIOQQYJKoZIhvcNAQcCoIIOMjCCDi4CAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU/25GvzBN7uvFiW+nMS+LMjd4
# c2Wgggt5MIIFhjCCBG6gAwIBAgIQNa8HWQ8ES6XAd67RtM/zIDANBgkqhkiG9w0B
# AQsFADB8MQswCQYDVQQGEwJVUzELMAkGA1UECBMCTUkxEjAQBgNVBAcTCUFubiBB
# cmJvcjESMBAGA1UEChMJSW50ZXJuZXQyMREwDwYDVQQLEwhJbkNvbW1vbjElMCMG
# A1UEAxMcSW5Db21tb24gUlNBIENvZGUgU2lnbmluZyBDQTAeFw0xNjA2MDEwMDAw
# MDBaFw0xOTA2MDEyMzU5NTlaMIGmMQswCQYDVQQGEwJVUzEOMAwGA1UEEQwFNDc0
# MDUxCzAJBgNVBAgMAklOMRQwEgYDVQQHDAtCbG9vbWluZ3RvbjEXMBUGA1UECQwO
# OTAwIEUuIDd0aCBTdC4xETAPBgNVBAkMCElNVSBNMDA1MRswGQYDVQQKDBJJbmRp
# YW5hIFVuaXZlcnNpdHkxGzAZBgNVBAMMEkluZGlhbmEgVW5pdmVyc2l0eTCCASIw
# DQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBALI+xEe50vYWngAMPC5Qowa99cHo
# MHfqzPL93CJT1nw2wxKhu0DaG/wIAZDT2z0sT0n+RgkdDAZgCSN2hptZLTm7csjf
# fD3qDRtsRZv2kQFpEIjjMXnb0WqcfA4pMKYjg18MAOc4fNyAJzJ6MY0EPu8vjTfP
# IXOlk7TCxwtEG3rrfHQbC3CF8BB1B04504BsGLm/irA79KKB14X8waj6/LBdOkzL
# 4kLG2U0LQVoCznlapMgLbKNIiTWsHYCpGGG/qUEvQ+TkfwJM9SbiMovxa7DJ6YFL
# 6SeVvFpEkC5DAuf5L6NNqzcprVKe31D3Uwt3TB0snAyT2wTgqJpTmmMdDjkCAwEA
# AaOCAdcwggHTMB8GA1UdIwQYMBaAFK41Ixf//wY9nFDgjCRlMx5wEIiiMB0GA1Ud
# DgQWBBRDAwrnQ7Y98uWbLGjyzTVZd8/+SjAOBgNVHQ8BAf8EBAMCB4AwDAYDVR0T
# AQH/BAIwADATBgNVHSUEDDAKBggrBgEFBQcDAzARBglghkgBhvhCAQEEBAMCBBAw
# ZgYDVR0gBF8wXTBbBgwrBgEEAa4jAQQDAgEwSzBJBggrBgEFBQcCARY9aHR0cHM6
# Ly93d3cuaW5jb21tb24ub3JnL2NlcnQvcmVwb3NpdG9yeS9jcHNfY29kZV9zaWdu
# aW5nLnBkZjBJBgNVHR8EQjBAMD6gPKA6hjhodHRwOi8vY3JsLmluY29tbW9uLXJz
# YS5vcmcvSW5Db21tb25SU0FDb2RlU2lnbmluZ0NBLmNybDB+BggrBgEFBQcBAQRy
# MHAwRAYIKwYBBQUHMAKGOGh0dHA6Ly9jcnQuaW5jb21tb24tcnNhLm9yZy9JbkNv
# bW1vblJTQUNvZGVTaWduaW5nQ0EuY3J0MCgGCCsGAQUFBzABhhxodHRwOi8vb2Nz
# cC5pbmNvbW1vbi1yc2Eub3JnMBgGA1UdEQQRMA+BDWl1c21zaUBpdS5lZHUwDQYJ
# KoZIhvcNAQELBQADggEBABhb2UjZfl13aRAohq2cgQfFeR/YNyj3hSny3yEDj2ea
# 848d+vosa4sI1aPsBoTe2ImdzG4rGj9U2+o+73K7whHT7vc5vKTPrYrD1LYmdgU3
# Csho8AW8ird6z00F440Xe2pQWCU2uedlKRIznHHHbcrl2O9W5KNxp2x8IQubAJqm
# CUmKsMIAmGxIfICR/6zwpMUNUK8bFmwvkfnFJ6eJOL51So4jy3MVIx7CgcBryTPU
# pOQz1FVLMEwpasMcf4C8B4/zXwjc/GfO5gN8f1/djof2opLI2HEUsUmr4+nANaOC
# sxW1uKFW76y4kfCoJJIDu2OWfbditfqSeyBGMtnq/WswggXrMIID06ADAgECAhBl
# 4eLj1d5QRYXzJiSABeLUMA0GCSqGSIb3DQEBDQUAMIGIMQswCQYDVQQGEwJVUzET
# MBEGA1UECBMKTmV3IEplcnNleTEUMBIGA1UEBxMLSmVyc2V5IENpdHkxHjAcBgNV
# BAoTFVRoZSBVU0VSVFJVU1QgTmV0d29yazEuMCwGA1UEAxMlVVNFUlRydXN0IFJT
# QSBDZXJ0aWZpY2F0aW9uIEF1dGhvcml0eTAeFw0xNDA5MTkwMDAwMDBaFw0yNDA5
# MTgyMzU5NTlaMHwxCzAJBgNVBAYTAlVTMQswCQYDVQQIEwJNSTESMBAGA1UEBxMJ
# QW5uIEFyYm9yMRIwEAYDVQQKEwlJbnRlcm5ldDIxETAPBgNVBAsTCEluQ29tbW9u
# MSUwIwYDVQQDExxJbkNvbW1vbiBSU0EgQ29kZSBTaWduaW5nIENBMIIBIjANBgkq
# hkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAwKAvix56u2p1rPg+3KO6OSLK86N25L99
# MCfmutOYMlYjXAaGlw2A6O2igTXrC/Zefqk+aHP9ndRnec6q6mi3GdscdjpZh11e
# mcehsriphHMMzKuHRhxqx+85Jb6n3dosNXA2HSIuIDvd4xwOPzSf5X3+VYBbBnyC
# V4RV8zj78gw2qblessWBRyN9EoGgwAEoPgP5OJejrQLyAmj91QGr9dVRTVDTFyJG
# 5XMY4DrkN3dRyJ59UopPgNwmucBMyvxR+hAJEXpXKnPE4CEqbMJUvRw+g/hbqSzx
# +tt4z9mJmm2j/w2nP35MViPWCb7hpR2LB8W/499Yqu+kr4LLBfgKCQIDAQABo4IB
# WjCCAVYwHwYDVR0jBBgwFoAUU3m/WqorSs9UgOHYm8Cd8rIDZsswHQYDVR0OBBYE
# FK41Ixf//wY9nFDgjCRlMx5wEIiiMA4GA1UdDwEB/wQEAwIBhjASBgNVHRMBAf8E
# CDAGAQH/AgEAMBMGA1UdJQQMMAoGCCsGAQUFBwMDMBEGA1UdIAQKMAgwBgYEVR0g
# ADBQBgNVHR8ESTBHMEWgQ6BBhj9odHRwOi8vY3JsLnVzZXJ0cnVzdC5jb20vVVNF
# UlRydXN0UlNBQ2VydGlmaWNhdGlvbkF1dGhvcml0eS5jcmwwdgYIKwYBBQUHAQEE
# ajBoMD8GCCsGAQUFBzAChjNodHRwOi8vY3J0LnVzZXJ0cnVzdC5jb20vVVNFUlRy
# dXN0UlNBQWRkVHJ1c3RDQS5jcnQwJQYIKwYBBQUHMAGGGWh0dHA6Ly9vY3NwLnVz
# ZXJ0cnVzdC5jb20wDQYJKoZIhvcNAQENBQADggIBAEYstn9qTiVmvZxqpqrQnr0P
# rk41/PA4J8HHnQTJgjTbhuET98GWjTBEE9I17Xn3V1yTphJXbat5l8EmZN/JXMvD
# NqJtkyOh26owAmvquMCF1pKiQWyuDDllxR9MECp6xF4wnH1Mcs4WeLOrQPy+C5kW
# E5gg/7K6c9G1VNwLkl/po9ORPljxKKeFhPg9+Ti3JzHIxW7LdyljffccWiuNFR51
# /BJHAZIqUDw3LsrdYWzgg4x06tgMvOEf0nITelpFTxqVvMtJhnOfZbpdXZQ5o1Ts
# pxfTEVOQAsp05HUNCXyhznlVLr0JaNkM7edgk59zmdTbSGdMq8Ztuu6VyrivOlMS
# PWmay5MjvwTzuNorbwBv0DL+7cyZBp7NYZou+DoGd1lFZN0jU5IsQKgm3+00pnnJ
# 67crdFwfz/8bq3MhTiKOWEb04FT3OZVp+jzvaChHWLQ8gbCORgClaZq1H3aqI7Je
# RkWEEEp6Tv4WAVsr/i7LoXU72gOb8CAzPFqwI4Excdrxp0I4OXbECHlDqU4sTInq
# wlMwofmxeO4u94196qIqJQl+8Sykl06VktqMux84Iw3ZQLH08J8LaJ+WDUycc4Oj
# Y61I7FGxCDkbSQf3npXeRFm0IBn8GiW+TRDk6J2XJFLWEtVZmhboFlBLoUlqHUCK
# u0QOhU/+AEOqnY98j2zRMYICMjCCAi4CAQEwgZAwfDELMAkGA1UEBhMCVVMxCzAJ
# BgNVBAgTAk1JMRIwEAYDVQQHEwlBbm4gQXJib3IxEjAQBgNVBAoTCUludGVybmV0
# MjERMA8GA1UECxMISW5Db21tb24xJTAjBgNVBAMTHEluQ29tbW9uIFJTQSBDb2Rl
# IFNpZ25pbmcgQ0ECEDWvB1kPBEulwHeu0bTP8yAwCQYFKw4DAhoFAKB4MBgGCisG
# AQQBgjcCAQwxCjAIoAKAAKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQw
# HAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFP7w
# 15QFOmdo16fcoBHuVbOwWbzBMA0GCSqGSIb3DQEBAQUABIIBAJY30mTBMvhVpIXU
# tDJYMB49U8slOrEeUDHgo2iS+FEqrm4ROrssDRQtGZn7GzWstBugv7PUiPbABZYI
# uYDamp8JYZl82L2/MVYIgu9QPOQVJ+UiQKx7Tb+Aux2168/zDUO8GfW/eg+fp6qH
# ZOMx3e+1x+dYsFTv80L+wpxaOQBhBzLpfNx1IQ52npd8rYitXm015DLpxnU0oP8B
# 2HOIyHcoZ7l4v4bbU1E8N+JU6t1rCGb6K4Yfd7urXUVL4UjJrBdvCFEeHkF6WNyx
# l3vPELqPLlfVi5XH+8ACiwP5tlzPu7W4gD2XrRLLthyuIyh2sBrwPlDEXwUY1cfs
# yRj30mk=
# SIG # End signature block
