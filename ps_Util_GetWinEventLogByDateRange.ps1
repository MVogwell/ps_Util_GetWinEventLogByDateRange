<#

.SYNOPSIS
This script will search through all available Windows eventlogs and return all entries found for a specific date range. Results will be exported to a folder with the filename set as the eventlog name.

.PARAMETER ExportFolderPath
    [Optional]  This is the path to save the results to. If not specified then c:\temp\EventExport will be used.

.PARAMETER StartDate
	[Optional] If empty the EndDate will be set to the current date/time minus 24 hours. If specified the date/time must be in the format "dd/mm/yyyy hh:mm:ss" and should be specified as a string (not datetime)

.PARAMETER EndDate
	[Optional] If empty the EndDate will be set to the current date/time. If specified the date/time must be in the format "dd/mm/yyyy hh:mm:ss" and should be specified as a string (not datetime)

.PARAMETER ScanSecurityLog
	[Optional] If set to true the security log will be included in the results. By default the security scan is NOT included

.EXAMPLE

.\ps_Util_GetEventLogByDateRange.ps1

Uses the default path

.EXAMPLE

.\ps_Util_GetEventLogByDateRange.ps1 -ExportFolderPath c:\MyFolderExport

Export the results to c:\MyFolderExport

.EXAMPLE

.\ps_Util_GetEventLogByDateRange.ps1 -ScanSecurityLog:$True

The security log will be included in the results

.EXAMPLE

.\ps_Util_GetEventLogByDateRange.ps1 -StartDate "01/01/2019 08:00:00" -EndDate "01/01/2019 09:00:00"

This would scan the logs for the 1st of Jan 2019 between 08:00h and 09:00h

.NOTES
MVogwell - 16-05-19 - v1.1

v1.0 - Initial release
v1.1 - Added event source (ProviderName) to the outputed data

.LINK

#>

[CmdletBinding()]

param (
	[Parameter(Mandatory=$false)][string]$ExportFolderPath ="C:\temp\EventExport",
	[Parameter(Mandatory=$false)][string]$StartDate = "",
	[Parameter(Mandatory=$false)][string]$EndDate = "",
	[Parameter(Mandatory=$false)][boolean]$ScanSecurityLog = $False
)

Function ps_Function_CheckRunningAsAdmin {
    [CmdletBinding()]
    param()

    # Constructor
    [bool]$bRunningAsAdmin = $False

    Try {
        # Attempt to check if the current powershell session is being run with admin rights
        # System.Security.Principal.WindowsIdentity -- https://msdn.microsoft.com/en-us/library/system.security.principal.windowsidentity(v=vs.110).aspx
        # Info on Well Known Security Identifiers in Windows: https://support.microsoft.com/en-gb/help/243330/well-known-security-identifiers-in-windows-operating-systems

        write-verbose "ps_Function_CheckRunningAsAdmin :: Checking for admin rights"
        $bRunningAsAdmin = [bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544")
    }
    Catch {
        $bRunningAsAdmin = $False
        write-verbose "ps_Function_CheckRunningAsAdmin :: ERROR Checking for admin rights in current session"
        write-verbose "ps_Function_CheckRunningAsAdmin :: Error: $($Error[0].Exception)"
    }
    Finally {}

    write-verbose "ps_Function_CheckRunningAsAdmin :: Result :: $bRunningAsAdmin"

    # Return result from function
    return $bRunningAsAdmin

}


#@# Main
write-host "Eventlog export by date range utility - MVogwell - 16-05-19 - v1.0 `n" -fore green

$bRunningAsAdmin = ps_Function_CheckRunningAsAdmin
if(!($bRunningAsAdmin)) {
	write-host "You must be running as an admin to run this script. Please open an administrator elevated powershell session and try again! `n`n" -fore red #Exit
}
Else {
	If(!(Test-Path $ExportFolderPath)) {
		$bCreateFolderFailed = $False

		Try {
			New-Item -Path $ExportFolderPath -ItemType Directory -Force | Out-Null
		}
		Catch {
			write-host "Unable to create folder path $ExportFolderPath - the script will now exit! `n`n" -fore red
			$bCreateFolderFailed = $True
		}
	}

	$arrAllLogData =@()

	If(!($bCreateFolderFailed)) {
		$ComputerName = $env:COMPUTERNAME#Current computer
		$EventLogNames = (get-winevent -ComputerName $ComputerName -ListLog * -ea "SilentlyContinue").LogName

		$bStartDateError =$False
		If($StartDate.length -eq 0) {
			$EventStartDate = ((Get-Date).AddDays(-1))
		}
		Else {
			Try {
				$EventStartDate = get-Date($StartDate)
			}
			Catch {
				$bStartDateError = $True
			}
		}

		$bEndDateError =$False
		If($EndDate.length -eq 0) {
			$EventEndTime = Get-Date
		}
		Else {
			Try {
				$EventEndTime = get-Date($EndDate)
			}
			Catch {
				$bEndDateError = $True
			}
		}


		write-host "Exporting log files to $ExportFolderPath" -fore yellow
		write-host "Using delimiter: ~" -fore yellow
		write-host "Scan Security Log?: $ScanSecurityLog" -fore yellow
		write-host "Start Date: $($EventStartDate.toString())" -fore yellow
		write-host "End Date: $($EventEndTime.toString()) `n" -fore yellow
		write-verbose "Start date invalid: $bStartDateError "
		write-verbose "End date invalid: $bEndDateError "

		If(($bStartDateError -eq $True) -or($bEndDateError -eq $True)) {
			write-host "Unable to set date!" -fore red # NEEDS WORK!
		}
		Else {
			write-host "Exporting logs for... " -fore yellow
			Foreach($EventLogName in $EventLogNames) {
				$bScanLog = $True

				If($EventLogName -eq "Security") {
					If($ScanSecurityLog -eq $False) {
						$bScanLog = $False
					}
				}

				If($bScanLog -eq $True) {
					write-host $EventLogName -fore yellow
					$EventCritea = @{logname = $EventLogName; StartTime=$EventStartDate; EndTime=$EventEndTime}
					$ExportPath = $ExportFolderPath +"\" + $EventLogName.replace("/","-").replace("\","-") + ".txt"
					$Evts = Get-WinEvent -ComputerName $ComputerName -FilterHashTable $EventCritea  -ErrorAction SilentlyContinue | select LogName,MachineName,TimeCreated,ProviderName,Id,LevelDisplayName, @{n="Msg";e={$_.Message.replace("`n"," :: ").replace("`r"," :: ") }}
					If(($Evts | Measure).count -gt 0) {
						$Evts | Export-CSV $ExportPath -NoTypeInformation -Delimiter "~"
						$arrAllLogData += $Evts
					}
				}
			}

			$ExportPath = $ExportFolderPath + "\_AllExportedLogData.txt"
			$arrAllLogData | Export-CSV $ExportPath -NoTypeInformation -Delimiter "~"

			write-host "`nAll events have been exported to $ExportPath - Please open the text files using Excel and select the delimiter ~`n`n" -fore green
		}
	}
}
