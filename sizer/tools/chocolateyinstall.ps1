$ErrorActionPreference = 'Stop'; # stop on all errors

$packageName= 'sizer' # arbitrary name for the package, used in messages
$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$url        = 'http://www.brianapps.net/sizer/sizer334.msi' # download url
$LogFile    = "`"$env:TEMP\chocolatey\$($packageName)\$($packageName).MsiInstall.log`""
$packageArgs = @{
  packageName   = $packageName
  unzipLocation = $toolsDir
  fileType      = 'MSI' #only one of these: exe, msi, msu
  url           = $url

  #MSI
  silentArgs    = "/qn /norestart /l*v $LogFile" # ALLUSERS=1 DISABLEDESKTOPSHORTCUT=1 ADDDESKTOPICON=0 ADDSTARTMENU=0
  validExitCodes= @(0, 3010, 1641)

  softwareName  = 'sizer*' #part or all of the Display Name as you see it in Programs and Features. It should be enough to be unique
  checksum      = '5CE3BCEE86C58065442B8E88AE3433A5BEBA7A91'
}

Write-Output "The installation log is: $LogFile"

Install-ChocolateyPackage @packageArgs
