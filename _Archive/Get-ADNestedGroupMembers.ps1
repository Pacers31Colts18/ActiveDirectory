function Get-ADNestedGroupMembers { 
<#  
.SYNOPSIS
Author: Piotr Lewandowski
Version: 1.01 (04.11.2014)
Get nested group membership from a given group or a number of groups.

.DESCRIPTION
Function enumerates members of a given AD group recursively along with nesting level and parent group information. 
It also displays if each user account is enabled. 
When used with an -indent switch, it will display only names, but in a more user-friendly way (sort of a tree view) 
   
.EXAMPLE   
Get-ADNestedGroupMembers "MyGroup1", "MyGroup2" | Export-CSV .\NedstedMembers.csv -NoTypeInformation

.EXAMPLE  
Get-ADGroup "MyGroup" | Get-ADNestedGroupMembers | ft -autosize
            
.EXAMPLE             
Get-ADNestedGroupMembers "MyGroup" -indent
 
.EXAMPLE             
"MyGroup1", "MyGroup2" | Get-ADNestedGroupMembers  -indent
 
#>

param ( 
[CmdLetBinding()]
[Parameter(ValuefromPipeline=$true,mandatory=$true)][String] $GroupName, 
[int] $nesting = -1, 
[int]$circular = $null, 
[switch]$indent 
) 
BEGIN {
    function indent  
    { 
    Param($list) 
        foreach($line in $list) 
        { 
        $space = $null 
         
            for ($i=0;$i -lt $line.nesting;$i++) 
            { 
            $space += "    " 
            } 
            $line.name = "$space" + "$($line.name)" 
        } 
      return $List 
    }
    
    $modules = get-module | select -expand name
    $nesting++  
   }  
PROCESS {
        if ($modules -contains "ActiveDirectory") 
        {
            if ($indent -and $nesting -eq 0)
            {
            [console]::foregroundcolor = "green"
            write-output $GroupName
            [console]::ResetColor()
            }
            
            $table = $null 
            $nestedmembers = $null 
            $adgroupname = $null     
            $ADGroupname = get-adgroup $groupname -properties memberof,members
            
            <#
            #Replaced by the code below to handle Usernames and DNs as inputs in addition to groupnames

            # See if we have a DN
            Try {$ADGroupname = Get-ADObject -Identity $groupname -properties memberof
                # If we have a DN, is it a group?
                If ($ADGroupname.ObjectClass -eq 'group') {
                    #Get the members of the group in addition to the memberof property
                    $ADGroupname = Get-ADGroup -Identity $ADGroupname -properties memberof,members
                    Write-Verbose "Processing a group from DN"
                }
                Write-Verbose "Processing a user from DN"} 
            Catch {
                # If we don't have a DN, see if it is a user
                Try {$ADGroupname = Get-ADUser -Identity $groupname -properties memberof
                    Write-Verbose "Processing a User"}
                Catch {
                    #If not a user, see if it's a group
                    Try {$ADGroupname = Get-ADGroup -Identity $groupname -properties memberof,members
                        Write-Verbose "Processing a Group"}
                    Catch { 
                        # If it goes this far something went wrong, throw exception.
                        Throw (New-Object System.Exception("Unable to get members for $groupname")) 
                    }
                }
            }
            #>

            $memberof = $adgroupname | select -expand memberof 
            write-verbose "Checking group: $($adgroupname.name)" 
            if ($adgroupname) 
            {  
                if ($circular) 
                { 
                    $nestedMembers = Get-ADGroupMember -Identity $GroupName -recursive 
                    $circular = $null 
                } 
                else 
                { 
                    $nestedMembers = Get-ADGroupMember -Identity $GroupName | sort objectclass -Descending
                    if (!($nestedmembers))
                    {
                        $unknown = $ADGroupname | select -expand members
                        if ($unknown)
                        {
                            $nestedmembers=@()
                            foreach ($member in $unknown)
                            {
                            $nestedmembers += get-adobject $member
                            }
                        }

                    }
                } 
     
                foreach ($nestedmember in $nestedmembers) 
                { 
                    $Props = @{Type=$nestedmember.objectclass;Name=$nestedmember.name;ParentGroup=$ADgroupname.name;Enabled="";Nesting=$nesting;DN=$nestedmember.distinguishedname;Comment=""} 
                     
                    if ($nestedmember.objectclass -eq "user") 
                    { 
                        $nestedADMember = get-aduser $nestedmember -properties enabled 
                        $table = new-object psobject -property $props 
                        $table.enabled = $nestedadmember.enabled 
                        if ($indent) 
                        { 
                        indent $table | select -expand name
                        } 
                        else 
                        { 
                        $table | select type,name,parentgroup,enabled,nesting,dn,comment 
                        } 
                    } 
                    elseif ($nestedmember.objectclass -eq "group") 
                    {  
                        $table = new-object psobject -Property $props 
                         
                        if ($memberof -contains $nestedmember.distinguishedname) 
                        { 
                            $table.comment ="Circular membership" 
                            $circular = 1 
                        } 
                        if ($indent) 
                        {
                        indent $table | select name,comment | %{
    						
    						if ($_.comment -ne "")
    						{
    						[console]::foregroundcolor = "red"
    						write-output "$($_.name) (Circular Membership)"
    						[console]::ResetColor()
    						}
    						else
    						{
    						[console]::foregroundcolor = "yellow"
    						write-output "$($_.name)"
    						[console]::ResetColor()
    						}
                        }
    					}
                        else 
                        { 
                        $table | select type,name,parentgroup,enabled,nesting,dn,comment 
                        } 
                        if ($indent) 
                        { 
                           Get-ADNestedGroupMembers -GroupName $nestedmember.distinguishedName -nesting $nesting -circular $circular -indent 
                        } 
                        else  
                        { 
                           Get-ADNestedGroupMembers -GroupName $nestedmember.distinguishedName -nesting $nesting -circular $circular 
                        } 
                  	                  
                   } 
                    else 
                    { 
                        
                        if ($nestedmember)
                        {
                            $table = new-object psobject -property $props
                            if ($indent) 
                            { 
        	                    indent $table | select name 
                            } 
                            else 
                            { 
                            $table | select type,name,parentgroup,enabled,nesting,dn,comment    
                            } 
                         }
                    } 
                  
                } 
             } 
        } 
        else {Write-Warning "Active Directory module is not loaded"}        
    }
 END {
        
 
    }
}


#Get-ADNestedGroupMembers -GroupName 'IU-IUSM-Admins' -indent

#$a = 'CN=aIU-IUSM-DANES_SQL-ANES_pedschronicpain-DBOwner,OU=SQL Database Permissions,OU=SQL,OU=Server,OU=Security,OU=Groups,OU=IU-IUSM,OU=IU,DC=ads,DC=iu,DC=edu'


# SIG # Begin signature block
# MIIOJwYJKoZIhvcNAQcCoIIOGDCCDhQCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU/b7zfif3X7wC+lp+PqNxqklT
# IRigggtfMIIFbDCCBFSgAwIBAgIQNfbEOOj3ehF5nQxYwH0kXTANBgkqhkiG9w0B
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
# AgEVMCMGCSqGSIb3DQEJBDEWBBQEAW3mdyt0KjZTpv95KgKyl4/J8jANBgkqhkiG
# 9w0BAQEFAASCAQBEvo/q8vw39PaEEWZjL/4aP36GhUUHiFllaT7tI0qeZlxBRC0r
# O5Xixvdi+0WD4qISt0RPKWAlMb5YIHzSc1XQIB6jC/hJPP7nhEKqWvBdwV919pDJ
# U6byJ8dkD7g2d2AzV3gDbeWHsW/3VMpmiXAoMefxuWZkk7Zmddc/sa9K9HtyhdLD
# sP+EDqkI4uF2zyjuhjpj2UFXuhZ4g37FPsBII7Qr1pQrAfCH7hXEc7Yox80+inq6
# KLKdeXnAqdPbw7Zy9vjEdnApNhdfAfyCmjcaIuxfdpRHltPeZXxdh0ZMWzDwjwAz
# avdxfk+NxeJKzdJ+wBTzp0OWx0e37SFCW4XP
# SIG # End signature block
