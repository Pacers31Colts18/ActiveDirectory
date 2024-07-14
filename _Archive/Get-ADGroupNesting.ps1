﻿##########Copy the below script into a new file called Get-ADGroupNesting.ps1

Param ( 
    [Parameter(Mandatory=$true, 
        Position=0, 
        ValueFromPipeline=$true, 
        HelpMessage="DN or ObjectGUID of the AD Group." 
    )] 
    [string]$groupIdentity, 
    [switch]$showTree 
    )

$global:numberOfRecursiveGroupMemberships = 0 
$lastGroupAtALevelFlags = @()

function Get-GroupNesting ([string] $identity, [int] $level, [hashtable] $groupsVisitedBeforeThisOne, [bool] $lastGroupOfTheLevel) 
{ 
    $group = $null 
    $group = Get-ADGroup -Identity $identity -Properties "memberOf"    
    if($lastGroupAtALevelFlags.Count -le $level) 
    { 
        $lastGroupAtALevelFlags = $lastGroupAtALevelFlags + 0 
    } 
    if($group -ne $null) 
    { 
        if($showTree) 
        { 
            for($i = 0; $i -lt $level - 1; $i++) 
            { 
                if($lastGroupAtALevelFlags[$i] -ne 0) 
                { 
                    Write-Host -ForegroundColor Yellow -NoNewline "  " 
                } 
                else 
                { 
                    Write-Host -ForegroundColor Yellow -NoNewline "│ " 
                } 
            } 
            if($level -ne 0) 
            { 
                if($lastGroupOfTheLevel) 
                { 
                    Write-Host -ForegroundColor Yellow -NoNewline "└─" 
                } 
                else 
                { 
                    Write-Host -ForegroundColor Yellow -NoNewline "├─" 
                } 
            } 
            Write-Host -ForegroundColor Yellow $group.Name 
        } 
        $groupsVisitedBeforeThisOne.Add($group.distinguishedName,$null) 
        $global:numberOfRecursiveGroupMemberships ++ 
        $groupMemberShipCount = $group.memberOf.Count 
        if ($groupMemberShipCount -gt 0) 
        { 
            $maxMemberGroupLevel = 0 
            $count = 0 
            foreach($groupDN in $group.memberOf) 
            { 
                $count++ 
                $lastGroupOfThisLevel = $false 
                if($count -eq $groupMemberShipCount){$lastGroupOfThisLevel = $true; $lastGroupAtALevelFlags[$level] = 1} 
                if(-not $groupsVisitedBeforeThisOne.Contains($groupDN)) #prevent cyclic dependancies 
                { 
                    $memberGroupLevel = Get-GroupNesting -Identity $groupDN -Level $($level+1) -GroupsVisitedBeforeThisOne $groupsVisitedBeforeThisOne -lastGroupOfTheLevel $lastGroupOfThisLevel 
                    if ($memberGroupLevel -gt $maxMemberGroupLevel){$maxMemberGroupLevel = $memberGroupLevel} 
                } 
            } 
            $level = $maxMemberGroupLevel 
        } 
        else #we've reached the top level group, return it's height 
        { 
            return $level 
        } 
        return $level 
    } 
} 
$global:numberOfRecursiveGroupMemberships = 0 
$groupObj = $null 
$groupObj = Get-ADGroup -Identity $groupIdentity 
if($groupObj) 
{ 
    [int]$maxNestingLevel = Get-GroupNesting -Identity $groupIdentity -Level 0 -GroupsVisitedBeforeThisOne @{} -lastGroupOfTheLevel $false 
    Add-Member -InputObject $groupObj -MemberType NoteProperty  -Name MaxNestingLevel -Value $maxNestingLevel -Force 
    Add-Member -InputObject $groupObj -MemberType NoteProperty  -Name NestedGroupMembershipCount -Value $($global:numberOfRecursiveGroupMemberships - 1) -Force 
    $groupObj 
}
# SIG # Begin signature block
# MIIOJwYJKoZIhvcNAQcCoIIOGDCCDhQCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUAtvl+2mAVS3TAbAgaipzmA6t
# L1+gggtfMIIFbDCCBFSgAwIBAgIQNfbEOOj3ehF5nQxYwH0kXTANBgkqhkiG9w0B
# AQsFADB8MQswCQYDVQQGEwJVUzELMAkGA1UECBMCTUkxEjAQBgNVBAcTCUFubiBB
# cmJvcjESMBAGA1UEChMJSW50ZXJuZXQyMREwDwYDVQQLEwhJbkNvbW1vbjElMCMG
# A1UEAxMcSW5Db21tb24gUlNBIENvZGUgU2lnbmluZyBDQTAeFw0xNTEyMDcwMDAw
# MDBaFw0xODEyMDYyMzU5NTlaMIGmMQswCQYDVQQGEwJVUzEOMAwGA1UEEQwFNDc0
# MDUxCzAJBgNVBAgMAklOMRQwEgYDVQQHDAtCbG9vbWluZ3RvbjEXMBUGA1UECQwO
# OTAwIEUuIDd0aCBTdC4xETAPBgNVBAkMCElNVSBNMDA1MRswGQYDVQQKDBJJbmRp
# YW5hIFVuaXZlcnNpdHkxGzAZBgNVBAMMEkluZGlhbmEgVW5pdmVyc2l0eTCCASIw
# DQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAMGJ2R6TDuU0+RQ54ScsOlJr0U9Z
# lL2R/EYEs8EeXmsGM5t3S1yWSWAPkqeC+Ahqvvgz7MtjLQlbblIQ/TS5ctk5Jl9e
# nREXvWEzBO9FTo3dGpgLPefF9biV2tdOuArOZ/Dp4HFhI8ypvjv1IvKRoBvXHAq0
# 6+e9zRPOdlWjLjQJGrn/sLL8VChrixf3B+pESVPvfQSO8bFz1AHSKnLA6RvfqlWR
# hq79b7D3XQQcwqjwJc6GAv4TJuzMcAK7824EOZE0M64PrcwIgXGVbpyDa+BVULAJ
# 4u+kA2rw6uwVW9m1zXdPWWj0XPIXX6co2aBWNOb7GjocZNmMzo2S1kbkl68CAwEA
# AaOCAb0wggG5MB8GA1UdIwQYMBaAFK41Ixf//wY9nFDgjCRlMx5wEIiiMB0GA1Ud
# DgQWBBTpnG2qdR4N0ABK6aIEVzv5M61eGDAOBgNVHQ8BAf8EBAMCB4AwDAYDVR0T
# AQH/BAIwADATBgNVHSUEDDAKBggrBgEFBQcDAzARBglghkgBhvhCAQEEBAMCBBAw
# ZgYDVR0gBF8wXTBbBgwrBgEEAa4jAQQDAgEwSzBJBggrBgEFBQcCARY9aHR0cHM6
# Ly93d3cuaW5jb21tb24ub3JnL2NlcnQvcmVwb3NpdG9yeS9jcHNfY29kZV9zaWdu
# aW5nLnBkZjBJBgNVHR8EQjBAMD6gPKA6hjhodHRwOi8vY3JsLmluY29tbW9uLXJz
# YS5vcmcvSW5Db21tb25SU0FDb2RlU2lnbmluZ0NBLmNybDB+BggrBgEFBQcBAQRy
# MHAwRAYIKwYBBQUHMAKGOGh0dHA6Ly9jcnQuaW5jb21tb24tcnNhLm9yZy9JbkNv
# bW1vblJTQUNvZGVTaWduaW5nQ0EuY3J0MCgGCCsGAQUFBzABhhxodHRwOi8vb2Nz
# cC5pbmNvbW1vbi1yc2Eub3JnMA0GCSqGSIb3DQEBCwUAA4IBAQAGXlwZzEdbiXoT
# ynbAr/zhFgECzt3rRrAaVo7wUxzvxxB+d1jGXDpsl86tXcLa5a8YEip50CaE2KVH
# 8nIlW+gCkJq3lfUVvGyrNBv8J2x2WlJlZpNyQSCbYWngZvd40P+gb2tx4/vZlAVF
# GoEleWSD6lveNUXULMk3isVvbfzUOme67wZp0o1h2KYQn5zB2+T7UjQJKXgSilV7
# vya5xdvYWXWPgPCBtwh6QRONKHsT7Gq9Ycm4yl+S+CwCl8GE5qAIfRLwMOtiDI98
# OhSt83HDj1gUTRgnpcMweWC9yq2ftJ2zTSp3ZOVht57LW7keaiMFdZvWkZbXwwiM
# t3Z932XYMIIF6zCCA9OgAwIBAgIQZeHi49XeUEWF8yYkgAXi1DANBgkqhkiG9w0B
# AQ0FADCBiDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCk5ldyBKZXJzZXkxFDASBgNV
# BAcTC0plcnNleSBDaXR5MR4wHAYDVQQKExVUaGUgVVNFUlRSVVNUIE5ldHdvcmsx
# LjAsBgNVBAMTJVVTRVJUcnVzdCBSU0EgQ2VydGlmaWNhdGlvbiBBdXRob3JpdHkw
# HhcNMTQwOTE5MDAwMDAwWhcNMjQwOTE4MjM1OTU5WjB8MQswCQYDVQQGEwJVUzEL
# MAkGA1UECBMCTUkxEjAQBgNVBAcTCUFubiBBcmJvcjESMBAGA1UEChMJSW50ZXJu
# ZXQyMREwDwYDVQQLEwhJbkNvbW1vbjElMCMGA1UEAxMcSW5Db21tb24gUlNBIENv
# ZGUgU2lnbmluZyBDQTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAMCg
# L4seertqdaz4PtyjujkiyvOjduS/fTAn5rrTmDJWI1wGhpcNgOjtooE16wv2Xn6p
# Pmhz/Z3UZ3nOqupotxnbHHY6WYddXpnHobK4qYRzDMyrh0YcasfvOSW+p93aLDVw
# Nh0iLiA73eMcDj80n+V9/lWAWwZ8gleEVfM4+/IMNqm5XrLFgUcjfRKBoMABKD4D
# +TiXo60C8gJo/dUBq/XVUU1Q0xciRuVzGOA65Dd3UciefVKKT4DcJrnATMr8UfoQ
# CRF6VypzxOAhKmzCVL0cPoP4W6ks8frbeM/ZiZpto/8Npz9+TFYj1gm+4aUdiwfF
# v+PfWKrvpK+CywX4CgkCAwEAAaOCAVowggFWMB8GA1UdIwQYMBaAFFN5v1qqK0rP
# VIDh2JvAnfKyA2bLMB0GA1UdDgQWBBSuNSMX//8GPZxQ4IwkZTMecBCIojAOBgNV
# HQ8BAf8EBAMCAYYwEgYDVR0TAQH/BAgwBgEB/wIBADATBgNVHSUEDDAKBggrBgEF
# BQcDAzARBgNVHSAECjAIMAYGBFUdIAAwUAYDVR0fBEkwRzBFoEOgQYY/aHR0cDov
# L2NybC51c2VydHJ1c3QuY29tL1VTRVJUcnVzdFJTQUNlcnRpZmljYXRpb25BdXRo
# b3JpdHkuY3JsMHYGCCsGAQUFBwEBBGowaDA/BggrBgEFBQcwAoYzaHR0cDovL2Ny
# dC51c2VydHJ1c3QuY29tL1VTRVJUcnVzdFJTQUFkZFRydXN0Q0EuY3J0MCUGCCsG
# AQUFBzABhhlodHRwOi8vb2NzcC51c2VydHJ1c3QuY29tMA0GCSqGSIb3DQEBDQUA
# A4ICAQBGLLZ/ak4lZr2caqaq0J69D65ONfzwOCfBx50EyYI024bhE/fBlo0wRBPS
# Ne1591dck6YSV22reZfBJmTfyVzLwzaibZMjoduqMAJr6rjAhdaSokFsrgw5ZcUf
# TBAqesReMJx9THLOFnizq0D8vguZFhOYIP+yunPRtVTcC5Jf6aPTkT5Y8SinhYT4
# Pfk4tycxyMVuy3cpY333HForjRUedfwSRwGSKlA8Ny7K3WFs4IOMdOrYDLzhH9Jy
# E3paRU8albzLSYZzn2W6XV2UOaNU7KcX0xFTkALKdOR1DQl8oc55VS69CWjZDO3n
# YJOfc5nU20hnTKvGbbrulcq4rzpTEj1pmsuTI78E87jaK28Ab9Ay/u3MmQaezWGa
# Lvg6BndZRWTdI1OSLECoJt/tNKZ5yeu3K3RcH8//G6tzIU4ijlhG9OBU9zmVafo8
# 72goR1i0PIGwjkYApWmatR92qiOyXkZFhBBKek7+FgFbK/4uy6F1O9oDm/AgMzxa
# sCOBMXHa8adCODl2xAh5Q6lOLEyJ6sJTMKH5sXjuLveNfeqiKiUJfvEspJdOlZLa
# jLsfOCMN2UCx9PCfC2iflg1MnHODo2OtSOxRsQg5G0kH956V3kRZtCAZ/Bolvk0Q
# 5OidlyRS1hLVWZoW6BZQS6FJah1AirtEDoVP/gBDqp2PfI9s0TGCAjIwggIuAgEB
# MIGQMHwxCzAJBgNVBAYTAlVTMQswCQYDVQQIEwJNSTESMBAGA1UEBxMJQW5uIEFy
# Ym9yMRIwEAYDVQQKEwlJbnRlcm5ldDIxETAPBgNVBAsTCEluQ29tbW9uMSUwIwYD
# VQQDExxJbkNvbW1vbiBSU0EgQ29kZSBTaWduaW5nIENBAhA19sQ46Pd6EXmdDFjA
# fSRdMAkGBSsOAwIaBQCgeDAYBgorBgEEAYI3AgEMMQowCKACgAChAoAAMBkGCSqG
# SIb3DQEJAzEMBgorBgEEAYI3AgEEMBwGCisGAQQBgjcCAQsxDjAMBgorBgEEAYI3
# AgEVMCMGCSqGSIb3DQEJBDEWBBRqgs5MYOxsPs18Ry9G7/w8/1G8sTANBgkqhkiG
# 9w0BAQEFAASCAQCZzq6jxlfQKgdZvU7NYts5h2b8L3vVADLvycW3g5E3IxcrWdZW
# X+JdVw0RP9bRO0gG8hhUvJayuosceQCQwkQWHFbaCfVIc6UdalUBXAhnyqIi6ito
# nK+dTynQKA8O7rFRwdlWzRy0OIRjLBsPVc8CAubujjWxixDNVKgIuHZPOIwC0TX2
# jCSS1iRNp7TjSs7fjl+vWSE+H8z1qdxrl0ZOhDfAAN6VPaJK/vG3isqmQOgiCTwz
# x/usk/wqCAXpYXsJjtK4BzqkFNxgOGIi0quiTrRolqNIl1RpP2BsmAEkJyk06Am8
# xzU6iJkeZaBnePYo0yilS2N3U3mFd874lxKr
# SIG # End signature block
