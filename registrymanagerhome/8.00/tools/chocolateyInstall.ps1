$packageName = 'registrymanager'
$installerType = 'EXE'
$url = 'http://www.resplendence.com/download/RegistrarHomeV8.exe'
$silentArgs = "/VERYSILENT /NORESTART /LOG"
$validExitCodes = @(0)

Install-ChocolateyPackage "$packageName" "$installerType" "$silentArgs" "$url" -validExitCodes $validExitCodes

Write-Output "**************************************************************************************"
Write-Output "*  INSTRUCTIONS: Use the start menu to search for `"Registrar Registry Manager...`"  *"
Write-Output "*   More Info:                                                                       *"
Write-Output "*   http://www.resplendence.com/registrar_features                                   *"
Write-Output "**************************************************************************************"
