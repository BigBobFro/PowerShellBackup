<#
Custom backup script

Originally written: Nov 5, 2015
Original Author: Victor Willingham (https://github.com/BigBobFro)

Dependancies: 		Powershell 2.0
					.NET 4.0
					Windows 7
					PowerShell Execution Policy set to Bypass
					
Version History
Current Version 1.1.1 -- May 15, 2025
========================================
1.0 	- New Script developed in Powershell 2.0
1.1 	- Addition of AppSetting in config file for Temp and Log locations
    		- Also requires that logging section be moved later, after collection of info from datafile
1.1.1	- [2025-05-15] Minor syntax corrections
========================================
#>


# ===================================================================================================
# Capture passed parameters
param($datafile = $null)	

# ===================================================================================================
# Constants
$srcPath = Split-Path -Path $MyInvocation.MyCommand.Path
$divider = "====================================================================================================================" 


# ===============================================================================================================================
# Check for settings file in same folder as execution path
# $DataPath = "$srcpath\Settings.xml"
if (Test-Path -path $datapath) 
{
	[xml]$dataFile = Get-Content $datapath
	"Using Datafile $datapath" | out-file -filepath $LogFile -append
	$divider | out-file -filepath $LogFile -append
}
Else {"No Settings File" | out-file -filepath $LogFile -append; exit 5}

# Setup Logging
$LogName = "PowerShellBackup.log"
$LogPath = $datafile.root.appsettings.logfolder							# Grab folder location from datafile
$LogFile = "$LogPath\$LogName"
if ($null -eq $($datafile.root.appsettings.tempfolder)){
	$TempPath = "%WINDIR%\temp"}
Else {
	$TempPath = $datafile.root.appsettings.tempfolder}					# Grab folder location from datafile. Set to c:\win\temp if empty

If(-not(Test-Path -Path $LogPath) -eq $true)							# Create Logs Directory if doesn't exist
	{New-Item -ItemType Directory -Path $LogPath -Force}
	
If(-not(Test-Path -Path $TempPath) -eq $true)							# Create Temp Directory if doesn't exist
	{New-Item -ItemType Directory -Path $TempPath -Force}

# Attach to existing script log or create new script log if DNE
If(Test-Path -Path $LogFile) {"`n`n`n$divider" | Out-File -Filepath $logFile -Append}
Else {"$divider`n$divider" | Out-File -Filepath $logFile}


$global:BUdate = "$(get-date -f yyyyMMdd)"
$global:destination = "$($datafile.root.destination)\$global:budate"

$ret = $datafile.root.retention

switch($ret.unit)  
{
	"Month" { $global:retentionDate = $($(get-date).addmonths($ret.number))}
	"Day"	{ $global:retentionDate = $($(get-date).adddays($ret.number))}
	else	{ $global:retentionDate = $($(get-date).addmonths($ret.number))}
}
"Retention date set to $global:retentionDate" | out-file -filepath $LogFile -append


$old_Folders = get-childitem $($datafile.root.destination) | ?{$_.lastwritetime -le $retentiondate}
foreach ($folder in $old_folders)
{
	"Removing old folder $folder" | out-file -filepath $LogFile -append
	remove-item $folder -recurse -force
	if (test-path $folder) {"$folder not removed" |out-file -filepath $LogFile -append}
	else {"$folder removed" | out-file -filepath $LogFile -append}
}

foreach ($backup in $Datafile.root)
{
	copy-item -path "$($backup.location)" -destination "$TempPath\$($backup.name)" -recurse
	if ($comp)
	{
		$app = "c:\program files\7-zip\7z.exe"
		$arrgs = "a $tempPath\$($backup.name) $($backup.location)\$($backup.name)-$($global:BUdate).zip -r"
		
		$rc = start-process $app -argumentlist $arrgs -passthru -wait
		"Compression of $($backup.location) completed with exit code: $($rc.exitcode)" | out-file -filepath $LogFile -append
	}
	"Backup of $($backup.location) complete" | out-file -filepath $LogFile -append
}

"Script Complete at $(get-date)"
