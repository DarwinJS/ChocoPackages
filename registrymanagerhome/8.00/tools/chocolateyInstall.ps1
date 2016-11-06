
$ErrorActionPreference = 'Stop';
$packageName = 'registrymanager'
$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"

$packageArgs = @{
  packageName   = $packageName
  unzipLocation = $toolsDir
  installerType = 'EXE'
  url           = 'http://www.resplendence.com/download/RegistrarHomeV8.exe'
  checksum      = '9C937F08BC6570D7A9F1EAC9ED128BC92974FEBF'
  checksumtype  = 'sha1'
  silentArgs    = "/VERYSILENT /NORESTART /LOG"
  validExitCodes= @(0, 3010, 1641)
}

Install-ChocolateyPackage @packageArgs

Write-Output "**************************************************************************************"
Write-Output "*  INSTRUCTIONS: Use the start menu to search for `"Registrar Registry Manager...`"  *"
Write-Output "*   More Info:                                                                       *"
Write-Output "*   http://www.resplendence.com/registrar_features                                   *"
Write-Output "**************************************************************************************"
