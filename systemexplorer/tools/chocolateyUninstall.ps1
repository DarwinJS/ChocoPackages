
Uninstall-ChocolateyZipPackage systemexplorer SystemExplorerPortable_700.zip
$exeName = 'systemexplorer.exe'
$AppPathKey = "Registry::HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\$exeName"
If (Test-Path $AppPathKey) {Remove-Item "$AppPathKey" -Force -Recurse -EA SilentlyContinue | Out-Null}
