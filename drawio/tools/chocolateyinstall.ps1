$ErrorActionPreference = 'Stop'; # stop on all errors
$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$url        = 'https://github.com/jgraph/drawio-desktop/releases/download/v9.3.1/draw.io-setup-signed-9.3.1.exe'

$packageArgs = @{
  packageName   = $env:ChocolateyPackageName
  unzipLocation = $toolsDir
  fileType      = 'EXE'
  file          = $toolsDir/draw.io-setup-signed-9.3.1.exe
  softwareName  = 'drawio*' #part or all of the Display Name as you see it in Programs and Features. It should be enough to be unique
  checksum      = '4006D22608E2E8DADC7ED196B3F22EF14D301722B73C1D69FB26EF17858379FD'
  checksumType  = 'sha256' #default is md5, can also be sha1, sha256 or sha512
  checksum64    = '4006D22608E2E8DADC7ED196B3F22EF14D301722B73C1D69FB26EF17858379FD'
  checksumType64= 'sha256' #default is checksumType

  # MSI
  silentArgs   = '/S'           # NSIS
  #validExitCodes= @(0) #please insert other valid exit codes here
}

Install-ChocolateyPackage @packageArgs # https://chocolatey.org/docs/helpers-install-chocolatey-package
