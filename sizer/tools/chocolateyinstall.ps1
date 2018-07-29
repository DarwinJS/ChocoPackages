$ErrorActionPreference = 'Stop';

$packageName= 'sizer'
$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$url        = 'http://www.brianapps.net/sizer4/sizer4_dev570.msi'
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
  checksum      = 'CE5529FAA4F4392A60FDB558545D88DD9DD8AB11'
  checksumtype  = 'sha1'
}

Write-Output "The installation log is: $LogFile"

Install-ChocolateyPackage @packageArgs
