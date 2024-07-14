Function Get-ADMemberOf {
<#
.Synopsis
   Returns an ADObject with extra fields added
.DESCRIPTION
   Returns an ADObject with extra fields added:     
   MemberOfAll:  Added to all objects.  Follows nested groups to report all the groups that the object is a member of
   IsCircular: Added to group objects.  A boolean that is true if there is a circular group reference
   CircularGroups: Added to group objects.  A collection of groups with circular references if any exist
.EXAMPLE
   >Get-ADMemberOf -ADUser jkaetzel


   MemberOfAll       : {CN=IU-IUSM-dANES-File-Staging,OU=File Shares,OU=Server,OU=Security,OU=Groups,OU=IU-IUSM,OU=IU,DC=ads,DC=iu,DC=edu, CN=IU-IUSM-dANES-File-SQL Backups,OU=File Shares,OU=Server,OU=Security,OU=Groups,OU=IU-IUSM,OU=IU,DC=ads,DC=iu,DC=edu, CN=IU-IUSM-DANES_SQL-ANES_pedschronicpain-DBOwner,OU=SQL Database Permissions,OU=SQL,OU=Server,OU=Security,OU=Groups,OU=IU-IUSM,OU=IU,DC=ads,DC=iu,DC=edu, CN=IU-IUSM-D12SQL_SQL-DatabaseMailUser,OU=SQL,OU=Server,OU=Security,OU=Groups,OU=IU-IUSM,OU=IU,DC=ads,DC=iu,DC=edu...}
   DistinguishedName : CN=jkaetzel,OU=Accounts,DC=ads,DC=iu,DC=edu
   MemberOf          : {CN=IU-IUSM-dANES-File-Staging,OU=File Shares,OU=Server,OU=Security,OU=Groups,OU=IU-IUSM,OU=IU,DC=ads,DC=iu,DC=edu, CN=IU-IUSM-dANES-File-SQL Backups,OU=File Shares,OU=Server,OU=Security,OU=Groups,OU=IU-IUSM,OU=IU,DC=ads,DC=iu,DC=edu, CN=IU-IUSM-DANES_SQL-ANES_pedschronicpain-DBOwner,OU=SQL Database Permissions,OU=SQL,OU=Server,OU=Security,OU=Groups,OU=IU-IUSM,OU=IU,DC=ads,DC=iu,DC=edu, CN=IU-IUSM-D12SQL_SQL-DatabaseMailUser,OU=SQL,OU=Server,OU=Security,OU=Groups,OU=IU-IUSM,OU=IU,DC=ads,DC=iu,DC=edu...}
   Name              : jkaetzel
   ObjectClass       : user
   ObjectGUID        : ce3a84fb-f275-46c3-800f-66c19b56f5bb
.EXAMPLE
   >Get-ADMemberOf -ADGroup IU-IUSM-Admins-Server


   MemberOfAll       : {CN=IU-IUSM-SQL-Admins,OU=ServerAdmins,OU=Server,OU=Security Groups,OU=Groups,OU=IU-IUSM,OU=IU,DC=ads,DC=iu,DC=edu, CN=IU-IUSM-MSSQL-Admins,OU=Server,OU=Security Groups,OU=Groups,OU=IU-IUSM,OU=IU,DC=ads,DC=iu,DC=edu, CN=IU-IUSM-TMSSQL-Admins,OU=Server,OU=Security Groups,OU=Groups,OU=IU-IUSM,OU=IU,DC=ads,DC=iu,DC=edu, CN=IU-IUSM-REMOTE-TEST069,OU=IUSD-Local,OU=Old Workstation Access Groups,OU=Workstations,OU=Security,OU=Groups,OU=IU-IUSM,OU=IU,DC=ads,DC=iu,DC=edu...}
   CircluarGroups    : {}
   IsCircular        : False
   DistinguishedName : CN=IU-IUSM-Admins-Server,OU=Unsorted,OU=Server,OU=Security,OU=Groups,OU=IU-IUSM,OU=IU,DC=ads,DC=iu,DC=edu
   MemberOf          : {CN=IU-IUSM-SQL-Admins,OU=ServerAdmins,OU=Server,OU=Security Groups,OU=Groups,OU=IU-IUSM,OU=IU,DC=ads,DC=iu,DC=edu, CN=IU-IUSM-MSSQL-Admins,OU=Server,OU=Security Groups,OU=Groups,OU=IU-IUSM,OU=IU,DC=ads,DC=iu,DC=edu, CN=IU-IUSM-TMSSQL-Admins,OU=Server,OU=Security Groups,OU=Groups,OU=IU-IUSM,OU=IU,DC=ads,DC=iu,DC=edu, CN=IU-IUSM-REMOTE-TEST069,OU=IUSD-Local,OU=Old Workstation Access Groups,OU=Workstations,OU=Security,OU=Groups,OU=IU-IUSM,OU=IU,DC=ads,DC=iu,DC=edu...}
   Name              : IU-IUSM-Admins-Server
   ObjectClass       : group
   ObjectGUID        : 4cfe25d7-60f7-4444-9095-630f5bb6fdce
.INPUTS
   ADUser:  Gets an active directory user
   ADGroup:  Gets an active directory group
   ADObject:  Gets an active directory object
.OUTPUTS
   [Microsoft.ActiveDirectory.Management.ADObject]
.NOTES
   
.COMPONENT
   
.ROLE
   
.FUNCTIONALITY
   
.LINK
   
#>

    [CmdletBinding()]
    # LDAP Distinguished Name
    Param (
        [Parameter(Mandatory=$True,ValueFromPipeline=$True,Position=0,ParameterSetName="ADUser")]
        [ValidateScript({Get-ADUser -Identity $_})]
        [String]$ADUser,

        [Parameter(Mandatory=$True,ValueFromPipeline=$True,Position=0,ParameterSetName="ADGroup")]
        [ValidateScript({Get-ADGroup -Identity $_})]
        [String]$ADGroup,

        [Parameter(Mandatory=$True,ValueFromPipeline=$True,Position=0,ParameterSetName="ADObject")]
        [ValidateScript({Get-ADObject -Identity $_})]
        [String]$ADObjectDN
    
    )
    
    If (-Not [String]::IsNullOrEmpty($ADUser)) {
    
        $ADObjectDN = (Get-ADUser -Identity $ADUser).DistinguishedName
    
    }

    ElseIf (-Not [String]::IsNullOrEmpty($ADGroup)) {
    
        $ADObjectDN = (Get-ADGroup -Identity $ADGroup).DistinguishedName

    }

    $ADObjectAll = Get-ADObject -Identity $ADObjectDN -Properties MemberOf -ErrorAction Stop
    $ADObjectCircular = Get-ADObject -Identity $ADObjectDN -Properties MemberOf -ErrorAction Stop
    $ADObject = Get-ADObject -Identity $ADObjectDN -Properties MemberOf -ErrorAction Stop
    
    $ADObject | Add-Member -MemberType NoteProperty -Name 'MemberOfAll' -Value ($ADObjectAll.MemberOf) -Force
    
    #Extra properties to check for circular references
    
    
    If ($ADObject.ObjectClass -eq 'group') {

        $ADObject | Add-Member -MemberType NoteProperty -Name 'CircularGroups' -Value ($ADOBjectCircular.MemberOf) -Force
        $ADObject.CircularGroups.Clear()

        $ADObject | Add-Member -MemberType NoteProperty -Name 'IsCircular' -Value $False -Force
    
    }

    #$ADObject | Add-Member -MemberType NoteProperty -Name 'CircluarReferences' -Value (New-Object System.Collections.Generic.List``1[String]) -Force

    #$ADObject | Add-Member -MemberType NoteProperty -Name 'HasCircularReferences' -Value $False -Force
    
    #If ($ADObject.ObjectClass -eq 'user') {$ADObject.MemberOf.Add('CN=Domain Users,CN=Users,DC=ads,DC=iu,DC=edu')}


    $StackMemberOf = New-Object System.Collections.Stack

    $ADObject.MemberOf | ForEach-Object {
                                        #[void]$ADObject.MemberOfAll.Add($_)
                                        [void]$StackMemberOf.Push($_)
                                        }
    If ($PSCmdlet.ParameterSetName -eq "ADUser") {
        [void]$StackMemberOf.Push('CN=Domain Users,CN=Users,DC=ads,DC=iu,DC=edu')
    }
    

    #$ADObject.MemberOf | ForEach-Object {}
        
    While ($StackMemberOf.Count -gt 0) {

        $Group = $StackMemberOf.Pop()

        $ADTempObject = Get-ADObject -Identity $Group -Properties MemberOf

        $ADTempObject.MemberOf | ForEach-Object {
                                        <#
                                        If (-Not $ADObject.MemberOfAll.Contains($_)) {
                                            [void]$ADObject.MemberOfAll.Add($_)
                                            [void]$StackMemberOf.Push($_)
                                        }
                                        If ($ADObject.ObjectClass -eq 'group' -and $_ -eq $ADObjectDN) {
                                            $ADObject.IsCircular = $True
                                            [void]$ADObject.CircularGroups.Add($ADTempObject.DistinguishedName)
                                        }
                                        #>
                                        If (-Not $ADObject.MemberOfAll.Contains($_)) {
                                            [void]$ADObject.MemberOfAll.Add($_)
                                            [void]$StackMemberOf.Push($_)
                                        }
                                        ElseIf ($ADObject.ObjectClass -eq 'group' -and $_ -eq $ADObjectDN) {
                                            $ADObject.IsCircular = $True
                                            [void]$ADObject.CircularGroups.Add($ADTempObject.DistinguishedName)
                                        }
                                        <#
                                        ElseIf ($ADTempObject.DistinguishedName -ne 'CN=Domain Users,CN=Users,DC=ads,DC=iu,DC=edu') {
                                            $ADObject.HasCircularReferences = $True
                                            [void]$ADObject.CircularReferences.Add( $_ + "-->" + $ADTempObject.DistinguishedName)
                                        }
                                        #>
                                                                                                                      
                                    }
        
    }
        
    Return $ADObject

}



# SIG # Begin signature block
# MIIOJwYJKoZIhvcNAQcCoIIOGDCCDhQCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUPGLXopciDKKJbI8hljJpYyGp
# 7KqgggtfMIIFbDCCBFSgAwIBAgIQNfbEOOj3ehF5nQxYwH0kXTANBgkqhkiG9w0B
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
# AgEVMCMGCSqGSIb3DQEJBDEWBBR6sYyLzGBCs/AYz0nF2dB2WI90YjANBgkqhkiG
# 9w0BAQEFAASCAQB+LVCbhroNP+CZ646WOj+MN2czJVFE/niloe/LMMaFb5ffvY9M
# xsiojD3CKL6dmuziq7eT3zxHIOXKSYGJbxyAeuGmrCisx8gjtyHniITBLqxbWf5P
# Zh5Iz99xvMgCWUl9XVmcZ5PDLiq1rbBwcIWFFiDhgj3UX1GT99VIdOruDbqqHKen
# f5mT+ZLs3ftVHJVEJqK2kKyDkpseL3pZOb4+tuXJUcwLucRVHJmBdV0LcVGimPt/
# 7ywcooJX6z+FbtPk8UjbZ3+5ckevF9Uzt+1vsXCGSjku6py7COpPI/xxpDWY1Dj4
# 5sXfaxCP9+fksDmDyzBcJjsHHUwD/6n5wDY0
# SIG # End signature block
