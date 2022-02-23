<#
Custom backup script

Originally written: Nov 5, 2015
Original Author: Victor Willingham (Fro and Bob: Technology Services)

Dependancies: 		Powershell 2.0
					.NET 4.0
					Windows 7
					PowerShell Execution Policy set to Bypass
					
Version History
Current Version 1.0 -- Nov 5, 2015
========================================
1.0 - New Script developed in Powershell 2.0

========================================
#>


# ===================================================================================================
# Capture passed parameters
param( 	$datafile = $null)	

# ===================================================================================================
# Constants
$srcPath = Split-Path -Path $MyInvocation.MyCommand.Path
$divider = "====================================================================================================================" 


# Setup Logging
$LogName = "CustomBackup.log"
$LogPath = "C:\Logs"
$LogFile = "$LogPath\$LogName"
$tmpPath = "c:\temp"

If(-not(Test-Path -Path $LogPath) -eq $true)							# Create Logs Directory if doesn't exist
	{New-Item -ItemType Directory -Path $LogPath}
	
If(-not(Test-Path -Path $TmpPath) -eq $true)							# Create Temp Directory if doesn't exist
	{New-Item -ItemType Directory -Path $TmpPath}

# Attach to existing script log or create new script log if DNE
If(Test-Path -Path $LogFile) {"`n`n`n$divider" | Out-File -Filepath $logFile -Append}
Else {"$divider`n$divider" | Out-File -Filepath $logFile}

# ===============================================================================================================================
# Check for settings file in same folder as execution path
# $DataPath = "$srcpath\Settings.xml"
if (Test-Path -path $datapath) 
{
	[xml]$dataFile = Get-Content $datapath
	"Using Datafile $datapath" | out-file -filepath $logfile -append
	$divider | out-file -filepath $logfile -append
}
Else {"No Settings File" | out-file -filepath $logfile -append; exit 5}

$global:BUdate = "$(get-date -f yyyyMMdd)"
$global:destination = "$datafile.root.destination\$global:budate"

$ret = $datafile.root.retention

switch($ret.unit)  
{
	"Month" { $global:retentionDate = $($get-date).addmonths($ret.number)}
	"Day"	{ $global:retentionDate = $($get-date).adddays($ret.number)}
	else	{ $global:retentionDate = $($get-date).addmonths($ret.number)}
}
"Retention date set to $global:retentionDate" | out-file -filepath $logfile -append


$old_Folders = get-childitem $($datafile.root.destination) | ($_.lastwritetime -le $retentiondate)
foreach ($folder in $old_folders)
{
	"Removing old folder $folder" | out-file -filepath $logfile -append
	remove-item $folder -recurse -force
	if (test-path $folder) {"$folder not removed" |out-file -filepath $logfile -append}
	else {"$folder removed" | out-file -filepath $logfile -append}
}

foreach ($backup in $Datafile.root)
{
	copy-item -path "$backup.location" -destination "$global:destination\$backup.name" -recurse
	if ($comp)
	{
		$app = "c:\program files\7-zip\7z.exe"
		$arrgs = "a $($Global:Destination\backup.name).zip $($backup.location) -r"
		
		$rc = start-process $app -argumentlist $arrgs -passthru -wait
		"Compression of $backup.location completed with exit code: $rc.exitcode" | out-file -filepath $logfile -append
	}
	"Backup of $backup.location complete" | out-file -filepath $logfile -append
}


