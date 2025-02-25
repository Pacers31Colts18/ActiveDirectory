# Tests Configuration manager client ports to Domain Controllers
function Test-G46NetConnection {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $False)]
        [array]$Domains,
        [Parameter(Mandatory = $False)]
        [array]$Ports = @(53,88,135,137,139,389,445,464,636,3268,3269)

    )

    #region Parameter Logic
    if ($Domains.Count -eq 0) { $Domains = (Import-CSV -path $global:DomainsFile | Out-GridView -PassThru).Title }   
    #endregion

    #region Declarations
    $FunctionName = $MyInvocation.MyCommand.Name.ToString()
    $date = Get-Date -Format yyyyMMdd-HHmm
    if ($outputdir.Length -eq 0) { $outputdir = $pwd }
    $OutputFilePath = "$OutputDir\$FunctionName-$date.csv"
    $LogFilePath = "$OutputDir\$FunctionName-$date.log"
    $ResultsArray = @()
    #endregion

    Foreach ($domain in $domains) {
        [array]$IPAddresses = (Resolve-DnsName -Name $domain).ipaddress

        Foreach ($IP in $ipAddresses) {
            Foreach ($Port in $Ports) {
                $TestPort = (Test-NetConnection -Computername $IP -Port $Port).TcpTestSucceeded
                If ($TestPort -eq $False) {
                    $TestPort = "Fail"
                }
                If ($TestPort -eq $True) {
                    $TestPort = "Pass"
                }
                $result = New-Object -TypeName PSObject -Property @{
                    DomainName = $Domain
                    IPAddress  = $IP
                    Port       = $Port
                    Result     = $TestPort 
                }
                $ResultsArray += $result
            }
        }
    }
        #region Results
        if ($resultsArray.count -ge 1) {
            $ResultsArray | Select-Object DomainName, IPAddress, Port, Result | Sort-Object -Property DomainName, IPAddress | Export-Csv -Path $outputfilepath -NoTypeInformation
        }
    
        #Test if results file was created
        If (Test-Path $outputfilepath) {
            Write-g46log -message "Results found. Results file=$outputfilepath."
        }
        else {
            Write-g46log -message "No results found." -level Warning
        }
        #endregion
}