<#
	.SYNOPSIS
	This script will search through all available Windows eventlogs and return all entries found for a specific date range. Results will be exported to a folder with the filename set as the eventlog name.

	.PARAMETER ExportFolderPath
    [Optional]  This is the path to save the results to. If not specified then c:\temp\EventExport will be used.

	.PARAMETER StartDate
	[Optional] If empty the EndDate will be set to the current date/time minus 24 hours. If specified the date/time must be in the format "dd/mm/yyyy hh:mm:ss" and should be specified as a string (not datetime)

	.PARAMETER EndDate
	[Optional] If empty the EndDate will be set to the current date/time. If specified the date/time must be in the format "dd/mm/yyyy hh:mm:ss" and should be specified as a string (not datetime)

	.PARAMETER IncludeSecurityLog
	[Optional] If set to true the security log will be included in the results. By default the security scan is NOT included

	.PARAMETER ExportIndividualLogs
	[Optional] To export each individual log to a separate file start the script with this switch

	.EXAMPLE

	.\ps_Util_GetEventLogByDateRange.ps1

	Uses the default path

	.EXAMPLE

	.\ps_Util_GetEventLogByDateRange.ps1 -ExportFolderPath c:\MyFolderExport

	Export the results to c:\MyFolderExport

	.EXAMPLE

	.\ps_Util_GetEventLogByDateRange.ps1 -IncludeSecurityLog

	The security log will be included in the results

	.EXAMPLE

	.\ps_Util_GetEventLogByDateRange.ps1 -StartDate "01/01/2019 08:00:00" -EndDate "01/01/2019 09:00:00"

	This would scan the logs for the 1st of Jan 2019 between 08:00h and 09:00h

	.NOTES
	MVogwell - 2022-11-24 - v1.2

	v1.0 - Initial release
	v1.1 - Added event source (ProviderName) to the outputed data
	v1.2 - Removed Write-Host

	.LINK

#>

[CmdletBinding()]

param (
	[Parameter(Mandatory=$false)][string]$ExportFolderPath ="C:\temp\EventExport",
	[Parameter(Mandatory=$false)][string]$StartDate = "",
	[Parameter(Mandatory=$false)][string]$EndDate = "",
	[Parameter(Mandatory=$false)][switch]$IncludeSecurityLog,
	[Parameter(Mandatory=$false)][switch]$ExportIndividualLogs
)

#@# Main
Write-Output "`n`n=== Eventlog export by date range utility - MVogwell - Nov 2022 - v1.2 ===`n"

try {
	Write-Output "*** Checking if running as admin"

	$bRunningAsAdmin = [bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544")

	if ($bRunningAsAdmin -eq $true) {
		Write-Output "`t+++ Session is running as admin `n"
	}
	else {
		Write-Output "`t--- Session is NOT running as admin - not all logs (including Security) will be exported! `n"
	}
}
catch {
	Write-Output "`t--- Failed to discover whether this session is running as admin."
	Write-Output "`t--- It is possible that not all logs will be exported. `n"
}

$bScanLog = $true	# flag to decide whether a log file should be scanned
$bProceed = $true
[System.Collections.ArrayList]$arrAllLogData = @()
$sTimestamp = Get-Date -Format "yyyyMMdd-HHmmss"

If((Test-Path $ExportFolderPath) -eq $false) {
	Try {
		Write-Output "*** Creating output folder $ExportFolderPath"

		New-Item -Path $ExportFolderPath -ItemType Directory -Force | Out-Null

		Write-Output "`t+++ Success"
	}
	Catch {
		$bProceed = $false

		Write-Output "Unable to create folder path $ExportFolderPath - the script will now exit! `n`n"
	}
}
else {
	Write-Output "*** Checking output folder $ExportFolderPath available"
	Write-Output "`t+++ Success `n"
}

# Only continue if the results folder could be created
If($bProceed -eq $true) {
	$sComputerName = $env:ComputerName	# Get Current computer name

	# Get a list of available Windows logs
	try {
		Write-Output "*** Enumerating available windows logs"

		$arrEventLogNames = (Get-WinEvent -ComputerName $sComputerName -ListLog * -ea "SilentlyContinue").LogName

		Write-Output "`t+++ Success `n"
	}
	catch {
		$sErrMsg = ("Failed! Error: " + ($Error[0].Exception.Message).Replace("`r","").Replace("`n"," "))
		Write-Output "`t---$sErrMsg"

		$bProceed = $false
	}

# Set the start date to value in the param EventStartDate. If not available set it to 24 hours ago
if ($bProceed -eq $true) {}
	if ([string]::IsNullOrEmpty($StartDate)) {
		$EventStartDate = ((Get-Date).AddDays(-1))
	}
	else {
		try {
			$EventStartDate = Get-Date($StartDate)
		}
		catch {
			$bProceed = $false
		}
	}

	# Set the end date to value in the param EventStartDate. If not available set it to 24 hours ago
	If([string]::IsNullOrEmpty($EndDate)) {
		$EventEndTime = Get-Date
	}
	Else {
		Try {
			$EventEndTime = Get-Date($EndDate)
		}
		Catch {
			$bProceed = $false
		}
	}
}

if ($bProceed -eq $false) {
		Write-Output "Unable to set start or end date! Please check the values and try again"
}
else {
	Write-Output "*** Startup parameters:"
	Write-Output "`t... Computer name: $sComputerName"
	Write-Output "`t... Exporting log files to $ExportFolderPath"
	Write-Output "`t... Using delimiter: ~"
	Write-Output "`t... Export Security Log?: $IncludeSecurityLog"
	Write-Output "`t... Export individual log files: $ExportIndividualLogs"
	Write-Output "`t... Start Date: $($EventStartDate.toString())"
	Write-Output "`t... End Date: $($EventEndTime.toString()) `n"

	Write-Output "*** Exporting logs:"

	# Loop through each log returned from list all
	Foreach($sEventLogName in $arrEventLogNames) {
		try {
			Write-Progress -Activity "Exporting log data" -Status "Logname: $sEventLogName"
		}
		catch {
			Write-Progress -Activity "Exporting log data"
		}

		# Check if the current log is "Security. Only scan if startup parameter IncludeSecurityLog is false"
		if (($sEventLogName -eq "Security") -and ($IncludeSecurityLog -eq $false)) {
			$bScanLog = $false
		}

		If($bScanLog -eq $true) {
			$hEventCritea = @{logname = $sEventLogName; StartTime=$EventStartDate; EndTime=$EventEndTime}

			$sExportPath = $ExportFolderPath +"\" + $sEventLogName.replace("/","-").replace("\","-") + ".txt"

			# Retrieve the log data
			try {
				$arrEvts = Get-WinEvent -ComputerName $sComputerName -FilterHashTable $hEventCritea  -ErrorAction SilentlyContinue | Select-Object LogName,MachineName,TimeCreated,ProviderName,Id,LevelDisplayName, @{n="Msg";e={$_.Message.replace("`n"," :: ").replace("`r","") }}
			}
			catch {
				Write-Output "`t--- Error: $sEventLogName - unable to export log data!"
				$arrEvts = @()
			}

			# Export the log data and add to the cumulative log file (arrAllLogData)
			if ($null -eq $arrEvts) {
				Write-Output "`t--- No data: $sEventLogName"
			}
			else {
				if ($ExportIndividualLogs -eq $true) {
					try {
						$arrEvts | Sort-Object TimeCreated | Export-CSV $sExportPath -NoTypeInformation -Delimiter "~"
					}
					catch {
						Write-Output "`t--- Failed to save individual log: $sExportPath"
					}
				}

				# Add the retreived log events to the collation array
				if ($arrEvts.GetType().BaseType.Name -eq 'Array') {
					$arrAllLogData.AddRange($arrEvts)
				}
				else {
					$arrAllLogData.Add($arrEvts)
				}

				Write-Output "`t+++ Completed: $sEventLogName"
			}
		}

		# Tidy up - Clear the buffer of events
		Remove-Variable arrEvts -ErrorAction "SilentlyContinue"

		# Reset flag to scan logs
		$bScanLog = $true
	}

	$sExportPath = $ExportFolderPath + "\_" + $sComputerName + "_AllExportedLogData_" + $sTimestamp + ".txt"
	$arrAllLogData | Sort-Object TimeCreated,LogName | Export-CSV $sExportPath -NoTypeInformation -Delimiter "~"

	# Display output information
	if ($ExportIndividualLogs -eq $true) {
		Write-Output "`nIndividual logs have been exported to $ExportFolderPath"
	}

	Write-Output "`n* Discovered log data from $($arrAllLogData.count) event logs"

	Write-Output "* All events have been exported to $sExportPath"

	Write-Output "* Please open the text files using Excel and select the delimiter ~`n"
}


# Tidy up
Remove-Variable sErrMsg,sComputerName,bResultsFolderAvailable,ExportFolderPath,bProceed,sExportPath -ErrorAction "SilentlyContinue"
Remove-Variable EventEndTime,EventStartDate,arrAllLogData,arrEventLogNames -ErrorAction "SilentlyContinue"

Write-Output "=== Finished === `n`n"