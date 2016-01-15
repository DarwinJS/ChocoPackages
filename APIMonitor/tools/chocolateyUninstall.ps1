
Uninstall-ChocolateyZipPackage apimonitor api-monitor-v2r13-x86-x64.zip

$exename1 = 'apimonitor-x86.exe'
$exename2 = 'apimonitor-x64.exe'

Foreach ($exeName in @($exename1,$exename2))
{
$AppPathKey = "Registry::HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\$exeName"
If (Test-Path $AppPathKey) {Remove-Item "$AppPathKey" -Force -Recurse -EA SilentlyContinue | Out-Null}
}
