function Test-PortNetConnection {
    <#
    .Synopsis
    Tests ports for connectivity. Used for AD port testing, but can be repurposed for other purposes. Default ports are listed, but can be customized with input.
    .Description
    Tests ports for connectivity. Used for AD port testing, but can be repurposed for other purposes. Default ports are listed, but can be customized with input.
    .Example
    Test-PortNetConnection -domains joeloveless.com
    .Parameter Domains
    Enter the domain name or leave blank to utilize Out-GridView selection.
    .Parameter Ports
    Not mandatory. Leaving blank will test against 53,88,135,137,139,389,445,464,636,3268,3269.
    .Parameter DomainCSVPath
    Not mandatory. If using multiple domains and do not want to type into an array, having a CSV file of the list of domains is useful for selection.
    #> 
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $False)]
        [array]$Domains,
        [Parameter(Mandatory = $False)]
        [array]$Ports = @(53,88,135,137,139,389,445,464,636,3268,3269),
        [Parameter(Mandatory = False)]
        $DomainCSVPath
    )

    #region Parameter Logic
    if ($Domains.Count -eq 0) { $Domains = (Import-CSV -path $DomainCSVPath | Out-GridView -PassThru).Title }   
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
            Write-Output "Results found. Results file=$outputfilepath."
        }
        else {
            Write-Warning -message "No results found." -level Warning
        }
        #endregion
}
