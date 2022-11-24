# ps_Util_GetEventLogByDateRange.ps1

* A PowerShell script to export all available Windows event logs for a specific date/time range to a csv type file.<br><br>
* The script exports (by default) to a single file, collating log data in a csv format which can be opened in a spreadsheet application.<br><br>
* The script has an option to export each windows log to a separate log file.<br><br>
* The csv delimeter used is the ~ character.<br><br>
* Line breaks are removed from the event log messages and replace with " :: ".<br><br>
* By default the Security event log is not exported. 
* The startup parameters of the script provide options to include the Security log, set the start and end date/times and export separate csv files for each windows log.<br><br>
* Whilst the script can be run without admin rights - some event logs will not be exported (including the security event log) without running the script with elevated privileges. <br><br>

## Parameters

* PARAMETER ExportFolderPath
  * [Optional]  This is the path to save the results to. If not specified then c:\temp\EventExport will be used (if this folder doesn't exist it will be created). <br><br>

* PARAMETER StartDate
  * [Optional] If empty the EndDate will be set to the current date/time minus 24 hours. If the parameter is used, the date/time must be in the format dd/mm/yyyy hh:mm:ss (or the local date format).<br><br>
	
* PARAMETER EndDate
  * [Optional] If empty the EndDate will be set to the current date/time. If the parameter is used, the date/time must be in the format dd/mm/yyyy hh:mm:ss (or the local date format).<br><br>

* PARAMETER IncludeSecurityLog
  * [Optional] By default the security log is not exported (as it can take a while). Using this switch includes the security log data in results file.<br><br>

* PARAMETER ExportIndividualLogs
  * [Optional] By default all log entries are collated into a single file in the export folder. Using this switch will export each windows log into a separate file.<br><br>

<br>

## Examples

### EXAMPLE - Default options

`.\ps_Util_GetEventLogByDateRange.ps1`

* Exports all windows log data available for the last 24 hours, except the Security Log
  * The security log is excluded by default as it can take a longer time to export
* Exports collated data to the default path c:\temp\EventExport

<br>

### EXAMPLE -Include the security log

`.\ps_Util_GetEventLogByDateRange.ps1 -IncludeSecurityLog`

* Exports all windows log data available for the last 24 hours, including the Security Log
* Exports collated data to the default path c:\temp\EventExport

<br>

### EXAMPLE - Set a date/time range to capture

`.\ps_Util_GetEventLogByDateRange.ps1 -StartDate "01/01/2022 10:00" -EndDate "01/01/2022 11:00"`

* Exports windows log data available for a specific time period - in this case between 10am and 11am on the 1st of Jan 2022
* Exports collated data to the default path c:\temp\EventExport

<br>

### EXAMPLE -

`.\ps_Util_GetEventLogByDateRange.ps1 -ExportIndividualLogs`

* Exports all windows log data available for the last 24 hours, excluding the Security Log
* Exports a collated data to the default path c:\temp\EventExport
* Exports each log to an individual csv file as well creating a collated log file

<br>

### EXAMPLE - Export to a custom folder

`.\ps_Util_GetEventLogByDateRange.ps1 -ExportFolderPath "c:\MyExportFolder"`

* Exports all windows log data available for the last 24 hours, excluding the Security Log
* Exports collated data to a custom path specified in "ExportFolderPath" (in this instance c:\MyExportFolder)


