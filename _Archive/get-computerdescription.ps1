$DomainName = 'LDAP://OU=REGI,OU=LegacyMachines,OU=Production,OU=Win10,OU=Workstations,OU=Computers,OU=IU-CAIT,OU=IU,DC=ads,DC=iu,DC=edu'
$Root = New-Object DirectoryServices.DirectoryEntry $DomainName
$objSearcher = New-Object DirectoryServices.DirectorySearcher
$objSearcher.SearchRoot = $Root
$objSearcher.SearchScope = "SubTree"
$objSearcher.Filter =  "(objectCategory=computer)"
$colResults = $objSearcher.FindAll()
foreach ($objResult in $colResults)
{
	$objComputer = $objResult.Properties
	$computer = $objResult.GetDirectoryEntry()
	$name = [string]$computer.name
	$Description = [string]$computer.description
	Write-Output "$description' $name"
}