Function Get-LocalGroupMembership {
<#
    .SYNOPSIS
        Recursively list all members of a specified Local group.

    .DESCRIPTION
        Recursively list all members of a specified Local group. This can be run against a local or
        remote system or systems. Recursion is unlimited unless specified by the -Depth parameter.

        Alias: glgm

    .PARAMETER Computername
        Local or remote computer/s to perform the query against.

        Default value is the local system.

    .PARAMETER Group
        Name of the group to query on a system for all members.

        Default value is 'Administrators'

    .PARAMETER Depth
        Limit the recursive depth of a query. 

        Default value is 2147483647.

    .PARAMETER Throttle
        Number of concurrently running jobs to run at a time

        Default value is 10

    .NOTES
        Author: Boe Prox
        Created: 8 AUG 2013
        Version 1.0 (8 AUG 2013):
            -Initial creation

    .EXAMPLE
        Get-LocalGroupMembership

        Name              ParentGroup       isGroup Type   Computername Depth
        ----              -----------       ------- ----   ------------ -----
        Administrator     Administrators      False Domain DC1              1
        boe               Administrators      False Domain DC1              1
        testuser          Administrators      False Domain DC1              1
        bob               Administrators      False Domain DC1              1
        proxb             Administrators      False Domain DC1              1
        Enterprise Admins Administrators       True Domain DC1              1
        Sysops Admins     Enterprise Admins    True Domain DC1              2
        Domain Admins     Enterprise Admins    True Domain DC1              2
        Administrator     Enterprise Admins   False Domain DC1              2
        Domain Admins     Administrators       True Domain DC1              1
        proxb             Domain Admins       False Domain DC1              2
        Administrator     Domain Admins       False Domain DC1              2
        Sysops Admins     Administrators       True Domain DC1              1
        Org Admins        Sysops Admins        True Domain DC1              2
        Enterprise Admins Sysops Admins        True Domain DC1              2       

        Description
        -----------
        Gets all of the members of the 'Administrators' group on the local system.        

    .EXAMPLE
        Get-LocalGroupMembership -Group 'Administrators' -Depth 1

        Name              ParentGroup    isGroup Type   Computername Depth
        ----              -----------    ------- ----   ------------ -----
        Administrator     Administrators   False Domain DC1              1
        boe               Administrators   False Domain DC1              1
        testuser          Administrators   False Domain DC1              1
        bob               Administrators   False Domain DC1              1
        proxb             Administrators   False Domain DC1              1
        Enterprise Admins Administrators    True Domain DC1              1
        Domain Admins     Administrators    True Domain DC1              1
        Sysops Admins     Administrators    True Domain DC1              1   

        Description
        -----------
        Gets the members of 'Administrators' with only 1 level of recursion.         

#>
[cmdletbinding()]
Param (
    [parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
    [Alias('CN','__Server','Computer','IPAddress')]
    [string[]]$Computername = $env:COMPUTERNAME,
    [parameter()]
    [string]$Group = "Administrators",
    [parameter()]
    [int]$Depth = ([int]::MaxValue),
    [parameter()]
    [Alias("MaxJobs")]
    [int]$Throttle = 10
)
    Begin {
        # Check for the ActiveDirectory module and try to load it if needed.  
        If (-Not (get-module | select -expand name).contains("ActiveDirectory")) {
            Try {Import-Module ActiveDirectory -ErrorAction Stop}
            Catch {Throw "Unable to load ActiveDirectory module"}
        }
        
        $PSBoundParameters.GetEnumerator() | ForEach {
            Write-Verbose $_
        }
        #region Extra Configurations
        Write-Verbose ("Depth: {0}" -f $Depth)
        #endregion Extra Configurations
        #Define hash table for Get-RunspaceData function
        $runspacehash = @{}
        #Function to perform runspace job cleanup
        Function Get-RunspaceData {
            [cmdletbinding()]
            param(
                [switch]$Wait
            )
            Do {
                $more = $false         
                Foreach($runspace in $runspaces) {
                    If ($runspace.Runspace.isCompleted) {
                        $runspace.powershell.EndInvoke($runspace.Runspace)
                        $runspace.powershell.dispose()
                        $runspace.Runspace = $null
                        $runspace.powershell = $null                 
                    } ElseIf ($runspace.Runspace -ne $null) {
                        $more = $true
                    }
                }
                If ($more -AND $PSBoundParameters['Wait']) {
                    Start-Sleep -Milliseconds 100
                }   
                #Clean out unused runspace jobs
                $temphash = $runspaces.clone()
                $temphash | Where {
                    $_.runspace -eq $Null
                } | ForEach {
                    Write-Verbose ("Removing {0}" -f $_.computer)
                    $Runspaces.remove($_)
                }             
            } while ($more -AND $PSBoundParameters['Wait'])
        }

        #region ScriptBlock
            $scriptBlock = {
            Param ($Computer,$Group,$Depth,$NetBIOSDomain,$ObjNT,$Translate)            
            $Script:Depth = $Depth
            $Script:ObjNT = $ObjNT
            $Script:Translate = $Translate
            $Script:NetBIOSDomain = $NetBIOSDomain
            Function Get-LocalGroupMember {
                [cmdletbinding()]
                Param (
                    [parameter()]
                    [System.DirectoryServices.DirectoryEntry]$LocalGroup
                )
                # Invoke the Members method and convert to an array of member objects.
                $Members= @($LocalGroup.psbase.Invoke("Members"))
                $Counter++
                ForEach ($Member In $Members) {                
                    Try {
                        $Name = $Member.GetType.Invoke().InvokeMember("Name", 'GetProperty', $Null, $Member, $Null)
                        $Path = $Member.GetType.Invoke().InvokeMember("ADsPath", 'GetProperty', $Null, $Member, $Null)
                        # Check if this member is a group.
                        $isGroup = ($Member.GetType.Invoke().InvokeMember("Class", 'GetProperty', $Null, $Member, $Null) -eq "group")
                        If (($Path -like "*/$Computer/*")) {
                            $Type = 'Local'
                        } Else {$Type = 'Domain'}
                        New-Object PSObject -Property @{
                            Computername = $Computer
                            Name = $Name
                            Type = $Type
                            ParentGroup = $LocalGroup.Name[0]
                            isGroup = $isGroup
                            Depth = $Counter
                        }
                        If ($isGroup) {
                            # Check if this group is local or domain.
                            #$host.ui.WriteVerboseLine("(RS)Checking if Counter: {0} is less than Depth: {1}" -f $Counter, $Depth)
                            If ($Counter -lt $Depth) {
                                If ($Type -eq 'Local') {
                                    If ($Groups[$Name] -notcontains 'Local') {
                                        $host.ui.WriteVerboseLine(("{0}: Getting local group members" -f $Name))
                                        $Groups[$Name] += ,'Local'
                                        # Enumerate members of local group.
                                        Get-LocalGroupMember $Member
                                    }
                                } Else {
                                    If ($Groups[$Name] -notcontains 'Domain') {
                                        $host.ui.WriteVerboseLine(("{0}: Getting domain group members" -f $Name))
                                        $Groups[$Name] += ,'Domain'
                                        # Enumerate members of domain group.
                                        Get-DomainGroupMember $Member $Name $True
                                    }
                                }
                            }
                        }
                    } Catch {
                        $host.ui.WriteWarningLine(("GLGM{0}" -f $_.Exception.Message))
                    }
                }
            }

            Function Get-DomainGroupMember {
                [cmdletbinding()]
                Param (
                    [parameter()]
                    $DomainGroup, 
                    [parameter()]
                    [string]$NTName, 
                    [parameter()]
                    [string]$blnNT
                )
                Try {
                    If ($blnNT -eq $True) {
                        # Convert NetBIOS domain name of group to Distinguished Name.
                        $objNT.InvokeMember("Set", "InvokeMethod", $Null, $Translate, (3, ("{0}{1}" -f $NetBIOSDomain.Trim(),$NTName)))
                        $DN = $objNT.InvokeMember("Get", "InvokeMethod", $Null, $Translate, 1)
                        $ADGroup = [ADSI]"LDAP://$DN"
                    } Else {
                        $DN = $DomainGroup.distinguishedName
                        $ADGroup = $DomainGroup
                    }         
                    $Counter++   
                    ForEach ($MemberDN In $ADGroup.Member) {
                        $MemberGroup = [ADSI]("LDAP://{0}" -f ($MemberDN -replace '/','\/'))
                        New-Object PSObject -Property @{
                            Computername = $Computer
                            Name = $MemberGroup.name[0]
                            Type = 'Domain'
                            ParentGroup = $NTName
                            isGroup = ($MemberGroup.Class -eq "group")
                            Depth = $Counter
                        }
                        # Check if this member is a group.
                        If ($MemberGroup.Class -eq "group") {              
                            If ($Counter -lt $Depth) {
                                If ($Groups[$MemberGroup.name[0]] -notcontains 'Domain') {
                                    Write-Verbose ("{0}: Getting domain group members" -f $MemberGroup.name[0])
                                    $Groups[$MemberGroup.name[0]] += ,'Domain'
                                    # Enumerate members of domain group.
                                    Get-DomainGroupMember $MemberGroup $MemberGroup.Name[0] $False
                                }                                                
                            }
                        }
                    }
                } Catch {
                    $host.ui.WriteWarningLine(("GDGM{0}" -f $_.Exception.Message))
                }
            }
            #region Get Local Group Members
            $Script:Groups = @{}
            $Script:Counter=0
            # Bind to the group object with the WinNT provider.
            $ADSIGroup = [ADSI]"WinNT://$Computer/$Group,group"
            Write-Verbose ("Checking {0} membership for {1}" -f $Group,$Computer)
            $Groups[$Group] += ,'Local'
            Get-LocalGroupMember -LocalGroup $ADSIGroup
            #endregion Get Local Group Members
        }
        #endregion ScriptBlock
        Write-Verbose ("Checking to see if connected to a domain")
        Try {
            $Domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
            $Root = $Domain.GetDirectoryEntry()
            $Base = ($Root.distinguishedName)

            # Use the NameTranslate object.
            $Script:Translate = New-Object -comObject "NameTranslate"
            $Script:objNT = $Translate.GetType()

            # Initialize NameTranslate by locating the Global Catalog.
            $objNT.InvokeMember("Init", "InvokeMethod", $Null, $Translate, (3, $Null))

            # Retrieve NetBIOS name of the current domain.
            $objNT.InvokeMember("Set", "InvokeMethod", $Null, $Translate, (1, "$Base"))
            [string]$Script:NetBIOSDomain =$objNT.InvokeMember("Get", "InvokeMethod", $Null, $Translate, 3)  
        } Catch {Write-Warning ("{0}" -f $_.Exception.Message)}         

        #region Runspace Creation
        Write-Verbose ("Creating runspace pool and session states")
        $sessionstate = [system.management.automation.runspaces.initialsessionstate]::CreateDefault()
        $runspacepool = [runspacefactory]::CreateRunspacePool(1, $Throttle, $sessionstate, $Host)
        $runspacepool.Open()  

        Write-Verbose ("Creating empty collection to hold runspace jobs")
        $Script:runspaces = New-Object System.Collections.ArrayList        
        #endregion Runspace Creation
    }

    Process {
        ForEach ($Computer in $Computername) {
            #Create the powershell instance and supply the scriptblock with the other parameters 
            $powershell = [powershell]::Create().AddScript($scriptBlock).AddArgument($computer).AddArgument($Group).AddArgument($Depth).AddArgument($NetBIOSDomain).AddArgument($ObjNT).AddArgument($Translate)

            #Add the runspace into the powershell instance
            $powershell.RunspacePool = $runspacepool

            #Create a temporary collection for each runspace
            $temp = "" | Select-Object PowerShell,Runspace,Computer
            $Temp.Computer = $Computer
            $temp.PowerShell = $powershell

            #Save the handle output when calling BeginInvoke() that will be used later to end the runspace
            $temp.Runspace = $powershell.BeginInvoke()
            Write-Verbose ("Adding {0} collection" -f $temp.Computer)
            $runspaces.Add($temp) | Out-Null

            Write-Verbose ("Checking status of runspace jobs")
            Get-RunspaceData @runspacehash   
        }
    }
    End {
        Write-Verbose ("Finish processing the remaining runspace jobs: {0}" -f (@(($runspaces | Where {$_.Runspace -ne $Null}).Count)))
        $runspacehash.Wait = $true
        Get-RunspaceData @runspacehash

        #region Cleanup Runspace
        Write-Verbose ("Closing the runspace pool")
        $runspacepool.close()  
        $runspacepool.Dispose() 
        #endregion Cleanup Runspace    
    }
}
# SIG # Begin signature block
# MIIOJwYJKoZIhvcNAQcCoIIOGDCCDhQCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUPqV0ecoP1y5t3F6q1r1y8C7v
# 9cCgggtfMIIFbDCCBFSgAwIBAgIQNfbEOOj3ehF5nQxYwH0kXTANBgkqhkiG9w0B
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
# AgEVMCMGCSqGSIb3DQEJBDEWBBSpNZo4hDRoiGal/SRCPjAW24ixGTANBgkqhkiG
# 9w0BAQEFAASCAQCCHRoThnRI1RmEng8jg2o5kG4BwwlBI7xzV3vBNAXGLJh6HxCD
# gjLuw7F6FxYrWiAG+qV0S9H/LdayRgwt2LpUOTJt+ojZQAKHFyRF1WhB2+JQofuu
# o2VSqI9OX2FbpLT20IwZbEKs3JG/GxUck/9K+Dc4gWcNMzyuy/ciqVDFCLmrhTAt
# Cdc4cQNbi2NMrzJAM8asGzhBw11u+dKs6dNIBEbwjoaBFMiZ2mBX2ZV3TLaioeA/
# JGXjSIj1zgnWyzdyI+hQbPTAhjui81IfmI5ALKaC2kApeOose8op3kHjvPEk6qSo
# WrDfxNs+sbnmpOAu5yQW1k0HcKejATxpFzGY
# SIG # End signature block
