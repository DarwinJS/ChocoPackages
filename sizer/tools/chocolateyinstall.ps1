$ErrorActionPreference = 'Stop';

$packageName= 'sizer'
$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$url        = 'http://www.brianapps.net/sizer4/sizer4_dev562.msi'
$LogFile    = "`"$env:TEMP\chocolatey\$($packageName)\$($packageName).MsiInstall.log`""
$packageArgs = @{
  packageName   = $packageName
  unzipLocation = $toolsDir
  fileType      = 'MSI'
  url           = $url

  #MSI
  silentArgs    = "/qn /norestart /l*v $LogFile"
  validExitCodes= @(0, 3010, 1641)

  softwareName  = 'sizer*'
  checksum      = 'E8091D5165B74EB674455D1896DFB3BF96BAC1A0'
  checksumtype  = 'sha1'
}

Write-Output "The installation log is: $LogFile"

Install-ChocolateyPackage @packageArgs
