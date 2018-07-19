
$ErrorActionPreference = 'Stop';
$packageName = 'whysoslow'
$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"

$packageArgs = @{
  packageName   = $packageName
  unzipLocation = $toolsDir
  installerType = 'EXE'
  url           = 'http://www.resplendence.com/download/whysoslowSetup.exe'
  checksum      = '0B84948FB0A74ED87D8872B55A6EBBA0F5566EF6'
  checksumtype  = 'sha1'
  silentArgs    = "/VERYSILENT /NORESTART /LOG=`"$env:temp\CHOCO-INSTALL-whysoslow.log`""
  validExitCodes= @(0, 3010, 1641)
}

Install-ChocolateyPackage @packageargs

Write-Output "********************************************************************"
Write-Output "*  INSTRUCTIONS: Use the start menu to search for `"whysoslow`"   *"
Write-Output "*   More Info:                                                     *"
Write-Output "*   http://www.resplendence.com/whysoslow                         *"
Write-Output "********************************************************************"
