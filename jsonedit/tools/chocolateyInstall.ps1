$packageName = 'jsonedit'
$url = 'http://tomeko.net/software/JSONedit/bin/JSONedit_0_9_16.zip'
$validExitCodes = @(0)
$exeName = "jsonedit.exe"
$checksum      = 'A0884CA7242A99340D2AFDB4F575D88517774B81'
$checksumType  = 'sha1'

Install-ChocolateyZipPackage "$packageName" "$url" "$(Split-Path -parent $MyInvocation.MyCommand.Definition)" -checksum $checksum -checksumType $checksumType

$AppPathKey = "Registry::HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\$exeName"
If (!(Test-Path $AppPathKey)) {New-Item "$AppPathKey" | Out-Null}
Set-ItemProperty -Path $AppPathKey -Name "(Default)" -Value "$env:chocolateyinstall\lib\$packagename\tools\$exeName"
Set-ItemProperty -Path $AppPathKey -Name "Path" -Value "$env:chocolateyinstall\lib\$packagename\tools\"

Write-Output "************************************************************************************************"
Write-Output "*  INSTRUCTIONS: In the search prompt of your start menu type `"$exeName`"                     *"
Write-Output "*   More Info:                                                                                 *"
Write-Output "*   http://tomeko.net/software/JSONedit/                                                       *"
Write-Output "************************************************************************************************"
