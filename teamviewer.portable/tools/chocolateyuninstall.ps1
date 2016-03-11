
$ErrorActionPreference = 'Stop';

$packageName = 'teamviewer.portable'
$exeName = "TeamViewerPortable.exe"
$AppPathKey = "Registry::HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\$exeName"

If (Test-Path $AppPathKey) {Remove-Item "$AppPathKey" -Force -Recurse -EA SilentlyContinue | Out-Null}
