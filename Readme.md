# ps_Util_GetEventLogByDateRange.ps1

This script will search through all available Windows eventlogs and return all entries found for a specific date range. Results will be exported to a folder with the filename set as the eventlog name.

## Parameters

PARAMETER ExportFolderPath
    [Optional]  This is the path to save the results to. If not specified then c:\temp\EventExport will be used.

PARAMETER StartDate
	[Optional] If empty the EndDate will be set to the current date/time minus 24 hours. If specified the date/time must be in the format dd/mm/yyyy hh:mm:ss
	
PARAMETER EndDate
	[Optional] If empty the EndDate will be set to the current date/time. If specified the date/time must be in the format dd/mm/yyyy hh:mm:ss

## Examples

EXAMPLE

.\ps_Util_GetEventLogByDateRange.ps1 -ExportFolderPath c:\MyFolderExport

Uses the default path	
	
EXAMPLE

.\ps_Util_GetEventLogByDateRange.ps1 -ExportFolderPath c:\MyFolderExport
