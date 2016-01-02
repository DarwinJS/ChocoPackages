$packageName = 'LuaBuglight'
$exeName = "luabuglight.exe"
$AppPathKey = "Registry::HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\$exeName"

Uninstall-ChocolateyZipPackage LuaBuglight LuaBuglight.zip

If (Test-Path $AppPathKey) {Remove-Item "$AppPathKey" -Force -Recurse -EA SilentlyContinue | Out-Null}
