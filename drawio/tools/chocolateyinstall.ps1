$ErrorActionPreference = 'Stop';
$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$url        = 'https://github.com/jgraph/drawio-desktop/releases/download/v9.3.1/draw.io-setup-signed-9.3.1.exe'

$packageArgs = @{
  packageName   = $env:ChocolateyPackageName
  unzipLocation = $toolsDir
  fileType      = 'EXE'
  file          = "$toolsDir/draw.io-setup-signed-9.3.1.exe"
  softwareName  = 'drawio*'
  checksum      = '4006D22608E2E8DADC7ED196B3F22EF14D301722B73C1D69FB26EF17858379FD'
  checksumType  = 'sha256'
  silentArgs   = '/S'
}

Install-ChocolateyPackage @packageArgs
