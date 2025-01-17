﻿Import-Module ActiveDirectory
$Searcher = New-Object DirectoryServices.DirectorySearcher([ADSI]"")
$Searcher.SearchRoot = 'OU=Workstations,OU=IN-REGI,OU=IN,DC=ads,DC=iu,DC=edu'
$Searcher.Filter = "(objectClass=computer)"
$Computers = ($Searcher.Findall())

$Results = @()
md C:\Temp\All_Local_Admins

Foreach ($Computer in $Computers){
	$Path=$Computer.Path
	$Name=([ADSI]"$Path").Name
	write-host $Name
	$members =[ADSI]"WinNT://$Name/Administrators"
	$members = @($members.psbase.Invoke("Members"))
	$members | foreach {
		$LocalAdmins = $_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null)    # Create a new object for the purpose of exporting as a CSV
		$pubObject = new-object PSObject	
        $pubObject | add-member -membertype NoteProperty -name "Server" -Value $Name[0]
		$pubObject | add-member -membertype NoteProperty -name "Administrators" -Value $LocalAdmins

		# Append this iteration of our for loop to our results array.
		$Results += $pubObject
	}
}

$Results | Export-Csv -Path "C:\Temp\All_Local_Admins\REGILocalAdmins.csv" -NoTypeInformation
$Results = $Null