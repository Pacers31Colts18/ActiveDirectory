function Export-ADOrganizationalUnits {
<#
.Synopsis
Export Organizational Unit details for a list of domains, gathering a count of devices, users, groups, and ous.
.Description
Export Organizational Unit details for a list of domains, gathering a count of devices, users, groups, and ous.
.Example
Export-g46ADOrganizationalUnits -Domains "example.com"
#> 

    param(
        [Parameter(Mandatory = $False)]
        [array]$Domains
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

    #Get OU
    foreach ($domain in $domains) {
        try {
            $ouList = Get-ADOrganizationalUnit -LDAPFilter '(name=*)' -Server $domain
        }
        catch {
            Write-Error "$_"
        }
        foreach ($OU in $ouList) {
            #Get User Count
            try {
                $Users = (Get-ADUser -Filter * -SearchBase $($OU.distinguishedName) -SearchScope OneLevel -Server $domain | Measure-Object).count
            }
            catch {
                Write-Error "$_"
            }

            #Get Device Count
            try {
                $devices = (Get-ADComputer -filter * -SearchBase $($OU.distinguishedName) -SearchScope OneLevel -Server $domain | Measure-Object).count
            }
            catch {
                Write-Error "$_"
            }

            #Get Group Count
            try {
                $groups = (Get-ADGroup -Filter * -SearchBase $($OU.distinguishedName) -SearchScope OneLevel -Server $domain | Measure-Object).count
            }
            catch {
                Write-Error "$_"
            }

            #Get OU Count
            try {
                $ous = (Get-ADOrganizationalUnit -Filter * -SearchBase $($OU.distinguishedName) -SearchScope OneLevel -Server $domain | Measure-Object).count
            }
            catch {
                Write-Error "$_"
            }

            $result = New-Object -TypeName PSObject -Property @{
                Domain           = $domain
                OUPath           = $ou.distinguishedName
                TotalObjectCount = ($ous + $users + $devices + $groups)
                SubOUCount       = $ous
                UserCount        = $users
                DeviceCount      = $devices
                GroupCount       = $groups
            }
            $resultsArray += $result
        }
    }
    #region Export
    if ($ResultsArray.Count -gt 0) {
        $ResultsArray | Select-Object Domain, OUPath, TotalObjectCount, SubOUCount, UserCount, DeviceCount, GroupCount | Sort-Object Domain, OUPath | Export-Csv -Path $outputFilePath -NoTypeInformation
        Write-Output "Output file = $outputFilePath."
    }
    else {
        Write-Warning "No output file created."
    }
    #endregion
}
