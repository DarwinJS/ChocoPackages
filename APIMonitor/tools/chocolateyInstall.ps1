$packageName = 'APIMonitor' # arbitrary name for the package, used in messages
$url = 'http://www.rohitab.com/download/api-monitor-v2r13-x86-x64.zip' # download url
$url64 = 'http://www.rohitab.com/download/api-monitor-v2r13-x86-x64.zip' # 64bit URL here or remove - if installer decides, then use $url
$silentArgs = 'SILENT_ARGS_HERE' # "/s /S /q /Q /quiet /silent /SILENT /VERYSILENT" # try any of these to get the silent installer #msi is always /quiet
$validExitCodes = @(0) #please insert other valid exit codes here, exit codes for ms http://msdn.microsoft.com/en-us/library/aa368542(VS.85).aspx

Install-ChocolateyZipPackage "$packageName" "$url" "$(Split-Path -parent $MyInvocation.MyCommand.Definition)" "$url64"

Write-Output "***********************************************************************************"
Write-Output "*  INSTRUCTIONS: Type `"apimonitor-x86.exe`" to monitor 32-bit Windows processes. *"
Write-Output "*                Type `"apimonitor-x64.exe`" to monitor 64-bit Windows processes. *"
Write-Output "*       More Info: http://www.rohitab.com/apimonitor                              *"
Write-Output "***********************************************************************************"
