<#Powershell script to dump members of an ADS group to a text file.

Make sure you run the script with an account that has access to the group and access to the root of C where the text file is saved.
 #>

$ErrorActionPreference=1

Try {

    # Import the powershell AD Module
    Import-Module ActiveDirectory

}
Catch {
    Write-Host -ForegroundColor Red 'Failed to import the ActiveDirectory module'
    Write-Host -ForegroundColor Red $_.Exception.Message
    Break
}

#Get the ADS group name.

$groupname = Read-Host "Groupname"
$groupname = $groupname.Trim()

Try {
    # Get the ADS Group Object
    $GroupMembersObject = Get-ADGroupMember $groupname
}
Catch {
    Write-Host -ForegroundColor Red 'Cannot find an object with identity:'
    Write-Host -ForegroundColor Red $_.Exception.Message
    Break
    
}

# Create text file based on groupname and save somewhere.

Try {

    $Filepath = 'c:\'
    $NewFilepath = Read-Host "`r`n`r`nPath to save file or Enter to accept Default`r`n[$Filepath]`r`n"
    if($NewFilepath -ne $null -and $NewFilepath -ne ""){$Filepath = $NewFilepath}

    $file = New-Object System.IO.StreamWriter ($filepath + $groupname + '.txt') -ea stop


    #Write the group members to the file
    $file.WriteLine("List of group members")
    foreach ($groupmember in $GroupMembersObject) {
        
        $file.WriteLine($groupmember.name)
        
    }
    
    

}
Catch {
    Write-Host -ForegroundColor Red 'Failed to open file, check path and try again'
    Write-Host -ForegroundColor Red $_.Exception.Message
    Break
}
Finally {
    $file.close()
}
# SIG # Begin signature block
# MIIOJwYJKoZIhvcNAQcCoIIOGDCCDhQCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUdlq0R0ucobdmD863AJ0Nbk0m
# m3egggtfMIIFbDCCBFSgAwIBAgIQNfbEOOj3ehF5nQxYwH0kXTANBgkqhkiG9w0B
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
# AgEVMCMGCSqGSIb3DQEJBDEWBBQu34wf/pwGKItXRXhK5a8Dng2/XDANBgkqhkiG
# 9w0BAQEFAASCAQBZTAK3bt1GrjLWsB5/SpumVx4nRvuSF/1qWqJTwEK1MXG4qxX1
# Rpo72fywWYb2X19pH0Sd5aipdR0gbRms3BO1+yGjeSsE0K+f0w5+fsPemTRdG16a
# 4SRBQjOOUT5D/TOpsdxxnoNSS4RmAoeWROqY4jnt8nzoBOUmPmkLg21MVcgPfXOe
# XyDfLF3o9/AJaf6TBOYm4LWNOSMXbKfIVOv3emizV8lxksCvbs55NUXrF1cAi72k
# ry+9HarlfzxqRnud+4ySqPUxi0JEyeWW+e8HwmNl84xJOaP2/D8r364qm8cZcZ8V
# YgH+PRYTVJ9HC4WfX3iOlGHFVePqZFpt8qtR
# SIG # End signature block
