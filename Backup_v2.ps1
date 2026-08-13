<#
.TITLE
    Custom Backup script

.DESCRIPTION
    Backup identified folders and file location to configured desitination.
	Backup retention is also configuraable.
	Compression options if 7zip is installed.

.NOTES
    Author      :   Fro (https://github.com/BigBobFro)
    Date        :   Nov 5, 2015
    Git         :   https://github.com/BigBobFro/PowerShellBackup
    Version     :   2.0 Beta

.REQUIREMENTS
	Powershell 2.0
	Windows 10+
	PowerShell Execution Policy set to Bypass
	7zip installed for compression of backup files (optional)

.CHANGELOG
	1.0 	= New Script developed in Powershell 2.0
	1.1 	= Addition of AppSetting in config file for Temp and Log locations
				- Also requires that logging section be moved later, after collection of info from datafile
	1.1.1	= [2025-05-15] Minor syntax corrections
	2.0     = Rewrite to build consistency and improve functionality.

.USAGE
    

.LICENSE
    Free to use as long as it is kept whole to preserve authorship
    If includes are impossible in a secure environment, sections of code may be used, so long as
        they are cited via comments in the code where they are used.

#>


# ===================================================================================================
# Capture passed parameters
param($settingsPath = $null)	

# ===================================================================================================
# Constants
$srcPath = Split-Path -Path $MyInvocation.MyCommand.Path
$divider = "==============================================================================================" 

# ===================================================================================================
# Templog to hold logging information until logging configurations are retrieved from settings file.
$tempLog = "$divider`n$divider"

# ===============================================================================================================================
# Check for settings file in same folder as execution path
# $settingsPath = ".\powershellbackup\Settings.xml"
if($null -eq $settingspath){
	## No setting file passed
	$settingspath = "$srcpath\settings.xml"
	$templog += "`n[$(get-date)] - Using execution path settings file`n$divider" 
} 
if (Test-Path -path $settingsPath) {
	[xml]$dataFile = Get-Content $settingsPath
	$templog += "`n[$(get-date)] - Using settings file $settingsPath`n$divider" 
} else {
	write-host "No settings file provided or found"; exit 5
}
# ===================================================================================================
# Setup Logging and temp directory locations and files.

$LogFileName = "Backup.log"
$LogFilePath = $datafile.root.appsettings.logfolder					# Grab folder location from settingsfile
$tempFilePath = $datafile.root.appsettings.tempfolder				# Grab folder location from settingsfile

if($null -eq $LogFilePath){		# No Log path found; use execution path for log file
	$logfilepath = $srcpath
	$templog += "`n[$(get-date)] - No log path found in settings file; using execution path for log file`n"
}
if(!$(test-path -path $LogFilePath)){
	new-item -itemtype directory -path $LogFilePath -force
	$templog += "`n[$(get-date)] - Log folder $LogFilePath created`n"
}
$LogFile = "$LogFilePath\$LogFileName"
if(test-path -path $LogFile){ $templog | out-file -filepath $LogFile -append} 
else { "$divider`n$divider`n$templog" | out-file -filepath $LogFile }

# Setting up Temp directory to hold files for backup while being collected and compressed.

if($null -eq $tempFilePath){		# No Temp path found; use windows temp path
	$tempfilepath = "%WINDIR%\temp"
	"[$(get-date)] - No temp path found in settings file; using Windows temp path" | out-file -filepath $LogFile -append
} else {
	if (!$(test-path -path $tempFilePath)){
		new-item -itemtype directory -path $tempFilePath -force
		"[$(get-date)] - Temp folder $tempFilePath created" | out-file -filepath $LogFile -append
	}
}
$global:BUdate = "$(get-date -f yyyyMMdd)"
$global:Destination = "$($datafile.root.destination)\$($global:budate)"

$ret = $datafile.root.retention

switch($ret.unit)  
{
	"Month" { $global:retentionDate = $( $(get-date).addmonths($([int]$ret.number * -1))) }
	"Day"	{ $global:retentionDate = $( $(get-date).adddays($([int]$ret.number * -1))) }
	else	{ $global:retentionDate = $( $(get-date).addmonths($([int]$ret.number * -1))) }
}
"[$(get-date)] - Retention date set to $($global:retentionDate)" | out-file -filepath $LogFile -append

$old_Folders = get-childitem $($datafile.root.destination) | ?{$_.lastwritetime -le $retentiondate}
if($old_folders.count -eq 0) { "[$(get-date)] - No old backup folders found to remove" | out-file -filepath $LogFile -append }
else{
	foreach ($folder in $old_folders) {
		"[$(get-date)] - Removing old folder $folder" | out-file -filepath $LogFile -append
		remove-item $folder -recurse -force
		if (test-path $folder) {"$folder not removed" |out-file -filepath $LogFile -append}
		else {"$folder removed" | out-file -filepath $LogFile -append}
	}
}

$CompApp = "c:\program files\7-zip\7z.exe"
if(test-path -path $CompApp){ $comp = $true }
else { $comp = $false }
"[$(get-date)] - Compression status: $comp`n$divider" | out-file -filepath $LogFile -append

foreach ($backup in $Datafile.root.backup)
{
	if( test-path -path $($backup.location) ){
		"[$(get-date)] - Backing up $($backup.name)" | out-file -filepath $LogFile -append
		copy-item -path "$($backup.location)" -destination "$($TempFilePath)\$($backup.name)" -recurse -erroraction silentlycontinue
		if ($comp)
		{
			$arrgs = "a ""$($Global:destination)\$($backup.name)-$($global:BUdate).zip"" ""$($tempfilePath)\$($backup.name)"" -r"
			
			$rc = start-process $CompApp -argumentlist $arrgs -passthru -wait

			"[$(get-date)] - Compression of $($backup.location) completed with exit code: $($rc.exitcode)" | out-file -filepath $LogFile -append
		} else {
			copy-item -path "$($TempFilePath)\$($backup.name)" -Destination "$($global:destination)\$($backup.name)" -recurse
		}
		Remove-Item -path "$($TempFilePath)\$($backup.name)" -recurse -force
		"[$(get-date)] - Backup of $($backup.location) complete" | out-file -filepath $LogFile -append
	} else { "[$(get-date)] - Backup location $($backup.location) not found" | out-file -filepath $LogFile -append }
	"$divider`n" | out-file -filepath $LogFile -append
}

"[$(get-date)] - Script Complete`n$divider" | out-file -filepath $LogFile -append
