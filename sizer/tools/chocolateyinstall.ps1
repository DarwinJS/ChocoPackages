$ErrorActionPreference = 'Stop';

$packageName= 'sizer'
$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$url        = 'http://www.brianapps.net/sizer4/sizer4_dev550.msi'
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
  checksum      = '43BF377195D62C80E3B3CF8B2577F805C24327D5'
  checksumtype  = 'sha1'
}

Write-Output "The installation log is: $LogFile"

Install-ChocolateyPackage @packageArgs
