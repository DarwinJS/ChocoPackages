$packageName = 'whocrashed'
$installerType = 'EXE'
$url = 'http://www.resplendence.com/download/whocrashedSetup.exe'
$silentArgs = "/VERYSILENT /NORESTART /LOG=`"$env:temp\CHOCO-INSTALL-whocrashed.log`""
$validExitCodes = @(0)

Install-ChocolateyPackage "$packageName" "$installerType" "$silentArgs" "$url" -validExitCodes $validExitCodes

Write-Output "********************************************************************"
Write-Output "*  INSTRUCTIONS: Use the start menu to search for `"WhoCrashed`"   *"
Write-Output "*   More Info:                                                     *"
Write-Output "*   http://www.resplendence.com/whocrashed                         *"
Write-Output "********************************************************************"