
$ErrorActionPreference = 'Stop';
$packageName = 'whocrashed'
$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"

$packageArgs = @{
  packageName   = $packageName
  unzipLocation = $toolsDir
  installerType = 'EXE'
  url           = 'http://www.resplendence.com/download/whocrashedSetup.exe'
  checksum      = '3A8ED4F8D3EC0E64050BB6C4375B4523377BD39B'
  checksumtype  = 'sha1'
  silentArgs    = "/VERYSILENT /NORESTART /LOG=`"$env:temp\CHOCO-INSTALL-whocrashed.log`""
  validExitCodes= @(0, 3010, 1641)
}

Install-ChocolateyPackage @packageargs

Write-Output "********************************************************************"
Write-Output "*  INSTRUCTIONS: Use the start menu to search for `"WhoCrashed`"   *"
Write-Output "*   More Info:                                                     *"
Write-Output "*   http://www.resplendence.com/whocrashed                         *"
Write-Output "********************************************************************"
