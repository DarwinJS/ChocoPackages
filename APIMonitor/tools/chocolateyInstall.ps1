$packageName = 'apimonitor'
$url = 'http://www.rohitab.com/download/api-monitor-v2r13-x86-x64.zip'
$url64 = 'http://www.rohitab.com/download/api-monitor-v2r13-x86-x64.zip'
$validExitCodes = @(0)

Install-ChocolateyZipPackage "$packageName" "$url" "$(Split-Path -parent $MyInvocation.MyCommand.Definition)" "$url64"
$exename1 = 'apimonitor-x86.exe'
$exename2 = 'apimonitor-x64.exe'

Foreach ($exeName in @($exename1,$exename2))
{
$AppPathKey = "Registry::HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\$exeName"
If (!(Test-Path $AppPathKey)) {New-Item "$AppPathKey" | Out-Null}
Set-ItemProperty -Path $AppPathKey -Name "(Default)" -Value "$env:chocolateyinstall\lib\$packagename\tools\$exeName"
Set-ItemProperty -Path $AppPathKey -Name "Path" -Value "$env:chocolateyinstall\lib\$packagename\tools\"
}

Write-Output "***********************************************************************************"
Write-Output "*  INSTRUCTIONS: Type `"apimonitor-x86.exe`" to monitor 32-bit Windows processes. *"
Write-Output "*                Type `"apimonitor-x64.exe`" to monitor 64-bit Windows processes. *"
Write-Output "*       More Info: http://www.rohitab.com/apimonitor                              *"
Write-Output "***********************************************************************************"
