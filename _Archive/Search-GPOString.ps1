<#
.Synopsis
 Searches for a string match in the GPOs of a given domain
.DESCRIPTION
 Searches for a string match in the GPOs of a given domain
.EXAMPLE
./Search-GPO.ps1
.INPUTS
in-progress
.OUTPUTS
in-progress
.NOTES
Author: Joe Loveless
Date: 10/14/2019
.COMPONENT
in progress
.ROLE
in progress
.FUNCTIONALITY
in progress
#>

Import-Module grouppolicy

# Get the string we want to search for 
$string = Read-Host -Prompt "What string do you want to search for?" 

# Get the domain we want to search for
$DomainName = Read-Host "What domain do we want to search?"
  
# Find all the GPOs
Write-Host "Searching the GPOs in $DomainName..."
$GPOs = Get-GPO -All -Domain $DomainName 
 
# Look through each GPO's XML for matching string
foreach ($gpo in $GPOs)
{ 
    $report = Get-GPOReport -Guid $gpo.Id -ReportType XML 
    if ($report -match $string)
    { 
        write-host "*** Match found in: $($gpo.DisplayName) ***" -BackgroundColor green
    }
    else
    { 
        Write-Host "No match in: $($gpo.DisplayName)" -BackgroundColor red
    }
}
 