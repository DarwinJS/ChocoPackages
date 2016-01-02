$packageName = 'jsonedit'
$exeName = "jsonedit.exe"
$AppPathKey = "Registry::HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\$exeName"

Uninstall-ChocolateyZipPackage jsonedit JSONedit_0_9_14.zip

If (Test-Path $AppPathKey) {Remove-Item "$AppPathKey" -Force -Recurse -EA SilentlyContinue | Out-Null}