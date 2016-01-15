$packageName = 'registrymanager'
$installerType = 'EXE'
$url = 'http://www.resplendence.com/download/RegistrarHomeV7.exe'
$silentArgs = "/VERYSILENT /NORESTART /LOG"
$validExitCodes = @(0)

$checksum = '50FC113EE9473E464C7E23C2143434180EF4B62B'
$checksumtype = 'sha1'

Install-ChocolateyPackage "$packageName" "$installerType" "$silentArgs" "$url" -checksum $checksum -checksumtype $checksumtype -validExitCodes $validExitCodes

Write-Output "**************************************************************************************"
Write-Output "*  INSTRUCTIONS: Use the start menu to search for `"Registrar Registry Manager...`"  *"
Write-Output "*   More Info:                                                                       *"
Write-Output "*   http://www.resplendence.com/registrar_features                                   *"
Write-Output "**************************************************************************************"
